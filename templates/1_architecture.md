# Project architecture and repository tree

**Status:** Template awaiting repository inspection. No project structure or runtime architecture has been verified. Complete this file from actual repository evidence before marking the documentation audit complete.

## Inventory scope

Include the repository root and every maintained directory and file below it, including source, solution and project files, root instructions, configuration, deployment definitions, tests, and checked-in assets.

Exclude the entire `docs/` and `docs-ai/` subtrees, version-control internals, temporary files, build outputs, caches, and generated intermediates. Replace the table below with the concrete paths or patterns present in the repository. Do not exclude maintained files solely because an ignore pattern matches them.

| Excluded path or pattern | Reason |
| --- | --- |
| `docs/` | Human documentation subtree |
| `docs-ai/` | AI documentation subtree |

## Complete repository tree

Replace the placeholder below with a complete hierarchical tree rooted at the repository directory. Show every included file; do not collapse maintained subtrees into ellipses or representative examples. An indented Markdown list or a fenced directory tree may be used.

- `<repository-root>/` — replace with the actual root name and all included descendants.

## Root files and module responsibilities

Populate from inspected files. Describe the purpose of each important root file and each maintained root directory, then explain the responsibilities of significant modules below them. Include `scripts/`, the framework launcher `fetch-agents.bat`, and the project-owned operation entry point `debug-handler.bat`; inspect its contents before describing implemented operations, because it is initially empty.

| Repository-relative path | Responsibility | Evidence |
| --- | --- | --- |

## Solution and project boundaries

List actual solution files and projects. Distinguish executable applications, shared libraries, tests, examples or Gallery projects, and infrastructure definitions. Describe project references and relevant dependency direction without inferring a runtime boundary from a project boundary.

| Solution or project path | Kind | Responsibility | References and boundaries |
| --- | --- | --- | --- |

## Runtime and resource boundaries

Describe verified processes, entry points, deployment units, databases, and other external resources. Explain orchestration and communication only where established by source or configuration. If a boundary cannot be verified, mark it as unknown.

| Application or resource | Runtime/deployment boundary | Communication or persistence | Evidence |
| --- | --- | --- | --- |

## Active project constraints and exceptions

Record current project-specific constraints and applicable authorized exceptions. Include their scope and a link to supporting evidence when available. Keep completed approval narratives and superseded decisions in the history directories.

## Verification and unresolved facts

Record the repository revision or inspection scope, evidence used, and any unresolved gaps. Keep this file marked incomplete while essential tree entries or architecture facts remain unverified.
