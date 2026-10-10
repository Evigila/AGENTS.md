# BAT console closes without input

Recorded at 2026-10-10 20:30:30 in America/Sao_Paulo (UTC-03:00).

## Symptoms and root cause

The user reported that the entry-point console closed as soon as execution finished and requested menus that require input before operations. The previous fetch launcher forwarded arguments immediately and returned directly after cleanup. The debug entry was an empty seed, so it provided no interaction. Existing seed preservation would also leave historical empty entries unchanged.

This follows the update-controller work in [framework 1.2.0](2026-10-10_174957_launcher-update-ownership.md).

## Fix

Framework `1.2.1` adds numbered menus, default selection through empty Enter, validation retries, cancellation, and a completion wait. Explicit fetch arguments require confirmation. Only first-argument `-NonInteractive` bypasses both waits for automation. Menu input is read as text without shell evaluation.

Fetch confirmation uses distinct internal codes for authorization, cancellation, and EOF; shell failures return an error instead of being reported as successful cancellation. Fetch parses its entire finishing block before replacement. Debug invokes child BAT files in a separate CMD process so a child using plain `exit` cannot close the entry point. Both entries retain operation exit codes across completion input and restore the caller's directory.

Missing or legacy zero-byte debug entries receive the menu seed. Nonempty entries remain project-owned and protected. The seed dispatches only configured project scripts; missing operations report their expected paths.

## Regression evidence

- PowerShell 7 and Windows PowerShell 5.1 each passed 68 checks, including initial and final waiting states observed through native redirected process input/output. No Computer Use was performed.
- Before selection or confirmation, project snapshots and Git traces prove that acquisition and project writes have not started. Check remains read-only. Empty Enter updates successfully through self-replacement; Force retains exact backup bytes.
- Invalid input, EOF, cancellation, and a test-only invalid shell image cannot authorize an operation. Confirmation startup failure returns error `1` after the completion wait.
- Child BAT `exit 37` and PS1 fallback `exit 29` preserve their exact results after waiting. Missing operations return `1`; cancellation returns `0`.
- Existing consumer files, Git state, audit state, custom entries, and historical rollback/upgrade behavior remain protected. One existing symbolic-link fixture was unavailable in each local edition.

## Limits and manual checklist

Linux/macOS were not run locally; portable verification remains in hosted CI. Existing nonempty custom debug entries are preserved and need project-owned adaptation to follow the interaction contract. The source supplies dispatch only. Tests simulate operations in disposable fixtures without performing real project operations.

1. Double-click each entry in a disposable consumer. Leave the menu untouched and confirm that no operation begins. Enter an invalid value and confirm another prompt appears.
2. In fetch, choose `2` for Check; in debug, press Enter to select Debug. Confirm the selected operation or unconfigured-operation message appears.
3. After completion or `0` cancellation, confirm the window stays open until another input. In an existing terminal, verify that the caller remains open and the operation exit code is retained.
