#!/usr/bin/env bash
#
# Claude Code CLI + MCP 一鍵安裝（macOS）
#
# 用法：
#   chmod +x setup-mac.sh
#   ./setup-mac.sh
#
# 帶金鑰跑（可省略，之後再補也行）：
#   FIRECRAWL_API_KEY=fc-xxxx APIFY_TOKEN=xxxx ./setup-mac.sh
#
# 重跑安全：已經裝好的會跳過，不會重複註冊。

# 不用 set -u：macOS 內建的 bash 是 3.2，展開空陣列會被它當成未定義變數直接中止。
set -o pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd)"

REPO_URL="https://github.com/neuracreate/claude-code-starter"
STARTER_URL="https://raw.githubusercontent.com/neuracreate/claude-code-starter/main/starter/CLAUDE.md"

ok()    { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn()  { printf "  \033[33m!\033[0m %s\n" "$1"; }
fail()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }
title() { printf "\n\033[1m%s\033[0m\n" "$1"; }

SKIPPED_NOTES=()

# ---------------------------------------------------------------- 1. 前置檢查

title "[1/5] 檢查環境"

if [ "$(uname)" != "Darwin" ]; then
  warn "這支腳本是寫給 macOS 的，你現在的系統是 $(uname)。可以繼續，但沒測過。"
fi

command -v curl >/dev/null 2>&1 || { fail "找不到 curl，沒辦法下載安裝程式。"; exit 1; }
ok "curl"

# 用 `curl ... | bash` 跑的話，腳本自己會佔住 stdin，問金鑰跟授權那兩段會靜默跳過，
# 使用者卻以為裝完整了。先講清楚，別讓它默默降級。
if [ ! -t 0 ]; then
  warn "非互動模式（stdin 不是終端機），問金鑰與瀏覽器授權都會自動跳過。"
  echo "      要完整流程請改用這個寫法（注意是 bash -c，不是 | bash）："
  echo '      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/neuracreate/claude-code-starter/main/setup-mac.sh)"'
fi

# Node.js 不是 Claude Code 的必要條件，官方安裝程式裝的是原生執行檔。
# 只有 playwright、firecrawl、apify 這三個 MCP 靠 npx 啟動，才需要 Node。
HAS_NODE=0
if command -v node >/dev/null 2>&1; then
  HAS_NODE=1
  ok "Node $(node -v)"
else
  warn "沒有 Node.js。Claude Code 本身不用它，可以繼續裝。"
  echo "      但 playwright、firecrawl、apify 這三個 MCP 需要 Node，這輪會跳過。"
  echo "      之後想補：到 https://nodejs.org 裝 LTS 版，再跑一次這支腳本。"
fi

# ---------------------------------------------------------------- 2. Claude Code

title "[2/5] 安裝 Claude Code CLI"

# 安裝程式會把 claude 放進 ~/.local/bin，那個路徑預設不在新 Mac 的 PATH 裡。
# 先補進來，這樣同一輪的後續步驟才叫得到它。
export PATH="$HOME/.local/bin:$PATH"

# 官方安裝程式只放執行檔，它不會去動你的 shell 設定檔，而 macOS 原廠 PATH
# （/etc/paths）沒有 ~/.local/bin。少了這步，腳本跑完一切正常，但使用者關掉
# 終端機再打 claude 就是 command not found — 對新手最傷的一個坑。
persist_path() {
  [ -x "$HOME/.local/bin/claude" ] || return 0

  local rc
  case "${SHELL##*/}" in
    bash) rc="$HOME/.bash_profile" ;;
    *)    rc="$HOME/.zshrc" ;;   # macOS 從 Catalina 起預設就是 zsh
  esac

  if [ -f "$rc" ] && grep -q '\.local/bin' "$rc" 2>/dev/null; then
    ok "PATH 已經設好了（${rc##*/}）"
    return 0
  fi

  if printf '\n# Claude Code\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc" 2>/dev/null; then
    ok "已把 ~/.local/bin 寫進 ${rc##*/}"
    SKIPPED_NOTES+=("PATH 是剛剛才寫進 ${rc##*/} 的，這個終端機視窗還沒吃到。
     開一個新視窗，或先跑：source $rc")
  else
    fail "寫不進 ${rc}，claude 之後可能叫不到。"
    echo "      請自己補跑這一行："
    echo "      echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> $rc"
  fi
}

if command -v claude >/dev/null 2>&1; then
  ok "已安裝：$(claude --version 2>/dev/null || echo '版本讀取失敗')"
  persist_path
else
  echo "  用官方安裝程式裝，不需要 Node.js。這步會跑一兩分鐘…"
  echo ""
  if curl -fsSL https://claude.ai/install.sh | bash; then
    echo ""
    if command -v claude >/dev/null 2>&1; then
      ok "安裝完成：$(claude --version 2>/dev/null)"
      persist_path
    else
      fail "安裝程式回報成功，但 ~/.local/bin/claude 不在那裡。"
      echo "      跑 claude doctor 看狀態，或改用 Homebrew：brew install --cask claude-code"
      exit 1
    fi
  else
    fail "安裝失敗。"
    echo "      有 Homebrew 的話改用它試試：brew install --cask claude-code"
    exit 1
  fi
