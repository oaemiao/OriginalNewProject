# WinCC OA 项目 Git 协作指南

## 首次克隆与启动（3 步）

### Step 1: Clone

```bash
git clone https://github.com/oaemiao/OriginalNewProject
cd OriginalNewProject
```

### Step 2: 运行 bootstrap 脚本

自动修正 `config/config` 中的 `proj_path` 和 `pvss_path` 为当前机器的路径：

```powershell
.\tools\bootstrap.ps1
```

脚本会自动检测 WinCC OA 安装路径（注册表/常见路径），如果检测失败会提示手动输入。

完成后即可用 **WinCC OA Console** 打开该项目。

### Step 3: 首次启动

Console 打开项目并启动时，WinCC OA 会自动：
- 创建 `db/wincc_oa/VA_*/` 归档运行时目录
- 生成 `dbase.status`、`event.status` 等运行时标记文件

> 系统核心 `.db`/`.key` 文件（`db/wincc_oa/*.db`、`db/wincc_oa/*.key`）已随 Git 跟踪，
> 无需在启动时重新创建。

> ⚠️ `config/config` 被 bootstrap 脚本修改后属于**本地专属改动**，不要 `git commit` 此文件。

---

## bootstrap 脚本详细用法

```powershell
# 纯修复路径（推荐首次使用）
.\tools\bootstrap.ps1

# 指定 WinCC OA 安装路径
.\tools\bootstrap.ps1 -WinCC_OAPath "C:/Siemens/Automation/WinCC_OA/3.19"

# 修复路径后自动启动 Console
.\tools\bootstrap.ps1 -WinCC_OAPath "C:/Siemens/Automation/WinCC_OA/3.19" -StartConsole
```

如果 `WinCC OA` 安装路径检测失败，脚本会进入交互模式等待输入。

---

## .gitignore 要点

| 规则 | 说明 |
|------|------|
| `bin/`, `log/`, `cache/`, `tmp/`, `pmon/` | 运行时自动创建，无保留价值 |
| `db/**/*.db`, `db/**/*.key` | 归档子目录运行时数据；`db/wincc_oa/` 根层系统文件例外（! 排除规则） |
| `db/wincc_oa/vista.log`, `*.taf`, `dbase.*`, `event.status` | 运行时日志与状态标记 |
| `**/private/`, `*.key`, `config/host-key.pem` | 私钥与敏感文件，禁止入库 |
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
| `config/` (不含 `host-key.pem`) | 项目配置，分发必须 |
| `db/**/*.dbd` | 数据库 schema 定义 |
| `db/wincc_oa/*.db` 和 `*.key` | 系统核心数据库文件，WCCILdata 启动时必须 OPEN |
| `panels/`、`scripts/` | UI 面板与 CONTROL 脚本 |
| `pictures/`、`images/` | 图片资源 |
| `data/Reporting/Templates/` | BIRT/SSRS 报表模板 |
| `data/xls_report/` | Excel 报表模板 |
| `data/iec104/PKI/certs/*.crt` | 公开证书（非私钥） |
| `data/opcua/client(PKI|server/PKI/CA/certs/*.der` | 公开证书（非私钥） |

> **关于 `db/` 中的 `.db`/`.key` 文件**：`db/wincc_oa/` 根层级的系统数据库文件（约 1.4 MB）**必须跟踪**，否则 DataManager 在另一台机器上会报 "TypeAndIdDb, open: No such file or directory" 错误。归档子目录（`0000000000/`, `al*`, `VA_*` 等）内的运行时 `.db`/`.key` 继续忽略。

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
