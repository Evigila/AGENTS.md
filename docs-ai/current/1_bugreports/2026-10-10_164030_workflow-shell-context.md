# Workflow rejected for matrix shell context

Recorded at 2026-10-10 16:40:30 in America/Sao_Paulo (UTC-03:00).

## Symptoms and evidence

The user reported that [workflow run 38017452656](https://github.com/Evigila/AGENTS.md/actions/runs/38017452656/workflow) was rejected as an invalid workflow. Diagnostics at lines 31, 34, and 38 reported `Unrecognized named-value: 'matrix'` in `matrix.shell`. The local `.github/workflows/verify.yml` contained those expressions in all three run steps' `shell` fields. This rejection occurs during workflow validation, before the verification scripts execute.

## Root cause

Expression contexts depend on the workflow key. The [official context availability table](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#context-availability) allows `matrix` in job-level `defaults.run`. The [official runner schema](https://github.com/actions/runner/blob/main/src/Sdk/DTPipelines/workflow-v1.0.json) supplies the `matrix` context to `job-defaults-run`; `run-step.shell` is a `non-empty-string` without an expression context. The previous workflow used the matrix expression at the unsupported step location.

## Fix

Set `jobs.integration.defaults.run.shell` to `${{ matrix.shell }}` once and remove the three step-level shell overrides. The existing matrix still selects Windows PowerShell 5.1, PowerShell 7 on Windows, and PowerShell 7 on Linux. Triggers, runner selections, checkout pin, conditions, and script bodies are unchanged.

This is a source-only CI correction. It changes neither the installed framework payload nor its prepared `1.1.0` release manifest. The recent audit gate returns `SKIP_AUDIT`; audit state is unchanged by this fix.

## Regression verification and limits

- Targeted static verification passed against the official runner's job-defaults context definition and confirmed that no step shell overrides remain.
- A comparison with the original workflow confirmed that only shell placement changed; the three matrix entries and step bodies remain identical.
- PowerShell syntax parsing of the embedded bootstrap block passed; the framework payload-hash check and `git diff --check` passed.
- The PowerShell integration suites were not rerun for this configuration-only fix. The working-tree suites passed on Windows PowerShell 5.1 and PowerShell 7 earlier in this session. Those results include the preceding, uncommitted script-entry changes and do not establish hosted execution of an isolated CI-fix commit.
- No full YAML linter was available locally, and no new dependency was installed. The targeted checks do not replace GitHub's server validation or execution on hosted runners. The fix remains local and uncommitted, so no successful remote run is claimed.

## Manual verification

1. After committing and pushing the corrected workflow, trigger `Verify framework` for that new commit.
2. Confirm GitHub creates all three matrix jobs without an invalid-workflow error and that each job completes the hash and synchronization checks.
3. Confirm the bootstrap smoke step completes on both Windows jobs and is skipped on Linux by its existing condition.
