# Framework architecture and repository tree

## Inventory scope

The tree includes every maintained file in this central source repository outside the two documentation subtrees. Exclusions: `docs/**` and `docs-ai/**` (documentation), `.git/**` (Git internals), `.agents/backups/**` (consumer recovery copies), and `*.tmp` (atomic-write intermediates). No generated build outputs, caches, application binaries, or external runtime distributions belong to this repository.

## Complete repository tree

- `AGENTS.md/` (repository root)
  - `.agents/`
    - `skills/`
      - `audit-project-docs/`
        - `agents/`
          - `openai.yaml`
        - `SKILL.md`
      - `sync-agents-framework/`
        - `agents/`
          - `openai.yaml`
        - `SKILL.md`
  - `.github/`
    - `workflows/`
      - `verify.yml`
  - `scripts/`
    - `fetch-agents.ps1`
    - `publish-framework.ps1`
  - `templates/`
    - `1_architecture.md`
    - `1_dependency.md`
    - `AGENTS.ensure.json`
    - `empty.gitkeep`
  - `tests/`
    - `test-sync.ps1`
  - `.gitattributes`
  - `.gitignore`
  - `AGENTS.ensure.json`
  - `AGENTS.framework.json`
  - `AGENTS.md`
  - `README.md`
  - `fetch-agents.bat`

## Responsibilities and dependency direction

| Location | Responsibility |
| --- | --- |
| `AGENTS.md` | Routes task reading, audit, and synchronization; does not replace the runtime's instruction hierarchy |
| `AGENTS.framework.json` | Versioned payload source/target/mode/digest inventory; excludes its own digest |
| `AGENTS.ensure.json` | Audit state for this central source; never imported as consumer completion evidence |
| `.agents/skills/` | Audit and explicit synchronization workflows, with optional Codex UI metadata |
| `scripts/fetch-agents.ps1` | Validates a single committed source snapshot, computes a plan, protects project facts/customizations, writes payload then lock, and rolls back failed writes where possible |
| `fetch-agents.bat` | Windows shell/Git discovery, trusted bootstrap installer acquisition, argument forwarding, cleanup and exit-code propagation |
| `scripts/publish-framework.ps1` | Maintainer-only manifest digest generation and strictly increasing release version preparation |
| `templates/` | Unverified consumer architecture/dependency templates, unaudited state, and empty directory marker |
| `tests/test-sync.ps1` | Package-free temporary Git integration fixtures and preservation/conflict/regression assertions |
| `.github/workflows/verify.yml` | Windows PowerShell 5.1 / Windows PowerShell 7 / Linux PowerShell 7 verification matrix |
| `.gitattributes` | Text checkout normalization; BAT checkout uses CRLF |
| `.gitignore` | Recovery and atomic-write intermediate exclusions |
| `README.md` | Installation, version model, ownership, conflicts, migration, and maintainer commands |
| `docs-ai/common/` (tree-excluded) | Centrally managed current standards; procedural skills reference them |
| `docs-ai/current/` (tree-excluded) | Facts and records for the central source, separate from consumer templates |
| `docs/` (tree-excluded) | Human documentation area; empty marker only |

There are no solution/project files, application assemblies, shared runtime libraries, microservices, UI components, or deployment units. PowerShell scripts are separate command entry points. The publisher and tests are central maintenance tools; only the launcher, installer, instructions, and manifest-listed templates are imported by consumers.

## Runtime and persistence boundaries

The launcher can clone the central `main` branch into a temporary directory to obtain its installer. The installer either fetches the selected repository/ref into a temporary bare repository or reads a supplied local clone. It resolves one commit and reads regular Git blobs from that commit. No target checkout, remote mutation, Git staging, branch change, or commit occurs.

The installation manifest defines managed files and seed-only project files. The generated consumer `AGENTS.lock.json` records the imported commit, source/ref, version, manifest digest, and owned-file hashes. Normalized text hashes protect both uncommitted and committed local modifications. Project-added files have no ownership entry and remain untouched. Managed files retired by a release can be removed only through the old lock's ownership baseline.

Filesystem changes are prevalidated and planned in memory. Existing conflicting managed files require an explicit `-Force` and are backed up separately. Seeds are initialized only when absent. The lock is written last; failures trigger best-effort restoration of planned paths. Interrupted power loss and concurrent writes are outside the transaction guarantee.

## Active constraints

This repository has no UI, so the shared Flourish UI integration rules create no installer dependency. Namespace/project-name rules apply to actual language/project identities and do not require renaming script functions. User-authorized framework maintenance includes the root README, scripts, templates, tests, and CI in addition to the AI documentation area.

The central source does not require a consumer `AGENTS.lock.json`. Its verified `current/` documents are never synchronized into another project. The seed templates explicitly remain incomplete until that project's own audit succeeds.

## Verification scope

The listed maintained paths and script responsibilities are based on source inspection. Integration results and platform limitations belong in the release change record; structure inspection alone does not establish runtime compatibility. Update this tree whenever maintained paths change.
