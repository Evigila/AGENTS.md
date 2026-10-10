#requires -Version 5.1
[CmdletBinding()]
param([switch]$KeepFixtures)

# Run with powershell.exe or pwsh -NoProfile -File tests/test-sync.ps1.
# All source and project repositories live in a temporary directory; no network,
# Pester, global Git configuration, or changes to this checkout are required.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false, $true)
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$powerShellName = if ($PSVersionTable.PSEdition -eq 'Desktop') { 'powershell.exe' }
    elseif ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { 'pwsh.exe' }
    else { 'pwsh' }
$powerShellExecutable = Join-Path $PSHOME $powerShellName
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('agents-sync-tests-' + [Guid]::NewGuid().ToString('N'))
$testCount = 0
$skipCount = 0
$successful = $false

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Assert-Equal($Expected, $Actual, [string]$Message) {
    if ($Expected -cne $Actual) { throw "$Message`nExpected: $Expected`nActual: $Actual" }
}

function Quote-NativeArgument([string]$Value) {
    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append('"')
    $slashes = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq [char]92) { $slashes++; continue }
        if ($character -eq [char]34) {
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

function Invoke-Native([string]$Executable, [string[]]$Arguments, [string]$RawArguments = '') {
    $start = New-Object System.Diagnostics.ProcessStartInfo
    $start.FileName = $Executable
    $start.Arguments = if ($RawArguments) { $RawArguments }
        else { (($Arguments | ForEach-Object { Quote-NativeArgument $_ }) -join ' ') }
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.EnvironmentVariables['GIT_TERMINAL_PROMPT'] = '0'
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $start
    try {
        [void]$process.Start()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            Output = $stdoutTask.Result + $stderrTask.Result
        }
    } finally { $process.Dispose() }
}

function Invoke-TestGit([string[]]$Arguments) {
    $result = Invoke-Native 'git' $Arguments
    if ($result.ExitCode -ne 0) { throw "Fixture Git failed ($($result.ExitCode)): $($result.Output)" }
    return $result.Output.Trim()
}

function Invoke-TestScript([string]$ScriptPath, [string[]]$Arguments) {
    return Invoke-Native $powerShellExecutable (@('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath) + $Arguments)
}

function Write-TestBytes([string]$Path, [byte[]]$Bytes) {
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path))
    [IO.File]::WriteAllBytes($Path, $Bytes)
}

function Write-TestText([string]$Path, [string]$Text) {
    Write-TestBytes $Path $utf8.GetBytes($Text)
}

function Read-TestJson([string]$Path) {
    return ([IO.File]::ReadAllText($Path, $utf8) | ConvertFrom-Json)
}

function Write-TestJson([string]$Path, $Value) {
    Write-TestText $Path (($Value | ConvertTo-Json -Depth 30) + "`n")
}

function Get-TestHash([byte[]]$Bytes) {
    $text = $utf8.GetString($Bytes).TrimStart([char]0xFEFF).Replace("`r`n", "`n")
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($algorithm.ComputeHash($utf8.GetBytes($text)))).Replace('-', '').ToLowerInvariant() }
    finally { $algorithm.Dispose() }
}

function Get-TestBytes([string]$Path) {
    return [Convert]::ToBase64String([IO.File]::ReadAllBytes($Path))
}

function Get-ProjectSnapshot([string]$Root) {
    $snapshot = @{}
    foreach ($directory in [IO.Directory]::GetDirectories($Root, '*', [IO.SearchOption]::AllDirectories)) {
        $relative = $directory.Substring($Root.Length + 1).Replace([char]92, [char]47)
        $snapshot['directory:' + $relative] = ''
    }
    foreach ($file in [IO.Directory]::GetFiles($Root, '*', [IO.SearchOption]::AllDirectories)) {
        $relative = $file.Substring($Root.Length + 1).Replace([char]92, [char]47)
        $snapshot['file:' + $relative] = Get-TestBytes $file
    }
    return $snapshot
}

function Assert-Snapshot($Before, [string]$Root, [string]$Message) {
    $after = Get-ProjectSnapshot $Root
    Assert-Equal $Before.Count $after.Count "$Message (file/directory count)"
    foreach ($key in $Before.Keys) {
        Assert-True ($after.ContainsKey($key)) "$Message (missing $key)"
        Assert-Equal $Before[$key] $after[$key] "$Message (changed $key)"
    }
}

