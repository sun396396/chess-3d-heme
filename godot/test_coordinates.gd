extends SceneTree

# 自動測試腳本：模擬點擊棋盤上的每個格子，看 _world_to_cell 對不對

func _initialize() -> void:
	print("=== 嘿美的座標轉換測試 ===")

	# 直接測試 _world_to_cell 函式（從 Board3D.gd 複製邏輯）
	const CELL_SIZE := 1.2
	const BOARD_ORIGIN := Vector3(-4.2, 0, -4.2)

	# 模擬棋盤左下角 (row=7, col=0) — 白方 a1 應該在最近
	var test_positions = [
		# (world_x, world_z, 預期 row, 預期 col, 描述)
		[-4.2,  -4.2,  7, 0, "a1 (白方最近左角)"],
		[-3.0,  -4.2,  7, 1, "b1 (白方第二格)"],
		[ 4.2,  -4.2,  7, 7, "h1 (白方最近右角)"],
		[-4.2,   4.2,  0, 0, "a8 (黑方最遠左角)"],
		[ 4.2,   4.2,  0, 7, "h8 (黑方最遠右角)"],
		[-0.6,   0.6,  3, 3, "d5 (棋盤中央)"],
		[-4.2,  -3.0,  6, 0, "a2 (白方第二排)"],
	]

	var all_pass := true
	for test in test_positions:
		var wx: float = test[0]
		var wz: float = test[1]
		var exp_r: int = test[2]
		var exp_c: int = test[3]
		var desc: String = test[4]

		var world_pos := Vector3(wx, 0, wz)
		var c: int = int(round((world_pos.x - BOARD_ORIGIN.x) / CELL_SIZE))
		var r_inv: int = int(round((world_pos.z - BOARD_ORIGIN.z) / CELL_SIZE))
		var r: int = 7 - r_inv

		var ok: bool = (r == exp_r and c == exp_c)
		var status: String = "✅" if ok else "❌"
		print("%s %s: world(%.1f, %.1f) → cell(%d, %d)  [預期 (%d, %d)]" % [status, desc, wx, wz, r, c, exp_r, exp_c])
		if not ok:
			all_pass = false

	print("")
	if all_pass:
		print("🎉 全部通過！座標轉換正確")
	else:
		print("❌ 有失敗！需要修 _world_to_cell")
	quit()