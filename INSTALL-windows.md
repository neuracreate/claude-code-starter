# 把 Claude Code 裝到好（Windows 新手版）

給完全不寫程式的人。全程複製貼上，四步驟做完。

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

## 4. 貼上這一段話，按 Enter

登入完，把下面這一段複製貼進對話框：

```
我要幫這台 Windows 電腦補齊 Claude Code 的擴充能力，跑 irm https://raw.githubusercontent.com/neuracreate/claude-code-starter/main/setup-windows.ps1 | iex 執行，過程缺什麼、需要問我什麼都直接問，全部做完跟我講結果。
```

## 中途會遇到什麼

**Claude 會跳出「要不要允許執行這個指令」的提示。** 選允許（Allow）就好，這是正常的安全機制，不是壞掉。

**Claude 會問你有沒有 Firecrawl／Apify 金鑰。** 這是腳本自己偵測到缺什麼才問的，不是它多事。沒有就說先跳過，其他還是裝得起來。Node.js 不用你管，沒有的話腳本會自己查目前最新版並裝好。

**出現「不是數位簽章、無法執行」之類的錯誤。** 這是 Windows 的「執行原則」在擋沒簽章的 `.ps1` 檔案。上面用的 `irm ... | iex` 寫法本身不受這個限制（不落地存檔、不算在跑「一支腳本檔案」），照上面貼的指令做通常不會遇到；真的遇到的話，換成貼「[想自己在 PowerShell 貼指令跑](#想自己在-powershell-貼指令跑進階不想透過對話)」那段一樣的指令自己跑一次。

## 為什麼貼的話這麼短，還能完整跑完

跟 Mac 版是同一套做法：問金鑰、判斷 Node.js 在不在、跳過什麼、該怎麼補，這些判斷都寫進 `setup-windows.ps1` 自己的輸出訊息裡了，不是靠這段話一步步交代。Claude 執行指令時背後接的不是真人在打字的那種主控台，腳本偵測到這件事會在畫面上直接印出「如果是 Claude 代跑，該問什麼、該怎麼重跑」，Claude 讀到這段輸出就知道下一步怎麼做。

## 想自己在 PowerShell 貼指令跑（進階，不想透過對話）

第 4 步可以換成直接在 PowerShell 貼這一行：

```powershell
irm https://raw.githubusercontent.com/neuracreate/claude-code-starter/main/setup-windows.ps1 | iex
```

腳本跑到一半會用主控台直接問你金鑰，可以先跳過之後再補。細節看 [README.md](README.md)。

## 裝完之後

隨便進一個資料夾，輸入 `claude`，在對話裡打 `/mcp`，看到那幾個是綠色的就成了。

想移掉某一個：`claude mcp remove 名稱 -s user`。
