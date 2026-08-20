# ChessLogic.gd
# 從 Python 移植過來的西洋棋核心邏輯
# 作者：嘿美 🦉（主人的電競陪玩貓頭鷹）

extends Node

# 棋盤狀態：8x8 二維陣列
# 大寫 = 白方, 小寫 = 黑方, "." = 空
var board: Array = []
var current_turn: String = "white"
var move_history: Array = []

func _ready() -> void:
	reset_board()

func reset_board() -> void:
	board = [
		["r","n","b","q","k","b","n","r"],
		["p","p","p","p","p","p","p","p"],
		[".",".",".",".",".",".",".","."],
		[".",".",".",".",".",".",".","."],
		[".",".",".",".",".",".",".","."],
		[".",".",".",".",".",".",".","."],
		["P","P","P","P","P","P","P","P"],
		["R","N","B","Q","K","B","N","R"],
	]
	current_turn = "white"
	move_history = []

func in_bounds(r: int, c: int) -> bool:
	return r >= 0 and r < 8 and c >= 0 and c < 8

func get_piece(r: int, c: int) -> String:
	if not in_bounds(r, c):
		return "."
	return board[r][c]

func is_white(p: String) -> bool:
	return p != "." and p == p.to_upper()

func is_black(p: String) -> bool:
	return p != "." and p == p.to_lower()

func is_enemy(p: String, color: String) -> bool:
	if p == ".":
		return false
	if color == "white":
		return p == p.to_lower()
	else:
		return p == p.to_upper()

func get_moves(r: int, c: int) -> Array:
	var piece: String = get_piece(r, c)
	if piece == ".":
		return []
	var color: String = "white" if is_white(piece) else "black"
	var t: String = piece.to_lower()
	var moves: Array = []

	if t == "p":
		var direction: int = -1 if color == "white" else 1
		var start_row: int = 6 if color == "white" else 1
		var nr: int = r + direction
		if in_bounds(nr, c) and get_piece(nr, c) == ".":
			moves.append([nr, c])
			var nr2: int = r + 2 * direction
			if r == start_row and get_piece(nr2, c) == ".":
				moves.append([nr2, c])
		for dc in [-1, 1]:
			var ar: int = r + direction
			var ac: int = c + dc
			if in_bounds(ar, ac) and is_enemy(get_piece(ar, ac), color):
				moves.append([ar, ac])

	elif t == "n":
		for d in [[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]]:
			var kr: int = r + d[0]
			var kc: int = c + d[1]
			if in_bounds(kr, kc) and not _is_friendly(get_piece(kr, kc), color):
				moves.append([kr, kc])

	elif t == "b" or t == "r" or t == "q":
		var dirs: Array = []
		if t == "b" or t == "q":
			dirs += [[-1,-1],[-1,1],[1,-1],[1,1]]
		if t == "r" or t == "q":
			dirs += [[-1,0],[1,0],[0,-1],[0,1]]
		for d in dirs:
			var sr: int = r + d[0]
			var sc: int = c + d[1]
			while in_bounds(sr, sc):
				var target: String = get_piece(sr, sc)
				if target == ".":
					moves.append([sr, sc])
				elif is_enemy(target, color):
					moves.append([sr, sc])
					break
				else:
					break
				sr += d[0]
				sc += d[1]

	elif t == "k":
		for dr in [-1, 0, 1]:
			for dc in [-1, 0, 1]:
				if dr == 0 and dc == 0:
					continue
				var mr: int = r + dr
				var mc: int = c + dc
				if in_bounds(mr, mc) and not _is_friendly(get_piece(mr, mc), color):
					moves.append([mr, mc])

	return moves

func _is_friendly(p: String, color: String) -> bool:
	if p == ".":
		return false
	if color == "white":
		return p == p.to_upper()
	else:
		return p == p.to_lower()

func make_move(fr: int, fc: int, tr: int, tc: int) -> Dictionary:
	# 回傳 { ok: bool, captured: String }
	var piece: String = get_piece(fr, fc)
	if piece == ".":
		return {"ok": false, "captured": "."}
	var color: String = "white" if is_white(piece) else "black"
	if color != current_turn:
		return {"ok": false, "captured": "."}
	var all_moves: Array = get_moves(fr, fc)
	if not [tr, tc] in all_moves:
		return {"ok": false, "captured": "."}

	var captured: String = board[tr][tc]
	board[tr][tc] = piece
	board[fr][fc] = "."

	# 兵升變
	if piece.to_lower() == "p" and (tr == 0 or tr == 7):
		if piece == piece.to_upper():
			board[tr][tc] = "Q"
		else:
			board[tr][tc] = "q"

	move_history.append({"from": [fr, fc], "to": [tr, tc], "captured": captured})
	if current_turn == "white":
		current_turn = "black"
	else:
		current_turn = "white"
	return {"ok": true, "captured": captured}