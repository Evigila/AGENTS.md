# Preserve upgrades across installer template changes

Recorded at 2026-10-10 17:30:38 in America/Sao_Paulo (UTC-03:00).

## Implemented

- Prepared framework `1.1.1` and refreshed payload hashes. Added optional installer protocol `1`, verified temporary source-installer handoff, same-commit child reads, original repository/ref preservation, and bounded temporary cleanup.
- Retained read-only checks, local customization protection, Force backups, and protocol-less historical rollback. No consumer files were manually replaced and Colligere was not updated.
- Added actual historical-installer regression fixtures and future-allowlist handoff tests. CI now checks out full history so the pinned historical fixture commit is available.
- Added legacy recovery guidance to both READMEs and the synchronization skill. Updated active synchronization rules, architecture responsibilities, and Git test prerequisites.
- Completed the source documentation audit for `1.1.1`: 18 required paths, all 22 maintained files in the architecture scope, two skill manifests, required document content and local links. Dependencies remain unchanged.

## Verification and delivery

PowerShell 7 and Windows PowerShell 5.1 each passed all 44 integration checks, with one existing symbolic-link check skipped per environment. Payload hashes, script syntax, and whitespace checks passed. Independent read-only review found no blocking defect. A central-installer check against actual Colligere reported the remote `1.1.0` update with exit `2`; it did not apply it.

The fix is local and uncommitted. Hosted CI and Linux/macOS execution remain unverified. Already deployed old installers need one central-installer recovery because they cannot acquire the new protocol themselves. See [the investigation](../1_bugreports/2026-10-10_173038_legacy-installer-upgrade.md) for evidence, compatibility limits, and manual steps.
