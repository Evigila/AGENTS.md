# Make BAT responsible for framework updates

Recorded at 2026-10-10 17:49:57 in America/Sao_Paulo (UTC-03:00).

## Implemented

- Prepared `1.2.0`, stable central launcher protocol `1`, and payload installer protocol `2`; refreshed all managed payload hashes.
- Removed the installed-PS1-first BAT path. Every invocation acquires and verifies the current central controller before processing project state; failure stops without local fallback.
- Added explicit BAT `-ProjectRoot` routing and separate central launcher provenance. Historical payload rollback retains the current BAT and its actual managed hash so the next ordinary update remains possible.
- Preserved conflict detection, Force backups, seed ownership, read-only checks, fixed-commit handoff and transaction rollback. Corrected bootstrap cleanup when TEMP and TMP differ.
- Replaced manual central-PS1 recovery guidance with BAT-based migration. Updated source architecture, dependency usage and synchronization rules/skill. The old launcher still requires one deployment of its replacement because its existing execution path cannot receive the new behavior.
- Completed the source documentation audit: 18 required paths, 22 maintained tree files, two skill manifests, required content and local links. No dependency package or tool was added.

## Verification and delivery

Both PowerShell 7 and the real PowerShell 5.1 BAT fallback passed 54 integration checks, each with one existing symbolic-link scenario skipped. Regression coverage includes actual historical consumers, local-script independence, central acquisition/contract/hash failures, entry-point replacement, default routing, TEMP/TMP cleanup, exact conflict backups, and rollback followed by ordinary BAT upgrade. Syntax, payload hashes and whitespace checks passed.

Changes are local and uncommitted. Colligere was inspected but not migrated; its observed lock is `1.1.1`. Hosted CI and live acquisition of the new central controller require publication. See [the investigation](../1_bugreports/2026-10-10_174957_launcher-update-ownership.md) for compatibility boundaries and manual verification.
