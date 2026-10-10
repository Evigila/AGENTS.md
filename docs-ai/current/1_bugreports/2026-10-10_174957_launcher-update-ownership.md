# The launcher must own its update capability

Recorded at 2026-10-10 17:49:57 in America/Sao_Paulo (UTC-03:00).

## Symptoms and evidence

The user rejected the recovery workflow in [the previous investigation](2026-10-10_173038_legacy-installer-upgrade.md): invoking a central PS1 manually adds a separate operation instead of making `fetch-agents.bat` responsible for updates. The deployed BAT contains an installed-script-first branch, so an old script can prevent acquisition of any new update logic. Framework `1.1.1` added engine handoff but left that branch unchanged.

Latest read-only inspection found Colligere's lock at framework `1.1.1`, commit `9ecad95472b201eab0f483c14fca22721188f8a4`. Its audit state remains project-owned and unchanged by this task. No consumer update or migration was performed.

## Root cause and redesign

The control entry point and version-selected framework payload shared the same lifecycle. Installed script compatibility determined whether an update could start. Historical rollback also restored the old BAT, removing the new update path again. A manual PS1 workaround did not meet the single-entry requirement.

Prepared framework `1.2.0` with these responsibilities:

- On every invocation, BAT clones central `main` into temporary storage and verifies its BAT and PS1 entries as regular Git files with manifest-matching normalized hashes. It never executes the project-local PS1 and does not fall back to it when central acquisition fails.
- Central `launcherProtocolVersion: 1` defines a stable controller invocation contract independently of payload `installerProtocolVersion: 2`. The BAT checks the launcher contract, permitting compatible controller evolution without coupling the entry point to payload protocol numbers.
- `-ProjectRoot` can explicitly select a consumer. The launcher's directory supplies the default through a process-local environment variable, avoiding duplicate arguments and the temporary checkout becoming the target.
- BAT-driven synchronization validates all selected payload files but installs the current central BAT even for a historical payload. Managed hashes baseline the actual installed entry point. Optional lock `launcher` metadata records its repository/ref/commit/hash separately from the payload provenance.
- Protocol `2` handoff retains central launcher context and reads the target from the already-resolved commit. BAT-driven updates interpret protocol-less and protocol `1` historical payloads directly. Direct PowerShell compatibility remains available, but is not the Windows recovery workflow.
- The finishing block is parsed before the executing BAT can be replaced. Cleanup checks the absolute path, parent and expected prefix using the same `TEMP` root as creation; distinct `TMP` values do not prevent cleanup.

An already deployed legacy BAT cannot obtain code through a path that it does not contain. One deployment of the current entry point is unavoidable. A current BAT can perform this migration through normal synchronization with `-ProjectRoot`; consumers do not need to invoke PS1, delete a lock, or replace managed scripts manually. Thereafter every check, update and rollback uses the consumer's own BAT. This migration has not yet been applied to Colligere.

## Regression verification

- PowerShell `7.6.5` and Windows PowerShell `5.1.26100.9444` each passed all 54 integration checks. The Desktop suite narrows only BAT subprocess PATH to exclude pwsh, so it exercises the real PowerShell 5.1 fallback. Each suite skips one existing environment-limited symbolic-link scenario.
- Actual historical `1.0.0` BAT/script fixtures reproduce the old failure. Current central BAT checks and migrates that target, preserving project files and the requested payload ref. Consumer BAT then operates independently of missing, old, or executable customized local PS1 files while preserving conflict protection.
- Central clone failure, incompatible actual historical controller, and incorrect controller hash all stop without executing unverified or local scripts. Checks preserve the consumer snapshot and lock timestamp.
- Default-root, lock-selected routing works with no target/source/ref arguments. Separate TEMP and TMP directories are left free of temporary caches.
- A future protocol-2 fixture verifies source-engine handoff, exact resolved commit, original repository/ref, Force conflict backup bytes, and exit codes. Real historical rollback retains the current BAT and its truthful lock baseline, followed by an ordinary consumer BAT upgrade without manual recovery.
- Git URL redirection is limited to test child processes and local fixtures. No global Git configuration, production URL, or consumer repository was changed.
- An initial strict Desktop fixture run failed because PowerShell 5.1 returned multiple Git executable matches; the helper now selects the first application explicitly. The subsequent complete 5.1 suite passed.
- Script syntax, payload hashes, whitespace checks, documentation structure and links passed. Independent review identified the controller-contract and TEMP-root issues before the final test runs; both were corrected.

## Limits and manual verification

The redesign is local and uncommitted. Live central acquisition for this release and hosted CI remain unverified until publication. Linux/macOS were not run locally; portable PS1 tests remain in CI. Every BAT operation requires central availability, even with a local selected payload. Hash checks establish consistency with the trusted source manifest, not a separate signature scheme.

After publication:

1. Use the current BAT once with `-ProjectRoot` pointing to Colligere and `-Check`; confirm update availability and unchanged project bytes. Then use the same BAT without `-Check` for an intended migration.
2. Run Colligere's own `fetch-agents.bat -Check`; confirm exit `0`, lock version `1.2.0`, and preservation of project documents, custom skills, audit state and operation entry point.
3. In a disposable migrated project, intentionally roll back the payload with a pinned historical ref and Force, then upgrade through that project's BAT. Confirm the current launcher remains installed throughout and the lock records its separate source.
