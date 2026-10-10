# Unified project script entry points

Recorded at 2026-10-10 16:37:10 in America/Sao_Paulo (UTC-03:00).

## Implemented

- Prepared framework version `1.1.0` with updated normalized payload hashes in `AGENTS.framework.json`.
- Added the root zero-byte `debug-handler.bat` as a project-owned seed. Installation creates it only when missing; initialization, updates, and `-Force` preserve existing contents. The installer accepts this exact seed target, and the lock does not manage it.
- Added `scripts/` and `debug-handler.bat` to the required layout. The router directs script and operation tasks to the shared entry-point rules. AI may create only `debug-handler.bat` and `fetch-agents.bat` as root scripts. Debug startup, database clearing, remote Git tag publication, and NuGet publication use `debug-handler.bat`, with separate implementations under `scripts/`.
- Updated both READMEs and the consumer architecture template. Corrected the README seed-preservation description and local license filename, and clarified documentation ownership.
- Completed the documentation audit after discovering omitted maintained files and changing the framework version. The architecture tree now includes `LICENSE`, `README_zh-CN.md`, and the new entry point. Refreshed observed tool/runtime versions without changing dependencies; rechecked the pinned checkout action's declaration and license.

## Verification

- Framework `1.1.0` payload-hash check passed.
- PowerShell `7.6.5` on Windows: all 30 integration checks passed; the symbolic-link scenario was skipped because creation requires administrator privilege.
- Windows PowerShell `5.1.26100.9444`: all 30 integration checks passed; the symbolic-link scenario was skipped because its relative target could not be resolved by that environment.
- Integration coverage verifies a fresh empty entry point, preservation of an existing entry point during first installation, project customization without conflicts, and byte preservation during upgrade and `-Force`.
- Audit structure checks matched 18 required paths, all 22 maintained files in the architecture scope, two skill manifests, nonempty required documents, and router/standards/skill local links. The central source requires no consumer lock.
- Initial sandboxed test attempts stopped at temporary fixture Git configuration writes with permission denied. The same suites passed under controlled permissions; their repositories are temporary and the current checkout's Git state was not changed.

## Limits and manual verification

Linux/macOS and the live network bootstrap were not run in this task. The distributed entry point is intentionally empty; no project startup, database clearing, tag publication, or NuGet publication commands were added or executed. Changes remain uncommitted.

After this version is available for installation, use a disposable Git project:

1. Install the framework and confirm `scripts/fetch-agents.ps1` exists and `debug-handler.bat` is zero bytes. Running the empty entry point should perform no operation.
2. Add harmless custom content to the test project's entry point, synchronize normally and with `-Force`, and confirm the contents remain unchanged. Also try initializing a project with an existing entry point.
3. When adding real project operations later, keep their implementations under `scripts/`, route them through `debug-handler.bat`, and confirm the root has no additional AI-created scripts.
