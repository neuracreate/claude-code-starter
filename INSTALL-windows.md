# 把 Claude Code 裝到好（Windows 新手版）

給完全不寫程式的人。全程複製貼上，四步驟做完。

Mac 版走的是一支自動化腳本；Windows 沒有對應腳本，改成讓 Claude 直接下指令，一樣不用你自己打任何 MCP 指令。

## 1. 裝 VS Code

到 <https://code.visualstudio.com> 下載安裝。

## 2. 裝 Claude Code

按開始鍵，打「PowerShell」，Enter 打開（**要用 PowerShell，不是命令提示字元 cmd**）。貼上這一行，按 Enter：

```powershell
irm https://claude.ai/install.ps1 | iex
```

裝完打 `claude --version`，看到版本號就對了。

## 3. 打開 Claude Code

同一個視窗打：

```powershell
claude
```

第一次會跳出瀏覽器要你登入 Claude 帳號（要付費方案，Pro / Max / Team / Enterprise 都可以）。

## 4. 貼上這一整段話，按 Enter

登入完，把下面這一整段複製貼進對話框：

```
我要幫這台 Windows 電腦補齊 Claude Code 的擴充能力，照下面順序做，每步做完跟我講結果：

1. 跑 node -v 確認 Node.js 有沒有裝好。沒有的話停下來告訴我，我會先去 https://nodejs.org 下載 LTS 版裝好再回來繼續，你先不要往下做。
2. 問我：有沒有 Firecrawl API key（沒有可以先去 https://firecrawl.dev 拿）、有沒有 Apify token（沒有可以先去 https://console.apify.com 拿）。這兩把金鑰決定你能不能幫我抓網頁跟爬 IG/FB，我可以當場給你，也可能先跳過。
3. 依序執行這幾行（我沒給金鑰的那把，對應那一行就不要跑）：
   claude mcp add playwright -s user -- npx -y @playwright/mcp@latest
   claude mcp add --transport http context7 https://mcp.context7.com/mcp -s user
   claude mcp add firecrawl -s user -e FIRECRAWL_API_KEY=剛剛給的值 -- npx -y firecrawl-mcp
   claude mcp add apify -s user -e APIFY_TOKEN=剛剛給的值 -- npx -y @apify/actors-mcp-server
4. 全部做完跑 claude mcp list，用白話（不要術語）告訴我哪些是綠燈、哪些還沒接上、我還要做什麼。
```

## 中途會遇到什麼

**Claude 會跳出「要不要允許執行這個指令」的提示。** 選允許（Allow）就好，這是正常的安全機制，不是壞掉。

**沒有 Firecrawl 或 Apify 金鑰也沒關係，先跳過。** 之後想補，直接跟 Claude 說「幫我補 Firecrawl 的金鑰」，把金鑰貼給它就行。

**第 3 步某一行失敗，說找不到 npx。** 代表 Node.js 沒裝好或這個視窗還沒吃到新的 PATH，關掉 PowerShell 重開一個再試一次。

## 為什麼跟 Mac 版做法不一樣

Mac 版有一支測過的自動化腳本（`setup-mac.sh`），一行指令就會把四個 MCP 都裝好。Windows 沒有對應腳本，硬套 bash 腳本會直接失敗，所以改成讓 Claude 讀懂需求後，直接逐行下 `claude mcp add` 指令——這幾行指令本身是跨平台的（呼叫的是 `claude.exe`，不是 shell script），效果跟 Mac 版一樣。

## 裝完之後

隨便進一個資料夾，輸入 `claude`，在對話裡打 `/mcp`，看到那幾個是綠色的就成了。

想移掉某一個：`claude mcp remove 名稱 -s user`。
