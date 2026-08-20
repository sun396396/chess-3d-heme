# MonsterFactory.gd
# 用程式生成 6 種西洋棋怪獸
# 作者：嘿美 🦉（加班中）

# 注意：不宣告 class_name，避免 autoload 衝突
extends Node

# 6 種怪獸：白方 & 黑方各一種，依棋子種類區分
# K=龍王, Q=蜘蛛后, R=石頭巨人, B=巨魔僧侶, N=狼騎士, P=小狼崽

const MONSTER_TYPES := {
	# 白方怪獸
	"K": "white_dragon_king",
	"Q": "white_spider_queen",
	"R": "white_stone_golem",
	"B": "white_troll_bishop",
	"N": "white_wolf_knight",
	"P": "white_wolf_pup",
	# 黑方怪獸
	"k": "black_dragon_king",
	"q": "black_spider_queen",
	"r": "black_stone_golem",
	"b": "black_troll_bishop",
	"n": "black_wolf_knight",
	"p": "black_wolf_pup",
}

static func create_monster(piece: String) -> Node3D:
	var monster_type: String = MONSTER_TYPES.get(piece, "default")
	return _build_monster(monster_type, piece)

static func _build_monster(type: String, piece: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Monster_" + piece

	var body: Node3D
	match type:
		"white_dragon_king", "black_dragon_king":
			body = _build_dragon(type)
		"white_spider_queen", "black_spider_queen":
			body = _build_spider(type)
		"white_stone_golem", "black_stone_golem":
			body = _build_golem(type)
		"white_troll_bishop", "black_troll_bishop":
			body = _build_troll(type)
		"white_wolf_knight", "black_wolf_knight":
			body = _build_wolf_knight(type)
		"white_wolf_pup", "black_wolf_pup":
			body = _build_wolf_pup(type)
		_:
			body = _build_default_monster(type)

	root.add_child(body)
	body.name = "Body"
	body.position.y = 0.0
	return root

# === 龍王（王）===
static func _build_dragon(type: String) -> Node3D:
	var root := Node3D.new()
	var is_white := type.begins_with("white")
	var main_color := Color(0.9, 0.85, 0.95) if is_white else Color(0.3, 0.1, 0.15)
	var accent := Color(1, 0.7, 0.2) if is_white else Color(0.8, 0.2, 0.3)

	# 身體（橢圓形）
	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.4
	body_mesh.height = 0.7
	body.mesh = body_mesh
	_mat(body, main_color, 0.4, 0.5)
	body.position.y = 0.5
	root.add_child(body)

	# 頭
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.25
	head_mesh.height = 0.4
	head.mesh = head_mesh
	_mat(head, main_color, 0.4, 0.5)
	head.position = Vector3(0.4, 0.7, 0)
	root.add_child(head)

	# 角（金色）
	for side in [-1, 1]:
		var horn := MeshInstance3D.new()
		var horn_mesh := CylinderMesh.new()
		horn_mesh.top_radius = 0.02
		horn_mesh.bottom_radius = 0.06
		horn_mesh.height = 0.35
		horn.mesh = horn_mesh
		_mat(horn, accent, 0.6, 0.3)
		horn.position = Vector3(0.45, 1.05, side * 0.15)
		horn.rotation_degrees = Vector3(-15, 0, side * 25)
		root.add_child(horn)

	# 翅膀（兩片）
	for side in [-1, 1]:
		var wing := MeshInstance3D.new()
		var wing_mesh := BoxMesh.new()
		wing_mesh.size = Vector3(0.05, 0.4, 0.7)
		wing.mesh = wing_mesh
		_mat(wing, main_color.darkened(0.2), 0.3, 0.6)
		wing.position = Vector3(side * 0.5, 0.7, 0)
		wing.rotation_degrees = Vector3(0, 0, side * 20)
		wing.name = "Wing_" + ("L" if side < 0 else "R")
		root.add_child(wing)

	# 尾巴
	var tail := MeshInstance3D.new()
	var tail_mesh := CylinderMesh.new()
	tail_mesh.top_radius = 0.05
	tail_mesh.bottom_radius = 0.12
	tail_mesh.height = 0.5
	tail.mesh = tail_mesh
	_mat(tail, main_color, 0.4, 0.5)
	tail.position = Vector3(-0.4, 0.4, 0)
	tail.rotation_degrees = Vector3(0, 0, 80)
	root.add_child(tail)

	# 眼睛（會發光）
	for side in [-1, 1]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.04
		eye_mesh.height = 0.08
		eye.mesh = eye_mesh
		var eye_mat := StandardMaterial3D.new()
		eye_mat.albedo_color = Color(1, 0.9, 0.2)
		eye_mat.emission_enabled = true
		eye_mat.emission = Color(1, 0.6, 0.1)
		eye_mat.emission_energy_multiplier = 2.0
		eye.material_override = eye_mat
		eye.position = Vector3(0.55, 0.75, side * 0.12)
		root.add_child(eye)

	root.set_meta("monster_type", "dragon")
	return root

# === 蜘蛛后（后）===
static func _build_spider(type: String) -> Node3D:
	var root := Node3D.new()
	var is_white := type.begins_with("white")
	var main_color := Color(0.85, 0.85, 0.95) if is_white else Color(0.25, 0.05, 0.3)
	var accent := Color(0.8, 0.4, 0.8)

	# 腹部（大球）
	var abdomen := MeshInstance3D.new()
	var abdomen_mesh := SphereMesh.new()
	abdomen_mesh.radius = 0.35
	abdomen_mesh.height = 0.6
	abdomen.mesh = abdomen_mesh
	_mat(abdomen, main_color, 0.5, 0.3)
	abdomen.position.y = 0.6
	root.add_child(abdomen)

	# 頭胸（小球）
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.4
	head.mesh = head_mesh
	_mat(head, main_color, 0.5, 0.3)
	head.position = Vector3(0.3, 0.55, 0)
	root.add_child(head)

	# 8 隻腳
	var leg_angles = [-60, -30, 30, 60]
	var leg_layers = [-0.25, 0.25]
	var leg_idx := 0
	for layer in leg_layers:
		for ang in leg_angles:
			var leg := MeshInstance3D.new()
			var leg_mesh := CylinderMesh.new()
			leg_mesh.top_radius = 0.03
			leg_mesh.bottom_radius = 0.05
			leg_mesh.height = 0.6
			leg.mesh = leg_mesh
			_mat(leg, main_color.darkened(0.3), 0.4, 0.5)
			var rad := deg_to_rad(ang)
			leg.position = Vector3(layer * 0.7, 0.5, 0)
			leg.rotation_degrees = Vector3(0, ang, -70)
			leg.name = "Leg_%d" % leg_idx
			root.add_child(leg)
			leg_idx += 1

	# 8顆眼睛（紅寶石）
	for i in 8:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.025
		eye_mesh.height = 0.05
		eye.mesh = eye_mesh
		var eye_mat := StandardMaterial3D.new()
		eye_mat.albedo_color = Color(1, 0.1, 0.1)
		eye_mat.emission_enabled = true
		eye_mat.emission = Color(1, 0.1, 0.1)
		eye_mat.emission_energy_multiplier = 3.0
		eye.material_override = eye_mat
		var a := float(i) * TAU / 8.0
		eye.position = Vector3(0.42, 0.62, sin(a) * 0.1)
		root.add_child(eye)

	root.set_meta("monster_type", "spider")
	return root

# === 石頭巨人（車）===
static func _build_golem(type: String) -> Node3D:
	var root := Node3D.new()
	var is_white := type.begins_with("white")
	var main_color := Color(0.75, 0.7, 0.65) if is_white else Color(0.3, 0.25, 0.2)
	var accent := Color(0.5, 0.4, 0.3) if is_white else Color(0.2, 0.15, 0.1)

	# 身體（方塊）
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.7, 0.8, 0.5)
	body.mesh = body_mesh
	_mat(body, main_color, 0.1, 0.8)
	body.position.y = 0.55
	root.add_child(body)

	# 頭（方塊）
	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.5, 0.4, 0.4)
	head.mesh = head_mesh
	_mat(head, main_color, 0.1, 0.8)
	head.position = Vector3(0.35, 1.05, 0)
	root.add_child(head)

	# 肩膀（兩塊大石）
	for side in [-1, 1]:
		var shoulder := MeshInstance3D.new()
		var shoulder_mesh := BoxMesh.new()
		shoulder_mesh.size = Vector3(0.3, 0.3, 0.5)
		shoulder.mesh = shoulder_mesh
		_mat(shoulder, accent, 0.1, 0.8)
		shoulder.position = Vector3(side * 0.45, 0.85, 0)
		root.add_child(shoulder)

	# 拳頭（兩顆球）
	for side in [-1, 1]:
		var fist := MeshInstance3D.new()
		var fist_mesh := SphereMesh.new()
		fist_mesh.radius = 0.18
		fist_mesh.height = 0.35
		fist.mesh = fist_mesh
		_mat(fist, accent, 0.1, 0.8)
		fist.position = Vector3(side * 0.55, 0.55, 0)
		fist.name = "Fist_" + ("L" if side < 0 else "R")
		root.add_child(fist)

	# 裂痕（眼睛發光）
	for side in [-1, 1]:
		var eye := MeshInstance3D.new()
		var eye_mesh := BoxMesh.new()
		eye_mesh.size = Vector3(0.06, 0.06, 0.05)
		eye.mesh = eye_mesh
		var eye_mat := StandardMaterial3D.new()
		eye_mat.albedo_color = Color(1, 0.5, 0.1)
		eye_mat.emission_enabled = true
		eye_mat.emission = Color(1, 0.3, 0.0)
		eye_mat.emission_energy_multiplier = 2.5
		eye.material_override = eye_mat
		eye.position = Vector3(0.58, 1.1, side * 0.1)
		root.add_child(eye)

	root.set_meta("monster_type", "golem")
	return root

