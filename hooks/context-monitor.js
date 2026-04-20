#!/usr/bin/env node
// rsd context monitor — PostToolUse hook
//
// Purpose: proactive nudge toward /rsd:handoff before context fills.
// Reads the bridge file written by statusline.js and injects an
// agent-facing message when context crosses thresholds we haven't
// nudged for yet this session.
//
// Advisory only — never blocks tool execution.

const fs = require('fs');
const path = require('path');
const os = require('os');

// Thresholds: at each one, nudge once per session.
// Escalates with urgency.
const THRESHOLDS = [
  { pct: 45, message: 'Context is at {used}%. Good time to /rsd:handoff if you want a clean break soon.' },
  { pct: 60, message: 'Context at {used}%. Consider /rsd:handoff before you hit the wall at 80%.' },
  { pct: 75, message: 'Context at {used}% — strongly recommend /rsd:handoff now. Auto-compact triggers at ~83%.' },
];

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const session = data.session_id;
    if (!session) { process.exit(0); }

    // Read context from the bridge file (written by statusline.js).
    const bridgePath = path.join(os.tmpdir(), `rsd-ctx-${session}.json`);
    let bridge;
    try {
      bridge = JSON.parse(fs.readFileSync(bridgePath, 'utf8'));
    } catch (e) {
      process.exit(0);  // statusline hasn't written yet — nothing to do.
    }

    const used = bridge.used_pct;
    if (used == null) { process.exit(0); }

    // Track which thresholds we've already nudged for in this session.
    const nudgePath = path.join(os.tmpdir(), `rsd-nudge-${session}.json`);
    let nudged = [];
    try {
      nudged = JSON.parse(fs.readFileSync(nudgePath, 'utf8')).nudged || [];
    } catch (e) {}

    // Find the highest threshold crossed that we haven't nudged for.
    let toNudge = null;
    for (const t of THRESHOLDS) {
      if (used >= t.pct && !nudged.includes(t.pct)) {
        toNudge = t;  // keep going — escalate to highest crossed.
      }
    }

    if (!toNudge) { process.exit(0); }

    // Record that we nudged for this threshold.
    nudged.push(toNudge.pct);
    try {
      fs.writeFileSync(nudgePath, JSON.stringify({ nudged }));
    } catch (e) {}

    const msg = toNudge.message.replace('{used}', String(used));
    const output = {
      hookSpecificOutput: {
        hookEventName: 'PostToolUse',
        additionalContext: `📎 ${msg}`,
      },
    };
    process.stdout.write(JSON.stringify(output));
  } catch (e) {
    // Silent fail — never block tool execution.
    process.exit(0);
  }
});
