# AGENTS framework

A versioned English instruction framework for Git repositories. `AGENTS.md` routes each task to the applicable standards and project facts. Repository skills live in the standard `.agents/skills/<name>/SKILL.md` location.

## Install in a project

Requirements: an existing Git repository, Git for Windows, and Windows PowerShell 5.1 or PowerShell 7. Run this command from the project's Git root when `fetch-agents.bat` is absent:

```bat
cmd /c "curl.exe -fL https://raw.githubusercontent.com/Evigila/AGENTS.md/main/fetch-agents.bat -o fetch-agents.bat && call fetch-agents.bat"
```

After installation, double-click `fetch-agents.bat`, or run it from CMD:

```bat
fetch-agents.bat
fetch-agents.bat -Check
```

The launcher selects PowerShell 7 when available, otherwise Windows PowerShell. It bootstraps the installer from this repository when the local script is absent. The installer fetches one source commit, validates the manifest and every payload, then synchronizes the listed files. Review `git diff` and commit the imported framework and generated lock with your project.

PowerShell also works directly on Windows, Linux, and macOS:

```powershell
# Run a trusted copy of the central installer against your project.
./scripts/fetch-agents.ps1 -ProjectRoot /path/to/project
./scripts/fetch-agents.ps1 -ProjectRoot /path/to/project -Check
```

First installation creates architecture/dependency templates and an unaudited state. Complete the `audit-project-docs` workflow from actual project evidence before setting the audit completion timestamp.

## Layout and ownership

| Location | Role | Consumer update behavior |
| --- | --- | --- |
| `AGENTS.md` | Compact entry point and required reading routes | Managed |
| `docs-ai/common/` | Mandatory code, execution, documentation, and UI integration standards | Manifest-listed files managed |
| `.agents/skills/audit-project-docs/` | Repeatable full documentation audit | Managed package |
| `.agents/skills/sync-agents-framework/` | Explicit version check, initialization, or update | Managed package |
| `AGENTS.framework.json` | Published version and exact payload manifest | Managed |
| `AGENTS.lock.json` | Source/ref, imported commit, manifest digest, file baselines, sync time | Generated locally and tracked in project Git |
| `AGENTS.ensure.json` | Monthly documentation audit state and audited framework version | Seed only; existing state preserved |
| `docs-ai/current/` | Project-specific architecture, dependencies, records, and archives | Seed missing template/marker files only |
| `docs/` | Human-maintained documentation | Seed missing empty marker only |
| `fetch-agents.bat`, `scripts/fetch-agents.ps1` | Bootstrap, check, and synchronization | Managed |
| `templates/`, publisher, tests, CI, README | Central repository maintenance | Source only; never copied as project facts |

`common/` remains normative documentation. Converting all of it into implicitly selected skills would make mandatory rules depend on skill matching. Skills package reusable procedures and reference the common standards instead of duplicating policy. The two workflows are explicitly routed from `AGENTS.md` so they remain usable when native skill discovery is unavailable.

The shared code/UI standards retain the configured Arkheide namespace and Flourish integration rules. Assess their applicability before adopting the framework for a different organization; document authorized project-specific exceptions in `current/`.

## Version checks and reproducibility

The manifest uses stable `major.minor.patch` versions. Increase the version whenever the manifest or any installed payload changes. Use a major increment for incompatible framework/schema changes, minor for compatible additions, and patch for corrections.

The consumer lock identifies the exact imported commit and SHA-256 baseline of each managed file. Hashing removes an initial UTF-8 BOM and normalizes CRLF to LF. Version plus manifest digest identifies a release; source-only documentation commits do not create a new framework release. Checks still print the currently resolved source commit. An explicit repository/ref switch is recorded even when its payload is identical.

| Exit code | Meaning |
| --- | --- |
| `0` | Check: current; apply: successful/current |
| `1` | Invalid input/source/payload, network or filesystem failure, refused downgrade, or apply stopped on a conflict |
| `2` | Check: update or missing installation/template files available |
| `3` | Check: local managed-file conflict |

`-Check` does not write project files. A framework version check is explicit; unrelated development does not fetch the central repository on every task.

Select a branch, existing tag, or full commit SHA:

```bat
fetch-agents.bat -Ref main
fetch-agents.bat -Ref <full-commit-sha>
```

The selected ref persists in the lock. A commit pin stays fixed until you explicitly choose another ref. A maintainer-created tag such as `v1.0.0` works after that tag exists; the manifest version does not itself create a Git tag. `-Repository <git-url>` selects a different compatible source. `-SourcePath <local-central-clone>` reads committed files from a local clone without a network fetch; `-Ref` still selects its commit. The lock records the configured upstream repository, not a machine-specific local clone path.

## Local customizations and migration

The installer compares working files with their last imported hashes. It detects committed customizations as well as uncommitted edits. Files added by the project outside the manifest remain untouched, including additional skills and common documents. A file removed from a newer manifest is deleted only if the previous lock proves framework ownership and its content is unchanged.

A conflict stops application before changes. Review the conflicting files and preserve useful project-specific material. If replacing those managed customizations is intended, rerun explicitly with `-Force`:

```bat
fetch-agents.bat -Force
```

Conflicting existing files are copied byte-for-byte to `.agents/backups/<UTC-time>-<id>/` before replacement. `-Force` also allows an intentional version downgrade. It never overwrites existing project templates/audit state or bypasses path, link, and payload validation. Add `.agents/backups/` to your project's ignore rules if desired; the installer does not change your `.gitignore`.

For an older framework with `docs-ai/common/SKILLS/`, move each genuine skill package to `.agents/skills/<skill-name>/`, retain its resources and valid `SKILL.md`, and update references. Review destination conflicts first. The central framework no longer creates the old directory; synchronization leaves pre-existing unowned files there intact. Do not turn common policy files into skills simply to relocate them.

Updates preserve the target's origin, Git index, branch, commits, existing human documents, project facts, and audit state. They write the new lock last and attempt to restore affected files after a write failure. This is a multi-file best-effort rollback, not a guarantee against power loss or concurrent writers; run one synchronization at a time. A new framework version makes the next full audit due through `auditedFrameworkVersion` without pretending that synchronization audited the project.

## Maintain the central repository

Edit payload files and, when needed, add/remove exact entries in `AGENTS.framework.json`. Only the approved framework locations can be managed; templates use `seed` mode. Publish the next version and verify:

```powershell
./scripts/publish-framework.ps1 -Version 1.0.1
./scripts/publish-framework.ps1 -Check
./tests/test-sync.ps1
```

Commit the manifest and matching payload together. Once published, do not alter payload at the same version: consumers reject a changed manifest digest for an already installed version. Tags are optional labels; a commit SHA is the authoritative reproducibility pin. The central source has its own `current/` facts and audit state, while consumer templates are separate under `templates/`.

CI runs the manifest check and integration suite on Windows PowerShell 5.1, PowerShell 7 on Windows, and PowerShell 7 on Linux. The test suite uses temporary local Git repositories and requires no Pester or third-party PowerShell modules.