# === 巨魔僧侶（象）===
static func _build_troll(type: String) -> Node3D:
	var root := Node3D.new()
	var is_white := type.begins_with("white")
	var main_color := Color(0.5, 0.7, 0.4) if is_white else Color(0.3, 0.5, 0.2)
	var accent := Color(0.9, 0.8, 0.4)

	# 身體（瘦長）
	var body := MeshInstance3D.new()
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.2
	body_mesh.bottom_radius = 0.3
	body_mesh.height = 0.9
	body.mesh = body_mesh
	_mat(body, main_color, 0.3, 0.6)
	body.position.y = 0.6
	root.add_child(body)

	# 頭（歪斜）
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.25
	head_mesh.height = 0.5
	head.mesh = head_mesh
	_mat(head, main_color.lightened(0.2), 0.3, 0.6)
	head.position = Vector3(0.15, 1.2, 0)
	head.rotation_degrees = Vector3(0, 0, -10)
	root.add_child(head)

	# 長耳朵
	for side in [-1, 1]:
		var ear := MeshInstance3D.new()
		var ear_mesh := CylinderMesh.new()
		ear_mesh.top_radius = 0.02
		ear_mesh.bottom_radius = 0.05
		ear_mesh.height = 0.25
		ear.mesh = ear_mesh
		_mat(ear, main_color, 0.3, 0.6)
		ear.position = Vector3(0.1, 1.35, side * 0.18)
		ear.rotation_degrees = Vector3(0, 0, side * 35)
		root.add_child(ear)

	# 法杖（金色）
	var staff := MeshInstance3D.new()
	var staff_mesh := CylinderMesh.new()
	staff_mesh.top_radius = 0.04
	staff_mesh.bottom_radius = 0.04
	staff_mesh.height = 1.4
	staff.mesh = staff_mesh
	_mat(staff, accent, 0.5, 0.4)
	staff.position = Vector3(-0.35, 1.0, 0)
	staff.name = "Staff"
	root.add_child(staff)

	# 法杖寶石（發光）
	var orb := MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.1
	orb_mesh.height = 0.2
	orb.mesh = orb_mesh
	var orb_mat := StandardMaterial3D.new()
	orb_mat.albedo_color = Color(0.3, 0.7, 1.0)
	orb_mat.emission_enabled = true
	orb_mat.emission = Color(0.3, 0.7, 1.0)
	orb_mat.emission_energy_multiplier = 3.0
	orb.material_override = orb_mat
	orb.position = Vector3(-0.35, 1.75, 0)
	orb.name = "Orb"
	root.add_child(orb)

	root.set_meta("monster_type", "troll")
	return root

