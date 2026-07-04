# WinCC OA 项目 Git 协作指南

## 首次克隆与启动

```bash
git clone https://github.com/oaemiao/OriginalNewProject
cd OriginalNewProject
```

打开 `config/config`，将 `proj_path` 改为本地实际路径，`pvss_path` 改为 WinCC OA 安装路径。

然后运行以下命令，标记运行时数据库文件为本地忽略（它们随仓库分发，但每次启停会变更，不应误提交）：
```powershell
git ls-files "db/wincc_oa/al0000000000/*.db" "db/wincc_oa/al0000000000/*.key" |
  ForEach-Object { git update-index --skip-worktree $_ }
git ls-files "db/wincc_oa/aloverflow/*.db" "db/wincc_oa/aloverflow/*.key" |
  ForEach-Object { git update-index --skip-worktree $_ }
git ls-files "db/wincc_oa/alliving/*.db" "db/wincc_oa/alliving/*.key" |
  ForEach-Object { git update-index --skip-worktree $_ }
git ls-files "db/wincc_oa/lastval/*.db" "db/wincc_oa/lastval/*.key" |
  ForEach-Object { git update-index --skip-worktree $_ }
```

然后用 WinCC OA Console 打开该项目。首次启动时，WinCC OA 会自动创建 `db/wincc_oa/VA_*/` 归档运行时目录和 `dbase.status`、`event.status` 等运行时标记文件。

> 所有 `.db`/`.key` 文件均随 Git 跟踪（`VA_*` 归档运行时除外），clone 后即可使用。报警归档、在线报警、最后值缓存目录（`al*`、`alliving`、`lastval`）的启停变更通过 `skip-worktree` 屏蔽。

---

## .gitignore 要点

| 规则 | 说明 |
|------|------|
| `bin/`, `log/`, `cache/`, `tmp/`, `pmon/` | 运行时自动创建，无保留价值 |
| `db/wincc_oa/VA_*/` | 值归档运行时目录（45 MB+，每次启动重建） |
| `db/wincc_oa/vista.log`, `*.taf`, `dbase.*`, `event.status` | 运行时日志与状态标记 |
| `**/private/`, `**/private/*.key`, `**/private/*.pem` | 私钥与敏感文件 |
| `data/rcp/`, `data/rct/`, `data/sounds/` | 运行时子目录 |
| `panels/**/*.ba?` | 面板编译产物 |
| `*.ctc` | CTRL 脚本编译产物 |
| `*.bak`, `*.tmp`, `~*`, `*.exe`, `*.rar` | 备份与临时文件 |
| `__pycache__/`, `*.pyc`, `.vscode/`, `.idea/` | Python 与 IDE 产物 |
| `dplist/*/elements/`, `dplist/*/variables/`, `dplist/_migration_draft/` | 迁移中间产物，可复现 |
| `snapshot_*.txt` | 快照脚本输出，可复现 |
| `CODEBUDDY.md` | 本地专属配置 |

| **必须跟踪** | 说明 |
|-------------|------|
| `config/`（含 `host-key.pem`） | 项目配置（开发密钥一起分发） |
| `db/**/*.dbd` | 数据库 schema 定义 |
| `db/wincc_oa/` 全部 `.db`/`.key`（`VA_*` 除外） | 所有数据库文件，DataManager 启动时必须 OPEN |
| `panels/`、`scripts/` | UI 面板与 CONTROL 脚本 |
| `pictures/`、`images/` | 图片资源 |
| `data/Reporting/Templates/` | BIRT/SSRS 报表模板 |
| `data/xls_report/` | Excel 报表模板 |
| `data/iec104/PKI/certs/*.crt` | 公开证书（非私钥） |
| `data/opcua/client(PKI|server/PKI/CA/certs/*.der` | 公开证书（非私钥） |

> **关于 `.db`/`.key`**：所有运行时数据库文件全部跟踪（除 `VA_*`）。
> 报警归档（`al*`）和最后值缓存（`lastval/`）的启停变更通过 `git update-index --skip-worktree` 屏蔽，不会出现在 `git status` 中。
> 仅当 `.dbd` 变更需要同步更新 `.db` 时，才取消 skip-worktree 并重新提交对应 `.db` 文件。

## 分支策略建议

- `main` — 仅存放跨机器通用的项目文件
- 每台机器的首次启动变化（`.db` 初始化、`proj_path` 等）**不要合入 main**
- 可在本地分支（如 `PC_xxx`）上提交机器特定的 `proj_path` 修改，方便日后参考
- 验证分支测试完成后关闭即可，无需 PR 到 main

## 快照工具

| 文件 | 说明 |
|------|------|
| `oa_project_snapshot.ps1` | 生成项目目录树与文件清单 |
| `generate_zh_tree.ps1` | 生成中文注释版目录树 |

输出文件（`snapshot_*.txt`）为脚本生成物，已被 `.gitignore` 忽略。
