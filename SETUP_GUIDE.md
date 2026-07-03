# WinCC OA 项目 Git 协作指南

## 首次克隆与启动

```bash
git clone https://github.com/oaemiao/OriginalNewProject
```

### 1. 修改项目路径（必改）

打开 `config/config`，将 `proj_path` 改为本地实际路径：

```ini
proj_path = "C:/Your/Actual/Path"
```

> ⚠️ **此项每台机器必改**，`proj_path` 是绝对路径，每台机器 clone 位置不同。路径使用正斜杠 `/`。

### 2. 启动项目

用 WinCC OA Console 打开该项目，首次启动会自动：

- 根据 `.dbd` 定义初始化并分配 `.db`/`.key` 数据库文件
- 创建 `db/wincc_oa/VA_*/` 归档目录（数量取决于 `config/progs` 中 `WCCOAvalarch -num` 的实例数：`-num 0` ~ `-num 5` 即 `VA_0000` ~ `VA_0005`）
- 生成 `dbase.status`、`event.status` 等状态文件

### 3. 首次启动后

首次启动生成的 `.db`/`.key` 等运行时文件已被 `.gitignore` 忽略，不会出现在 `git status` 中，无需处理。

### 4. 提交公共变更

```bash
git add -A
git commit -m "说明变更内容"
git push
```

> 提交前请检查 `git status`，确保无 runtime 文件或私钥文件被意外加入。

## .gitignore 要点

| 规则 | 说明 |
|------|------|
| `bin/`, `log/`, `cache/`, `tmp/`, `pmon/` | 运行时自动创建的目录，内容无保留价值 |
| `db/**/*.db`, `db/**/*.key`, `VA_*/` | 数据库运行时文件，从 `.dbd` 再生 |
| `db/wincc_oa/vista.log`, `*.taf`, `dbase.*`, `event.status` | 运行时日志与状态标记 |
| `**/private/`, `*.key`, `config/host-key.pem` | 私钥与敏感文件，禁止入库 |
| `data/rcp/`, `data/rct/`, `data/sounds/` | 运行时子目录，启动时自动创建 |
| `panels/**/*.ba?` | 面板编译产物，从 `.pnl` 再生 |
| `*.ctc` | CTRL 脚本编译产物，从 `.ctl` 再生 |
| `*.bak`, `*.tmp`, `~*`, `*.exe`, `*.rar` | 备份与临时文件 |
| `__pycache__/`, `*.pyc`, `.vscode/`, `.idea/` | Python 与 IDE 产物 |
| `dplist/*/elements/`, `dplist/*/variables/`, `dplist/_migration_draft/` | 迁移中间产物，可复现 |
| `snapshot_*.txt` | 快照脚本输出，可复现 |
| `CODEBUDDY.md` | 本地专属配置 |

| **必须跟踪** | 说明 |
|-------------|------|
| `config/` (不含 `host-key.pem`) | 项目配置，分发必须 |
| `db/**/*.dbd` | 数据库定义，从零重建的起点 |
| `panels/`、`scripts/` | UI 面板与 CONTROL 脚本 |
| `pictures/`、`images/` | 图片资源 |
| `data/Reporting/Templates/` | BIRT/SSRS 报表模板 |
| `data/xls_report/` | Excel 报表模板 |
| `data/iec104/PKI/certs/*.crt` | 公开证书（非私钥） |
| `data/opcua/client(PKI|server/PKI/CA/certs/*.der` | 公开证书（非私钥） |

## 分支策略建议

- `main` — 仅存放跨机器通用的项目文件
- 每台机器的首次启动变化（`.db` 初始化、`proj_path` 等）**不要合入 main**
- 可在本地分支（如 `PC_xxx`）上提交机器特定的 `proj_path` 修改，方便日后参考
- 验证分支（如 `PC_Astro`）测试完成后关闭即可，无需 PR 到 main

## 快照工具

| 文件 | 说明 |
|------|------|
| `oa_project_snapshot.ps1` | 生成项目目录树与文件清单（脚本已跟踪） |
| `generate_zh_tree.ps1` | 生成中文注释版目录树（脚本已跟踪） |

输出文件（`snapshot_*.txt`）为脚本生成物，已被 `.gitignore` 忽略，不在 Git 中跟踪。各机器可自由运行而不产生污染。
