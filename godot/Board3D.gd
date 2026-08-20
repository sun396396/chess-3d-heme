# Board3D.gd
# 3D 棋盤控制器
# 作者：嘿美 🦉

extends Node3D

@onready var logic: Node = $ChessLogic
@onready var board_root: Node3D = $BoardRoot
@onready var pieces_root: Node3D = $PiecesRoot
@onready var camera: Camera3D = $Camera3D
@onready var combat: Node = $CombatAnimations

# 注意：MonsterFactory / GLBMonsterManager / SoundFactory 都有 class_name，可以直接呼叫
# 但 .new() 會建立新節點實例；對 SoundFactory（純靜態工具）我們不需要 .new()

# 使用 preload 取得靜態工具類別（避免 class_name 與 autoload 衝突）
const MonsterFactoryScript = preload("res://MonsterFactory.gd")
const SoundFactoryScript = preload("res://SoundFactory.gd")

# 棋盤格子的世界座標（每格 1.2 單位寬）
const CELL_SIZE := 1.2
const BOARD_ORIGIN := Vector3(-4.2, 0, -4.2)  # a1 棋格的中心位置

# 棋子節點快取 [row][col] -> Node3D
var piece_nodes: Array = []

# 選取狀態
var selected: Array = []  # [r, c] or []

# 注意：主版本已改用 MonsterFactory 程式生成怪獸！

func _ready() -> void:
	_build_board()
	_spawn_pieces()

func _build_board() -> void:
	# 8x8 棋盤（淺深交錯）
	# 使用 Area3D 接收點擊（Godot 4 標準做法）
	for r in range(8):
		for c in range(8):
			# 容器：Area3D（用於點擊偵測）
			var square: Area3D = Area3D.new()
			square.name = "Square_%d_%d" % [r, c]
			square.position = _cell_to_world(r, c)
			square.set_meta("row", r)
			square.set_meta("col", c)
			square.input_event.connect(_on_square_clicked)

			# 視覺：MeshInstance3D
			var visual: MeshInstance3D = MeshInstance3D.new()
			var mesh: BoxMesh = BoxMesh.new()
			mesh.size = Vector3(CELL_SIZE, 0.2, CELL_SIZE)
			visual.mesh = mesh

			var mat: StandardMaterial3D = StandardMaterial3D.new()
			var is_light: bool = (r + c) % 2 == 0
			mat.albedo_color = Color(0.9, 0.75, 0.55) if is_light else Color(0.4, 0.25, 0.15)
			visual.material_override = mat
			visual.position.y = -0.1
			square.add_child(visual)

			# 碰撞：BoxShape3D
			var collider: CollisionShape3D = CollisionShape3D.new()
			var shape: BoxShape3D = BoxShape3D.new()
			shape.size = Vector3(CELL_SIZE, 0.2, CELL_SIZE)
			collider.shape = shape
			square.add_child(collider)

			board_root.add_child(square)

	# 加光源
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.light_energy = 1.2
	add_child(light)

	# 加地板陰影
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.15, 0.1, 0.08)
	floor_mesh.material_override = floor_mat
	floor_mesh.position.y = -0.2
	add_child(floor_mesh)

func _spawn_pieces() -> void:
	piece_nodes.clear()
	for r in range(8):
		var row_array: Array = []
		for c in range(8):
			var piece: String = logic.board[r][c]
			if piece != ".":
				var node := _create_piece_mesh(piece)
				node.position = _cell_to_world(r, c)
				node.position.y = 0.2
				node.name = "Piece_%s_%d_%d" % [piece, r, c]
				pieces_root.add_child(node)
				row_array.append(node)
			else:
				row_array.append(null)
		piece_nodes.append(row_array)

func _create_piece_mesh(piece: String) -> Node3D:
	# 🔥 用程式生成的怪獸！
	var monster: Node3D = MonsterFactoryScript.create_monster(piece)
	monster.name = "MonsterRoot"
	# 縮放統一：兵小、王大
	var t: String = piece.to_lower()
	var scale: float = 1.0
	match t:
		"p": scale = 0.85
		"n", "b": scale = 0.95
		"r": scale = 1.1
		"q": scale = 1.15
		"k": scale = 1.25
	monster.scale = Vector3(scale, scale, scale)
	return monster

