# rsd installer (Windows / PowerShell)
#
# One-shot install. Registers rsd as a marketplace plugin in %USERPROFILE%\.claude\settings.json
# AND installs the statusline to %USERPROFILE%\.claude\hooks\. After this runs, restart Claude
# Code and rsd auto-loads everywhere - no --plugin-dir, no aliases.
#
# For dev mode (working on rsd itself), override with:
#   claude --plugin-dir C:\Users\<you>\dev\rsd
#
# Safe to re-run.
#
# Run from a normal PowerShell prompt:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
# Symlink creation is best-effort; enable Windows "Developer Mode" (or run as admin)
# for a live-updating link, otherwise the script falls back to a plain copy.

$ErrorActionPreference = 'Stop'

$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
$HooksDir  = Join-Path $ClaudeDir 'hooks'
$Settings  = Join-Path $ClaudeDir 'settings.json'
$ScriptDir = $PSScriptRoot

Write-Host "rsd installer (Windows)"
Write-Host "  CLAUDE_DIR: $ClaudeDir"
Write-Host "  source:     $ScriptDir"
Write-Host ""

# -- Ensure directories + settings.json exist -----------------------
New-Item -ItemType Directory -Force -Path $HooksDir | Out-Null
if (-not (Test-Path $Settings)) {
  '{}' | Out-File -FilePath $Settings -Encoding utf8
}

# -- Install statusline (symlink if possible, else copy) ------------
$StatuslineSrc  = Join-Path $ScriptDir 'hooks\statusline.js'
$StatuslineDest = Join-Path $HooksDir 'rsd-statusline.js'

if (Test-Path $StatuslineDest) {
  $item = Get-Item $StatuslineDest -Force
  $isLink = $item.Attributes -band [IO.FileAttributes]::ReparsePoint
  if ($isLink) {
    Remove-Item $StatuslineDest -Force
  } else {
    $backup = "$StatuslineDest.backup"
    Write-Host "  backing up existing $StatuslineDest to $backup"
    Move-Item $StatuslineDest $backup -Force
  }
}

$linked = $false
try {
  New-Item -ItemType SymbolicLink -Path $StatuslineDest -Target $StatuslineSrc -ErrorAction Stop | Out-Null
  $linked = $true
  Write-Host "  linked statusline: $StatuslineDest -> $StatuslineSrc"
} catch {
  Copy-Item $StatuslineSrc $StatuslineDest -Force
  Write-Host "  copied statusline: $StatuslineDest (symlink unavailable)"
  Write-Host "    note: enable Developer Mode or run as admin for a live-updating link."
  Write-Host "    otherwise re-run this script after 'git pull' to refresh the statusline."
}

# -- Load settings.json ---------------------------------------------
$json = Get-Content $Settings -Raw
if ([string]::IsNullOrWhiteSpace($json)) { $json = '{}' }
$s = $json | ConvertFrom-Json

# Helper: set/overwrite a property on a PSCustomObject
function Set-Prop($obj, $name, $value) {
  $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value -Force
}
# Helper: ensure a nested PSCustomObject property exists, return it
function Ensure-Obj($obj, $name) {
  if ($null -eq $obj.$name) {
    Set-Prop $obj $name ([pscustomobject]@{})
  }
  return $obj.$name
}

# -- Patch settings.json: statusLine --------------------------------
# Concrete resolved path (works whether the statusline runs under cmd or PowerShell).
$StatusLineCmd = 'node "' + $StatuslineDest + '"'
if ($s.statusLine -and $s.statusLine.command -ne $StatusLineCmd) {
  Set-Prop $s 'statusLine_backup' $s.statusLine
}
Set-Prop $s 'statusLine' ([pscustomobject]@{ type = 'command'; command = $StatusLineCmd })
Write-Host "  patched $Settings (statusLine)"

# -- Patch settings.json: register rsd marketplace + enable plugin --
# This is what makes rsd auto-load in every session without --plugin-dir.
$mkts = Ensure-Obj $s 'extraKnownMarketplaces'
Set-Prop $mkts 'snovis' ([pscustomobject]@{
  source = [pscustomobject]@{ source = 'github'; repo = 'snovis/rsd' }
})
$plugins = Ensure-Obj $s 'enabledPlugins'
Set-Prop $plugins 'rsd@snovis' $true
Write-Host "  patched $Settings (extraKnownMarketplaces.snovis, enabledPlugins['rsd@snovis'])"

# -- Write settings.json back ---------------------------------------
$s | ConvertTo-Json -Depth 100 | Out-File -FilePath $Settings -Encoding utf8

Write-Host ""
Write-Host "Done. Restart Claude Code to activate."
Write-Host ""
Write-Host "On first launch, Claude Code will clone snovis/rsd into its plugin cache"
Write-Host "and auto-load /rsd:handoff, /rsd:ho, /rsd:pickup, /rsd:pu."
Write-Host ""
Write-Host "To check:"
Write-Host "  /plugin marketplace list       (should show 'snovis')"
Write-Host "  /plugin list                   (should show 'rsd@snovis' enabled)"
Write-Host "  /rsd:handoff                   (try it in any git project)"
Write-Host ""
Write-Host "For dev mode on this repo, override with:"
Write-Host "  claude --plugin-dir `"$ScriptDir`""
