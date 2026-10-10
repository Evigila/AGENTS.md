# Windows test input and fault-fixture portability

Recorded at 2026-10-10 20:43:22 in America/Sao_Paulo (UTC-03:00).

Follow-up to [BAT interaction verification](2026-10-10_203030_interactive-bat-entry-points.md).

## Symptoms and evidence

The initial local suites each passed 68 checks. In [the first hosted run](https://github.com/Evigila/AGENTS.md/actions/runs/38095352501), Linux passed; Windows PowerShell 5.1's first interactive Check printed `Invalid selection` and timed out. Windows PowerShell 7 passed normal interaction, then the zero-byte executable fault fixture blocked without diagnostic output. Neither failure was the previous workflow-expression validation error.

Setting the local 5.1 parent's input encoding to UTF-8 with a BOM reproduced the first-selection failure. Direct pipe writes alone were insufficient: .NET Framework initializes an auto-flushing stdin writer during process startup, before the test sends its first bytes. Reflection confirmed that 5.1's ProcessStartInfo exposes no StandardInputEncoding property.

## Repairs

Test process creation temporarily selects no-BOM UTF-8 and restores the previous console encoding in `finally`. Input writes and EOF use the underlying pipe directly. This leaves operation input, invalid-input retries, default Enter, waits, snapshots, and result assertions intact.

The fault fixture now replaces exactly one confirmation invocation in a disposable BAT copy under `scripts/` with CMD `exit 1`, retaining the production confirmation-result handling and completion block. It verifies a failed confirmation command. The former invalid executable fixture depended on OS startup behavior; a blocking system error dialog is a possible explanation for its hosted timeout, not a directly observed diagnosis.

Concurrent local suite runs also selected the same bootstrap cache under shared TEMP, producing one clone failure and one missing-manifest failure. Each suite now gives BAT children their own fixture TEMP/TMP; explicit overrides still win. This isolates testing and adds no production concurrency guarantee. Run production synchronization sequentially when sharing its temporary directory.

## Verification and remaining checks

Syntax, whitespace, and unchanged `1.2.1` payload hashes passed. Both editions passed the repaired interaction scenarios; forced-BOM 5.1 also passed them. Final isolated complete suites and a new hosted run remain in progress at record creation. The framework payload, consumer projects, and existing audit state are unchanged by this source-test repair. Manual double-click verification remains in the linked interaction checklist.