# === 狼騎士（馬）===
static func _build_wolf_knight(type: String) -> Node3D:
	var root := Node3D.new()
	var is_white := type.begins_with("white")
	var wolf_color := Color(0.85, 0.85, 0.9) if is_white else Color(0.2, 0.2, 0.25)
	var armor_color := Color(0.7, 0.5, 0.2) if is_white else Color(0.4, 0.1, 0.1)

	# 狼身（橢圓）
	var wolf_body := MeshInstance3D.new()
	var wolf_mesh := SphereMesh.new()
	wolf_mesh.radius = 0.3
	wolf_mesh.height = 0.85
	wolf_body.mesh = wolf_mesh
	_mat(wolf_body, wolf_color, 0.3, 0.6)
	wolf_body.position.y = 0.5
	wolf_body.scale = Vector3(1, 0.8, 0.7)
	root.add_child(wolf_body)

	# 狼頭
	var wolf_head := MeshInstance3D.new()
	var wolf_head_mesh := SphereMesh.new()
	wolf_head_mesh.radius = 0.22
	wolf_head_mesh.height = 0.4
	wolf_head.mesh = wolf_head_mesh
	_mat(wolf_head, wolf_color, 0.3, 0.6)
	wolf_head.position = Vector3(0.45, 0.65, 0)
	root.add_child(wolf_head)

	# 狼耳
	for side in [-1, 1]:
		var ear := MeshInstance3D.new()
		var ear_mesh := PrismMesh.new()
		ear.mesh = ear_mesh
		_mat(ear, wolf_color.darkened(0.2), 0.3, 0.6)
		ear.position = Vector3(0.4, 0.95, side * 0.12)
		ear.scale = Vector3(0.1, 0.2, 0.08)
		root.add_child(ear)

	# 4 隻腿
	var leg_positions = [
		Vector3(0.25, 0.15, -0.2),
		Vector3(0.25, 0.15, 0.2),
		Vector3(-0.25, 0.15, -0.2),
		Vector3(-0.25, 0.15, 0.2),
	]
	for pos in leg_positions:
		var leg := MeshInstance3D.new()
		var leg_mesh := CylinderMesh.new()
		leg_mesh.top_radius = 0.04
		leg_mesh.bottom_radius = 0.06
		leg_mesh.height = 0.3
		leg.mesh = leg_mesh
		_mat(leg, wolf_color.darkened(0.3), 0.3, 0.6)
		leg.position = pos
		root.add_child(leg)

	# 騎士（坐在狼上）
	var rider := MeshInstance3D.new()
	var rider_mesh := CylinderMesh.new()
	rider_mesh.top_radius = 0.18
	rider_mesh.bottom_radius = 0.22
	rider_mesh.height = 0.6
	rider.mesh = rider_mesh
	_mat(rider, armor_color, 0.6, 0.4)
	rider.position = Vector3(-0.1, 1.0, 0)
	root.add_child(rider)

	# 騎士頭盔
	var helm := MeshInstance3D.new()
	var helm_mesh := SphereMesh.new()
	helm_mesh.radius = 0.16
	helm_mesh.height = 0.3
	helm.mesh = helm_mesh
	_mat(helm, armor_color, 0.6, 0.4)
	helm.position = Vector3(-0.1, 1.45, 0)
	root.add_child(helm)

	# 騎士持劍
	var sword := MeshInstance3D.new()
	var sword_mesh := BoxMesh.new()
	sword_mesh.size = Vector3(0.05, 0.7, 0.15)
	sword.mesh = sword_mesh
	var sword_mat := StandardMaterial3D.new()
	sword_mat.albedo_color = Color(0.9, 0.9, 1.0)
	sword_mat.metallic = 0.9
	sword_mat.roughness = 0.2
	sword.material_override = sword_mat
	sword.position = Vector3(0.1, 1.2, 0.25)
	sword.rotation_degrees = Vector3(0, 0, 15)
	sword.name = "Sword"
	root.add_child(sword)

	root.set_meta("monster_type", "wolf_knight")
	return root

