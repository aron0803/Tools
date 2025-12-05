# 🛠️ Ron小工具

實用的小工具集合，免費下載使用。

## 📥 下載

訪問下載頁面：**[https://aron0803.github.io/Tools/](https://aron0803.github.io/Tools/)**

或直接前往 [Releases](https://github.com/aron0803/Tools/releases) 頁面下載。

## 📦 工具列表

| 工具名稱 | 說明 | 版本 |
|---------|------|------|
| 螢幕錄影工具 | 輕量級螢幕錄影程式，支援全螢幕/視窗錄製、截圖、音訊錄製 | 1.0.0 |

## 🚀 發佈指南

### 準備工作

1. 安裝 [GitHub CLI](https://cli.github.com/)（可選，用於 Releases 功能）
   ```powershell
   winget install GitHub.cli
   ```

2. 登入 GitHub CLI
   ```powershell
   gh auth login
   ```

### 發佈新版本

1. 將 `.zip` 檔案放入 `File/` 目錄
2. 更新 `tools.json` 中的工具描述（可選）
3. 執行發佈腳本：
   ```powershell
   .\publish.ps1
   ```

### 發佈腳本參數

```powershell
# 指定版本號
.\publish.ps1 -Version "1.0.1"

# 自訂提交訊息
.\publish.ps1 -Message "新增功能"

# 跳過 GitHub Release（僅更新網頁）
.\publish.ps1 -SkipRelease
```

### 啟用 GitHub Pages

1. 前往 Repository 的 **Settings**
2. 點選 **Pages**
3. Source 選擇 **Deploy from a branch**
4. Branch 選擇 **main**，Folder 選擇 **/docs**
5. 點選 **Save**

幾分鐘後即可訪問：`https://aron0803.github.io/Tools/`

## 📁 目錄結構

```
Tools/
├── File/              # 放置要上傳的 .zip 檔案
│   └── *.zip
├── docs/              # GitHub Pages 網站目錄
│   └── index.html     # 下載頁面（自動產生）
├── tools.json         # 工具描述設定檔
├── publish.ps1        # 發佈腳本
└── README.md
```

## 📝 tools.json 格式

```json
{
  "siteName": "Ron小工具",
  "siteDescription": "實用的小工具集合，免費下載使用",
  "author": "Ron",
  "tools": {
    "ToolFileName": {
      "name": "工具顯示名稱",
      "description": "工具說明",
      "version": "1.0.0",
      "category": "多媒體"
    }
  }
}
```

### 可用的分類

- 多媒體
- 系統工具
- 網路工具
- 開發工具
- 其他

## 📄 授權

MIT License
