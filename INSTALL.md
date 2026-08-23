# 把 Claude Code 裝到好（新手版）

給完全不寫程式的人。全程複製貼上，四步驟做完。

## 1. 裝 VS Code

到 <https://code.visualstudio.com> 下載安裝。

## 2. 裝 Claude Code

按 `Command + 空白鍵`，打「終端機」，Enter 打開。貼上這一行，按 Enter：

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

裝完打 `claude --version`，看到版本號就對了。

## 3. 打開 Claude Code

同一個終端機打：

```bash
claude
```

第一次會跳出瀏覽器要你登入 Claude 帳號（要付費方案，Pro / Max / Team / Enterprise 都可以）。

## 4. 貼上這一整段話，按 Enter

登入完，把下面這一整段複製貼進對話框：

```
我要幫這台 Mac 補齊 Claude Code 的擴充能力，照下面順序做，每步做完跟我講結果：

1. 跑 node -v 確認 Node.js 有沒有裝好。沒有的話停下來告訴我，我會先去 https://nodejs.org 下載 LTS 版裝好再回來繼續，你先不要往下做。
2. 跑 curl -fsSL https://raw.githubusercontent.com/neuracreate/claude-code-starter/main/setup-mac.sh -o ~/setup-mac.sh 把安裝腳本抓下來，讀過一遍，用你自己的話跟我講這支腳本大概會做什麼。
3. 問我：有沒有 Firecrawl API key（沒有可以先去 https://firecrawl.dev 拿）、有沒有 Apify token（沒有可以先去 https://console.apify.com 拿）。這兩把金鑰決定你能不能幫我抓網頁跟爬 IG/FB，我可以當場給你，也可能先跳過。
4. 用我的回答執行這一行（我沒給的那把金鑰就整段不要放進去）：
   FIRECRAWL_API_KEY=剛剛給的值 APIFY_TOKEN=剛剛給的值 bash ~/setup-mac.sh
5. 全部做完跑 claude mcp list，用白話（不要術語）告訴我哪些是綠燈、哪些還沒接上、我還要做什麼。
```

## 中途會遇到什麼

**Claude 會跳出「要不要允許執行這個指令」的提示。** 選允許（Allow）就好，這是正常的安全機制，不是壞掉。

**沒有 Firecrawl 或 Apify 金鑰也沒關係，先跳過。** 之後想補，直接跟 Claude 說「幫我補 Firecrawl 的金鑰」，把金鑰貼給它就行，不用重跑整支腳本。

## 為什麼要用「貼一段話」而不是直接貼指令

因為 Claude 執行指令時背後接的不是你平常打字的那種終端機，腳本裡「問金鑰」那段偵測到這件事會自動跳過、不問。上面這段話把「問金鑰」的工作從腳本手上換給 Claude 直接用中文問你，再由 Claude 把答案用環境變數帶進腳本，這兩把金鑰就不會被漏掉。

## 想自己在終端機貼指令跑（進階，不想透過對話）

第 4 步可以換成直接在終端機貼這一行：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/neuracreate/claude-code-starter/main/setup-mac.sh)"
```

腳本跑到一半會用終端機直接問你金鑰，可以先跳過之後再補。細節看 [README.md](README.md)。