function Get-ProjectGitState([string]$Root) {
    return [pscustomobject]@{
        Head = Invoke-TestGit @('-C', $Root, 'rev-parse', 'HEAD')
        Origin = Invoke-TestGit @('-C', $Root, 'config', '--get', 'remote.origin.url')
        Index = Get-TestBytes (Join-Path $Root '.git/index')
        StagedFile = Get-TestBytes (Join-Path $Root 'staged.txt')
    }
}

function Assert-ProjectGitState($Before, [string]$Root) {
    $after = Get-ProjectGitState $Root
    Assert-Equal $Before.Head $after.Head 'Installer changed the project HEAD.'
    Assert-Equal $Before.Origin $after.Origin 'Installer changed the project origin.'
    Assert-Equal $Before.Index $after.Index 'Installer changed the project index or staged changes.'
    Assert-Equal $Before.StagedFile $after.StagedFile 'Installer changed an unrelated staged/unstaged file.'
}

function Initialize-TestRepository([string]$Root) {
    [void][IO.Directory]::CreateDirectory($Root)
    [void](Invoke-TestGit @('init', '--quiet', $Root))
    [void](Invoke-TestGit @('-C', $Root, 'symbolic-ref', 'HEAD', 'refs/heads/main'))
    [void](Invoke-TestGit @('-C', $Root, 'config', 'user.name', 'AGENTS Sync Tests'))
    [void](Invoke-TestGit @('-C', $Root, 'config', 'user.email', 'agents-sync-tests@example.invalid'))
    [void](Invoke-TestGit @('-C', $Root, 'config', 'core.autocrlf', 'false'))
    [void](Invoke-TestGit @('-C', $Root, 'config', 'commit.gpgsign', 'false'))
}

function Commit-TestRepository([string]$Root, [string]$Message) {
    [void](Invoke-TestGit @('-C', $Root, 'add', '--all'))
    [void](Invoke-TestGit @('-C', $Root, 'commit', '--quiet', '-m', $Message))
    return Invoke-TestGit @('-C', $Root, 'rev-parse', 'HEAD')
}

function Add-TestManifestFile([string]$Root, [string]$Relative, [string]$Text) {
    Write-TestText (Join-Path $Root $Relative) $Text
    $manifestPath = Join-Path $Root 'AGENTS.framework.json'
    $manifest = Read-TestJson $manifestPath
    $manifest.files = @($manifest.files) + @([pscustomobject]@{
        source = $Relative; target = $Relative; mode = 'managed'
        sha256 = Get-TestHash ([IO.File]::ReadAllBytes((Join-Path $Root $Relative)))
    })
    Write-TestJson $manifestPath $manifest
}

function New-SourceVariant([string]$Name) {
    $variant = Join-Path $fixtureRoot $Name
    [void](Invoke-TestGit @('clone', '--quiet', '--no-hardlinks', $source, $variant))
    [void](Invoke-TestGit @('-C', $variant, 'config', 'user.name', 'AGENTS Sync Tests'))
    [void](Invoke-TestGit @('-C', $variant, 'config', 'user.email', 'agents-sync-tests@example.invalid'))
    [void](Invoke-TestGit @('-C', $variant, 'config', 'core.autocrlf', 'false'))
    [void](Invoke-TestGit @('-C', $variant, 'config', 'commit.gpgsign', 'false'))
    return $variant
}

function Invoke-Sync([string]$From, [string[]]$ExtraArguments) {
    $syncArguments = @('-ProjectRoot', $project, '-SourcePath', $From, '-Repository', $source)
    if ($ExtraArguments -notcontains '-Ref') { $syncArguments += @('-Ref', 'main') }
    return Invoke-TestScript $installer ($syncArguments + $ExtraArguments)
}

function Invoke-InstalledBatch([string]$From, [string[]]$ExtraArguments) {
    $batchPath = Join-Path $project 'fetch-agents.bat'
    $batchArguments = @('-SourcePath', $From, '-Repository', $source, '-Ref', 'main') + $ExtraArguments
    $command = (Quote-NativeArgument $batchPath) + ' ' + (($batchArguments | ForEach-Object { Quote-NativeArgument $_ }) -join ' ')
    return Invoke-Native $env:ComSpec @() ('/d /s /c "' + $command + '"')
}

