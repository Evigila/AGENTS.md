# AGENTS.md

[English](https://github.com/Evigila/AGENTS.md/blob/main/README.md) | [简体中文](https://github.com/Evigila/AGENTS.md/blob/main/README_zh-CN.md)

An AGENTS.md framework for Git repositories.

## Quick Installation

Requirements:

- The target repository MUST already be initialized with Git
- Git for Windows
- Windows PowerShell 5.1 or PowerShell 7

Use the following command to download `fetch-agents.bat`, the quick launcher for this repository. 

Make sure the target repository does **NOT** already contain a file with this name; if it does, remove the existing file first.

```bat
cmd /c "curl.exe -fL https://raw.githubusercontent.com/Evigila/AGENTS.md/main/fetch-agents.bat -o fetch-agents.bat && call fetch-agents.bat"
```

After downloading the batch file, **double-click it to run**, or use the following command to check its status:

```bat
fetch-agents.bat -Check
```

## What will be Installed

| Path (relative to the root) | Purpose |
| --- | --- |
| `AGENTS.md` | Entry point |
| `docs-ai/common/` | Shared standards |
| `.agents/skills/audit-project-docs/` | Skill for auditing project documentation |
| `.agents/skills/sync-agents-framework/` | Skill for synchronizing the AGENTS.md framework |
| `AGENTS.framework.json` | Framework manifest and version control |
| `AGENTS.lock.json` | Tracking file |
| `AGENTS.ensure.json` | Documentation audit results |
| `docs-ai/current/` | AI-maintained project facts and records. Agents do **NOT** have permission to modify human documentation under `docs/` unless you explicitly grant it. |
| `docs-ai/current/1_changelogs/` | Change history for the current project |
| `docs-ai/current/1_bugreports/` | Previously encountered issues and their fixes |
| `docs-ai/current/1_archived/` | Archived and obsolete |
| `docs/` | You should maintain manually **HUMAN** |
| `fetch-agents.bat`, `scripts/fetch-agents.ps1` | Quick launcher for checking and synchronizing |
| `scripts/` | Project operation scripts and the synchronization implementation |
| `debug-handler.bat` | Initially empty, unified entry point for project operations; created only when missing |
| `templates/`, publisher, tests, CI, README | Will **NOT** copied into your repository |

AI-created scripts belong under `scripts/`; only `debug-handler.bat` and `fetch-agents.bat` may be created at the root. Starting the project for debugging, clearing databases, publishing remote Git tags, and publishing NuGet packages must use `debug-handler.bat`, which may call separate scripts under `scripts/`. Framework synchronization preserves any existing content in this project-owned entry point, including with `-Force`.

## Commands

- Check for updates:

```
.\fetch-agents.bat -Check
```

- Install, update, or do nothing if already up to date (can also be run by **double-clicking**):

```
.\fetch-agents.bat
```

- Force replacement with the remote version (creates backups under `.agents/backups/`):

```
.\fetch-agents.bat -Force
```

- Use the remote `main` branch:

```
.\fetch-agents.bat -Ref main
```

- Use a specific version:

```
.\fetch-agents.bat -Ref "Commit SHA or existing tag"
```

- Roll back to an older version:

```
.\fetch-agents.bat -Ref "Older commit SHA" -Force
```

- Use another compatible remote repository (the remote repository is remembered unless you override it later):

```
.\fetch-agents.bat -Repository "Git repository URL" -Ref main
```

## Exclusions

Project-specific documentation under `current/`, `AGENTS.ensure.json`, and `debug-handler.bat` are seeded only when missing. Synchronization preserves existing contents, including with `-Force`. The `-Force` option replaces conflicting managed framework files and creates backups under `.agents/backups/`.

If you are confident with `-Force` replacement, you can delete the backups. It is **recommended** to make a Git commit first so you retain a copy in Git history in case you need it later.

## AI assistance

> [!IMPORTANT]
> This library was developed with assistance from AI Agent (ChatGPT Codex).

## License

Licensed under the [MIT License](https://github.com/Evigila/AGENTS.md/blob/main/LICENSE).
