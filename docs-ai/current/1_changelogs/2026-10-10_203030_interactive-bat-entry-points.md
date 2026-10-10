# Interactive BAT entry points

Recorded at 2026-10-10 20:30:30 in America/Sao_Paulo (UTC-03:00).

## Implemented

- Prepared framework `1.2.1` and refreshed the payload manifest hashes.
- Added input before operations and completion input after success, failure, or cancellation. Empty Enter selects the first option; invalid input repeats; EOF cancels. Explicit fetch options require confirmation.
- Added Update/Check/Force/Exit to `fetch-agents.bat` and Debug/Clear database/Publish tag/Publish NuGet/Exit to the project-owned `debug-handler.bat` seed. Project implementations remain under `scripts/`, with BAT preferred over PS1.
- Added first-argument `-NonInteractive` for authorized automation and updated Windows CI calls. Preserved operation exit codes, directory restoration, self-update completion, and isolated child BAT execution.
- Initialized legacy zero-byte debug entries with the menu while preserving all nonempty custom entries, including under Force. Updated shared BAT standards, synchronization skill, READMEs, templates, architecture, and dependency usage.
- Completed the source documentation audit: 18 required paths, 22 maintained tree files, two skill manifests, required content, and local links. No tool or package dependency was added.

## Verification and delivery scope

PowerShell `7.6.5` and Windows PowerShell `5.1.26100.9444` each passed all 68 integration checks. The Desktop suite exercises the actual BAT 5.1 fallback. Each suite skipped one existing environment-limited symbolic-link scenario. Both editions passed syntax checks; payload hashes and whitespace checks passed.

Coverage includes input before any Git/project work, empty Enter, read-only Check, Force backup bytes, explicit confirmation failure, invalid input, EOF, cancellation, self-updating completion, child BAT `exit 37`, PS1 fallback `exit 29`, legacy entry migration, nonempty customization, and historical upgrade/rollback preservation.

The user authorized committing and pushing version `1.2.1`. Consumer repositories were not changed. No actual project startup, database reset, remote tag, or NuGet publication was implemented or executed. Hosted CI and manual double-click verification follow publication. See [the investigation and manual checklist](../1_bugreports/2026-10-10_203030_interactive-bat-entry-points.md).
