#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Repository,
    [string]$Ref,
    [string]$SourcePath,
    [switch]$Check,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false, $true)

function Get-ContentHash([byte[]]$Bytes) {
    $text = $utf8.GetString($Bytes).TrimStart([char]0xFEFF).Replace("`r`n", "`n")
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($algorithm.ComputeHash($utf8.GetBytes($text)))).Replace('-', '').ToLowerInvariant() }
    finally { $algorithm.Dispose() }
}

function Read-Json([byte[]]$Bytes) {
    return ($utf8.GetString($Bytes).TrimStart([char]0xFEFF) | ConvertFrom-Json)
}

function Quote-NativeArgument([string]$Value) {
    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append('"')
    $slashes = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '\') { $slashes++; continue }
        if ($character -eq '"') {
            [void]$builder.Append(('\' * (2 * $slashes + 1)))
            [void]$builder.Append('"')
        } else {
            [void]$builder.Append(('\' * $slashes))
            [void]$builder.Append($character)
        }
        $slashes = 0
    }
    [void]$builder.Append(('\' * (2 * $slashes)))
    [void]$builder.Append('"')
    return $builder.ToString()
}

function Invoke-GitBytes([string[]]$GitArguments) {
    $start = New-Object System.Diagnostics.ProcessStartInfo
    $start.FileName = 'git'
    $start.Arguments = (($GitArguments | ForEach-Object { Quote-NativeArgument $_ }) -join ' ')
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.EnvironmentVariables['GIT_TERMINAL_PROMPT'] = '0'
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $start
    $buffer = New-Object System.IO.MemoryStream
    try {
        [void]$process.Start()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $process.StandardOutput.BaseStream.CopyTo($buffer)
        $process.WaitForExit()
        $stderrText = $stderrTask.Result
        if ($process.ExitCode -ne 0) { throw "Git failed ($($process.ExitCode)): $stderrText" }
        return ,$buffer.ToArray()
    } finally { $buffer.Dispose(); $process.Dispose() }
}

function Invoke-GitText([string[]]$GitArguments) {
    return $utf8.GetString((Invoke-GitBytes $GitArguments)).Trim()
}

function Assert-RelativePath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -match '[\\:<>"|?*\x00-\x1f]' -or $Path.StartsWith('/') -or
        $Path.EndsWith('/') -or @($Path.Split('/') | Where-Object {
            $_ -in @('', '.', '..', '.git') -or $_ -match '[. ]$' -or
            $_ -match '^(?i:CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])(?:\.|$)'
        }).Count -gt 0) {
        throw "Invalid framework path: $Path"
    }
}

function Assert-ManagedPath([string]$Path) {
    Assert-RelativePath $Path
    if ($Path -notin @('AGENTS.md', 'AGENTS.framework.json', 'fetch-agents.bat', 'scripts/fetch-agents.ps1') -and
        -not $Path.StartsWith('docs-ai/common/', [StringComparison]::Ordinal) -and
        -not $Path.StartsWith('.agents/skills/', [StringComparison]::Ordinal)) {
        throw "Path is outside managed framework locations: $Path"
    }
}

function Get-SafeTarget([string]$Root, [string]$Relative) {
    Assert-RelativePath $Relative
    $target = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    $cursor = $target
    while ($cursor -and $cursor.Length -ge $Root.Length) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Refusing linked destination: $cursor" }
        }
        if ($cursor -eq $Root) { break }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
    return $target
}

function Get-ExistingHash([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    if (-not [IO.File]::Exists($Path)) { throw "Expected a regular file: $Path" }
    $bytes = [IO.File]::ReadAllBytes($Path)
    try { return Get-ContentHash $bytes }
    catch {
        if ($_.Exception -is [Text.DecoderFallbackException] -or $_.Exception.InnerException -is [Text.DecoderFallbackException]) {
            return '(invalid UTF-8 local content)'
        }
        throw
    }
}

function Read-SourceFile([string]$Relative) {
    Assert-RelativePath $Relative
    $treeEntry = Invoke-GitText @('-C', $source, 'ls-tree', $commit, '--', $Relative)
    if ($treeEntry -notmatch '^(100644|100755) blob [0-9a-f]{40}\t') { throw "Source is not a regular Git file: $Relative" }
    return ,(Invoke-GitBytes @('-C', $source, 'show', ($commit + ':' + $Relative)))
}

function Write-AtomicBytes([string]$Path, [byte[]]$Bytes) {
    $temporary = $Path + '.' + [Guid]::NewGuid().ToString('N') + '.tmp'
    try {
        [IO.File]::WriteAllBytes($temporary, $Bytes)
        if ([IO.File]::Exists($Path)) { [IO.File]::Replace($temporary, $Path, [NullString]::Value) }
        else { [IO.File]::Move($temporary, $Path) }
    } finally {
        if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}

$temporaryRepository = $null
$exitCode = 1
try {
    $root = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    if (-not [IO.Directory]::Exists($root)) { throw 'ProjectRoot must be an existing project directory.' }
    $gitRoot = [IO.Path]::GetFullPath((Invoke-GitText @('-C', $root, 'rev-parse', '--show-toplevel'))).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    if (-not $root.Equals($gitRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Run the installer at the target Git repository root.' }
    $lockPath = Get-SafeTarget $root 'AGENTS.lock.json'
    $installed = $null
    $baseline = @{}
    if ([IO.File]::Exists($lockPath)) {
        $installed = Read-Json ([IO.File]::ReadAllBytes($lockPath))
        if ($installed.schemaVersion -ne 1 -or $installed.frameworkVersion -notmatch '^\d+\.\d+\.\d+$' -or
            $installed.manifestSha256 -notmatch '^[0-9a-f]{64}$' -or $installed.commit -notmatch '^[0-9a-f]{40}$') {
            throw 'Invalid AGENTS.lock.json. Resolve its state before synchronizing.'
        }
        foreach ($property in $installed.managedFiles.PSObject.Properties) {
            Assert-ManagedPath $property.Name
            if ($property.Value -notmatch '^[0-9a-f]{64}$') { throw 'Invalid managed file hash in AGENTS.lock.json.' }
            $baseline[$property.Name] = [string]$property.Value
        }
    }
    if ([string]::IsNullOrWhiteSpace($Repository)) {
        $Repository = if ($installed) { [string]$installed.repository } else { 'https://github.com/Evigila/AGENTS.md.git' }
    }
    if ([string]::IsNullOrWhiteSpace($Ref)) { $Ref = if ($installed) { [string]$installed.ref } else { 'main' } }
    if ($Repository.StartsWith('-') -or $Ref.StartsWith('-')) { throw 'Repository and Ref must not be Git command options.' }
    if ($SourcePath) {
        $source = [IO.Path]::GetFullPath($SourcePath)
        if ($source.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { throw 'SourcePath must not be the target repository.' }
        $commit = Invoke-GitText @('-C', $source, 'rev-parse', ($Ref + '^{commit}'))
    } else {
        $temporaryRepository = Join-Path ([IO.Path]::GetTempPath()) ('agents-source-' + [Guid]::NewGuid().ToString('N'))
        [void](Invoke-GitText @('init', '--bare', '--quiet', $temporaryRepository))
        [void](Invoke-GitText @('-C', $temporaryRepository, 'fetch', '--quiet', '--no-tags', '--depth=1', $Repository, $Ref))
        $source = $temporaryRepository
        $commit = Invoke-GitText @('-C', $source, 'rev-parse', 'FETCH_HEAD^{commit}')
    }
    if ($commit -notmatch '^[0-9a-f]{40}$') { throw 'The source must resolve to one Git commit.' }
    $manifestBytes = Read-SourceFile 'AGENTS.framework.json'
    $manifest = Read-Json $manifestBytes
    if ($manifest.schemaVersion -ne 1 -or $manifest.frameworkVersion -notmatch '^\d+\.\d+\.\d+$') { throw 'Unsupported framework manifest.' }
    $manifestHash = Get-ContentHash $manifestBytes
    if ($installed -and ([version]$manifest.frameworkVersion -lt [version]$installed.frameworkVersion) -and -not $Force) {
        throw 'The requested framework version is older. Use -Force only for an intentional rollback.'
    }
    if ($installed -and $manifest.frameworkVersion -eq $installed.frameworkVersion -and $manifestHash -ne $installed.manifestSha256) {
        throw 'Framework content changed without a version increment. Publish a new version first.'
    }
    $desired = @{}
    $managedHashes = [ordered]@{}
    foreach ($entry in @($manifest.files)) {
        Assert-RelativePath ([string]$entry.source)
        Assert-RelativePath ([string]$entry.target)
        if ($desired.ContainsKey($entry.target) -or $entry.target -in @('AGENTS.framework.json', 'AGENTS.lock.json')) { throw 'Duplicate or reserved manifest target.' }
        if ($entry.mode -eq 'managed') { Assert-ManagedPath $entry.target }
        elseif ($entry.mode -eq 'seed') {
            if ($entry.target -ne 'AGENTS.ensure.json' -and $entry.target -ne 'docs/.gitkeep' -and
                -not $entry.target.StartsWith('docs-ai/current/', [StringComparison]::Ordinal)) { throw 'Invalid project template target.' }
        } else { throw 'Unknown manifest file mode.' }
        if ($entry.sha256 -notmatch '^[0-9a-f]{64}$') { throw 'Invalid payload hash.' }
        $bytes = Read-SourceFile $entry.source
        if ((Get-ContentHash $bytes) -ne $entry.sha256) { throw "Payload hash mismatch: $($entry.source)" }
        $desired[$entry.target] = [pscustomobject]@{ mode = $entry.mode; bytes = $bytes; hash = $entry.sha256 }
        if ($entry.mode -eq 'managed') { $managedHashes[$entry.target] = $entry.sha256 }
    }
    foreach ($required in @('AGENTS.md', 'fetch-agents.bat', 'scripts/fetch-agents.ps1', 'docs-ai/common/rules.md', 'docs-ai/common/codedesign.md', 'docs-ai/common/UIUX.md')) {
        if (-not $managedHashes.Contains($required)) { throw "Required managed file is missing: $required" }
    }
    $desired['AGENTS.framework.json'] = [pscustomobject]@{ mode = 'managed'; bytes = $manifestBytes; hash = $manifestHash }
    $managedHashes['AGENTS.framework.json'] = $manifestHash
    $operations = New-Object System.Collections.Generic.List[object]
    $conflicts = New-Object System.Collections.Generic.List[string]
    foreach ($relative in @($desired.Keys | Sort-Object)) {
        $target = Get-SafeTarget $root $relative
        $entry = $desired[$relative]
        if ($entry.mode -eq 'seed') {
            if (Test-Path -LiteralPath $target) {
                if (-not [IO.File]::Exists($target)) { throw "Expected a regular project file: $target" }
            } else { $operations.Add([pscustomobject]@{ relative = $relative; path = $target; bytes = $entry.bytes; delete = $false }) }
            continue
        }
        $actualHash = Get-ExistingHash $target
        if ($actualHash -eq $entry.hash) { continue }
        if (($baseline.ContainsKey($relative) -and $actualHash -ne $baseline[$relative]) -or
            (-not $baseline.ContainsKey($relative) -and $null -ne $actualHash)) { $conflicts.Add($relative) }
        $operations.Add([pscustomobject]@{ relative = $relative; path = $target; bytes = $entry.bytes; delete = $false })
    }
    foreach ($relative in @($baseline.Keys | Sort-Object)) {
        if ($managedHashes.Contains($relative)) { continue }
        $target = Get-SafeTarget $root $relative
        $actualHash = Get-ExistingHash $target
        if ($null -eq $actualHash) { continue }
        if ($actualHash -ne $baseline[$relative]) { $conflicts.Add($relative) }
        $operations.Add([pscustomobject]@{ relative = $relative; path = $target; bytes = $null; delete = $true })
    }
    $installedVersion = if ($installed) { $installed.frameworkVersion } else { '(not installed)' }
    Write-Host "[Agents] Installed: $installedVersion; source: $($manifest.frameworkVersion); commit: $commit"
    $needsUpdate = -not $installed -or $operations.Count -gt 0 -or $manifestHash -ne $installed.manifestSha256 -or
        $Repository -ne $installed.repository -or $Ref -ne $installed.ref
    if ($conflicts.Count -gt 0) { Write-Host ('[Agents] Local conflicts: ' + ($conflicts -join ', ')) }
    if ($Check) {
        if ($conflicts.Count -gt 0) { $exitCode = 3 }
        elseif ($needsUpdate) { Write-Host '[Agents] Update available.'; $exitCode = 2 }
        else { Write-Host '[Agents] Up to date.'; $exitCode = 0 }
    } elseif ($conflicts.Count -gt 0 -and -not $Force) {
        throw 'Local framework changes detected, including committed customizations. Resolve them or rerun with -Force to back up and replace managed files.'
    } elseif (-not $needsUpdate) {
        Write-Host '[Agents] Up to date.'
        $exitCode = 0
    } else {
        $nextLock = [ordered]@{
            schemaVersion = 1; repository = $Repository; ref = $Ref; commit = $commit
            frameworkVersion = $manifest.frameworkVersion; manifestSha256 = $manifestHash
            managedFiles = $managedHashes; synchronizedAtUtc = [DateTime]::UtcNow.ToString('o')
        }
        $lockBytes = $utf8.GetBytes(($nextLock | ConvertTo-Json -Depth 20) + "`n")
        $operations.Add([pscustomobject]@{ relative = 'AGENTS.lock.json'; path = $lockPath; bytes = $lockBytes; delete = $false })
        $snapshots = @{}
        foreach ($operation in $operations) {
            $snapshots[$operation.path] = if ([IO.File]::Exists($operation.path)) { [IO.File]::ReadAllBytes($operation.path) } else { $null }
        }
        if ($Force -and $conflicts.Count -gt 0) {
            $backupRelative = '.agents/backups/' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [Guid]::NewGuid().ToString('N')
            foreach ($relative in $conflicts) {
                $original = Get-SafeTarget $root $relative
                if (-not [IO.File]::Exists($original)) { continue }
                $backup = Get-SafeTarget $root ($backupRelative + '/' + $relative)
                [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($backup))
                [IO.File]::Copy($original, $backup, $false)
            }
            Write-Host "[Agents] Local changes backed up to $backupRelative"
        }
        $createdDirectories = New-Object System.Collections.Generic.List[string]
        try {
            foreach ($operation in $operations) {
                $parent = [IO.Path]::GetDirectoryName($operation.path)
                $missingParents = New-Object System.Collections.Generic.List[string]
                while (-not [IO.Directory]::Exists($parent)) {
                    $missingParents.Add($parent); $parent = [IO.Path]::GetDirectoryName($parent)
                }
                for ($index = $missingParents.Count - 1; $index -ge 0; $index--) {
                    [void][IO.Directory]::CreateDirectory($missingParents[$index]); $createdDirectories.Add($missingParents[$index])
                }
                if ($operation.delete) { [IO.File]::Delete($operation.path) }
                else { Write-AtomicBytes $operation.path $operation.bytes }
            }
        } catch {
            $writeFailure = $_
            foreach ($operation in $operations) {
                try {
                    if ($null -eq $snapshots[$operation.path]) { if ([IO.File]::Exists($operation.path)) { [IO.File]::Delete($operation.path) } }
                    elseif ([IO.Directory]::Exists([IO.Path]::GetDirectoryName($operation.path))) { Write-AtomicBytes $operation.path $snapshots[$operation.path] }
                } catch { Write-Warning "Rollback needs manual review: $($operation.relative)" }
            }
            for ($index = $createdDirectories.Count - 1; $index -ge 0; $index--) {
                if (@(Get-ChildItem -LiteralPath $createdDirectories[$index] -Force).Count -eq 0) { [IO.Directory]::Delete($createdDirectories[$index]) }
            }
            throw $writeFailure
        }
        Write-Host '[Agents] Framework synchronized. Review git status and commit in the target project when ready.'
        $exitCode = 0
    }
} catch { Write-Host ('[Agents] Error: ' + $_.Exception.Message) -ForegroundColor Red; $exitCode = 1 }
finally {
    if ($temporaryRepository -and [IO.Directory]::Exists($temporaryRepository)) { Remove-Item -LiteralPath $temporaryRepository -Recurse -Force }
}
exit $exitCode
