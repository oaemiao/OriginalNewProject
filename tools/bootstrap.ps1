param(
    [string]$WinCC_OAPath = "",
    [switch]$StartConsole
)

<#
.SYNOPSIS
    WinCC OA 项目跨机器初始化引导脚本

.DESCRIPTION
    在 git clone 后的新机器上运行此脚本，自动完成：
      1. 将 config/config 中的 proj_path 修正为当前目录
      2. 检测或填入 WinCC OA 安装路径 (pvss_path)
      3. 验证项目结构完整性
      4. 可选启动 WinCC OA Console

    执行后 config/config 会被修改（不要提交此改动到 shared 仓库）。

.PARAMETER WinCC_OAPath
    手动指定 WinCC OA 安装路径，例如 "C:/Siemens/Automation/WinCC_OA/3.19"
    不指定则脚本尝试从注册表或常见路径自动检测。

.PARAMETER StartConsole
    指定此参数则在配置完成后自动启动 WinCC OA Console。

.EXAMPLE
    # 纯修复路径
    .\tools\bootstrap.ps1

    # 指定安装路径并启动 Console
    .\tools\bootstrap.ps1 -WinCC_OAPath "C:/Siemens/Automation/WinCC_OA/3.19" -StartConsole
#>

$ErrorActionPreference = "Stop"
$PROJ_ROOT = Split-Path -Parent $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " WinCC OA Project Bootstrap" -ForegroundColor Cyan
Write-Host " Project : $PROJ_ROOT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Step 1: 修正 proj_path
# ------------------------------------------------------------
$configFile = Join-Path $PROJ_ROOT "config" "config"
if (-not (Test-Path $configFile)) {
    Write-Error "未找到 config/config，请确认当前是 WinCC OA 项目根目录"
    exit 1
}

