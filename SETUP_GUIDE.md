# WinCC OA 项目 Git 协作指南

## 首次克隆与启动

```bash
git clone https://github.com/oaemiao/OriginalNewProject
```

### 1. 修改项目路径

打开 `config/config`，将 `proj_path` 改为本地实际路径：

```ini
proj_path = "C:/Your/Actual/Path"
```

> ⚠️ 此项每台机器必改，路径使用正斜杠 `/`。

### 2. 启动项目

用 WinCC OA Console 打开该项目，首次启动会自动：

- 初始化并分配 .db/.key 数据库文件大小
- 创建 `db/wincc_oa/VA_*/` 归档目录（数量取决于 `config/progs` 中 `WCCOAvalarch -num` 的实例数：`-num 0` ~ `-num 5` 即 `VA_0000` ~ `VA_0005`）
- 生成 `dbase.status`、`event.status` 等状态文件

### 3. 首次启动后的提交（可选）

首次启动后 .db/.key 文件大小会因初始化而变化，这是正常的。

```bash
git add -A
git commit -m "chore: first-startup database initialization"
```

> 后续日常启动不会再产生大幅 .db 变化。

## .gitignore 要点

| 忽略 | 原因 |
|------|------|
| `VA_*/` | 归档运行时数据，每次启动重建，机器相关（数量 = `WCCOAvalarch -num` 实例数） |
| `dbase.status / .touch / event.status` | 运行状态标记，启停变化 |
| `vista.log / vista.taf` | 运行时日志与事务文件 |
| `bin/`、`help/`、`msg/` | 随 OA 安装自带，无需入库 |
| `*.ctc`、`*.ba?` | 编译产物，可从源码再生 |

| **不能忽略** | 原因 |
|-------------|------|
| `db/` 核心文件 | 包含 .dbd/.key/.db，无此目录项目无法打开 |
| `config/` | 项目配置入口 |
| `panels/` | UI 面板文件 |
| `scripts/` | CONTROL 脚本 |
| `pictures/`、`images/` | 画面与图片资源 |

## 分支策略建议

- `main` — 仅存放跨机器通用的项目文件
- 每台机器的首次启动变化（.db 初始化、proj_path 等）**不要合入 main**
- 可在本地分支（如 `PC_xxx`）上提交机器特定的 proj_path 修改，方便日后参考
- 验证分支（如 `PC_Astro`）测试完成后关闭即可，无需 PR 到 main

## 快照工具

| 文件 | 说明 |
|------|------|
| `oa_project_snapshot.ps1` | 生成项目目录树与文件清单 |
| `snapshot_tree.txt` | 目录树快照 |
| `snapshot_tree_zh.txt` | 目录树快照（含中文注释） |
| `snapshot_files.txt` | 完整文件清单 |
