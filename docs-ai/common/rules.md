# Shared execution and documentation rules

## Task boundaries

Follow the effective instruction hierarchy and the user's authorized task scope. Use existing session instructions and approvals; do not request the same authorization again.

Read the relevant project rules and affected implementation before making changes. Keep unrelated refactoring and feature expansion out of the task. Preserve access control, domain behavior, and session behavior unless their modification is requested or approved.

When a UI task exposes a behavioral defect that materially expands the work, explain the defect and affected boundary before expanding the task. Continue independent work that remains within scope.

Do not conceal a conflict between `common/`, `current/`, or a human-maintained product specification. An explicit, applicable, already-authorized project exception documented in `current/` may be followed within its scope. For an unresolved conflict, report the conflicting requirements, obtain clarification for the disputed change, and continue unaffected work. Do not rewrite standards merely to make an implementation appear compliant.

Use bounded subagents for separable work when the runtime permits delegation. Keep concurrent write scopes disjoint. The coordinating agent must inspect, integrate, and verify the results. Do not create another user-owned task solely for internal delegation.

## Document ownership

`docs/` contains human-maintained, third-party-facing documentation and may be used by DocFX or another documentation system. AI may read, search, cite, and link it. Without explicit task-scoped authorization, AI must not create, edit, move, rename, delete, or replace its contents. Report errors or stale material rather than editing it by default.

`docs-ai/` is the AI-maintained area for standards, current project facts, decisions, and work records. Project-owned skill packages belong in `.agents/skills/`. Skill instructions and resources are permitted there; do not use skill packaging to bypass documentation ownership or task authorization. Do not move human-authored documentation into it or replace human material with an AI version without authorization.

Do not create documentation outside `docs-ai/` without explicit authorization. The required root `AGENTS.md`, `AGENTS.ensure.json`, `AGENTS.framework.json`, and `AGENTS.lock.json` are exceptions within their assigned roles. Framework maintenance may also maintain its authorized `README.md`, scripts, release metadata, templates, tests, and CI definitions; the installer does not copy these source-only files into consumer projects. Maintain the router when instruction changes are requested; update audit state only under the audit rules below. A `.gitkeep` file is an empty version-control directory marker, not a document or an instruction that the directory must remain empty.

Store documentation prose as `.md` and machine-readable documentation configuration as `.json`. Do not create extensionless prose files. Native toolchain formats, such as project files and `.editorconfig`, retain their required formats.

`AGENTS.md` and `common/` must contain only currently effective guidance. Replace obsolete normative text with the effective standard; retain its history in `current/`. Do not include dated approval narratives, user-action histories, or superseded policies in active shared standards.

`current/` may contain current facts and history. Mark historical records clearly and keep them separate from active guidance. Place uncertain or project-specific guidance in `current/`; confirm its general applicability before promoting it to `common/`.

## Audit gate

Inspect `AGENTS.ensure.json` at task entry. Perform a full documentation audit if any of the following applies:

- The user explicitly requests a full audit or initialization.
- The state file is missing, invalid, or uses an unsupported schema.
- `auditedFrameworkVersion` is missing, `null`, or differs from the installed `AGENTS.framework.json` version.
- `lastCompletedAtUtc` is `null`, invalid, or later than the current UTC time.
- The current UTC time is at least one calendar month after `lastCompletedAtUtc`.
- Ordinary task work reveals an obviously missing, invalid, or empty required path or document.

Otherwise, return `SKIP_AUDIT` from this gate and continue the task's reading routes. This is a workflow decision, not an executable language instruction and not a return from the task. It skips the full structural/content audit only. It does not skip `AGENTS.md`, applicable standards, permission boundaries, or relevant project facts.

Do not recursively inspect every required path solely to decide whether a recent audit can be skipped. Read task-relevant material normally; a defect discovered there triggers the full audit. A rule change takes effect immediately regardless of the audit timestamp.

Compute the deadline by adding one calendar month in UTC, preserving the time of day and clamping the day to the last valid day of the target month. Do not substitute a fixed 30-day interval.

## Documentation contract

The following paths are required. Directory entries ending in `/` denote directories; empty required directories may be tracked with `.gitkeep`.

