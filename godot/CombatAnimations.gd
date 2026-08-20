# CombatAnimations.gd
# 怪獸戰鬥動畫系統（攻擊、被擊、死亡）
# 作者：嘿美 🦉（加班爆肝中）

extends Node

# 使用 preload 取得靜態工具類別
const SoundFactoryScript = preload("res://SoundFactory.gd")

# 動畫狀態
enum AnimState {
	IDLE,
	ATTACK_WINDUP,   # 攻擊蓄力
	ATTACK_SLASH,    # 斬擊
	ATTACK_RECOVER,  # 收招
	HIT_REACT,       # 被擊反應
	DYING,           # 死亡動畫
	DEAD,
}

const ATTACK_DURATION := 0.6  # 整個攻擊動畫秒數
const SLASH_HIT_TIME := 0.3    # 斬擊命中的時機點

signal attack_finished
signal attack_hit  # 觸發斬擊粒子
signal monster_died

func play_attack_sequence(attacker: Node3D, target: Node3D) -> void:
	if attacker == null or target == null:
		return
	var monster_type: String = attacker.get_meta("monster_type", "default")
	var tween := attacker.create_tween()
	tween.set_parallel(false)

	# 階段 1：蓄力（拉後）
	var start_pos: Vector3 = attacker.position
	var windup_offset := _get_windup_offset(attacker, target)

	tween.tween_property(attacker, "position", start_pos + windup_offset, 0.15)
	tween.tween_callback(func(): _on_windup_done(attacker))
	tween.tween_interval(0.05)

	# 階段 2：衝刺斬擊
	var lunge_pos: Vector3 = _get_lunge_position(attacker, target)
	tween.tween_property(attacker, "position", lunge_pos, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _on_slash_hit(attacker, target))

	# 階段 3：播放怪獸專屬斬擊
	_play_monster_slash(attacker, monster_type, tween)

	# 階段 4：退回原位
	tween.tween_interval(0.1)
	tween.tween_property(attacker, "position", start_pos, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): attack_finished.emit())

func _get_windup_offset(attacker: Node3D, target: Node3D) -> Vector3:
	# 從目標方向往後退 0.5 單位
	var dir: Vector3 = (attacker.position - target.position).normalized()
	return dir * 0.5

func _get_lunge_position(attacker: Node3D, target: Node3D) -> Vector3:
	# 衝刺到目標前 0.3 單位
	var dir: Vector3 = (target.position - attacker.position).normalized()
	return attacker.position + dir * (attacker.position.distance_to(target.position) - 0.3)

func _on_windup_done(_attacker: Node3D) -> void:
	pass

func _on_slash_hit(attacker: Node3D, target: Node3D) -> void:
	attack_hit.emit()
	_play_hit_reaction(target)
	_spawn_slash_particles(attacker, target)

func _play_hit_reaction(target: Node3D) -> void:
	if target == null:
		return
	var tween := target.create_tween()
	tween.set_parallel(true)
	# 震動
	tween.tween_property(target, "position", target.position + Vector3(0.05, 0, 0.05), 0.05)
	tween.tween_property(target, "position", target.position, 0.05).set_delay(0.05)
	# 閃白
	_flash_white(target, 0.15)

func _flash_white(target: Node3D, duration: float) -> void:
	# 把所有 MeshInstance3D 暫時變白
	for child in target.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = child.material_override
			var original: Color = mat.albedo_color
			var tween := target.create_tween()
			tween.tween_property(mat, "albedo_color", Color(2, 2, 2), duration * 0.5)
			tween.tween_property(mat, "albedo_color", original, duration * 0.5)

func _play_monster_slash(attacker: Node3D, monster_type: String, tween: Tween) -> void:
	match monster_type:
		"dragon":
			_slash_with_breath(attacker, tween)
		"spider":
			_slash_with_venom(attacker, tween)
		"golem":
			_slash_with_smash(attacker, tween)
		"troll":
			_slash_with_magic(attacker, tween)
		"wolf_knight":
			_slash_with_sword(attacker, tween)
		"wolf_pup":
			_slash_with_bite(attacker, tween)
		_:
			pass

# === 龍王：噴火 ===
func _slash_with_breath(attacker: Node3D, tween: Tween) -> void:
	var mouth: Node3D = _find_or_create_fire_mouth(attacker)
	tween.tween_callback(func(): _do_breath(attacker, mouth))

# === 蜘蛛后：噴毒液 ===
func _slash_with_venom(attacker: Node3D, tween: Tween) -> void:
	tween.tween_callback(func(): _do_venom(attacker))

# === 巨人：重拳砸地 ===
func _slash_with_smash(attacker: Node3D, tween: Tween) -> void:
	# 巨人雙拳上舉
	var fists: Array = []
	for child in attacker.get_children():
		if child.name.begins_with("Fist_"):
			fists.append(child)

	for fist in fists:
		tween.parallel().tween_property(fist, "position:y", fist.position.y + 0.4, 0.1)
	tween.tween_callback(func(): _do_smash(attacker, fists))

# === 巨魔：法杖揮擊 ===
func _slash_with_magic(attacker: Node3D, tween: Tween) -> void:
	var staff: Node3D = attacker.get_node_or_null("Body/Staff")
	if staff:
		tween.tween_property(staff, "rotation:z", -1.2, 0.15)
		tween.tween_property(staff, "rotation:z", 0.0, 0.2)
		tween.tween_callback(func(): _do_magic(attacker))

