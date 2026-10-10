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
| `docs-ai/current/` | AI 维护的当前项目事实和记录；未经你显式授权，AI 不得修改 `docs/` 下的人工文档 |
| `docs-ai/current/1_changelogs/` | 当前项目的变更记录 |
| `docs-ai/current/1_bugreports/` | 当前项目曾遇到过的问题，以及修复方案 |
| `docs-ai/current/1_archived/` | 已被废弃的档案 |
| `docs/` | 你应当人工维护的文档，面向人类 |
| `fetch-agents.bat`, `scripts/fetch-agents.ps1` | 快捷处理器，快速检查和同步 |
| `scripts/` | 项目操作脚本和框架同步实现 |
| `debug-handler.bat` | 初始为空的项目操作统一入口，仅在文件不存在时创建 |
| `templates/`, publisher, tests, CI, README | 不会被复制到你的仓库 |

AI 创建的项目脚本应放在 `scripts/` 下；根目录只允许创建 `debug-handler.bat` 和 `fetch-agents.bat`。调试启动项目、清除数据库、发布远端 Git Tag、发布 NuGet 等操作必须统一通过 `debug-handler.bat` 入口，可由它调用 `scripts/` 下的独立脚本。该入口属于当前项目，框架同步会保留已有内容，包括使用 `-Force` 时。

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

## 旧版同步器恢复

旧版同步器可能因不认识新版本新增的模板而报 `Invalid project template target`。请使用当前中央仓库中的同步器检查目标项目，并保留目标项目原有的锁文件和已安装文件：

```powershell
& 'C:\中央仓库路径\AGENTS.md\scripts\fetch-agents.ps1' -ProjectRoot 'C:\目标项目路径' -Check
```

确认需要更新后，使用同一命令去掉 `-Check`。不要手动覆盖项目中的同步器或删除锁文件，正常同步需要继续检查本地冲突并保护项目文件。

新版清单声明同步器协议 `1`。兼容的同步器会先固定源提交，校验并在临时目录运行该提交中的同步器，再解析新增的模板路径；锁文件仍保留原仓库和分支或版本引用，`-Check` 不修改项目文件。没有协议字段的旧版清单继续由当前同步器处理，包含主动回退的场景。

## 排除

项目当前的 `current/` 文档、`AGENTS.ensure.json` 和 `debug-handler.bat` 仅在缺失时初始化。已有内容始终保留，包括使用 `-Force` 时。`-Force` 仅替换存在冲突的受管框架文件，并在 `.agents/backups/` 下生成备份。

如果你对 -Force 覆盖有信心，可以删除备份。不过推荐过一个提交再删除，以保留一份 Git 历史避免不时之需。

## AI 辅助

> [!IMPORTANT]
> 本库使用了 AI Agent (ChatGPT Codex) 技术来辅助编写。

## 许可证

使用 [MIT License](https://github.com/Evigila/AGENTS.md/blob/main/LICENSE)。
