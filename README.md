# Mac 上裝 Claude Code

三步驟裝好 Claude Code CLI 跟四個常用的 MCP，裝完 Claude 就會有開瀏覽器操作（playwright）、抓網頁（firecrawl）、爬 IG／FB（apify）的能力。

> **這支 `setup-mac.sh` 只支援 macOS。** Windows 用戶請改用 `setup-windows.ps1`，做法一樣、指令不同，看 [INSTALL-windows.md](INSTALL-windows.md)。

MCP 是給 Claude 外掛能力的東西。

**完全不寫程式、直接把整個安裝過程交給 Claude 做的話，看 [INSTALL.md](INSTALL.md)（Mac）或 [INSTALL-windows.md](INSTALL-windows.md)（Windows）。** 下面這份是自己在終端機貼指令跑的 Mac 版本。

## 開始前要有

一台 macOS 13 以上的 Mac，還有**付費的 Claude 帳號**。Pro、Max、Team、Enterprise 都可以，免費方案不能用 Claude Code。這點先確認，不然裝完會卡在登入那步。

Claude Code 本身裝的是原生執行檔，不需要 Node.js；`playwright`、`firecrawl`、`apify` 這三個 MCP 才需要它，但這步不用你自己動手——沒有 Node 的話下面的腳本會自動幫你裝一份（裝在 `~/.local/node`，不用 sudo、不動系統本來有的東西），不用你先去 nodejs.org 下載。

## 第一步：裝 VS Code

到 <https://code.visualstudio.com> 下載安裝。Claude Code 不一定要在 VS Code 裡開，但終端機跟編輯器擺同一個視窗比較好操作。

## 第二步：裝 Claude Code CLI

按 `Command + 空白鍵`，打「終端機」，按 Enter 開啟。貼上這一行：

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

裝完打 `claude --version`，看到版本號就對了。

## 第三步：跑安裝腳本

同一個終端機貼上這一行，按 Enter：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/neuracreate/claude-code-starter/main/setup-mac.sh)"
```

它會發現 Claude Code 裝過了，跳過那步；沒有 Node.js 的話會自動查目前最新的 LTS 版本並裝好（不寫死版本號，之後 Node.js 出新版也不用回來改這支腳本），接著裝四個 MCP、放一份協作規則。跑到一半會問金鑰，**Firecrawl 跟 Apify 這兩把不要跳過**——要抓網頁、爬 IG／FB 就是靠它們，跳過的話那兩個 MCP 裝是裝了，但沒有金鑰用不了。

重跑不會壞。已經裝好的它會跳過。

**想先看過腳本再跑**（拿到來路不明的安裝指令時，這是該有的習慣）：

```bash
git clone https://github.com/neuracreate/claude-code-starter.git
cd claude-code-starter
less setup-mac.sh
bash setup-mac.sh
```

## 會放一份協作規則

腳本會把 `starter/CLAUDE.md` 複製到 `~/.claude/CLAUDE.md`。那是 Claude 每次開工前都會讀的規則檔，決定它怎麼跟你講話、什麼時候該停下來問你、檔案該放哪。

**裝完先去填第 3 節「關於我」。** 那節是空的，要寫你自己的背景——你是工程師還是不碰程式、負責哪一塊。不填的話 Claude 只能猜你懂多少，解釋的深度會抓不準。

原本就有 `~/.claude/CLAUDE.md` 的話腳本不會覆蓋，會另存成 `CLAUDE.starter.md` 讓你自己比對。

那份規則是起手版，改它就對了。用一陣子你會發現有些習慣沒寫進去，補上；有些規則你根本不在意，刪掉。它越貼近你真實的工作方式，Claude 越好用。

## 會裝哪四個

| 名稱 | 做什麼 | 用之前要 |
|---|---|---|
| `playwright` | 開瀏覽器點頁面、填表單、截圖、讀 console log | 不用設定 |
| `context7` | 查套件與框架的最新官方文件，擋掉過時的寫法 | 不用設定（實測不登入也能連） |
| `firecrawl` | 把網頁抓成乾淨的文字，也能整站爬 | 要金鑰 |
| `apify` | 爬社群平台、搜尋結果這類現成資料 | 要金鑰 |

`context7` 是雲端服務，安裝時只是登記位址，實測不用登入就能連。如果之後 `/mcp` 顯示紅燈，自己跑一次：

```bash
claude mcp login context7
```

想加其他 MCP，裝完自己跑 `claude mcp add` 就行，指令格式看 [MCP 官方文件](https://docs.claude.com/en/docs/claude-code/mcp)。

## 金鑰去哪拿

兩個都是免費就能開始用，額度用完才要付錢。

**Firecrawl** 到 <https://firecrawl.dev> 註冊，在 dashboard 拿一串 `fc-` 開頭的字。

**Apify** 到 <https://console.apify.com> 註冊，在 Settings 的 API & Integrations 那頁拿 token。

腳本按這個順序找金鑰：先看環境變數，再看這個資料夾裡有沒有 `secrets.env`，都沒有就當場問你。

環境變數的給法：

```bash
FIRECRAWL_API_KEY=fc-xxxx APIFY_TOKEN=你的token ./setup-mac.sh
```

`secrets.env` 的格式，一行一個：

```
FIRECRAWL_API_KEY=fc-xxxx
APIFY_TOKEN=你的token
```

兩個都跳過的話其他四個照裝、Claude Code 一樣能用，但抓網頁跟爬 IG／FB 這兩個能力就是空的。想之後再補：

```bash
claude mcp add firecrawl -s user -e FIRECRAWL_API_KEY=你的金鑰 -- npx -y firecrawl-mcp
claude mcp add apify -s user -e APIFY_TOKEN=你的token -- npx -y @apify/actors-mcp-server
```

> 別把金鑰貼進 `setup-mac.sh` 裡面。那支腳本會被複製給下一個人，貼進去等於把金鑰一起送出去。

## 裝完之後

隨便進一個資料夾，輸入 `claude`。第一次會跳瀏覽器要你登入 Claude 帳號。

登入完在對話裡輸入 `/mcp`，看到那幾個是綠色的就成了。

Notion、Gmail、Google Drive、Canva、Supabase 這些不用裝。它們綁的是你的 Claude 帳號，在 `/mcp` 裡自己開就有。

## 卡住的話

**Claude Code 裝不起來。** 有 Homebrew 的話換一種裝法：`brew install --cask claude-code`。

**打 `claude` 說 command not found。** 安裝程式只把執行檔放進 `~/.local/bin`，它不會去改你的 shell 設定，而 macOS 原廠的 PATH 沒有這個目錄。腳本已經幫你把這行寫進 `~/.zshrc` 了，但**要開一個新的終端機視窗才會生效**（或在現在這個視窗跑 `source ~/.zshrc`）。

新視窗還是找不到的話，自己補跑一次：

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

**腳本幫我裝了 Node.js，但打 `node -v` 說 command not found。** 同樣是 PATH 要重開終端機才會生效，關掉重開一個再試。

**想確認到底裝對了沒。** 跑 `claude doctor`，它會印出安裝狀態跟設定檔的問題，不會開啟對話。

**`/mcp` 裡某個是紅的。** 先跑 `claude mcp get 名稱` 看錯誤訊息。如果是 `context7` 這種雲端服務，重跑一次 `claude mcp login 名稱`。

**想移掉某一個。** `claude mcp remove 名稱 -s user`。
