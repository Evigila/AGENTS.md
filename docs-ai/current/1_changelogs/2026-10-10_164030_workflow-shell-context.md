# Correct workflow shell context

Recorded at 2026-10-10 16:40:30 in America/Sao_Paulo (UTC-03:00).

Moved the matrix-selected shell from three step overrides to `jobs.integration.defaults.run.shell` in `.github/workflows/verify.yml`, resolving the reported workflow-validation error while preserving the three execution environments and all step bodies.

Targeted official-schema context checks, unchanged-content comparison, embedded PowerShell syntax parsing, framework payload-hash verification, and `git diff --check` passed. Hosted execution requires the corrected workflow to be committed and pushed; it has not been run remotely. No installed payload, dependency, or audit-state change was made for this CI fix.

See [the bug report](../1_bugreports/2026-10-10_164030_workflow-shell-context.md) for diagnostic evidence, verification limits, and the manual test checklist.
