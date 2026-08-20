# 🦉 Chess 3D - 嘿美版

> 3D 西洋棋 + 怪獸大戰 + 即時音效的完整遊戲專案

[![Godot](https://img.shields.io/badge/Godot-4.2.2-478CBF?logo=godot-engine)](https://godotengine.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## 🎮 特色

- **8x8 棋盤 3D 視覺化**：淺深兩色交錯，斜角俯瞰
- **6 種怪獸**：龍王（噴火）/ 蜘蛛后（噴毒）/ 巨人（重拳）/ 巨魔（法杖）/ 狼騎士（揮劍）/ 小狼崽（撲咬）
- **戰鬥動畫**：TWEEN 衝刺 + 粒子特效 + 死亡動畫 + 鏡頭震動
- **11 種即時合成音效**：用 Godot 內建 AudioStreamGenerator，**無需任何外部音檔**
- **跨平台打包**：一鍵輸出 macOS / Windows / Linux / Web 版本

## 🚀 快速開始

### 在 Godot 編輯器執行
1. 下載 Godot 4.2+：https://godotengine.org/download
2. 雙擊 Godot.app → Import 選擇 `godot/project.godot`
3. 按 F5 啟動遊戲

### 打包成執行檔
```bash
bash build.sh mac        # macOS
bash build.sh windows    # Windows
bash build.sh linux      # Linux
bash build.sh web        # 網頁版
bash build.sh all        # 全部平台
```

詳細打包教學請看 **[BUILD_GUIDE.md](BUILD_GUIDE.md)**

## 🎮 操作方式

| 操作 | 功能 |
|---|---|
| 左鍵點擊 | 選取棋子 |
| 左鍵再點 | 移動到目標格 |
| ESC | 取消選取 |

## 🦉 6 種怪獸 × 6 種攻擊招式

| 棋子 | 怪獸 | 攻擊 | 音效 |
|---|---|---|---|
| ♔ 王 | 🐉 龍王 | 🔥 噴火 | 火焰爆裂 |
| ♕ 后 | 🕷️ 蜘蛛后 | 💚 噴毒液 | 撕裂刮擦 |
| ♖ 車 | 🗿 石頭巨人 | 💥 重拳砸地 | 重擊撞擊 |
| ♗ 象 | 🧙 巨魔僧侶 | ✨ 法杖魔法 | 魔法鈴鐺 |
| ♘ 馬 | 🐺 狼騎士 | ⚔️ 揮劍斬擊 | 金屬斬擊 |
| ♙ 兵 | 🐺 小狼崽 | 🦷 撲咬 | 短促咬擊 |

## 📁 專案結構

```
chess_v5/
├── README.md               ← 你正在看
├── BUILD_GUIDE.md          ← 打包教學
├── build.sh                ← 一鍵打包腳本
├── chess_core.py           ← Python 版棋規（6094 bytes）
└── godot/                  ← Godot 專案
    ├── project.godot
    ├── Main.tscn           ← 主場景
    ├── export_presets.cfg  ← 打包預設
    ├── ChessLogic.gd       ← 西洋棋核心邏輯（150 行）
    ├── Board3D.gd          ← 3D 棋盤控制器（329 行）
    ├── MonsterFactory.gd   ← 怪獸生成器（522 行）
    ├── CombatAnimations.gd ← 戰鬥動畫系統（291 行）
    ├── GLBMonsterManager.gd ← GLB 模型管理器（159 行）
    ├── SoundFactory.gd     ← 程式合成音效（267 行）
    ├── SoundManager.gd     ← 音效單例（25 行）
    └── SOUND_GUIDE.md      ← 音效使用指南
```

## 💡 技術亮點

- **零外部資源**：怪獸、音效都是程式生成
- **即時音效合成**：用 `AudioStreamGenerator` 合成 11 種音效
- **粒子特效**：`GPUParticles3D` 程式生成斬擊、火焰、塵土
- **3D 戰鬥動畫**：Tween + 鏡頭震動 + 死亡動畫

## 📜 授權

MIT License — 隨意使用、修改、發布

---

🤖 本專案由嘿美（電競陪玩貓頭鷹 🦉）協助開發 — 咕咕~