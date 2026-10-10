# Legacy installer rejects a new project template

Recorded at 2026-10-10 17:30:38 in America/Sao_Paulo (UTC-03:00).

## Symptoms and diagnostic evidence

The user ran `fetch-agents -Check` in Colligere and received `Invalid project template target`. Read-only inspection found framework and lock version `1.0.0`, source commit `03ec2f6ebacb443585056b83c581f89a99c8ee36`, and the historical installed script. Its seed allowlist excludes `debug-handler.bat`, introduced by framework `1.1.0`.

The launcher prefers the existing consumer installer. That installer validates every template before replacing managed files, so it rejects the new seed before receiving the installer that understands it. Colligere is a valid target; the message reports a template compatibility failure rather than an invalid project directory.

The central current installer successfully checked Colligere against remote `main`: installed `1.0.0`, available `1.1.0`, source commit `873ec358a93f15a11cede16633e8728aa5b0e315`, exit `2`. This was a check only; no consumer update or audit-state change was performed.

## Root cause and coverage gap

The earlier script-entry regression suite used current installer code with an older version label. It did not execute the actual previously deployed installer. That missed a schema-compatible release whose new template target the old interpreter could not accept. This qualifies the upgrade coverage reported in [the script-entry record](../1_changelogs/2026-10-10_163710_script-entry-points.md).

## Implemented fix and recovery

Prepared framework `1.1.1` with optional installer protocol `1`. Before interpreting payload targets and managed lock paths, the running installer verifies the selected commit's installer hash and, when its code differs, executes that standalone script from temporary storage. The child reads the same resolved commit and retains the original repository/ref. Check operations, conflicts, Force backups, and exit codes retain their existing behavior. Protocol-less historical releases use the running interpreter directly, preserving intentional rollback compatibility.

An already deployed old installer cannot acquire this new mechanism itself. Recover once through a verified current central checkout:

```powershell
& 'C:\Users\Evigila\source\repos\AGENTS.md\scripts\fetch-agents.ps1' -ProjectRoot 'C:\Users\Evigila\source\repos\Colligere' -Check
```

Remove `-Check` only for an intended update. Keep the consumer lock and installed files intact until normal synchronization runs. Do not manually replace the installed script or automatically add `-Force`. The new `1.1.1` release is prepared locally; it must be pushed before a remote-main update can install it.

## Regression verification and limits

- PowerShell `7.6.5` and Windows PowerShell `5.1.26100.9444` each passed all 44 integration checks. Each skipped one existing symbolic-link scenario: administrator privilege is required in PowerShell 7; the relative link target cannot be resolved in the PowerShell 5.1 environment.
- Fixtures archive the real historical commit and reproduce the old check and update failures with unchanged consumer bytes. Central recovery preserves project-owned files and the requested non-default ref.
- A future fixture requires a new seed allowlist and exercises source-installer handoff through installed entry points, including a Git fetch into a temporary bare cache. Checks preserve files and lock timestamps; an incorrect installer hash prevents execution.
- Locally customized installer content still produces Check exit `3` and update failure without Force. Authorized Force preserves exact backup bytes, installs the future payload, and retains repository/ref and commit metadata. Intentional rollback restores actual historical installer bytes and preserves project-owned seeds.
- Payload hashes, PowerShell syntax, document structure/links, and whitespace checks passed. Independent read-only review found no blocking defect.
- Linux/macOS and hosted CI have not run for this local fix. Moving-ref races were not induced; the child receives the parent's resolved SHA. Protocol `1` assumes a standalone PS1 installer; future protocol/schema changes or accompanying runtime files need their own migration design.

## Manual verification

1. In Colligere, run the central check command and confirm update availability without changes in Git status attributable to synchronization.
2. After the release is pushed, use the same command without `-Check` when updating. If local conflicts are reported, inspect them before authorizing replacement.
3. Confirm the lock records version `1.1.1` and retains its original repository/ref, then run `fetch-agents.bat -Check`. Confirm existing project documentation, audit state, custom skills, and `debug-handler.bat` contents are preserved.
