<#
.SYNOPSIS
  生成 WinCC OA 项目的目录树快照和文件清单快照。

.DESCRIPTION
  1. 执行 tree /F /A 将项目完整目录树导出到 snapshot_tree.txt
  2. 递归列出所有文件的完整路径，导出到 snapshot_files.txt

.NOTES
  执行顺序：此脚本应先于 generate_zh_tree.ps1 执行。
  注意事项：
  - 输出文件会被 git 跟踪（已入库），每次运行后请确认变更再提交
  - 脚本不会过滤 .gitignore 规则，会列出磁盘上所有文件
    （包括 git 忽略的运行时文件如 VA_*/、vista.log 等）
  - 请在项目根目录下运行
#>

tree /F /A > snapshot_tree.txt
Get-ChildItem -Recurse -File | ForEach-Object { $_.FullName } > snapshot_files.txt