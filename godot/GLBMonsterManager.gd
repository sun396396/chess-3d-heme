# GLBMonsterManager.gd
# GLB 模型動畫管理器
# 適用於從 Mixamo / Sketchfab 下載的怪獸模型
# 作者：嘿美 🦉（加班到快禿頭）

extends Node

# GLB 模型設定表
# 主人下載模型後，把路徑填到這裡
const MONSTER_MODEL_PATHS := {
	"white_dragon_king":   "res://assets/models/white_dragon.glb",
	"black_dragon_king":   "res://assets/models/black_dragon.glb",
	"white_spider_queen":  "res://assets/models/white_spider.glb",
	"black_spider_queen":  "res://assets/models/black_spider.glb",
	# ... 主人依需求新增
}

# 動畫名稱對應（不同模型的動畫名稱可能不同）
const ANIMATION_NAMES := {
	"idle":   "Idle",          # 或 "idle" / "IDLE"
	"attack": "Attack",        # 或 "Slash" / "attack_01"
	"hit":    "Hit_React",     # 或 "Damage" / "GetHit"
	"death":  "Death",         # 或 "Die" / "death_01"
}

# 已載入的模型快取
var model_cache: Dictionary = {}

# 取得怪獸節點（含動畫播放器）
func get_monster(monster_type: String) -> Node3D:
	var monster := Node3D.new()
	monster.name = "Monster_" + monster_type

	var visual: Node3D = _load_or_fallback(monster_type)
	if visual:
		visual.name = "Visual"
		monster.add_child(visual)

	_setup_animation_player(monster)
	return monster

func _load_or_fallback(monster_type: String) -> Node3D:
	# 優先載入 GLB，找不到就用程式生成的
	var path: String = MONSTER_MODEL_PATHS.get(monster_type, "")
	if path != "" and ResourceLoader.exists(path):
		var scene: PackedScene = load(path)
		if scene:
			return scene.instantiate()
	# Fallback：用 MonsterFactory 程式生成
	var factory := preload("res://MonsterFactory.gd").new()
	return factory.create_monster(_type_to_piece(monster_type))

func _type_to_piece(monster_type: String) -> String:
	# "white_dragon_king" -> "K"
	var t := monster_type.to_lower()
	if t.begins_with("white_"):
		t = t.substr(6)
	else:
		t = t.substr(6)
	return {"dragon_king": "K", "spider_queen": "Q", "stone_golem": "R",
			"troll_bishop": "B", "wolf_knight": "N", "wolf_pup": "P"}.get(t, "P").to_upper() \
		if monster_type.begins_with("white") else {"dragon_king": "k", "spider_queen": "q", "stone_golem": "r",
			"troll_bishop": "b", "wolf_knight": "n", "wolf_pup": "p"}.get(t, "p")

func _setup_animation_player(monster: Node3D) -> void:
	# 自動找 GLB 裡的 AnimationPlayer
	var anim_player: AnimationPlayer = _find_animation_player(monster)
	if anim_player == null:
		# 程式生成的怪獸：建立空動畫器
		anim_player = AnimationPlayer.new()
		monster.add_child(anim_player)
		_create_fallback_animations(anim_player)
	anim_player.set_meta("monster_node", monster)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null

# === 程式生成怪獸的 fallback 動畫 ===
func _create_fallback_animations(anim_player: AnimationPlayer) -> void:
	var lib := AnimationLibrary.new()

	# Idle 動畫（輕微呼吸）
	lib.add_animation("Idle", _make_idle_animation())
	lib.add_animation("Attack", _make_attack_animation())
	lib.add_animation("Hit", _make_hit_animation())
	lib.add_animation("Death", _make_death_animation())

	anim_player.add_animation_library("", lib)

func _make_idle_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 1.5
	anim.loop_mode = Animation.LOOP_LINEAR
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, "Visual:position:y")
	anim.track_insert_key(track, 0.0, 0.0)
	anim.track_insert_key(track, 0.75, 0.1)
	anim.track_insert_key(track, 1.5, 0.0)
	return anim

func _make_attack_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.6
	anim.loop_mode = Animation.LOOP_NONE

	# 向前衝
	var t1 := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t1, "Visual:position:z")
	anim.track_insert_key(t1, 0.0, 0.0)
	anim.track_insert_key(t1, 0.3, 0.4)
	anim.track_insert_key(t1, 0.6, 0.0)

	# 旋轉
	var t2 := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t2, "Visual:rotation:y")
	anim.track_insert_key(t2, 0.0, 0.0)
	anim.track_insert_key(t2, 0.3, PI * 0.25)
	anim.track_insert_key(t2, 0.6, 0.0)
	return anim

func _make_hit_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.3
	var t := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t, "Visual:scale")
	anim.track_insert_key(t, 0.0, Vector3(1, 1, 1))
	anim.track_insert_key(t, 0.1, Vector3(1.2, 0.8, 1.2))
	anim.track_insert_key(t, 0.3, Vector3(1, 1, 1))
	return anim

func _make_death_animation() -> Animation:
	var anim := Animation.new()
	anim.length = 0.8
	var t := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t, "Visual:rotation_degrees:z")
	anim.track_insert_key(t, 0.0, 0.0)
	anim.track_insert_key(t, 0.4, 60.0)
	anim.track_insert_key(t, 0.8, 90.0)
	return anim

# === 播放動畫的高階 API ===
func play_animation(monster: Node3D, anim_name: String) -> void:
	var anim_player: AnimationPlayer = _find_animation_player(monster)
	if anim_player == null:
		return
	# 兼容 GLB 不同的命名
	var actual_name: String = ANIMATION_NAMES.get(anim_name, anim_name)
	if not anim_player.has_animation(actual_name):
		# 試試其他常見命名
		for variant in [anim_name, anim_name.to_lower(), anim_name.to_upper(), "idle"]:
			if anim_player.has_animation(variant):
				actual_name = variant
				break
	anim_player.play(actual_name)