fi

# ---------------------------------------------------------------- 3. 協作規則

title "[3/5] 協作規則 CLAUDE.md"

STARTER_MD="$HERE/starter/CLAUDE.md"
TARGET_MD="$HOME/.claude/CLAUDE.md"

# 用 curl 一行安裝時，本機沒有 starter/ 資料夾，改從 GitHub 抓
if [ ! -f "$STARTER_MD" ]; then
  TMP_MD="$(mktemp)"
  if curl -fsSL "$STARTER_URL" -o "$TMP_MD" 2>/dev/null && [ -s "$TMP_MD" ]; then
    STARTER_MD="$TMP_MD"
  fi
fi

if [ ! -f "$STARTER_MD" ]; then
  warn "拿不到協作規則檔，跳過這步。"
  SKIPPED_NOTES+=("協作規則沒裝。到 $REPO_URL 下載 starter/CLAUDE.md，
     自己放到 ~/.claude/CLAUDE.md。")
elif [ -f "$TARGET_MD" ]; then
  # 已經有一份就不覆蓋，另存讓他自己比對
  cp "$STARTER_MD" "$HOME/.claude/CLAUDE.starter.md"
  warn "你已經有 ~/.claude/CLAUDE.md，沒有覆蓋它。"
  echo "      起手版另存成 ~/.claude/CLAUDE.starter.md，要用的話自己挑想要的段落搬過去。"
else
  mkdir -p "$HOME/.claude"
  if cp "$STARTER_MD" "$TARGET_MD"; then
    ok "已安裝 ~/.claude/CLAUDE.md"
    SKIPPED_NOTES+=("~/.claude/CLAUDE.md 的第 3 節「關於我」是空的，開工前花兩分鐘填一下。
     那節決定 Claude 用什麼深度跟你講話，不填它會一直猜。")
  else
    fail "設定檔複製失敗。"
  fi
fi

# ---------------------------------------------------------------- 4. 註冊 MCP

title "[4/5] 註冊 MCP server"

# 先抓一次現有清單來判斷「裝過沒」。
# 不用 claude mcp get：它會順便對 server 做連線健康檢查，還沒授權的雲端 server 會回失敗，
# 會被誤判成「沒裝」。mcp list 的輸出是「名稱: 指令 - 狀態」，比對行首就夠。
EXISTING_MCP="$(claude mcp list 2>/dev/null)"
has_mcp() { printf '%s\n' "$EXISTING_MCP" | grep -q "^$1:"; }

NEED_LOGIN=()

# 底下的訊息一律寫成 ${name} 而不是 $name：macOS 內建的 bash 3.2 在 UTF-8 環境下，
# 遇到 "$name（" 會把全形括號的第一個位元組吃進變數名，結果名字整個消失、只吐亂碼。
# 加大括號把邊界標清楚就沒事。

# add_stdio <名稱> -- <指令> [參數...]
add_stdio() {
  local name="$1"; shift
  if has_mcp "$name"; then ok "${name}（已存在，跳過）"; return; fi
  if claude mcp add "$name" -s user "$@" >/dev/null 2>&1; then
    ok "$name"
  else
    fail "$name 註冊失敗"
  fi
}

# add_stdio_env <名稱> <KEY=值> -- <指令> [參數...]
add_stdio_env() {
  local name="$1" kv="$2"; shift 2
  if has_mcp "$name"; then ok "${name}（已存在，跳過）"; return; fi
  if claude mcp add "$name" -s user -e "$kv" "$@" >/dev/null 2>&1; then
    ok "$name"
  else
    fail "$name 註冊失敗"
  fi
}

# add_http <名稱> <網址>
add_http() {
  local name="$1" url="$2"
  if has_mcp "$name"; then ok "${name}（已存在，跳過）"; return; fi
  if claude mcp add --transport http "$name" "$url" -s user >/dev/null 2>&1; then
    ok "${name}（稍後要授權）"
    NEED_LOGIN+=("$name")
  else
    fail "$name 註冊失敗"
  fi
}

# --- 這三個靠 npx 啟動，沒有 Node 就裝不了 ---
if [ "$HAS_NODE" = "1" ]; then

  # 金鑰來源優先序：環境變數 → 同資料夾的 secrets.env → 當場問。
  # 先把環境變數存起來，讀完檔再蓋回去，免得檔案裡的舊值蓋掉命令列給的。
  if [ -f "$HERE/secrets.env" ]; then
    _fc="${FIRECRAWL_API_KEY:-}"; _ap="${APIFY_TOKEN:-}"
    set -a; . "$HERE/secrets.env"; set +a
    [ -n "$_fc" ] && FIRECRAWL_API_KEY="$_fc"
    [ -n "$_ap" ] && APIFY_TOKEN="$_ap"
  fi

  # 免金鑰
  add_stdio playwright -- npx -y @playwright/mcp@latest

  # Firecrawl
  if [ -z "${FIRECRAWL_API_KEY:-}" ] && [ -t 0 ]; then
    printf "  Firecrawl API key（沒有就直接按 Enter 跳過）: "
    read -r FIRECRAWL_API_KEY
  fi
  if [ -n "${FIRECRAWL_API_KEY:-}" ]; then
    add_stdio_env firecrawl "FIRECRAWL_API_KEY=$FIRECRAWL_API_KEY" -- npx -y firecrawl-mcp
  else
    warn "firecrawl（沒有金鑰，跳過）"
    SKIPPED_NOTES+=("firecrawl 沒裝。到 https://firecrawl.dev 拿金鑰後補這行：
     claude mcp add firecrawl -s user -e FIRECRAWL_API_KEY=你的金鑰 -- npx -y firecrawl-mcp")
  fi

  # Apify
  if [ -z "${APIFY_TOKEN:-}" ] && [ -t 0 ]; then
    printf "  Apify API token（沒有就直接按 Enter 跳過）: "
    read -r APIFY_TOKEN
  fi
  if [ -n "${APIFY_TOKEN:-}" ]; then
    add_stdio_env apify "APIFY_TOKEN=$APIFY_TOKEN" -- npx -y @apify/actors-mcp-server
  else
    warn "apify（沒有金鑰，跳過）"
    SKIPPED_NOTES+=("apify 沒裝。到 https://console.apify.com 拿 token 後補這行：
     claude mcp add apify -s user -e APIFY_TOKEN=你的token -- npx -y @apify/actors-mcp-server")
  fi

else
  warn "playwright、firecrawl、apify（這台沒有 Node.js，跳過）"
  SKIPPED_NOTES+=("playwright、firecrawl、apify 三個沒裝，因為這台沒有 Node.js。
     到 https://nodejs.org 裝 LTS 版，然後重跑這支腳本就會補上。")
fi

# --- hosted ---
add_http context7 https://mcp.context7.com/mcp

# ---------------------------------------------------------------- 5. 授權

title "[5/5] 授權 hosted server"

if [ ${#NEED_LOGIN[@]} -eq 0 ]; then
  ok "這次沒有新裝的雲端 server，不用授權。"
elif [ ! -t 0 ]; then
  warn "非互動模式，跳過授權。之後自己跑這幾行："
  for s in "${NEED_LOGIN[@]}"; do echo "      claude mcp login $s"; done
else
  echo "  這幾個要各開一次瀏覽器登入才會通：${NEED_LOGIN[*]}"
  echo "  一個一個來，每個都會等你在瀏覽器按完才繼續。"
  echo "  中途想跳過某一個就按 Control + C，不會影響已經裝好的東西。"
  printf "  現在就做嗎？(Y/n) "

  # read 讀到 EOF 會回非 0（stdin 被關掉、或被別的東西吃掉）。
  # 這種情況下不能落到「預設 yes」去連開三個瀏覽器，寧可跳過讓使用者之後自己跑。
  DO_LOGIN=""
  if read -r DO_LOGIN; then :; else DO_LOGIN="n"; echo ""; fi

  case "$DO_LOGIN" in
    [Nn]*)
      SKIPPED_NOTES+=("hosted server 還沒授權。之後一個一個跑：$(printf ' claude mcp login %s;' "${NEED_LOGIN[@]}")")
      ;;
    *)
      for s in "${NEED_LOGIN[@]}"; do
        echo ""
        echo "  → $s"
        claude mcp login "$s" || warn "$s 授權沒完成，之後可以再跑：claude mcp login $s"
      done
      ;;
  esac
fi

# ---------------------------------------------------------------- 收尾

title "裝好了"

echo ""
claude mcp list 2>/dev/null || warn "claude mcp list 讀不到，開一次 claude 之後再試。"

echo ""
echo "接下來："
echo "  1. 隨便進一個資料夾，輸入 claude"
echo "  2. 第一次會跳出瀏覽器要你登入 Claude 帳號"
echo "  3. 登入後在對話裡輸入 /mcp，看到上面那幾個是綠的就成了"
echo ""
echo "Notion、Gmail、Google Drive、Canva、Supabase 那些連接器綁的是帳號不是這台電腦，"
echo "登入後在 /mcp 裡自己開就有，不用另外安裝。"
echo ""
echo "上面清單裡哪個沒連上，就對它跑一次：claude mcp login 名稱"

if [ ${#SKIPPED_NOTES[@]} -gt 0 ]; then
  printf "\n\033[33m還有沒做完的：\033[0m\n"
  for n in "${SKIPPED_NOTES[@]}"; do
    echo "   • $n"
  done
fi
echo ""
