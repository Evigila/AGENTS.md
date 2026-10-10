# AGENTS.md

[English](https://github.com/Evigila/AGENTS.md/blob/main/README.md) | [简体中文](https://github.com/Evigila/AGENTS.md/blob/main/README_zh-CN.md)

适用于Git仓库的AGENTS.md规则框架。

## 快速安装

需求：

- 目标是Git初始化后的仓库
- 需要Git for Windows
- 需要Windows PowerShell 5.1 或者 7

使用以下命令快速获取 fetch-agents.bat，这是本仓库的“快捷处理器”。确保你的仓库没有该bat，否则你需要将其移除。

```bat
cmd /c "curl.exe -fL https://raw.githubusercontent.com/Evigila/AGENTS.md/main/fetch-agents.bat -o fetch-agents.bat && call fetch-agents.bat"
```

获取到bat后，双击，或者是运行代码检查状态：

```bat
fetch-agents.bat -Check
```

## 自动安装的文件

| 从根目录开始 | 用处 |
| --- | --- |
| `AGENTS.md` | 入口 |
| `docs-ai/common/` | 通用集成标准 |
| `.agents/skills/audit-project-docs/` | 文档审计SKILL |
| `.agents/skills/sync-agents-framework/` | 同步该AGENTS.md框架的SKILL |
| `AGENTS.framework.json` | 本框架清单和版本控制 |
| `AGENTS.lock.json` | 用于跟踪 |
| `AGENTS.ensure.json` | 审计结果文档 |
| `docs-ai/current/` | 当前项目的文档，ai agent会被要求仅在该文件夹中编辑和创作，它是面向ai的。同时失去docs/文件夹的控制权，你需要显式授予权限 |
| `docs-ai/current/1_changelogs/` | 当前项目的变更记录 |
| `docs-ai/current/1_bugreports/` | 当前项目曾遇到过的问题，以及修复方案 |
| `docs-ai/current/1_archived/` | 已被废弃的档案 |
| `docs/` | 你应当人工维护的文档，面向人类 |
| `fetch-agents.bat`, `scripts/fetch-agents.ps1` | 快捷处理器，快速检查和同步 |
| `templates/`, publisher, tests, CI, README | 不会被复制到你的仓库 |

## 使用命令

- 检查更新

```
.\fetch-agents.bat -Check
```

- 安装，更新或者什么都不做（可双击）

```
.\fetch-agents.bat
```

- 强制使用远端版本覆盖（会于`.agents/backups/`生成备份）

```
.\fetch-agents.bat -Force
```

- 使用远端main分支

```
.\fetch-agents.bat -Ref main
```

- 使用一个特定的版本

```
.\fetch-agents.bat -Ref "提交SHA或已有标签"
```

- 使用一个老的版本（会回退）

```
.\fetch-agents.bat -Ref "旧提交SHA" -Force
```

- 获取其他兼容的远端（会记住远端仓库除非再此指定别的main分支）

```
.\fetch-agents.bat -Repository "仓库Git地址" -Ref main
```

## 排除

项目当前的 `current/` 文档和 `AGENTS.ensure.json` 会始终被排除，这意味着同步不会覆盖。但是使用`-Force` 时仍然会替代，不过会在`.agents/backups/`下生成备份。

如果你对 -Force 覆盖有信心，可以删除备份。不过推荐过一个提交再删除，以保留一份 Git 历史避免不时之需。

## AI 辅助

> [!IMPORTANT]
> 本库使用了 AI Agent (ChatGPT Codex) 技术来辅助编写。

## 许可证

使用 [MIT License](https://github.com/Evigila/AGENTS.md/blob/main/LICENSE.txt)。
