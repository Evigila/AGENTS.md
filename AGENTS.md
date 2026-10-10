# Project instruction router

First inspect `AGENTS.ensure.json`, then complete the routing below. Follow the audit gate in [rules.md](docs-ai/common/rules.md#audit-gate). A `SKIP_AUDIT` result skips only the full documentation audit; it never skips this router or the rules applicable to the task.

## Read for the task

| Task or trigger | Required reading |
| --- | --- |
| Every project task | [rules.md: Task boundaries](docs-ai/common/rules.md#task-boundaries) and [Document ownership](docs-ai/common/rules.md#document-ownership) |
| Code, solution, project, namespace, or public API changes | Relevant sections of [codedesign.md](docs-ai/common/codedesign.md), affected source, and applicable repository configuration |
| UI or UX work | [UIUX.md](docs-ai/common/UIUX.md), then actual Flourish components, styles, public contracts, and host usage |
| Repository structure or architecture work | [1_architecture.md](docs-ai/current/1_architecture.md), then affected solution/project files and source |
| Dependency, SDK, package, service, asset, build, or deployment dependency changes | [rules.md: External dependencies](docs-ai/common/rules.md#external-dependencies) and [1_dependency.md](docs-ai/current/1_dependency.md), then dependency declarations and resolved evidence |
| Documentation creation, restructuring, or audit | [rules.md: Documentation contract](docs-ai/common/rules.md#documentation-contract) and [Full documentation audit](docs-ai/common/rules.md#full-documentation-audit) |
| Implementation, testing, or delivery | [rules.md: Implementation and verification](docs-ai/common/rules.md#implementation-and-verification) and [Delivery and records](docs-ai/common/rules.md#delivery-and-records) |
| A decision depends on project history | Only the relevant records in `docs-ai/current/1_changelogs/`, `1_bugreports/`, or `1_archived/` |
| A task needs a project-owned skill | The relevant package in `.agents/skills/`; use its `SKILL.md` directly when native discovery is unavailable |
| The audit gate requires a full audit | [audit-project-docs](.agents/skills/audit-project-docs/SKILL.md), plus the documentation contract |
| Framework initialization, version checks, or updates | [sync-agents-framework](.agents/skills/sync-agents-framework/SKILL.md), [synchronization rules](docs-ai/common/rules.md#framework-synchronization), and the source/local metadata |

Add the corresponding reading whenever the task's scope changes. Read only relevant sections and affected subtrees; do not load the complete history or dependency inventory for an unrelated task. Reuse already-read, unchanged material within the same task. Re-read material when it changes or its applicability becomes uncertain.

## Where instructions and facts belong

| Location | Responsibility |
| --- | --- |
| `AGENTS.md` | Entry point, reading routes, and instruction ownership |
| `docs-ai/common/codedesign.md` | Shared code, naming, and compatibility standards |
| `docs-ai/common/rules.md` | Shared execution, documentation, dependency approval, audit, and delivery rules |
| `docs-ai/common/UIUX.md` | Shared UI integration rules and Flourish ownership boundaries |
| `.agents/skills/` | Project-owned reusable skill packages |
| `docs-ai/current/1_architecture.md` | Verified repository tree and current project architecture |
| `docs-ai/current/1_dependency.md` | Verified inventory of dependencies used by this project |
| `docs-ai/current/1_changelogs/` | Append-only change records |
| `docs-ai/current/1_bugreports/` | Diagnosis, fixes, and regression evidence |
| `docs-ai/current/1_archived/` | Superseded or abandoned designs, retained as history |

Shared standards remain in `common/`; skills package repeatable workflows and reference those standards. Do not rely on implicit skill matching to enforce mandatory rules.

This router and `common/` describe the currently effective standards. Record dates, approval history, superseded decisions, and implementation history in `current/`; do not embed historical narratives in the router or shared standards.

Keep this file and `docs-ai/` under version control. When copying them to another repository, verify and adapt all project-specific content in `current/` and initialize `AGENTS.ensure.json` to an unaudited state. Managed updates preserve project facts and audit state; a changed framework version makes the next full audit due.

Follow the runtime's effective instruction hierarchy. This file does not override higher-priority instructions. Resolve project-rule conflicts according to [rules.md: Task boundaries](docs-ai/common/rules.md#task-boundaries).