# === 狼騎士：揮劍 ===
func _slash_with_sword(attacker: Node3D, tween: Tween) -> void:
	var sword: Node3D = attacker.get_node_or_null("Body/Sword")
	if sword:
		tween.tween_property(sword, "rotation:z", -1.5, 0.1)
		tween.tween_property(sword, "rotation:z", 0.15, 0.15)
		tween.tween_callback(func(): _do_sword_slash(attacker))

# === 小狼崽：撲咬 ===
func _slash_with_bite(attacker: Node3D, tween: Tween) -> void:
	tween.tween_callback(func(): _do_bite(attacker))

# === 找嘴巴/沒有就建一個 ===
func _find_or_create_fire_mouth(attacker: Node3D) -> Node3D:
	# 找龍頭，如果沒有就建立一個吐火點
	for child in attacker.get_children():
		if child.name == "Body":
			return child
	return attacker

# === 粒子效果生成 ===
func _spawn_fire_particles(emitter: Node3D) -> void:
	_spawn_particles(emitter, Color(1.0, 0.5, 0.1), 30, 1.5, 2.0)

func _spawn_venom_particles(emitter: Node3D) -> void:
	_spawn_particles(emitter, Color(0.4, 0.9, 0.2), 25, 1.2, 1.5)

func _spawn_dust_particles(emitter: Node3D) -> void:
	_spawn_particles(emitter, Color(0.7, 0.6, 0.5), 40, 0.8, 1.0, true)

func _spawn_magic_particles(emitter: Node3D) -> void:
	_spawn_particles(emitter, Color(0.3, 0.7, 1.0), 20, 1.5, 1.8)

func _spawn_slash_trail(emitter: Node3D) -> void:
	_spawn_particles(emitter, Color(0.95, 0.95, 1.0), 15, 0.6, 1.5)

func _spawn_slash_particles(attacker: Node3D, target: Node3D) -> void:
	# 在命中點噴發
	_spawn_particles(target, Color(1, 0.8, 0.3), 20, 0.7, 2.0)

func _spawn_particles(emitter: Node3D, color: Color, count: int, lifetime: float, energy: float, ground: bool = false) -> void:
	# 用 GPUParticles3D 程式生成粒子爆發
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.amount = count
	particles.lifetime = lifetime

	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.color = color
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3(0, -3, 0) if not ground else Vector3(0, 1, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.15
	particles.process_material = mat

	var draw_mesh := SphereMesh.new()
	draw_mesh.radius = 0.05
	draw_mesh.height = 0.1
	particles.draw_pass_1 = draw_mesh

	particles.position = emitter.position + Vector3(0.3, 0.3, 0)
	particles.emitting = true

	var root := emitter.get_tree().current_scene
	root.add_child(particles)

	# 一段時間後自動清除
	var t := emitter.get_tree().create_timer(lifetime + 0.2)
	await t.timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _shake_nearby(emitter: Node3D, amount: float) -> void:
	# 簡單的隨機震動（給被擊目標或附近的）
	var root := emitter.get_tree().current_scene
	for child in root.get_children():
		if child is Node3D and child != emitter:
			var original: Vector3 = child.position
			var tween := child.create_tween()
			for i in 4:
				var offset := Vector3(randf_range(-amount, amount), 0, randf_range(-amount, amount))
				tween.tween_property(child, "position", original + offset, 0.04)
			tween.tween_property(child, "position", original, 0.05)

func _camera_shake(amount: float) -> void:
	var root := get_tree().current_scene
	var cam: Camera3D = root.get_node_or_null("Camera3D")
	if cam == null:
		return
	var original: Vector3 = cam.position
	var tween := cam.create_tween()
	for i in 6:
		var offset := Vector3(randf_range(-amount, amount), randf_range(-amount, amount) * 0.5, 0)
		tween.tween_property(cam, "position", original + offset, 0.05)
	tween.tween_property(cam, "position", original, 0.06)

# === 死亡動畫 ===
func play_death_sequence(monster: Node3D) -> void:
	if monster == null:
		return
	var tween := monster.create_tween()
	tween.set_parallel(false)

	# 1. 最後一擊震動
	tween.tween_interval(0.1)

	# 2. 旋轉倒下
	tween.tween_property(monster, "rotation_degrees:z", 90.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(monster, "position:y", 0.05, 0.4)

	# 3. 縮放消失
	tween.tween_property(monster, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): _do_death(monster))

# === Lambda 內部動作的輔助方法（避免多行 lambda 的解析問題） ===
func _do_breath(attacker: Node3D, mouth: Node3D) -> void:
	if mouth:
		_spawn_fire_particles(mouth)
		_shake_nearby(attacker, 0.1)
		SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.CAPTURE_FIRE, mouth.position)

func _do_venom(attacker: Node3D) -> void:
	_spawn_venom_particles(attacker)
	SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.CAPTURE_CLAW, attacker.position)

func _do_smash(attacker: Node3D, fists: Array) -> void:
	for fist in fists:
		fist.position.y -= 0.4
	_spawn_dust_particles(attacker)
	_camera_shake(0.2)
	SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.CAPTURE_SMASH, attacker.position)

func _do_magic(attacker: Node3D) -> void:
	_spawn_magic_particles(attacker)
	SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.CAPTURE_MAGIC, attacker.position)

func _do_sword_slash(attacker: Node3D) -> void:
	_spawn_slash_trail(attacker)
	SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.CAPTURE_SWORD, attacker.position)

func _do_bite(attacker: Node3D) -> void:
	_shake_nearby(attacker, 0.05)
	SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.CAPTURE_BITE, attacker.position)

func _do_death(monster: Node3D) -> void:
	_spawn_dust_particles(monster)
	SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.DEATH, monster.position)
	monster.queue_free()
	monster_died.emit()