$config = Get-Content $configFile -Raw
$projPathLine = 'proj_path = "' + $PROJ_ROOT.Replace('\', '/') + '"'

if ($config -match 'proj_path\s*=') {
    $config = $config -replace 'proj_path\s*=.*', $projPathLine
    Write-Host "[1/4] proj_path 已修正为: $($PROJ_ROOT.Replace('\', '/'))" -ForegroundColor Green
} else {
    Write-Warning "config/config 中未找到 proj_path，请手动检查文件格式"
}

# ------------------------------------------------------------
# Step 2: 检测或设置 pvss_path
# ------------------------------------------------------------
if ([string]::IsNullOrEmpty($WinCC_OAPath)) {
    # 尝试从注册表检测 WinCC OA 安装路径
    $regPaths = @(
        "HKLM:\SOFTWARE\WOW6432Node\ETM\WinCC_OA\*\Installation",
        "HKLM:\SOFTWARE\ETM\WinCC_OA\*\Installation"
    )
    $found = $false
    foreach ($regPath in $regPaths) {
        $items = Get-ItemProperty -Path $regPath -Name "path" -ErrorAction SilentlyContinue
        if ($items) {
            $WinCC_OAPath = $items.path
            $found = $true
            break
        }
    }
    if (-not $found) {
        # 常见安装路径兜底
        $commonPaths = @(
            "C:\Siemens\Automation\WinCC_OA\3.17",
            "C:\Siemens\Automation\WinCC_OA\3.18",
            "C:\Siemens\Automation\WinCC_OA\3.19",
            "C:\Siemens\Automation\WinCC_OA\3.20",
            "C:\Program Files (x86)\Siemens\WinCC_OA\3.17",
            "C:\Program Files (x86)\Siemens\WinCC_OA\3.18",
            "C:\Program Files (x86)\Siemens\WinCC_OA\3.19"
        )
        foreach ($p in $commonPaths) {
            if (Test-Path $p) {
                $WinCC_OAPath = $p
                $found = $true
                break
            }
        }
    }
    if (-not $found) {
        Write-Warning "未能自动检测 WinCC OA 安装路径，请手动指定："
        Write-Host "  .\tools\bootstrap.ps1 -WinCC_OAPath `"C:/Siemens/Automation/WinCC_OA/3.xx`"" -ForegroundColor Yellow
        $WinCC_OAPath = Read-Host "请输入 WinCC OA 安装路径（例如 C:/Siemens/Automation/WinCC_OA/3.19）"
    }
}

# 确保路径使用正斜杠
$WinCC_OAPath = $WinCC_OAPath.Replace('\', '/')
$pvssPathLine = 'pvss_path = "' + $WinCC_OAPath + '"'

if ($config -match 'pvss_path\s*=') {
    $config = $config -replace 'pvss_path\s*=.*', $pvssPathLine
    Write-Host "[2/4] pvss_path 已设为: $WinCC_OAPath" -ForegroundColor Green
} else {
    Write-Warning "config/config 中未找到 pvss_path，请手动检查"
}

# ------------------------------------------------------------
# Step 3: 标记运行时数据库文件为 skip-worktree（防止误提交启停变更）
# ------------------------------------------------------------
Write-Host "[3/4] 设置 skip-worktree（屏蔽运行时数据库启停噪声）..." -ForegroundColor Green
$skipWorktreeDirs = @(
    "db/wincc_oa/al0000000000",
    "db/wincc_oa/aloverflow",
    "db/wincc_oa/alliving",
    "db/wincc_oa/lastval"
)
$total = 0
foreach ($d in $skipWorktreeDirs) {
    $files = git -C $PROJ_ROOT ls-files "$d/*.db" "$d/*.key"
    if ($files) {
        $files | ForEach-Object { git -C $PROJ_ROOT update-index --skip-worktree $_ }
        $cnt = ($files | Measure-Object).Count
        $total += $cnt
        Write-Host "  $d : $cnt files" -ForegroundColor Gray
    }
}
Write-Host "  skip-worktree 已设置 $total 个文件" -ForegroundColor Green

# ------------------------------------------------------------
# Step 4: 验证项目结构
# ------------------------------------------------------------
Write-Host "[4/4] 验证项目结构..." -ForegroundColor Green

$requiredDirs = @("config", "db", "panels", "scripts", "data")
$missingDirs = @()
foreach ($dir in $requiredDirs) {
    $fullPath = Join-Path $PROJ_ROOT $dir
    if (-not (Test-Path $fullPath)) {
        $missingDirs += $dir
    }
}

if ($missingDirs.Count -gt 0) {
    Write-Warning "缺少标准目录: $($missingDirs -join ', ')"
} else {
    Write-Host "  标准目录完整: $($requiredDirs -join ', ')" -ForegroundColor Green
}

# 检查 .dbd 文件
$dbdCount = (Get-ChildItem (Join-Path $PROJ_ROOT "db") -Recurse -Filter "*.dbd" | Measure-Object).Count
if ($dbdCount -gt 0) {
    Write-Host "  数据库定义文件 (.dbd): $dbdCount 个" -ForegroundColor Green
} else {
    Write-Warning "未找到 .dbd 文件，项目可能无法正常启动"
}

# ------------------------------------------------------------
# 写入更新后的 config
# ------------------------------------------------------------
$config | Set-Content $configFile -Encoding Default
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 配置完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "注意事项:" -ForegroundColor Yellow
Write-Host "  1. config/config 已被修改为当前机器路径" -ForegroundColor Yellow
Write-Host "  2. 此修改是机器特定的，不要 git commit 此改动" -ForegroundColor Yellow
Write-Host "  3. skip-worktree 已设置，运行时 .db/.key 变更不会出现在 git status 中" -ForegroundColor Yellow
Write-Host "  4. 每次在新机器 clone 后都需要重新运行本脚本" -ForegroundColor Yellow
Write-Host ""

# ------------------------------------------------------------
# 可选启动 Console
# ------------------------------------------------------------
if ($StartConsole) {
    $consolePath = Join-Path $WinCC_OAPath "Console.exe"
    if (Test-Path $consolePath) {
        Write-Host "正在启动 WinCC OA Console..." -ForegroundColor Cyan
        Start-Process -FilePath $consolePath -ArgumentList "-proj `"$($PROJ_ROOT)`""
        Write-Host "  Console 已启动 (PID: $((Get-Process -Name Console -ErrorAction SilentlyContinue).Id))" -ForegroundColor Green
    } else {
        Write-Warning "未找到 Console.exe: $consolePath"
        Write-Host "请手动打开 WinCC OA Console，然后选择项目路径: $PROJ_ROOT" -ForegroundColor Yellow
    }
} else {
    Write-Host "启动 WinCC OA Console 的命令:" -ForegroundColor Cyan
    Write-Host "  .\tools\bootstrap.ps1 -StartConsole" -ForegroundColor White
    Write-Host "  或手动: 打开 Console -> 选择项目 -> $PROJ_ROOT" -ForegroundColor White
}
