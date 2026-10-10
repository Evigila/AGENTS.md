# Stabilize Windows interaction tests

Recorded at 2026-10-10 20:43:22 in America/Sao_Paulo (UTC-03:00).

This follows [the 1.2.1 entry-point release](2026-10-10_203030_interactive-bat-entry-points.md).

- Published framework `1.2.1` in commit `c993bb6`; live remote Check, initial installation, current Check, and exact source provenance passed in a disposable consumer.
- Investigated the first hosted run: Linux passed; Windows 5.1 rejected the first test selection, and Windows 7 blocked in the invalid-executable fault fixture.
- Made test process creation and pipe input use no-BOM UTF-8. The console encoding is restored immediately after process creation. Replaced the invalid-image fixture with a temporary BAT copy whose confirmation command deterministically returns `1`; all authorization, waiting, snapshot, Git trace, and exit-code assertions remain.
- Isolated each suite's BAT TEMP/TMP directory after concurrent local suites collided in a shared bootstrap cache. Explicit environment overrides retain priority, including the distinct TEMP/TMP regression.

These changes affect only source tests and records; the installed manifest and payload remain `1.2.1`. Syntax, whitespace, and payload-hash checks passed. A forced-BOM 5.1 run passed all interaction tests after the creation fix; the subsequent shared-cache collision prevented full completion. Final isolated local suites and hosted verification are running at record creation. See [diagnosis and limitations](../1_bugreports/2026-10-10_204322_windows-test-input.md).