func _shape_for_piece(t: String) -> PrimitiveMesh:
	match t:
		"p":
			var m: CylinderMesh = CylinderMesh.new()
			m.top_radius = 0.25
			m.bottom_radius = 0.3
			m.height = 0.5
			return m
		"r":
			var m: BoxMesh = BoxMesh.new()
			m.size = Vector3(0.5, 0.5, 0.5)
			return m
		"n":
			var m: PrismMesh = PrismMesh.new()
			return m
		"b":
			var m: CylinderMesh = CylinderMesh.new()
			m.top_radius = 0.1
			m.bottom_radius = 0.3
			m.height = 0.8
			return m
		"q":
			var m: SphereMesh = SphereMesh.new()
			m.radius = 0.3
			m.height = 0.6
			return m
		"k":
			var m: CylinderMesh = CylinderMesh.new()
			m.top_radius = 0.2
			m.bottom_radius = 0.3
			m.height = 0.9
			return m
	var m: SphereMesh = SphereMesh.new()
	return m

func _piece_role(t: String) -> String:
	var lookup: Dictionary = {"k": "king", "q": "queen", "r": "rook", "b": "bishop", "n": "knight", "p": "pawn"}
	return lookup.get(t, "pawn")

func _apply_color(mesh_inst: MeshInstance3D, color: Color) -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.3
	mat.roughness = 0.5
	mesh_inst.material_override = mat

func _cell_to_world(r: int, c: int) -> Vector3:
	# 注意：西洋棋 board[r][c]，r=0 是黑方底線，r=7 是白方底線
	# 翻轉一下讓白方在近處
	var x: float = BOARD_ORIGIN.x + c * CELL_SIZE
	var z: float = BOARD_ORIGIN.z + (7 - r) * CELL_SIZE
	return Vector3(x, 0, z)

func _world_to_cell(world_pos: Vector3) -> Array:
	# 注意：CELL_SIZE = 1.2，_cell_to_world 把棋格中心放在 c*CELL_SIZE + BOARD_ORIGIN
	# 所以 world_pos.x == BOARD_ORIGIN.x + c * CELL_SIZE 時，c 為對應的 col
	var c: int = int(round((world_pos.x - BOARD_ORIGIN.x) / CELL_SIZE))
	var r_inv: int = int(round((world_pos.z - BOARD_ORIGIN.z) / CELL_SIZE))
	var r: int = 7 - r_inv
	if in_bounds(r, c):
		return [r, c]
	return [-1, -1]

func in_bounds(r: int, c: int) -> bool:
	return r >= 0 and r < 8 and c >= 0 and c < 8

func _on_square_clicked(_camera: Node, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 從事件的世界座標反推棋格（最可靠，不依賴 Area3D 順序）
		var cell: Array = _world_to_cell(event_position)
		var r: int = cell[0]
		var c: int = cell[1]
		if not in_bounds(r, c):
			print("🐛 DEBUG 點擊超出棋盤: pos=", event_position)
			return
		print("🐛 DEBUG 點擊棋格 row=", r, " col=", c, " pos=", event_position)
		_on_cell_clicked(r, c)

func _on_cell_clicked(r: int, c: int) -> void:
	if selected.is_empty():
		var piece: String = logic.board[r][c]
		if piece == ".":
			return
		# 檢查是不是當前玩家的棋子（明確宣告 bool 型別）
		var is_my_piece: bool = false
		if logic.current_turn == "white" and piece == piece.to_upper():
			is_my_piece = true
		elif logic.current_turn == "black" and piece == piece.to_lower():
			is_my_piece = true
		if not is_my_piece:
			return
		selected = [r, c]
		_highlight_selected(true)
		SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.UI_CLICK)
	else:
		var fr: int = selected[0]
		var fc: int = selected[1]
		_highlight_selected(false)

		var result: Dictionary = logic.make_move(fr, fc, r, c)
		if result.ok:
			SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.MOVE)
			_animate_move(fr, fc, r, c, result.captured)
			# ⭐ 王車易位：額外搬車節點
			if result.get("castled", false):
				_animate_castle_rook(fr, fc, r, c)
			selected = []
		else:
			# 不合法 → 重新選取
			var piece: String = logic.board[r][c]
			if piece != ".":
				selected = [r, c]
				_highlight_selected(true)
				SoundFactoryScript.play_sound(SoundFactoryScript.SoundType.UI_CLICK)
			else:
				selected = []