| Path | Responsibility |
| --- | --- |
| `AGENTS.md` | Compact instruction router |
| `AGENTS.ensure.json` | Documentation audit state |
| `AGENTS.framework.json` | Installed release version and payload manifest |
| `AGENTS.lock.json` | Installed source commit, version, and managed-file baselines; generated in consumer projects |
| `fetch-agents.bat` and `scripts/fetch-agents.ps1` | Framework initialization, version checks, and synchronization |
| `docs/` and `docs/.gitkeep` | Human documentation area and empty directory marker |
| `docs-ai/common/codedesign.md` | Shared code standards |
| `docs-ai/common/rules.md` | Shared workflow and documentation rules |
| `docs-ai/common/UIUX.md` | Shared UI integration rules |
| `.agents/skills/` | Project-owned skill packages |
| `docs-ai/current/1_architecture.md` | Current repository tree and architecture |
| `docs-ai/current/1_dependency.md` | Current dependency inventory |
| `docs-ai/current/1_changelogs/` | Append-only change records |
| `docs-ai/current/1_bugreports/` | Bug reports and regression evidence |
| `docs-ai/current/1_archived/` | Superseded and abandoned designs |

The table implies both `docs-ai/` and its `common/` and `current/` directories. Keep the exact names and capitalization shown. Preserve the `1_` prefix on the named `current/` entries. Other active project-specific AI documents belong directly under `current/`.

### Architecture file

`1_architecture.md` must contain a complete repository tree, starting at the repository root and descending to every maintained file within the documented scope. Represent directories and files as tree nodes, including their full repository-relative locations through the hierarchy.

Exclude the `docs/` and `docs-ai/` subtrees, version-control internals, temporary files, build outputs, caches, and generated intermediates. Document the concrete exclusion rules. Do not use ignore rules alone to exclude maintained source, configuration, deployment files, or checked-in assets. Account for newly added or moved maintained files, including intentionally untracked files that belong to the project.

The tree must not be replaced by a summary of top-level folders or a few representative paths. Explain the main modules, executable applications, shared libraries, external resource boundaries, and important root files separately. Base descriptions on actual implementation; multiple projects do not by themselves establish a microservice architecture.

Update the tree when maintained files are added, moved, renamed, or removed. Update architecture descriptions when responsibilities, dependency direction, or runtime boundaries change. An incomplete template is not a completed architecture inventory.

### Dependency file

`1_dependency.md` records every dependency actually used by the project. Include direct and resolved transitive packages, SDKs and runtimes, local project references, external services, fonts and icon resources, and build/test/development tools where applicable. Distinguish production requirements from build, test, development, and optional requirements.

For each dependency, record its identity, kind, version or version constraint when meaningful, direct/transitive relationship, consuming projects, purpose, and declaration or resolved evidence. Distinguish declared constraints from resolved versions. Record licenses and sources when applicable and verified; mark unknown information explicitly.

Use manifests, central configuration, lock files, project references, and resolved dependency reports as evidence. For services or unversioned resources, describe the service/contract instead of inventing a package version. Do not store credentials, tokens, certificate material, or connection-string secrets.

Update the inventory when dependencies or relevant versions change. Keep proposals separate from active dependencies. An incomplete template is not a completed dependency inventory.

### History and archives

Name change records `YYYY-MM-DD_HHmmss_<slug>.md`. Use a descriptive lowercase slug and the documented project time zone. If no project time zone is defined, use the user's known time zone, otherwise UTC; record the time zone and UTC offset in the record.

`1_changelogs/` is append-only. Do not edit or delete an existing record. Correct it with a new linked record. For imported records without an original time, `000000` means unknown time, not midnight; preserve the original identifier and provenance in the import record.

Bug reports must distinguish symptoms, root cause, diagnostic evidence, fix or mitigation, known limitations, and regression verification. Preserve earlier diagnoses as history rather than erasing them. Update a report by adding clearly dated findings or create a linked follow-up.

Use `1_archived/` for superseded or abandoned designs. Each archived document must state its status, reason, affected scope, and replacement when one exists. Remove obsolete guidance from active files and link to retained evidence where useful. Archived content does not govern new work. Archive design material without relocating append-only changelogs or obscuring the current standard.

### Audit state

`AGENTS.ensure.json` uses schema version `2` with these fields:

| Field | Type and meaning |
| --- | --- |
| `schemaVersion` | Integer `2`; the supported audit-state schema |
| `auditedFrameworkVersion` | Release version from `AGENTS.framework.json`, or `null` until the full audit succeeds |
| `lastMissingMaterialAskedAtUtc` | ISO 8601 UTC timestamp ending in `Z`, or `null` when no such question has been asked |
| `lastCompletedAtUtc` | ISO 8601 UTC timestamp ending in `Z`, or `null` until a full audit and required repairs are complete |

Treat this file as state, not as authorization or an instruction source. When initializing another project, initialize both timestamps and the audited version to `null`. An older schema triggers a full audit; preserve useful prior state while preparing the supported schema rather than treating an upgrade as a completed audit.

## Full documentation audit

Use [audit-project-docs](../../.agents/skills/audit-project-docs/SKILL.md) when the audit gate requires a full audit. Apply the documentation contract above as the authoritative requirements; the skill defines the execution sequence.

