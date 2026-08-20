# ChessLogic.gd
# 從 Python 移植過來的西洋棋核心邏輯
# 作者：嘿美 🦉（主人的電競陪玩貓頭鷹）

class_name ChessLogic
extends Node

# 棋盤狀態：8x8 二維陣列
# 大寫 = 白方, 小寫 = 黑方, "." = 空
var board: Array = []
var current_turn: String = "white"
var move_history: Array = []

# 王車易位追蹤
var white_king_moved: bool = false
var black_king_moved: bool = false
var white_rook_h_moved: bool = false  # h1 車
var white_rook_a_moved: bool = false  # a1 車
var black_rook_h_moved: bool = false  # h8 車
var black_rook_a_moved: bool = false  # a8 車

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
	# 重置易位狀態
	white_king_moved = false
	black_king_moved = false
	white_rook_h_moved = false
	white_rook_a_moved = false
	black_rook_h_moved = false
	black_rook_a_moved = false

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
			# ⭐ 修法 1：兵第一步可走兩格
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

		# ⭐ 王車易位（簡化版）
		# 條件：1) 王沒動過 2) 車沒動過 3) 中間無子 4) 王/經過/落點不被攻擊
		if color == "white":
			if not white_king_moved and r == 7 and c == 4:
				# 短易位：h1 車
				if not white_rook_h_moved and board[7][5] == "." and board[7][6] == ".":
					if not _square_attacked(7, 4, "black") and not _square_attacked(7, 5, "black") and not _square_attacked(7, 6, "black"):
						moves.append([7, 6])  # 王到 g1
				# 長易位：a1 車
				if not white_rook_a_moved and board[7][1] == "." and board[7][2] == "." and board[7][3] == ".":
					if not _square_attacked(7, 4, "black") and not _square_attacked(7, 3, "black") and not _square_attacked(7, 2, "black"):
						moves.append([7, 2])  # 王到 c1
		else:  # black
			if not black_king_moved and r == 0 and c == 4:
				if not black_rook_h_moved and board[0][5] == "." and board[0][6] == ".":
					if not _square_attacked(0, 4, "white") and not _square_attacked(0, 5, "white") and not _square_attacked(0, 6, "white"):
						moves.append([0, 6])  # 王到 g8
				if not black_rook_a_moved and board[0][1] == "." and board[0][2] == "." and board[0][3] == ".":
					if not _square_attacked(0, 4, "white") and not _square_attacked(0, 3, "white") and not _square_attacked(0, 2, "white"):
						moves.append([0, 2])  # 王到 c8

	return moves

func _is_friendly(p: String, color: String) -> bool:
	if p == ".":
		return false
	if color == "white":
		return p == p.to_upper()
	else:
		return p == p.to_lower()

# 檢查 (sr, sc) 是否被 by_color 攻擊（王車易位用）
func _square_attacked(sr: int, sc: int, by_color: String) -> bool:
	for r in range(8):
		for c in range(8):
			var p: String = board[r][c]
			if p == ".":
				continue
			var pcolor: String = "white" if p == p.to_upper() else "black"
			if pcolor != by_color:
				continue
			var t: String = p.to_lower()
			match t:
				"p":
					var dir: int = -1 if by_color == "white" else 1
					if sr == r + dir and (sc == c - 1 or sc == c + 1):
						return true
				"n":
					var km: Array = [[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]]
					for m in km:
						if sr == r + m[0] and sc == c + m[1]:
							return true
				"b":
					if _check_line_attack(r, c, sr, sc, [[-1,-1],[-1,1],[1,-1],[1,1]]):
						return true
				"r":
					if _check_line_attack(r, c, sr, sc, [[-1,0],[1,0],[0,-1],[0,1]]):
						return true
				"q":
					if _check_line_attack(r, c, sr, sc, [[-1,-1],[-1,1],[1,-1],[1,1],[-1,0],[1,0],[0,-1],[0,1]]):
						return true
				"k":
					for dr in [-1, 0, 1]:
						for dc in [-1, 0, 1]:
							if dr == 0 and dc == 0:
								continue
							if sr == r + dr and sc == c + dc:
								return true
	return false

func _check_line_attack(r: int, c: int, sr: int, sc: int, dirs: Array) -> bool:
	for d in dirs:
		var nr: int = r + d[0]
		var nc: int = c + d[1]
		while in_bounds(nr, nc):
			if nr == sr and nc == sc:
				return true
			if board[nr][nc] != ".":
				break
			nr += d[0]
			nc += d[1]
	return false

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

	# ⭐ 王車易位：把車一起搬
	if piece.to_lower() == "k" and abs(tc - fc) == 2 and fr == tr:
		# 短易位：王從 e 到 g（col 4 → 6），車從 h 移到 f（col 7 → 5）
		if tc == 6 and board[tr][7] == ("R" if color == "white" else "r"):
			board[tr][5] = board[tr][7]
			board[tr][7] = "."
			if color == "white":
				white_rook_h_moved = true
			else:
				black_rook_h_moved = true
		# 長易位：王從 e 到 c（col 4 → 2），車從 a 移到 d（col 0 → 3）
		elif tc == 2 and board[tr][0] == ("R" if color == "white" else "r"):
			board[tr][3] = board[tr][0]
			board[tr][0] = "."
			if color == "white":
				white_rook_a_moved = true
			else:
				black_rook_a_moved = true

	# 兵升變（簡化：到底線自動變后）
	if piece.to_lower() == "p" and (tr == 0 or tr == 7):
		if piece == piece.to_upper():
			board[tr][tc] = "Q"
		else:
			board[tr][tc] = "q"

	# ⭐ 追蹤王/車是否移動
	if piece == "K":
		white_king_moved = true
	elif piece == "k":
		black_king_moved = true
	elif piece == "R":
		if color == "white" and fc == 0:
			white_rook_a_moved = true
		elif color == "white" and fc == 7:
			white_rook_h_moved = true
	elif piece == "r":
		if color == "black" and fc == 0:
			black_rook_a_moved = true
		elif color == "black" and fc == 7:
			black_rook_h_moved = true

	move_history.append({"from": [fr, fc], "to": [tr, tc], "captured": captured})
	if current_turn == "white":
		current_turn = "black"
	else:
		current_turn = "white"
	return {"ok": true, "captured": captured}