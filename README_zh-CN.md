# AGENTS.md

[English](https://github.com/Evigila/AGENTS.md/blob/main/README.md) | [简体中文](https://github.com/Evigila/AGENTS.md/blob/main/README_zh-CN.md)

适用于Git仓库的AGENTS.md规则框架。

## 快速安装

需求：

- 目标是Git初始化后的仓库
- 需要Git for Windows
- 需要Windows PowerShell 5.1 或者 7

首次安装时，使用以下命令获取 `fetch-agents.bat`。

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
| `scripts/` | AI 创建的脚本应放在这里， 根目录只允许 `debug-handler.bat` 和 `fetch-agents.bat`。 |
| `debug-handler.bat` | 项目操作菜单，调用 `scripts/` 下已配置的实现 |
| `templates/`, publisher, tests, CI, README | 不会被复制到你的仓库 |

## 使用命令

双击 `fetch-agents.bat` 后显示 `1 Update`、`2 Check`、`3 Force`、`0 Exit`，收到输入前不会开始操作。直接回车选择 Update，非法输入会重新提示。使用显式命令行参数时，也需要回车确认。操作成功、失败或取消后，再按回车关闭窗口。

无人值守调用必须把 `-NonInteractive` 放在第一个参数，例如 `fetch-agents.bat -NonInteractive -Check`。该开关跳过开始与结束等待，校验、备份和操作退出码保持有效。

`debug-handler.bat` 使用相同交互规范，菜单为 `1 Debug`、`2 Clear database`、`3 Publish tag`、`4 Publish NuGet`、`0 Exit`，直接回车选择 Debug。对应调用 `scripts/debug`、`clear-database`、`publish-tag` 或 `publish-nuget`，优先 `.bat`，其次 `.ps1`。框架只提供菜单；未配置项目实现的操作会提示未配置。自动化可使用 `debug-handler.bat -NonInteractive 1`，或其他菜单编号。

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

项目当前的 `current/` 文档和 `AGENTS.ensure.json` 仅在缺失时初始化。项目自有的 `debug-handler.bat` 在缺失或仍为旧版零字节入口时初始化菜单；已有非空自定义内容始终保留，包括使用 `-Force` 时。`-Force` 仅替换存在冲突的受管框架文件，并在 `.agents/backups/` 下生成备份。

如果你对 -Force 覆盖有信心，可以删除备份。不过推荐过一个提交再删除，以保留一份 Git 历史避免不时之需。

## AI 辅助

> [!IMPORTANT]
> 本库使用了 AI Agent (ChatGPT Codex) 技术来辅助编写。

## 许可证

使用 [MIT License](https://github.com/Evigila/AGENTS.md/blob/main/LICENSE)。
