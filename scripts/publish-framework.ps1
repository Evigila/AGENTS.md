#requires -Version 5.1
[CmdletBinding()]
param([string]$Version, [switch]$Check)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$manifestPath = Join-Path $root 'AGENTS.framework.json'
$manifest = [IO.File]::ReadAllText($manifestPath, $utf8) | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1) { throw 'Unsupported manifest schema.' }
if (-not $Version) { $Version = [string]$manifest.frameworkVersion }
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Use a stable major.minor.patch version.' }
$changed = $false
foreach ($entry in @($manifest.files)) {
    if ($entry.source -match '[\\:]' -or $entry.source.StartsWith('/') -or @($entry.source.Split('/') | Where-Object { $_ -in @('', '.', '..', '.git') }).Count -gt 0) { throw 'Invalid manifest source path.' }
    $text = [IO.File]::ReadAllText((Join-Path $root $entry.source), $utf8).TrimStart([char]0xFEFF).Replace("`r`n", "`n")
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try { $hash = ([BitConverter]::ToString($algorithm.ComputeHash($utf8.GetBytes($text)))).Replace('-', '').ToLowerInvariant() }
    finally { $algorithm.Dispose() }
    if ($hash -ne $entry.sha256) { $changed = $true }
    $entry.sha256 = $hash
}
if ($Check) {
    if ($changed) { throw 'Manifest hashes are stale. Publish a new framework version.' }
    Write-Host "Framework $($manifest.frameworkVersion) payload hashes verified."
    exit 0
}
if ([version]$Version -le [version]$manifest.frameworkVersion) { throw 'Publishing requires a strictly greater framework version.' }
$manifest.frameworkVersion = $Version
[IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 20) + "`n", $utf8)
Write-Host "Prepared framework $Version. Run the tests, review the diff, and commit the release."
