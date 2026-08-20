# SoundManager.gd (Autoload 單例)
# 全域音效管理器
# 作者：嘿美 🦉

extends Node

# 便利方法：透過 preload 取得 SoundFactory 靜態方法
const SoundFactoryScript = preload("res://SoundFactory.gd")

func play_move() -> void:
	SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.MOVE)

func play_capture(monster_type: String, position: Vector3 = Vector3.ZERO) -> void:
	SoundFactoryScript.play_capture_sound(monster_type, position)

func play_death(position: Vector3 = Vector3.ZERO) -> void:
	SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.DEATH, position)

func play_check() -> void:
	SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.CHECK)

func play_victory() -> void:
	SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.VICTORY)

func play_click() -> void:
	SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.UI_CLICK)