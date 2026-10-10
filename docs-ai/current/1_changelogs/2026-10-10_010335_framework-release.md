# Framework release 1.0.0

## Implemented

- Replaced the old `docs-ai/common/SKILLS/` location with standard `.agents/skills/` packages. Added explicitly routed documentation audit and synchronization workflows.
- Retained mandatory code, execution/documentation, and Flourish integration standards in `common/`.
- Added a release manifest, normalized SHA-256 payload validation, consumer installation lock, audit schema 2, and separate seed templates.
- Added Windows bootstrap/update launcher and a PowerShell 5.1-compatible installer with explicit check exit codes, local customization detection, preserved project files, byte backups, and best-effort write rollback.
- Added publisher, package-free integration tests, and a Windows/Linux CI matrix with Windows bootstrap smoke coverage.
- Documented the central source architecture and dependencies separately from consumer project facts.

## Verification

The local PowerShell 7.4.7 / Git 2.51.1 run passed all 24 integration checks. Source symlink rejection ran successfully. Checks cover initial install/no-op, read-only behavior, managed additions/removal, unknown files, UTF-16 seed preservation, committed managed customizations, exact backups, payload tampering, unsafe paths, normalization, ref selection/downgrade, and Git state preservation. Both skill manifests passed validation; payload hashes and internal document links passed verification.

The Windows-only installed BAT checks were skipped on Linux and are configured in CI for exit-code propagation and self-replacement. Native bootstrap is also configured for Windows CI. The authorized GitHub upload was blocked by HTTP 403 (the current integration cannot write this repository), so remote CI has not yet run; its workflow results are independent runtime evidence. macOS is not in the CI matrix.

## Operational limits

Run one synchronization at a time. Multi-file updates attempt rollback on write failure but cannot guarantee recovery across power loss. Existing unowned legacy skills are preserved and require reviewed relocation. Only user-authorized `-Force` may replace managed customizations or intentionally downgrade. Consumer templates remain unaudited until inspected within their own project.