function Assert-Exit($Result, [int]$Expected, [string]$Message, [string]$OutputPattern = '') {
    Assert-Equal $Expected $Result.ExitCode "$Message`n$($Result.Output)"
    if ($OutputPattern) { Assert-True ($Result.Output -match $OutputPattern) "$Message (unexpected diagnostic): $($Result.Output)" }
}

function Assert-ReadOnlySync([string]$From, [string[]]$Arguments, [int]$Expected, [string]$Message, [string]$OutputPattern = '', [switch]$Batch) {
    $before = Get-ProjectSnapshot $project
    $lockPath = Join-Path $project 'AGENTS.lock.json'
    $lockTime = if ([IO.File]::Exists($lockPath)) { [IO.File]::GetLastWriteTimeUtc($lockPath).Ticks } else { $null }
    $result = if ($Batch) { Invoke-InstalledBatch $From $Arguments } else { Invoke-Sync $From $Arguments }
    Assert-Exit $result $Expected $Message $OutputPattern
    Assert-Snapshot $before $project "$Message wrote to the project"
    if ($null -ne $lockTime) { Assert-Equal $lockTime ([IO.File]::GetLastWriteTimeUtc($lockPath).Ticks) "$Message rewrote the lock" }
    $script:testCount++
    Write-Host "PASS: $Message"
}

function Assert-UserFiles {
    foreach ($relative in $userFiles.Keys) {
        Assert-Equal $userFiles[$relative] (Get-TestBytes (Join-Path $project $relative)) "Project-owned file changed: $relative"
    }
}

