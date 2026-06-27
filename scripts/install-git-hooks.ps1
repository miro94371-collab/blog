$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$hookDir = Join-Path $repoRoot ".git/hooks"
$preCommitPath = Join-Path $hookDir "pre-commit"
$hookPath = Join-Path $hookDir "pre-push"

if (-not (Test-Path $hookDir)) {
    New-Item -ItemType Directory -Path $hookDir | Out-Null
}

$preCommitContent = @'
#!/bin/sh
set -e

if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/update-site-stats.ps1
else
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/update-site-stats.ps1
fi

if ! git diff --quiet -- data/site_stats.toml; then
    git add data/site_stats.toml
fi
'@

$prePushContent = @'
#!/bin/sh
set -e

if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/update-site-stats.ps1
else
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/update-site-stats.ps1
fi

if ! git diff --quiet -- data/site_stats.toml; then
    echo "Site stats changed after your last commit."
    echo "Please commit data/site_stats.toml, then push again."
    exit 1
fi
'@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($preCommitPath, $preCommitContent.Replace("`r`n", "`n"), $utf8NoBom)
[System.IO.File]::WriteAllText($hookPath, $prePushContent.Replace("`r`n", "`n"), $utf8NoBom)

Write-Host "Installed pre-commit hook: $preCommitPath"
Write-Host "Installed pre-push hook: $hookPath"
