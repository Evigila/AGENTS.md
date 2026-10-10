---
name: sync-agents-framework
description: Initialize, check, or update the repository's shared AGENTS framework from its central Git repository. Use for an explicit framework sync/version request, not for unrelated development or monthly project documentation audits.
---

# Synchronize the AGENTS framework

1. Resolve the target Git repository root. Read `AGENTS.md` and [framework synchronization rules](../../../docs-ai/common/rules.md#framework-synchronization). Inspect the installed `AGENTS.framework.json` and generated `AGENTS.lock.json` when present; keep them separate from `AGENTS.ensure.json`.
2. For a version-only request, run `fetch-agents.bat -Check` on Windows, or run `scripts/fetch-agents.ps1 -ProjectRoot <root> -Check` with PowerShell. Treat exit `0` as current, `2` as an available update, `3` as a local conflict, and `1` as an error. A check must not change target files.
3. For an authorized initialization or update, run the launcher without `-Check`. Reuse the user's existing update authorization. For a version-only request, report the result without applying changes.
4. Resolve conflicts from the reported paths. Do not add `-Force` automatically. Use it only when replacement of local managed customizations is authorized; inspect the backup location and preserve project-specific facts. Follow a requested branch, tag, or commit through `-Ref`; a pin becomes the next default from the lock.
5. Verify the result through the lock's framework version, source commit, manifest digest, and managed-file hashes. Check Git status and relevant differences. Confirm existing `docs-ai/current/`, human documentation, project-specific skills, source, index, and origin were preserved.
6. Report the installed version and source commit, changed files, any backups/conflicts, and remaining work. Do not commit the consumer project unless authorized. Do not mark the documentation audit complete: a changed framework version triggers that separate workflow.

For first-time installation, use the documented bootstrap in the central repository README or run its installer against the target root. Never copy the central repository's `current/` facts into the target, and never substitute a broad `git restore` for the manifest-based installer.
