---
name: audit-project-docs
description: Perform a full project documentation audit when requested or required by the AGENTS audit gate. Verify current architecture and dependencies, repair authorized gaps, and update audit state only after completion. Do not run for an unrelated task with a current, valid audit state.
---

# Audit project documentation

1. Resolve the repository root. Read `AGENTS.md`, `AGENTS.ensure.json`, and the audit gate and documentation contract in [rules.md](../../../docs-ai/common/rules.md). Read `AGENTS.framework.json` for the effective release version. Stop this workflow if the gate returns `SKIP_AUDIT` and the user has not requested a full audit; continue the original task's reading routes.
2. Check every required path, its ownership, and the assigned content. Validate `.agents/skills/` packages through their `SKILL.md` manifests. Treat the central framework source differently from a consumer installation: a local installation lock is generated only for consumers.
3. Inspect maintained source/configuration and produce a complete tree in `docs-ai/current/1_architecture.md`. Exclude the two documentation subtrees and documented temporary/generated material. Verify modules, projects, executable boundaries, references, and resources from source.
4. Inspect declarations and available resolution evidence. Update `docs-ai/current/1_dependency.md` with every dependency actually used, including transitive packages where applicable. Distinguish declared and observed versions; mark unknown facts instead of guessing.
5. Consolidate missing information. Reuse provided material and existing authorization. Ask once only for information unavailable in the repository or session. Create authorized missing content in English. Preserve human documentation and existing history.
6. Check changes against current standards. Record durable repairs under `current/` when needed; keep history out of `AGENTS.md` and `common/`. Do not use placeholders as evidence of completeness.
7. If essential content is unresolved, report the gaps and leave audit completion state unchanged. Otherwise write the supported audit schema, the effective framework version, actual UTC completion time, and the preserved/applicable latest question timestamp.
8. Report inspected scope, completed repairs, verification, and unresolved facts. Return to the original task; completion of this workflow does not replace its implementation or verification.

Use the current shared standards as the authority. Do not copy their policy text into this skill, change dependencies merely to obtain inspection tools, or claim a source/structure inspection proves runtime tests passed.