func _highlight_selected(on: bool) -> void:
	if selected.is_empty():
		return
	var r: int = selected[0]
	var c: int = selected[1]
	var sq: Area3D = board_root.get_child(r * 8 + c)
	# 取子節點 MeshInstance3D 的材質
	var visual: MeshInstance3D = sq.get_child(0) as MeshInstance3D
	if visual == null:
		return
	var mat: StandardMaterial3D = visual.material_override as StandardMaterial3D
	if mat == null:
		return
	if on:
		mat.albedo_color = Color(1.0, 0.9, 0.3)  # 金色高亮
	else:
		var is_light: bool = (r + c) % 2 == 0
		mat.albedo_color = Color(0.9, 0.75, 0.55) if is_light else Color(0.4, 0.25, 0.15)

func _animate_move(fr: int, fc: int, tr: int, tc: int, captured: String) -> void:
	# 簡單 TWEEN 動畫：平滑移動 + 旋轉跳躍
	var piece_node: Node3D = piece_nodes[fr][fc]
	if piece_node == null:
		return

	var start_pos: Vector3 = piece_node.position
	var end_pos: Vector3 = _cell_to_world(tr, tc)
	end_pos.y = 0.2

	# 更新邏輯棋盤對應
	piece_nodes[tr][tc] = piece_node
	piece_nodes[fr][fc] = null

	# 吃子動畫：怪獸砍人！⚔️
	if captured != ".":
		print("⚔️ 嘿美提示：", captured, "被吃掉了！怪獸正在發動攻擊...")
		_play_capture_combat(fr, fc, tr, tc, captured)
		return

	# 移動 TWEEN（沒吃子時的單純移動）
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(piece_node, "position", end_pos, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece_node, "rotation:y", PI * 0.5, 0.2)
	tween.tween_property(piece_node, "rotation:y", 0.0, 0.2).set_delay(0.2)

# === 王車易位的車動畫 ===
func _animate_castle_rook(fr: int, fc: int, tr: int, tc: int) -> void:
	# tr/tc = 王的新位置 (g1 或 c1)
	# 王從 fr/fc (e1) 走來
	var row: int = tr
	# 判斷短/長易位
	var rook_from_col: int = 7 if tc == 6 else 0  # 短=h, 長=a
	var rook_to_col: int = 5 if tc == 6 else 3     # 短=f, 長=d
	var rook_node: Node3D = piece_nodes[row][rook_from_col]
	if rook_node == null:
		return
	var rook_dest: Vector3 = _cell_to_world(row, rook_to_col)
	rook_dest.y = 0.2

	# 更新 piece_nodes
	piece_nodes[row][rook_to_col] = rook_node
	piece_nodes[row][rook_from_col] = null

	# 平滑動畫
	var tween: Tween = create_tween()
	tween.tween_property(rook_node, "position", rook_dest, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# === 吃子戰鬥動畫 ===
func _play_capture_combat(fr: int, fc: int, tr: int, tc: int, captured: String) -> void:
	var attacker: Node3D = piece_nodes[fr][fc]
	var victim: Node3D = piece_nodes[tr][tc] if captured != "." else null

	var end_pos: Vector3 = _cell_to_world(tr, tc)
	end_pos.y = 0.2

	if attacker == null:
		return

	# 第一階段：衝向目標
	var lunge_tween: Tween = create_tween()
	lunge_tween.tween_property(attacker, "position", end_pos, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 第二階段：觸發戰鬥動畫
	lunge_tween.tween_callback(func():
		if victim and is_instance_valid(victim):
			combat.play_attack_sequence(attacker, victim)
			combat.attack_hit.connect(func():
				if victim and is_instance_valid(victim):
					combat.play_death_sequence(victim)
					combat.monster_died.connect(func():
						if victim:
							piece_nodes[tr][tc] = null
					, CONNECT_ONE_SHOT)
			, CONNECT_ONE_SHOT)
	)

	# 第三階段：攻擊者歸位
	lunge_tween.tween_interval(0.6)
	lunge_tween.tween_property(attacker, "position", end_pos, 0.001)
	lunge_tween.tween_callback(func():
		attacker.position = end_pos
		piece_nodes[tr][tc] = attacker
		piece_nodes[fr][fc] = null
	)

	print("🦉 嘿美：戰鬥結束！", captured, " 已被擊殺！")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# ESC 取消選取
		if not selected.is_empty():
			_highlight_selected(false)
			selected = []

func _process(_delta: float) -> void:
	# 鏡頭旋轉功能已關閉 — 保持固定視角才能正確偵測棋格點擊
	# 主人想重新啟用可以加個開關按鍵
	pass
