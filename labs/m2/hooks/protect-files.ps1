# PreToolUse guardrail (PowerShell twin of protect-files.sh) for Edit|Write|MultiEdit.
# Register in .claude/settings.json with:
#   { "type": "command", "shell": "powershell",
#     "command": "& \"$env:CLAUDE_PROJECT_DIR/.claude/hooks/protect-files.ps1\"" }
# Input: hook JSON on stdin. Output: exit 2 + stderr message (fed back to Claude) to block.
$ErrorActionPreference = 'Stop'
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try   { $data = $raw | ConvertFrom-Json } catch { exit 0 }
$filePath = $null
if ($data.tool_input -and $data.tool_input.file_path) { $filePath = [string]$data.tool_input.file_path }
if (-not $filePath) { exit 0 }                       # not a file tool call: allow
$filePath = $filePath -replace '\\', '/'             # normalise Windows backslashes

$protected = @('.env', '_pb2.py', '.pb.go', 'pb/', 'package-lock.json')
foreach ($pattern in $protected) {
  if ($filePath.Contains($pattern)) {
    [Console]::Error.WriteLine("Blocked: $filePath matches protected pattern '$pattern'. Generated protobuf code, lockfiles and .env files are never hand-edited in this repo; change the source (.proto / package.json) or ask the user.")
    exit 2
  }
}
exit 0