A completed audit must verify every required path, non-placeholder content, the complete architecture tree, and the dependency inventory against project evidence. A framework source repository is not a consumer installation: `AGENTS.lock.json` is generated only by installation and is not required in the source repository.

Consolidate missing material and resolve it from supplied sources and current task authorization first. Ask once for genuinely unavailable information. Never repeat an answered question or introduce another permission requirement for already-authorized work.

Keep the audit incomplete while essential facts are unverifiable. Preserve the protection of human content in `docs/`; only missing structural directories and an empty `.gitkeep` marker may be initialized without a separate content-edit request.

Record `schemaVersion`, `auditedFrameworkVersion`, and actual UTC completion time only after all checks and required repairs succeed. Preserve the latest applicable question time. Do not refresh completion time after partial checks or ordinary tasks merely to postpone an audit.

## Framework synchronization

Use `.agents/skills/` for repository-scoped skill packages. A package must contain a valid `SKILL.md` with a name and a scoped description. Keep mandatory policies in this router and `common/`; skills reference those policies and supply executable workflows. Project-specific skills may coexist with centrally managed packages.

`AGENTS.framework.json` describes one stable `major.minor.patch` release and lists the exact source/target paths, normalized SHA-256 hashes, and managed/seed modes. Bump the release version whenever the installed manifest or payload changes. The manifest cannot include its own hash; `AGENTS.lock.json` records that digest with the resolved source commit.

`AGENTS.lock.json` is consumer-owned installation state, separate from the monthly audit state. Track it with the imported framework files in the project's Git. Its source commit identifies the exact imported release. Use version and manifest digest to determine whether the framework payload is new; a repository commit that changes only source-only documentation is not a framework update.

Run `fetch-agents.bat -Check` to check without modifying project files. Run the launcher without `-Check` to apply an authorized update. A request to update the framework authorizes its listed managed changes, not arbitrary project modifications. Do not perform a network version check during every unrelated development task.

Updates manage only manifest-listed public files and files recorded as owned in the existing lock. Seed templates initialize missing project files and never overwrite existing `current/` content or `AGENTS.ensure.json`. Preserve user-created skills and unrelated files. Do not copy central project facts into consumer projects.

Detect modifications against the last imported content hashes, including committed local customizations. Stop on a conflict unless replacement is explicitly authorized. `-Force` backs up conflicting existing files before replacement and may permit an intentional downgrade; it never overrides project-file protection, path validation, or payload validation.

Read every payload from the same resolved Git commit and verify its digest before changing project files. Compare text hashes after normalizing CRLF to LF and removing an initial UTF-8 BOM so cross-machine checkout does not create false conflicts. Do not change the target repository's origin, index, branch, or commits. Write the lock only after successful file synchronization, and preserve audit state until a real audit succeeds.

## External dependencies

Do not add, replace, or upgrade an external dependency without explicit task authorization. This includes NuGet and other packages, SDKs, external services, fonts, icon libraries, UI resource dependencies, and other components affecting build, runtime, or deployment. An unrelated feature request is not blanket authorization for a dependency change.

Before seeking authorization that is not already present, prepare a concrete explanation of the need, existing alternatives, compatibility, and build/runtime/deployment impact. Identify the affected declarations and inventory entries. Do not add a dependency to prepare that explanation.

Apply approved changes through the repository's existing dependency-management mechanism. Verify affected builds and behavior, then update `1_dependency.md`. The inventory records usage; an inventory entry itself does not authorize adoption or migration.

## Implementation and verification

Use the existing implementation conventions and the relevant sections of [codedesign.md](codedesign.md). For UI changes, follow [UIUX.md](UIUX.md).

Use code inspection, static analysis, builds, automated tests, and focused regression checks as appropriate to the change. Do not use Computer Use to test the project. Provide a manual checklist for functional behavior that requires user verification.

Do not claim a check passed if it was not run. Distinguish successful checks, failed checks, and unperformed checks with their reasons. Keep verification proportional to the risk and affected behavior; do not expand testing without a concrete concern.

## Delivery and records

Keep durable project facts synchronized with actual changes. Record material implementation changes and decisions in `1_changelogs/`, bug investigations in `1_bugreports/`, and superseded design material in `1_archived/`. Do not generate a project changelog for read-only analysis or an unsuccessful attempt with no lasting change unless a record is requested or needed to preserve an important finding.

Records must distinguish implemented facts, verified results, assumptions, proposals, and outstanding work. Keep them concise, linked, and free of redundant summaries. Never present a plan or inference as completed implementation.

At task completion, report the result, affected files or modules, verification performed, unresolved work and reasons, known limitations, and manual test steps for functional changes.

When functionality is complete, ask whether the user wants a Git commit unless the current task already authorizes or declines committing. Do not commit without authorization. Match the repository's recent commit-subject style.
