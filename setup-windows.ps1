<#
Claude Code CLI + MCP 一鍵安裝（Windows）

用法（PowerShell，不是命令提示字元 cmd）：
  irm https://raw.githubusercontent.com/neuracreate/claude-code-starter/main/setup-windows.ps1 | iex

用 iex 直接執行、不落地存檔，才不會被 Windows 執行原則（ExecutionPolicy）
擋下沒簽章的 .ps1 檔案。真要存成檔案跑，記得先 Unblock-File。

帶金鑰跑（可省略，之後再補也行）：
  $env:FIRECRAWL_API_KEY="fc-xxxx"; $env:APIFY_TOKEN="xxxx"
  irm https://raw.githubusercontent.com/neuracreate/claude-code-starter/main/setup-windows.ps1 | iex

重跑安全：已經裝好的會跳過，不會重複註冊。
沒有 Node.js 會自動裝一份到 $env:LOCALAPPDATA\claude-code-starter\node（現查
nodejs.org 目前的 LTS 版本，不寫死版本號，不用系統管理員權限）。
#>

$ErrorActionPreference = 'Continue'

$RepoUrl = "https://github.com/neuracreate/claude-code-starter"
$StarterUrl = "https://raw.githubusercontent.com/neuracreate/claude-code-starter/main/starter/CLAUDE.md"
$SkippedNotes = New-Object System.Collections.Generic.List[string]

function Write-OkMsg($msg)    { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-WarnMsg($msg)  { Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Write-FailMsg($msg)  { Write-Host "  [X] $msg" -ForegroundColor Red }
function Write-TitleMsg($msg) { Write-Host "`n$msg" -ForegroundColor White }

# 幫一個資料夾補進 User 環境變數 PATH（不需要系統管理員權限），並讓目前這個
# session 立刻生效，同一輪後面呼叫 npx 的步驟才用得到，不用重開終端機。
function Add-UserPath($dir) {
  $current = [Environment]::GetEnvironmentVariable("Path", "User")
  $parts = @()
  if ($current) { $parts = $current -split ';' }
  if ($parts -notcontains $dir) {
    $new = if ($current) { "$current;$dir" } else { $dir }
    [Environment]::SetEnvironmentVariable("Path", $new, "User")
    $SkippedNotes.Add("PATH 剛加了 $dir，這個視窗還沒吃到，開一個新的 PowerShell 視窗才會生效。")
  }
  if (($env:Path -split ';') -notcontains $dir) {
    $env:Path = "$env:Path;$dir"
  }
}

# 裝 Node.js（不用系統管理員權限、不動系統原有的 node）。
# 不寫死版本號：從官方 https://nodejs.org/dist/index.json 現查目前的 LTS，
# 找第一筆 lts 不是 false 的就是現在的 LTS，往後 Node.js 出新版也不用回來改
# 這支腳本。查不到或下載/解壓縮失敗就放棄，讓使用者自己去 nodejs.org 裝，
# 不讓腳本整支中斷。
function Install-NodeJs {
  $arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64" -or $env:PROCESSOR_ARCHITEW6432 -eq "ARM64") { "arm64" } else { "x64" }

  Write-Host "  查目前 Node.js LTS 版本..."
  try {
    $releases = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json" -ErrorAction Stop
  } catch {
    Write-FailMsg "查不到 Node.js 版本清單（可能是網路問題），改自己去 https://nodejs.org 下載安裝。"
    return $false
  }
  $lts = $releases | Where-Object { $_.lts -ne $false } | Select-Object -First 1
  if (-not $lts) {
    Write-FailMsg "查不到目前的 Node.js LTS 版本，改自己去 https://nodejs.org 下載安裝。"
    return $false
  }
  $version = $lts.version
  Write-OkMsg "目前 LTS：$version"

  $installDir = "$env:LOCALAPPDATA\claude-code-starter\node"
  $tmpDir = Join-Path $env:TEMP "node-install-$([guid]::NewGuid().ToString('N').Substring(0,8))"
  $zipPath = Join-Path $tmpDir "node.zip"
  $url = "https://nodejs.org/dist/$version/node-$version-win-$arch.zip"

  New-Item -ItemType Directory -Force $tmpDir | Out-Null

  Write-Host "  下載 node-$version-win-$arch..."
  try {
    Invoke-WebRequest -Uri $url -OutFile $zipPath -ErrorAction Stop
  } catch {
    Write-FailMsg "下載失敗，改自己去 https://nodejs.org 下載安裝。"
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
    return $false
  }

  try {
    Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force -ErrorAction Stop
  } catch {
    Write-FailMsg "解壓縮失敗，改自己去 https://nodejs.org 下載安裝。"
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
    return $false
  }

  # zip 解出來是 node-vX.Y.Z-win-ARCH\ 這一層資料夾，node.exe/npm.cmd/npx.cmd
  # 都直接在裡面（不像 macOS tar 還有一層 bin\）。搬到固定路徑，這樣版本升級
  # PATH 也不用跟著改。
  $extracted = Get-ChildItem $tmpDir -Directory | Select-Object -First 1
  if (-not $extracted) {
    Write-FailMsg "解壓縮後找不到資料夾，改自己去 https://nodejs.org 下載安裝。"
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
    return $false
  }

  New-Item -ItemType Directory -Force (Split-Path $installDir -Parent) | Out-Null
  if (Test-Path $installDir) { Remove-Item -Recurse -Force $installDir }
  Move-Item -Path $extracted.FullName -Destination $installDir
  Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue

  Add-UserPath $installDir

  if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-OkMsg "Node.js 裝好了：$(node -v)"
    return $true
  }
  Write-FailMsg "裝完了但這個視窗還找不到 node，重開 PowerShell 再試一次。"
  return $false
}

# ---------------------------------------------------------------- 1. 前置檢查

Write-TitleMsg "[1/5] 檢查環境"

# Claude 用工具代跑指令時，背後接的不是真人在打字的那種主控台，stdin 會被
# 重導向。這種情況下問金鑰那段會自動跳過，先講清楚，別讓它默默降級。
$NonInteractive = [Console]::IsInputRedirected
if ($NonInteractive) {
  Write-WarnMsg "非互動模式（stdin 被重導向），問金鑰那段會自動跳過。"
  Write-Host "      如果是 Claude 代跑這支腳本：先問使用者有沒有 Firecrawl API key"
  Write-Host "      （https://firecrawl.dev）跟 Apify token（https://console.apify.com），"
  Write-Host "      拿到答案後用環境變數重跑一次（沒有的那把就不用設）："
  Write-Host '      $env:FIRECRAWL_API_KEY="xxx"; $env:APIFY_TOKEN="xxx"; .\setup-windows.ps1'
  Write-Host "      使用者說先跳過也沒關係，其他 MCP 一樣裝得起來。"
}

# 只有 playwright、firecrawl、apify 這三個 MCP 靠 npx 啟動，才需要 Node。
$HasNode = $false
if (Get-Command node -ErrorAction SilentlyContinue) {
  $HasNode = $true
  Write-OkMsg "Node $(node -v)"
} else {
  Write-Host "  沒有 Node.js，playwright/firecrawl/apify 這三個 MCP 需要它，現在幫你裝一份"
  Write-Host "  （裝在 `$env:LOCALAPPDATA\claude-code-starter\node，不用系統管理員權限）..."
  if (Install-NodeJs) {
    $HasNode = $true
  } else {
    Write-WarnMsg "Node.js 自動安裝沒成功，playwright/firecrawl/apify 這三個 MCP 這輪會跳過。"
    $SkippedNotes.Add("Node.js 沒裝成功。到 https://nodejs.org 手動下載 LTS 版裝好，再跑一次這支腳本就會補上 playwright/firecrawl/apify。")
  }
}

# ---------------------------------------------------------------- 2. Claude Code

Write-TitleMsg "[2/5] 安裝 Claude Code CLI"

if (Get-Command claude -ErrorAction SilentlyContinue) {
  Write-OkMsg "已安裝：$(claude --version 2>$null)"
} else {
  Write-Host "  用官方安裝程式裝，這步會跑一兩分鐘..."
  try {
    Invoke-Expression (Invoke-RestMethod -Uri "https://claude.ai/install.ps1")
  } catch {
    Write-FailMsg "安裝失敗：$_"
    exit 1
  }
  # 官方安裝程式自己會把 PATH 寫進 User 環境變數，這裡只重新整理目前這個
  # session 的 PATH，讓後面步驟馬上叫得到 claude。
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-OkMsg "安裝完成：$(claude --version 2>$null)"
  } else {
    Write-FailMsg "安裝程式跑完，但這個視窗還找不到 claude。重開 PowerShell 再跑一次這支腳本就會好。"
    exit 1
  }
}

