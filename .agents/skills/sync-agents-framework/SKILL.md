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

On Windows, keep installation, checking, updating, and rollback behind `fetch-agents.bat`. It obtains a verified current controller on every run and preserves the current launcher even when the requested payload is historical. Acquisition failures must not fall back to an installed script.

Normal BAT invocation requires input before an operation and again before closing. Use its menu or confirm explicit options. For authorized unattended execution, place `-NonInteractive` first, for example `fetch-agents.bat -NonInteractive -Check`; this bypasses only interaction, not conflict or payload validation. Follow the BAT interaction contract in the shared rules.

An already deployed legacy BAT lacks this acquisition path. Migrate through a verified current `fetch-agents.bat -ProjectRoot <target-root>`, using the same check or authorized update. Keep the consumer lock and installed files until normal synchronization runs; do not replace its PS1 by hand or remove its lock. A successful `-Check` does not authorize an update. After migration, use the consumer's own BAT for every operation. Do not present manual invocation of a central PS1 as the Windows recovery workflow.

For first-time installation, use the documented bootstrap in the central repository README or run its installer against the target root. Never copy the central repository's `current/` facts into the target, and never substitute a broad `git restore` for the manifest-based installer.
