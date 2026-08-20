# 🎵 嘿美的音效系統使用指南

## ⚠️ 重要：需要在 Godot 設定 SFX Bus！

打開 Godot 專案後，依序：

1. **Project → Project Settings → Audio**
2. 在 **Bus Layout** 區域，確認有 `Master` 和 `SFX` 兩個 Bus
3. 如果沒有 `SFX`，點右下角 **Add Bus** 加一個叫 `SFX` 的 Bus
4. 把 SFX Bus 的 **Volume (dB)** 調到 `0.0`

如果不做這步，會出現 "Bus SFX not found" 警告（但不會崩潰）。

---

## 🦉 11 種內建音效

| 觸發事件 | 音效 | 波形合成原理 |
|---|---|---|
| 棋子移動 | 🔉 低沉腳步 | 100Hz 鋸齒波快速衰減 |
| 狼騎士吃子 | ⚔️ 金屬斬擊 | 白噪音 + 高頻掃頻 |
| 蜘蛛吃子 | 🕸️ 撕裂刮擦 | 3 次連續刮擦噪音 |
| 巨人吃子 | 💥 重擊撞擊 | 低頻爆炸 + 高頻撞擊衰減 |
| 龍王吃子 | 🔥 火焰爆裂 | 噪音 + 低頻咆哮 + 隨機爆裂 |
| 巨魔吃子 | ✨ 魔法鈴鐺 | 上掃頻 + 奇數倍諧波 |
| 小狼吃子 | 🦷 咬擊 | 短促斬擊 |
| 怪獸死亡 | 💀 死亡嘶吼 | 400→80Hz 下滑 + 噪音喘息 |
| 將軍警告 | ⚠️ 三聲鐘響 | 800Hz 鐘聲 3 次 |
| 勝利音效 | 🎉 上行三和弦 | C-E-G-C 大調和弦 |
| UI 點擊 | 🔘 短促點擊 | 1500Hz 短暫嗶聲 |

**全部都用 `AudioStreamGenerator` 即時合成！** 主人不用下載任何音檔。

---

## 🔧 怎麼調整音量？

打開 `SoundFactory.gd`，第 35 行：
```gdscript
player.volume_db = -5.0   # ← 調這裡，數字越大越響
```

或在 Godot 內：**Project Settings → Audio → Bus SFX** → 調 Volume (dB)

---

## 🎼 想用自己的音檔？

主人如果想要更專業的音效，把 .wav / .ogg 檔放到：
```
~/Desktop/chess_v5/godot/assets/audio/
```

然後修改 `SoundFactory.gd` 的 `_get_duration()` 和各 `_emit_xxx()` 函式，改成載入外部檔案：

```gdscript
func _emit_sword_slash(p, total: int) -> void:
    var stream := load("res://assets/audio/sword_slash.ogg")
    # ... 用 AudioStreamPlayer 播放
```

---

## 🎬 完整戰鬥音效流程範例

當狼騎士揮劍斬殺小狼崽時：

```
1. 🔉 棋子移動音（低沉腳步）
2. ⚔️ 劍斬擊音（金屬摩擦，白噪音掃頻）
3. 💥 斬擊粒子命中時額外播放短促音效
4. 💀 死亡嘶吼（下滑頻 + 噪音喘息）
5. 💨 塵土粒子音效（巨人會多這一道）
```

全部加起來大概 1.5 秒，剛好配合戰鬥動畫的節奏！

---

咕咕~祝主人聽覺享受！(拍翅膀)