# ---------------------------------------------------------------- 3. 協作規則

Write-TitleMsg "[3/5] 協作規則 CLAUDE.md"

$TargetMd = "$env:USERPROFILE\.claude\CLAUDE.md"
$TmpMd = Join-Path $env:TEMP "claude-starter-$([guid]::NewGuid().ToString('N').Substring(0,8)).md"

$gotStarterMd = $true
try {
  Invoke-WebRequest -Uri $StarterUrl -OutFile $TmpMd -ErrorAction Stop
} catch {
  $gotStarterMd = $false
}

if (-not $gotStarterMd) {
  Write-WarnMsg "拿不到協作規則檔，跳過這步。"
  $SkippedNotes.Add("協作規則沒裝。到 $RepoUrl 下載 starter/CLAUDE.md，自己放到 $TargetMd。")
} elseif (Test-Path $TargetMd) {
  # 已經有一份就不覆蓋，另存讓他自己比對
  Copy-Item $TmpMd "$env:USERPROFILE\.claude\CLAUDE.starter.md" -Force
  Write-WarnMsg "你已經有 $TargetMd，沒有覆蓋它。"
  Write-Host "      起手版另存成 CLAUDE.starter.md，要用的話自己挑想要的段落搬過去。"
  Remove-Item $TmpMd -ErrorAction SilentlyContinue
} else {
  New-Item -ItemType Directory -Force (Split-Path $TargetMd -Parent) | Out-Null
  Copy-Item $TmpMd $TargetMd -Force
  Write-OkMsg "已安裝 $TargetMd"
  $SkippedNotes.Add("$TargetMd 的第 3 節「關於我」是空的，開工前花兩分鐘填一下。那節決定 Claude 用什麼深度跟你講話，不填它會一直猜。")
  Remove-Item $TmpMd -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------- 4. 註冊 MCP

Write-TitleMsg "[4/5] 註冊 MCP server"

# 先抓一次現有清單來判斷「裝過沒」，不用 claude mcp get：它會順便對 server
# 做連線健康檢查，還沒授權的雲端 server 會回失敗，會被誤判成「沒裝」。
$ExistingMcp = (claude mcp list 2>$null) -join "`n"
function Test-McpExists($name) { $ExistingMcp -match "(?m)^$([regex]::Escape($name)):" }

function Add-StdioMcp($name, $cmdArgs) {
  if (Test-McpExists $name) { Write-OkMsg "$name（已存在，跳過）"; return }
  & claude mcp add $name -s user -- @cmdArgs *> $null
  if ($LASTEXITCODE -eq 0) { Write-OkMsg $name } else { Write-FailMsg "$name 註冊失敗" }
}

function Add-StdioMcpWithEnv($name, $kv, $cmdArgs) {
  if (Test-McpExists $name) { Write-OkMsg "$name（已存在，跳過）"; return }
  & claude mcp add $name -s user -e $kv -- @cmdArgs *> $null
  if ($LASTEXITCODE -eq 0) { Write-OkMsg $name } else { Write-FailMsg "$name 註冊失敗" }
}

function Add-HttpMcp($name, $url) {
  if (Test-McpExists $name) { Write-OkMsg "$name（已存在，跳過）"; return }
  & claude mcp add --transport http $name $url -s user *> $null
  if ($LASTEXITCODE -eq 0) { Write-OkMsg $name } else { Write-FailMsg "$name 註冊失敗" }
}

# 這三個靠 npx 啟動，沒有 Node 就裝不了
if ($HasNode) {
  Add-StdioMcp "playwright" @("npx", "-y", "@playwright/mcp@latest")

  # 金鑰來源優先序：環境變數（已經有就不會問）→ 當場問。
  if (-not $env:FIRECRAWL_API_KEY -and -not $NonInteractive) {
    $env:FIRECRAWL_API_KEY = Read-Host "  Firecrawl API key（沒有就直接按 Enter 跳過）"
  }
  if ($env:FIRECRAWL_API_KEY) {
    Add-StdioMcpWithEnv "firecrawl" "FIRECRAWL_API_KEY=$env:FIRECRAWL_API_KEY" @("npx", "-y", "firecrawl-mcp")
  } else {
    Write-WarnMsg "firecrawl（沒有金鑰，跳過）"
    $SkippedNotes.Add("firecrawl 沒裝。到 https://firecrawl.dev 拿金鑰後補這行：`n     claude mcp add firecrawl -s user -e FIRECRAWL_API_KEY=你的金鑰 -- npx -y firecrawl-mcp")
  }

  if (-not $env:APIFY_TOKEN -and -not $NonInteractive) {
    $env:APIFY_TOKEN = Read-Host "  Apify API token（沒有就直接按 Enter 跳過）"
  }
  if ($env:APIFY_TOKEN) {
    Add-StdioMcpWithEnv "apify" "APIFY_TOKEN=$env:APIFY_TOKEN" @("npx", "-y", "@apify/actors-mcp-server")
  } else {
    Write-WarnMsg "apify（沒有金鑰，跳過）"
    $SkippedNotes.Add("apify 沒裝。到 https://console.apify.com 拿 token 後補這行：`n     claude mcp add apify -s user -e APIFY_TOKEN=你的token -- npx -y @apify/actors-mcp-server")
  }
} else {
  Write-WarnMsg "playwright、firecrawl、apify（沒有 Node.js，跳過）"
}

Add-HttpMcp "context7" "https://mcp.context7.com/mcp"

# ---------------------------------------------------------------- 收尾

Write-TitleMsg "裝好了"

Write-Host ""
claude mcp list 2>$null

Write-Host ""
Write-Host "接下來："
Write-Host "  1. 隨便進一個資料夾，輸入 claude"
Write-Host "  2. 第一次會跳出瀏覽器要你登入 Claude 帳號"
Write-Host "  3. 登入後在對話裡輸入 /mcp，看到上面那幾個是綠的就成了"
Write-Host ""
Write-Host "Notion、Gmail、Google Drive、Canva、Supabase 那些連接器綁的是帳號不是這台電腦，"
Write-Host "登入後在 /mcp 裡自己開就有，不用另外安裝。"
Write-Host ""
Write-Host "上面清單裡哪個沒連上，就對它跑一次：claude mcp login 名稱"

if ($SkippedNotes.Count -gt 0) {
  Write-Host "`n還有沒做完的：" -ForegroundColor Yellow
  foreach ($n in $SkippedNotes) { Write-Host "   - $n" }
}
Write-Host ""
