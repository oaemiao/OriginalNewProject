tree /F /A > snapshot_tree.txt
Get-ChildItem -Recurse -File | ForEach-Object { $_.FullName } > snapshot_files.txt