try {
    Assert-True ([IO.File]::Exists((Join-Path $repositoryRoot 'AGENTS.framework.json'))) 'Publish AGENTS.framework.json before running the tests.'
    [void][IO.Directory]::CreateDirectory($fixtureRoot)
    $source = Join-Path $fixtureRoot 'framework source'
    $project = Join-Path $fixtureRoot 'target project'
    Initialize-TestRepository $source
    $originalManifest = Read-TestJson (Join-Path $repositoryRoot 'AGENTS.framework.json')
    $copyPaths = @('AGENTS.framework.json', 'scripts/publish-framework.ps1', 'scripts/fetch-agents.ps1') + @($originalManifest.files | ForEach-Object { [string]$_.source })
    foreach ($relative in @($copyPaths | Select-Object -Unique)) {
        Write-TestBytes (Join-Path $source $relative) ([IO.File]::ReadAllBytes((Join-Path $repositoryRoot $relative)))
    }
    # Keep release scenarios deterministic as the real framework version grows.
    $fixtureManifestPath = Join-Path $source 'AGENTS.framework.json'
    $fixtureManifest = Read-TestJson $fixtureManifestPath
    $fixtureManifest.frameworkVersion = '1.0.0'
    Write-TestJson $fixtureManifestPath $fixtureManifest
    Add-TestManifestFile $source 'docs-ai/common/retired-test.md' "Managed fixture file removed in the next release.`n"
    $installer = Join-Path $source 'scripts/fetch-agents.ps1'
    $publisher = Join-Path $source 'scripts/publish-framework.ps1'
    Assert-Exit (Invoke-TestScript $publisher @('-Check')) 0 'The initial fixture manifest has valid payload hashes.'
    $initialCommit = Commit-TestRepository $source 'Initial 1.0.0 framework fixture'

    $existingEntryProject = Join-Path $fixtureRoot 'project with existing script entry'
    Initialize-TestRepository $existingEntryProject
    $existingEntryPath = Join-Path $existingEntryProject 'debug-handler.bat'
    Write-TestText $existingEntryPath "@echo off`r`nrem Existing project-owned script dispatch.`r`n"
    $existingEntryBytes = Get-TestBytes $existingEntryPath
    Assert-Exit (Invoke-TestScript $installer @('-ProjectRoot', $existingEntryProject, '-SourcePath', $source, '-Repository', $source, '-Ref', 'main')) 0 'Initial installation with an existing project script entry succeeds.'
    Assert-Equal $existingEntryBytes (Get-TestBytes $existingEntryPath) 'Initial installation replaced the existing project script entry.'
    $testCount++
    Write-Host 'PASS: Initial install preserves an existing custom debug-handler.bat.'

    Initialize-TestRepository $project
    Write-TestText (Join-Path $project 'README.md') "Project readme.`n"
    Write-TestText (Join-Path $project 'docs-ai/current/1_architecture.md') "Project architecture already edited by its owner.`r`n"
    Write-TestText (Join-Path $project 'docs-ai/current/custom-notes.md') "Arbitrary current documentation.`n"
    Write-TestText (Join-Path $project 'docs-ai/common/user-notes.md') "An unmanaged common file.`n"
    Write-TestText (Join-Path $project '.agents/skills/personal/SKILL.md') "A user-added skill.`n"
    $ensurePath = Join-Path $project 'AGENTS.ensure.json'
    $unicode = New-Object System.Text.UnicodeEncoding($false, $true)
    [IO.File]::WriteAllText($ensurePath, '{"projectSetting":"UTF-16 project-owned configuration"}', $unicode)
    [void](Commit-TestRepository $project 'Initial project-owned files')
    [void](Invoke-TestGit @('-C', $project, 'remote', 'add', 'origin', 'https://example.invalid/project.git'))
    Write-TestText (Join-Path $project 'staged.txt') "This content is staged.`n"
    [void](Invoke-TestGit @('-C', $project, 'add', '--', 'staged.txt'))
    Write-TestText (Join-Path $project 'staged.txt') "This content is staged.`nThis extra line is unstaged.`n"
    $gitState = Get-ProjectGitState $project
    $userFiles = @{}
    foreach ($relative in @('AGENTS.ensure.json', 'docs-ai/current/1_architecture.md', 'docs-ai/current/custom-notes.md', 'docs-ai/common/user-notes.md', '.agents/skills/personal/SKILL.md')) {
        $userFiles[$relative] = Get-TestBytes (Join-Path $project $relative)
    }

    Assert-ReadOnlySync $source @('-Check') 2 'Initial Check reports an available install and changes no project bytes.'
    Assert-Exit (Invoke-Sync $source @()) 0 'Initial installation succeeds.'
    Assert-UserFiles
    Assert-ProjectGitState $gitState $project
    $lock = Read-TestJson (Join-Path $project 'AGENTS.lock.json')
    Assert-Equal '1.0.0' $lock.frameworkVersion 'Initial lock records framework version.'
    Assert-Equal $initialCommit $lock.commit 'Initial lock pins the resolved source commit.'
    Assert-True ([IO.File]::Exists((Join-Path $project 'docs-ai/common/retired-test.md'))) 'Initial managed fixture file was not installed.'
    Assert-True ([IO.File]::Exists((Join-Path $project 'docs/.gitkeep'))) 'Missing documentation directory seed was not installed.'
    Assert-True ([IO.Directory]::Exists((Join-Path $project 'scripts'))) 'Required scripts directory was not installed.'
    $debugHandlerPath = Join-Path $project 'debug-handler.bat'
    Assert-True ([IO.File]::Exists($debugHandlerPath)) 'Missing project script entry seed was not installed.'
    Assert-Equal 0 ([IO.File]::ReadAllBytes($debugHandlerPath).Length) 'Initial project script entry must be empty.'
    Assert-True ($null -eq $lock.managedFiles.PSObject.Properties['debug-handler.bat']) 'Project script entry must not be managed by the lock.'
    $testCount++
    Write-Host 'PASS: Initial install preserves UTF-16 configuration, project files, index, HEAD, and origin.'
    $testCount++
    Write-Host 'PASS: Initial install creates an empty project-owned debug-handler.bat seed.'
    Assert-ReadOnlySync $source @('-Check') 0 'Current Check succeeds without rewriting the lock.'
    Assert-ReadOnlySync $source @() 0 'Current installer is a no-op without rewriting the lock.'
    $normalizationPath = Join-Path $project 'docs-ai/common/rules.md'
    $normalizationOriginalBytes = [IO.File]::ReadAllBytes($normalizationPath)
    $normalizationText = $utf8.GetString($normalizationOriginalBytes).TrimStart([char]0xFEFF).Replace("`r`n", "`n").Replace("`n", "`r`n")
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [IO.File]::WriteAllText($normalizationPath, $normalizationText, $utf8Bom)
    Assert-True ((Get-TestBytes $normalizationPath) -cne [Convert]::ToBase64String($normalizationOriginalBytes)) 'Normalization fixture did not change the managed file bytes.'
    Assert-ReadOnlySync $source @('-Check') 0 'Check treats UTF-8 BOM and CRLF normalization as unchanged content.'
    Assert-ReadOnlySync $source @() 0 'No-op updater preserves equivalent UTF-8 BOM and CRLF bytes.'
    Write-TestBytes $normalizationPath $normalizationOriginalBytes
    $windows = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
    if ($windows) {
        Assert-ReadOnlySync $source @('-Check') 0 'Installed BAT propagates current Check exit code 0.' -Batch
    } else {
        $skipCount++
        Write-Host 'SKIP: Installed BAT execution requires Windows.'
    }

    Write-TestText $debugHandlerPath "@echo off`r`nrem Project-owned script dispatch.`r`n"
    $userFiles['debug-handler.bat'] = Get-TestBytes $debugHandlerPath
    Assert-ReadOnlySync $source @('-Check') 0 'Check accepts project-owned debug-handler.bat customization without conflicts or writes.'
    Write-TestText (Join-Path $project 'docs-ai/current/1_dependency.md') "Edited dependency documentation after the initial install.`n"
    $userFiles['docs-ai/current/1_dependency.md'] = Get-TestBytes (Join-Path $project 'docs-ai/current/1_dependency.md')
    Add-TestManifestFile $source '.agents/skills/test-added/SKILL.md' "---`nname: test-added`ndescription: Integration fixture for managed skill additions.`n---`nNew managed skill in version 1.0.1.`n"
    $manifestPath = Join-Path $source 'AGENTS.framework.json'
    $manifest = Read-TestJson $manifestPath
    $manifest.files = @($manifest.files | Where-Object { $_.target -ne 'docs-ai/common/retired-test.md' })
    Write-TestJson $manifestPath $manifest
    [IO.File]::Delete((Join-Path $source 'docs-ai/common/retired-test.md'))
    $rulesSource = Join-Path $source 'docs-ai/common/rules.md'
    Write-TestText $rulesSource ([IO.File]::ReadAllText($rulesSource, $utf8) + "`nVersion 1.0.1 fixture rule.`n")
    $batchSource = Join-Path $source 'fetch-agents.bat'
    Write-TestText $batchSource ([IO.File]::ReadAllText($batchSource, $utf8) + "`r`nrem Version 1.0.1 self-update fixture marker.`r`n")
    Write-TestText (Join-Path $source 'templates/1_dependency.md') "A changed upstream dependency template must preserve project edits.`n"
    Assert-Exit (Invoke-TestScript $publisher @('-Version', '1.0.1')) 0 'Publisher prepares version 1.0.1.'
    Assert-Exit (Invoke-TestScript $publisher @('-Check')) 0 'Publisher verifies version 1.0.1 payload hashes.'
    $upgradeCommit = Commit-TestRepository $source 'Publish 1.0.1 with managed addition and removal'
    Assert-ReadOnlySync $source @('-Check') 2 'Upgrade Check reports an update without changing project bytes.'
    if ($windows) {
        Assert-ReadOnlySync $source @('-Check') 2 'Installed BAT propagates available-update Check exit code 2.' -Batch
        Assert-Exit (Invoke-InstalledBatch $source @()) 0 'Installed BAT completes its own managed self-update.'
    } else {
        Assert-Exit (Invoke-Sync $source @()) 0 'Upgrade succeeds.'
    }
    Assert-UserFiles
    Assert-ProjectGitState $gitState $project
    Assert-True (-not [IO.File]::Exists((Join-Path $project 'docs-ai/common/retired-test.md'))) 'Upgrade did not remove the retired managed file.'
    Assert-Equal (Get-TestBytes (Join-Path $source '.agents/skills/test-added/SKILL.md')) (Get-TestBytes (Join-Path $project '.agents/skills/test-added/SKILL.md')) 'Upgrade did not install the new managed skill.'
    Assert-Equal (Get-TestBytes $batchSource) (Get-TestBytes (Join-Path $project 'fetch-agents.bat')) 'Upgrade did not install the new managed BAT bytes.'
    $lock = Read-TestJson (Join-Path $project 'AGENTS.lock.json')
    Assert-Equal '1.0.1' $lock.frameworkVersion 'Upgrade lock records new version.'
    Assert-Equal $upgradeCommit $lock.commit 'Upgrade lock records new commit.'
    Assert-True ($null -eq $lock.managedFiles.PSObject.Properties['docs-ai/common/retired-test.md']) 'Removed file remains managed by the lock.'
    $testCount++
    Write-Host 'PASS: Published upgrade adds and removes managed files while preserving project edits and unknown files.'
    $testCount++
    Write-Host 'PASS: Published upgrade preserves customized debug-handler.bat bytes.'

    $rulesTarget = Join-Path $project 'docs-ai/common/rules.md'
    [IO.File]::WriteAllText($rulesTarget, "Committed project-specific managed customization.`r`nPreserve these exact UTF-16 BOM and CRLF bytes in backup.`r`n", $unicode)
    $customBytes = Get-TestBytes $rulesTarget
    [void](Invoke-TestGit @('-C', $project, 'add', '--', 'docs-ai/common/rules.md'))
    [void](Invoke-TestGit @('-C', $project, 'commit', '--quiet', '--only', '-m', 'Committed managed customization', '--', 'docs-ai/common/rules.md'))
    $gitState = Get-ProjectGitState $project
    Assert-ReadOnlySync $source @('-Check') 3 'Check detects a committed managed customization.' 'Local conflicts'
    Assert-ReadOnlySync $source @() 1 'Updater refuses a committed managed customization without writes.' 'Local framework changes'
    if ($windows) {
        Assert-ReadOnlySync $source @('-Check') 3 'Installed BAT propagates committed-conflict Check exit code 3.' 'Local conflicts' -Batch
        Assert-ReadOnlySync $source @() 1 'Installed BAT propagates updater failure exit code 1.' 'Local framework changes' -Batch
    }
    Assert-Exit (Invoke-Sync $source @('-Force')) 0 'Force restores managed content and creates a backup.'
    Assert-Equal (Get-TestBytes $rulesSource) (Get-TestBytes $rulesTarget) 'Force did not restore upstream managed bytes.'
    $backups = @([IO.Directory]::GetFiles((Join-Path $project '.agents/backups'), 'rules.md', [IO.SearchOption]::AllDirectories))
    Assert-Equal 1 $backups.Count 'Force must create exactly one backup of the conflict.'
    Assert-Equal $customBytes (Get-TestBytes $backups[0]) 'Force backup did not preserve the original UTF-16 BOM and CRLF bytes.'
    Assert-UserFiles
    Assert-ProjectGitState $gitState $project
    $testCount++
    Write-Host 'PASS: Force backs up exact customized bytes and leaves unrelated staged changes intact.'
    Assert-ReadOnlySync $source @('-Check') 0 'Check succeeds after Force and preserves the backup and lock.'

    $tampered = New-SourceVariant 'same-version tamper'
    $tamperedRules = Join-Path $tampered 'docs-ai/common/rules.md'
    Write-TestText $tamperedRules ([IO.File]::ReadAllText($tamperedRules, $utf8) + "Same-version content mutation.`n")
    $tamperedManifestPath = Join-Path $tampered 'AGENTS.framework.json'
    $manifest = Read-TestJson $tamperedManifestPath
    foreach ($entry in @($manifest.files)) {
        if ($entry.source -eq 'docs-ai/common/rules.md') { $entry.sha256 = Get-TestHash ([IO.File]::ReadAllBytes($tamperedRules)) }
    }
    Write-TestJson $tamperedManifestPath $manifest
    [void](Commit-TestRepository $tampered 'Invalid same-version content mutation')
    Assert-ReadOnlySync $tampered @('-Check') 1 'Same-version manifest change is refused by Check.' 'without a version increment'
    Assert-ReadOnlySync $tampered @() 1 'Same-version payload and manifest change is refused without writes.' 'without a version increment'
    Assert-ReadOnlySync $tampered @('-Force') 1 'Force cannot bypass the same-version publication rule.' 'without a version increment'

    $invalid = New-SourceVariant 'invalid manifest'
    $invalidManifestPath = Join-Path $invalid 'AGENTS.framework.json'
    $validManifest = Read-TestJson $invalidManifestPath
    $validManifest.frameworkVersion = '1.0.2'
    Write-TestJson $invalidManifestPath $validManifest
    $manifest = Read-TestJson $invalidManifestPath
    $manifest.files[0].sha256 = 'invalid-hash'
    Write-TestJson $invalidManifestPath $manifest
    [void](Commit-TestRepository $invalid 'Invalid payload hash syntax')
    Assert-ReadOnlySync $invalid @('-Check') 1 'Invalid payload hash is rejected without writes.' 'Invalid payload hash'
    Assert-ReadOnlySync $invalid @() 1 'Updater rejects an invalid payload hash without writes.' 'Invalid payload hash'
    $manifest = $validManifest
    $manifest.files[0].sha256 = ('0' * 64)
    Write-TestJson $invalidManifestPath $manifest
    [void](Commit-TestRepository $invalid 'Payload hash mismatch')
    Assert-ReadOnlySync $invalid @() 1 'A validly formatted but incorrect payload hash is rejected.' 'Payload hash mismatch'

    $manifest = Read-TestJson (Join-Path $source 'AGENTS.framework.json')
    $manifest.frameworkVersion = '1.0.2'
    $manifest.files[0].source = '../outside-project.md'
    Write-TestJson $invalidManifestPath $manifest
    [void](Commit-TestRepository $invalid 'Invalid source traversal')
    Assert-ReadOnlySync $invalid @('-Check') 1 'Source traversal path is rejected without writes.' 'Invalid framework path'
    $manifest = Read-TestJson (Join-Path $source 'AGENTS.framework.json')
    $manifest.frameworkVersion = '1.0.2'
    $manifest.files[0].target = 'docs-ai/common/../outside-project.md'
    Write-TestJson $invalidManifestPath $manifest
    [void](Commit-TestRepository $invalid 'Invalid destination traversal')
    Assert-ReadOnlySync $invalid @() 1 'Destination traversal path is rejected without writes.' 'Invalid framework path'

    $linked = New-SourceVariant 'linked payload'
    [void](Invoke-TestGit @('-C', $linked, 'config', 'core.symlinks', 'true'))
    $linkedPath = Join-Path $linked 'docs-ai/common/rules.md'
    Write-TestText (Join-Path $linked 'linked-payload.txt') "Payload behind a symbolic link.`n"
    [IO.File]::Delete($linkedPath)
    $linkCreated = $false
    try {
        [void](New-Item -ItemType SymbolicLink -Path $linkedPath -Value '../../linked-payload.txt' -ErrorAction Stop)
        $linkCreated = $true
    } catch {
        $skipCount++
        Write-Host ('SKIP: Source symbolic-link creation is unavailable: ' + $_.Exception.Message)
    }
    if ($linkCreated) {
        $linkedManifestPath = Join-Path $linked 'AGENTS.framework.json'
        $manifest = Read-TestJson $linkedManifestPath
        $manifest.frameworkVersion = '1.0.2'
        foreach ($entry in @($manifest.files)) {
            if ($entry.source -eq 'docs-ai/common/rules.md') { $entry.sha256 = Get-TestHash $utf8.GetBytes('../../linked-payload.txt') }
        }
        Write-TestJson $linkedManifestPath $manifest
        [void](Commit-TestRepository $linked 'Invalid symbolic-link source payload')
        $treeEntry = Invoke-TestGit @('-C', $linked, 'ls-tree', 'HEAD', '--', 'docs-ai/common/rules.md')
        Assert-True ($treeEntry -match '^120000 blob ') 'Fixture did not record its symbolic link as a Git symbolic link.'
        Assert-ReadOnlySync $linked @('-Check') 1 'A symbolic-link source payload is rejected by Check.' 'not a regular Git file'
        Assert-ReadOnlySync $linked @() 1 'A symbolic-link source payload is rejected by the updater.' 'not a regular Git file'
    }

    Assert-ReadOnlySync $source @('-Ref', $initialCommit, '-Check') 1 'Pinning the older commit is refused by Check without writes.' 'older'
    Assert-ReadOnlySync $source @('-Ref', $initialCommit) 1 'Pinning the older commit is refused by updater without writes.' 'older'
    Assert-UserFiles
    Assert-ProjectGitState $gitState $project
    $successful = $true
    Write-Host "All $testCount integration checks passed; $skipCount platform-specific checks skipped."
} catch {
    Write-Host ('FAIL: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Fixtures retained for diagnosis: ' + $fixtureRoot)
    exit 1
} finally {
    if ($successful -and -not $KeepFixtures -and [IO.Directory]::Exists($fixtureRoot)) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
exit 0
