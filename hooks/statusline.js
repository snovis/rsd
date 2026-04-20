#!/usr/bin/env node
// rsd statusline — Claude Code statusline, rsd-aware
// Shows: host | model | current task | directory (branch) | [H:Xm] | context bar
//
// Gracefully degrades when no .rsd/ is present — behaves identically to
// the standalone rymare-cli-bar.
//
// Install: handled by install.sh, which copies this to ~/.claude/hooks/
// and registers it as the statusLine command in settings.json.

const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');
const { execSync } = require('child_process');

// Walk up from startDir to find .git (dir or file for worktrees/submodules).
function findGitDir(startDir) {
  let dir = path.resolve(startDir);
  while (true) {
    const gitPath = path.join(dir, '.git');
    try {
      const stat = fs.statSync(gitPath);
      if (stat.isDirectory()) return { gitDir: gitPath, workDir: dir };
      const contents = fs.readFileSync(gitPath, 'utf8').trim();
      const m = contents.match(/^gitdir:\s*(.+)$/);
      if (m) {
        const gitDir = path.isAbsolute(m[1]) ? m[1] : path.resolve(dir, m[1]);
        return { gitDir, workDir: dir };
      }
      return null;
    } catch (e) {}
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

// Walk up from startDir to find .rsd (handoff state folder).
function findRsdDir(startDir) {
  let dir = path.resolve(startDir);
  while (true) {
    const rsdPath = path.join(dir, '.rsd');
    try {
      const stat = fs.statSync(rsdPath);
      if (stat.isDirectory()) return rsdPath;
    } catch (e) {}
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

function readBranch(gitDir) {
  try {
    const head = fs.readFileSync(path.join(gitDir, 'HEAD'), 'utf8').trim();
    const m = head.match(/^ref:\s*refs\/heads\/(.+)$/);
    if (m) return { name: m[1], detached: false };
    return { name: head.slice(0, 7), detached: true };
  } catch (e) {
    return null;
  }
}

// Cache dirty status for 2s to keep statusline renders cheap.
function getDirty(workDir) {
  const key = crypto.createHash('md5').update(workDir).digest('hex').slice(0, 12);
  const cachePath = path.join(os.tmpdir(), `rsd-git-${key}.json`);
  const now = Date.now();
  const TTL_MS = 2000;

  try {
    const cache = JSON.parse(fs.readFileSync(cachePath, 'utf8'));
    if (now - cache.timestamp < TTL_MS) return cache.dirty;
  } catch (e) {}

  try {
    const out = execSync('git status --porcelain', {
      cwd: workDir,
      timeout: 500,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    });
    const dirty = out.trim().length > 0;
    try { fs.writeFileSync(cachePath, JSON.stringify({ dirty, timestamp: now })); } catch (e) {}
    return dirty;
  } catch (e) {
    return null;
  }
}

// Handoff freshness: minutes since .rsd/HANDOFF.md was last written.
// Returns null if no handoff file exists.
function getHandoffAge(rsdDir) {
  if (!rsdDir) return null;
  const handoffPath = path.join(rsdDir, 'HANDOFF.md');
  try {
    const stat = fs.statSync(handoffPath);
    const ageMs = Date.now() - stat.mtimeMs;
    return Math.floor(ageMs / 60000);  // minutes
  } catch (e) {
    return null;
  }
}

// Format handoff age as "Xm" / "Xh" / "Xd".
function formatAge(minutes) {
  if (minutes < 60) return `${minutes}m`;
  if (minutes < 60 * 24) return `${Math.floor(minutes / 60)}h`;
  return `${Math.floor(minutes / (60 * 24))}d`;
}

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const model = data.model?.display_name || 'Claude';
    const dir = data.workspace?.current_dir || process.cwd();
    const session = data.session_id || '';
    const remaining = data.context_window?.remaining_percentage;

    // ── Context bar ─────────────────────────────────────────────
    // Claude Code reserves ~16.5% for auto-compact; scale to "usable".
    const AUTO_COMPACT_BUFFER_PCT = 16.5;
    let ctx = '';
    let used = null;
    if (remaining != null) {
      const usableRemaining = Math.max(
        0,
        ((remaining - AUTO_COMPACT_BUFFER_PCT) / (100 - AUTO_COMPACT_BUFFER_PCT)) * 100
      );
      used = Math.max(0, Math.min(100, Math.round(100 - usableRemaining)));
      const filled = Math.floor(used / 10);
      const bar = '█'.repeat(filled) + '░'.repeat(10 - filled);
      if (used < 50) ctx = ` \x1b[32m${bar} ${used}%\x1b[0m`;
      else if (used < 65) ctx = ` \x1b[33m${bar} ${used}%\x1b[0m`;
      else if (used < 80) ctx = ` \x1b[38;5;208m${bar} ${used}%\x1b[0m`;
      else ctx = ` \x1b[5;31m💀 ${bar} ${used}%\x1b[0m`;

      // Bridge file: let context-monitor read current usage without re-parsing.
      if (session) {
        try {
          const bridgePath = path.join(os.tmpdir(), `rsd-ctx-${session}.json`);
          fs.writeFileSync(bridgePath, JSON.stringify({
            session_id: session,
            remaining_percentage: remaining,
            used_pct: used,
            timestamp: Math.floor(Date.now() / 1000)
          }));
        } catch (e) {}
      }
    }

    // ── Current task (from Claude Code's todos) ─────────────────
    let task = '';
    const homeDir = os.homedir();
    const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(homeDir, '.claude');
    const todosDir = path.join(claudeDir, 'todos');
    if (session && fs.existsSync(todosDir)) {
      try {
        const files = fs.readdirSync(todosDir)
          .filter(f => f.startsWith(session) && f.includes('-agent-') && f.endsWith('.json'))
          .map(f => ({ name: f, mtime: fs.statSync(path.join(todosDir, f)).mtime }))
          .sort((a, b) => b.mtime - a.mtime);
        if (files.length > 0) {
          try {
            const todos = JSON.parse(fs.readFileSync(path.join(todosDir, files[0].name), 'utf8'));
            const inProgress = todos.find(t => t.status === 'in_progress');
            if (inProgress) task = inProgress.activeForm || '';
          } catch (e) {}
        }
      } catch (e) {}
    }

    // ── Git branch ──────────────────────────────────────────────
    let git = '';
    const gitInfo = findGitDir(dir);
    if (gitInfo) {
      const branch = readBranch(gitInfo.gitDir);
      if (branch) {
        if (branch.detached) {
          git = ` \x1b[2m(@${branch.name})\x1b[0m`;
        } else {
          const dirty = getDirty(gitInfo.workDir);
          if (dirty === true) git = ` \x1b[33m(${branch.name}●)\x1b[0m`;
          else git = ` \x1b[32m(${branch.name})\x1b[0m`;
        }
      }
    }

    // ── Handoff freshness (rsd-aware segment) ───────────────────
    let handoff = '';
    const rsdDir = findRsdDir(dir);
    const handoffAgeMin = getHandoffAge(rsdDir);
    if (handoffAgeMin != null) {
      const ageStr = formatAge(handoffAgeMin);
      // Color by staleness + context. Nudge visually when it's been a while
      // AND context is climbing — the "consider handing off" signal.
      let color = '\x1b[2m';  // dim default
      if (handoffAgeMin > 30 && used != null && used > 50) color = '\x1b[33m';  // yellow
      if (handoffAgeMin > 60 && used != null && used > 60) color = '\x1b[38;5;208m';  // orange
      handoff = ` ${color}H:${ageStr}\x1b[0m`;
    }

    // ── Render ──────────────────────────────────────────────────
    const dirname = path.basename(dir);
    const host = (os.hostname() || '').split('.')[0];
    const hostPrefix = host ? `\x1b[1;95m${host}\x1b[0m │ ` : '';
    const modelSeg = `\x1b[2m${model}\x1b[0m`;
    const dirSeg = `\x1b[2m${dirname}\x1b[0m`;

    if (task) {
      const taskSeg = `\x1b[1m${task}\x1b[0m`;
      process.stdout.write(`${hostPrefix}${modelSeg} │ ${taskSeg} │ ${dirSeg}${git}${handoff}${ctx}`);
    } else {
      process.stdout.write(`${hostPrefix}${modelSeg} │ ${dirSeg}${git}${handoff}${ctx}`);
    }
  } catch (e) {
    // Silent fail — don't break statusline on parse errors.
  }
});