# === 小狼崽（兵）===
static func _build_wolf_pup(type: String) -> Node3D:
	var root := Node3D.new()
	var is_white := type.begins_with("white")
	var color := Color(0.8, 0.8, 0.85) if is_white else Color(0.25, 0.25, 0.3)

	# 身體（小橢圓）
	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.22
	body_mesh.height = 0.5
	body.mesh = body_mesh
	_mat(body, color, 0.3, 0.6)
	body.position.y = 0.35
	body.scale = Vector3(1, 0.85, 0.75)
	root.add_child(body)

	# 頭
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.18
	head_mesh.height = 0.35
	head.mesh = head_mesh
	_mat(head, color, 0.3, 0.6)
	head.position = Vector3(0.28, 0.45, 0)
	root.add_child(head)

	# 耳
	for side in [-1, 1]:
		var ear := MeshInstance3D.new()
		var ear_mesh := PrismMesh.new()
		ear.mesh = ear_mesh
		_mat(ear, color.darkened(0.2), 0.3, 0.6)
		ear.position = Vector3(0.25, 0.7, side * 0.1)
		ear.scale = Vector3(0.08, 0.15, 0.06)
		root.add_child(ear)

	# 4 隻腳
	for pos in [Vector3(0.15, 0.05, -0.12), Vector3(0.15, 0.05, 0.12), Vector3(-0.15, 0.05, -0.12), Vector3(-0.15, 0.05, 0.12)]:
		var leg := MeshInstance3D.new()
		var leg_mesh := CylinderMesh.new()
		leg_mesh.top_radius = 0.03
		leg_mesh.bottom_radius = 0.04
		leg_mesh.height = 0.2
		leg.mesh = leg_mesh
		_mat(leg, color.darkened(0.3), 0.3, 0.6)
		leg.position = pos
		root.add_child(leg)

	# 尾巴
	var tail := MeshInstance3D.new()
	var tail_mesh := CylinderMesh.new()
	tail_mesh.top_radius = 0.02
	tail_mesh.bottom_radius = 0.05
	tail_mesh.height = 0.3
	tail.mesh = tail_mesh
	_mat(tail, color, 0.3, 0.6)
	tail.position = Vector3(-0.3, 0.35, 0)
	tail.rotation_degrees = Vector3(0, 0, 60)
	root.add_child(tail)

	root.set_meta("monster_type", "wolf_pup")
	return root

static func _build_default_monster(type: String) -> Node3D:
	var root := Node3D.new()
	var sphere := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.3
	mesh.height = 0.6
	sphere.mesh = mesh
	_mat(sphere, Color.GRAY, 0.5, 0.5)
	sphere.position.y = 0.4
	root.add_child(sphere)
	return root

# 共用材質函式
static func _mat(mesh_inst: MeshInstance3D, color: Color, metallic: float, roughness: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	mesh_inst.material_override = mat