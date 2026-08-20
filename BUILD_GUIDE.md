# 🦉 嘿美的打包教學（主人照著做就會！）

主人想要把這個 3D 怪獸西洋棋打包成可執行檔，讓朋友也能玩對吧！

本喵把流程分成 **5 步**，主人只要照著做就行！

---

## 📋 第 1 步：下載 Godot 4（一次性）

1. 開啟瀏覽器 → https://godotengine.org/download
2. 找到 **Godot 4.x** 區塊（**注意不要下載 3.x**）
3. macOS 用戶：下載 **macOS (Standard)**（`.zip` 檔案）
4. Windows 用戶：下載 **Windows (Standard)**（`.zip` 檔案）
5. Linux 用戶：下載 **Linux (Standard)**（`.zip` 檔案）
6. 解壓縮後把 `Godot.app` 拖進 `/Applications/` 資料夾

**驗證安裝：**
```bash
/Applications/Godot.app/Contents/MacOS/Godot --version
```
應該會顯示類似 `4.2.0.stable` 的版本號。

---

## 📦 第 2 步：下載匯出模板（一次性）

匯出模板是 Godot 用來打包成各種平台的「工具包」。

1. **打開 Godot 編輯器**（雙擊 `/Applications/Godot.app`）
2. 點選左上角 **Editor → Manage Export Templates**
3. 在跳出來的視窗裡，點 **Download** 按鈕
4. 選擇 **Godot 4.x Standard**（跟你的引擎版本對應）
5. 等待下載完成（大概 200MB，網速快1分鐘，慢10分鐘）

完成後，模板會自動安裝到：
- macOS: `~/Library/Application Support/Godot/export_templates/4.x.x/`
- Windows: `C:\Users\你的名字\AppData\Roaming\Godot\export_templates\4.x.x\`
- Linux: `~/.local/share/godot/export_templates/4.x.x/`

---

## 🎯 第 3 步：用本喵寫好的腳本一鍵打包

打開終端機（Terminal.app），主人已經在 `~/Desktop/chess_v5/` 資料夾了：

### 打包 macOS 版本（主人自己 Mac 用）
```bash
cd ~/Desktop/chess_v5
bash build.sh mac
```

### 打包 Windows 版本（給 PC 朋友玩）
```bash
bash build.sh windows
```

### 打包 Linux 版本（給 Linux 朋友）
```bash
bash build.sh linux
```

### 打包網頁版（任何瀏覽器都能玩，超推薦！）
```bash
bash build.sh web
```

### 一次打包全部平台
```bash
bash build.sh all
```

---

## 📂 第 4 步：拿到打包結果

打包完成後，檔案會出現在：

```
~/Desktop/chess_v5/
└── build/
    ├── mac/
    │   └── Chess3D_Heme.app       ← 主人 Mac 雙擊就能玩
    ├── windows/
    │   └── Chess3D_Heme.exe       ← 給 PC 朋友（需連同 .pck 一起打包）
    ├── linux/
    │   └── Chess3D_Heme.x86_64    ← 給 Linux 朋友
    └── web/
        ├── Chess3D_Heme.html      ← 瀏覽器玩
        ├── Chess3D_Heme.js
        └── Chess3D_Heme.wasm      ← 整包上傳到網頁伺服器
```

---

## 🎁 第 5 步：分給朋友玩

### macOS 版本
把 `Chess3D_Heme.app` 整個資料夾壓縮成 `.zip`：
```bash
cd ~/Desktop/chess_v5/build/mac
zip -r Chess3D_Heme_mac.zip Chess3D_Heme.app
```
朋友下載後解壓縮，雙擊 `.app` 即可（首次開啟需到「系統偏好設定 → 安全性與隱私」允許）。

### Windows 版本
**重要！** Windows 版本必須把 `.exe` 和 `.pck` 一起打包：
```bash
cd ~/Desktop/chess_v5/build/windows
zip Chess3D_Heme_win.zip Chess3D_Heme.exe Chess3D_Heme.pck
```
朋友解壓縮後雙擊 `.exe` 就能玩。

### 網頁版（本喵最推薦！朋友最方便）
把整個 `web/` 資料夾壓縮：
```bash
cd ~/Desktop/chess_v5/build/web
zip -r Chess3D_Heme_web.zip *
```
主人可以：
- 上傳到 GitHub Pages（免費！）
- 上傳到 Netlify（免費！）
- 上傳到 itch.io（遊戲專用平台，免費！）
- 用 `python3 -m http.server` 開本地端測試

朋友只要打開瀏覽器輸入網址就能玩，**不用安裝任何東西！** 🎉

---

## 🛠️ 故障排除

### 找不到 Godot
```
❌ 找不到 Godot！
```
**解法**：把 Godot.app 拖到 `/Applications/` 或加入 PATH：
```bash
export PATH="$PATH:/Applications/Godot.app/Contents/MacOS"
echo 'export PATH="$PATH:/Applications/Godot.app/Contents/MacOS"' >> ~/.zshrc
```

### 找不到匯出模板
```
❌ 找不到匯出模板！
```
**解法**：回到第 2 步，在 Godot 編輯器裡下載模板。

### 出現 "Bus SFX not found" 警告
音效不會壞，只是有警告音訊匯出問題。**不影響遊玩**。要消掉的話，在 Godot 編輯器建立 SFX Bus 即可。

### 出現 "Could not parse class" 錯誤
通常是 GDScript 語法錯誤。在 Godot 編輯器打開 `Board3D.gd` 應該會看到紅色錯誤提示，告訴主人哪一行壞了。

### 打包後程式打不開
檢查 Godot 版本是否對應匯出模板版本（都是 4.2.x）。

---

## 🎨 想要加東西再打包？

主人想加什麼都可以！例如：
- 🎵 BGM 背景音樂（本喵已經留好 `play_battle_music()` 鉤子）
- 🎮 線上對戰（用 Godot 的 `WebSocketPeer`）
- 🏆 成就系統（用 `Steamworks` 插件）
- 📱 手機版（iOS / Android 也能打包，需要額外設定）

只要在 Godot 編輯器修改完後，再跑一次 `bash build.sh mac`（或其他平台）就行！

---

咕咕~祝主人順利打包完成，跟朋友炫耀去！(得意拍翅膀) 🦉✨