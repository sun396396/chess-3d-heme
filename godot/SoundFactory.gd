# SoundFactory.gd
# 用程式合成即時音效（不需要任何外部音檔！）
# 作者：嘿美 🦉

# 注意：不宣告 class_name，避免 autoload 衝突
extends Node

# 音效類型
enum SoundType {
	MOVE,           # 棋子移動（低沉腳步）
	CAPTURE_SWORD,  # 劍斬擊（狼騎士）
	CAPTURE_CLAW,   # 利爪撕裂（蜘蛛）
	CAPTURE_SMASH,  # 重擊（巨人）
	CAPTURE_FIRE,   # 火焰爆裂（龍王）
	CAPTURE_MAGIC,  # 魔法光球（巨魔）
	CAPTURE_BITE,   # 咬擊（小狼）
	DEATH,          # 死亡（嘶吼）
	CHECK,          # 將軍警告
	VICTORY,        # 勝利音效
	UI_CLICK,       # UI 點擊
}

# 用 AudioStreamPlayer + AudioStreamGenerator 程式合成波形
# 支援單聲道, 22050Hz (省資源)

const SAMPLE_RATE := 22050

static func play_sound(sound_type: SoundType, position: Vector3 = Vector3.ZERO, parent: Node = null) -> AudioStreamPlayer3D:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.position = position
	if parent:
		parent.add_child(player)
	else:
		var current: Node = tree.current_scene
		if current == null:
			player.queue_free()
			return null
		current.add_child(player)

	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = 0.5
	player.stream = stream
	player.volume_db = -5.0
	player.bus = "SFX"
	player.play()

	# 同步填充緩衝區
	_fill_buffer_sync(player, sound_type)
	return player

static func _fill_buffer_sync(player: AudioStreamPlayer3D, sound_type: SoundType) -> void:
	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	var duration: float = _get_duration(sound_type)
	var total_samples: int = int(duration * SAMPLE_RATE)

	match sound_type:
		SoundType.MOVE:
			_emit_move(playback, total_samples)
		SoundType.CAPTURE_SWORD, SoundType.CAPTURE_BITE:
			_emit_sword_slash(playback, total_samples)
		SoundType.CAPTURE_CLAW:
			_emit_claw(playback, total_samples)
		SoundType.CAPTURE_SMASH:
			_emit_smash(playback, total_samples)
		SoundType.CAPTURE_FIRE:
			_emit_fire(playback, total_samples)
		SoundType.CAPTURE_MAGIC:
			_emit_magic(playback, total_samples)
		SoundType.DEATH:
			_emit_death(playback, total_samples)
		SoundType.CHECK:
			_emit_check(playback, total_samples)
		SoundType.VICTORY:
			_emit_victory(playback, total_samples)
		SoundType.UI_CLICK:
			_emit_click(playback, total_samples)

	# 用 Timer 自動清除播放器
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree:
		var t: SceneTreeTimer = tree.create_timer(duration + 0.1)
		# 用 call_deferred 排程清理
		player.set_meta("_cleanup_time", duration + 0.1)

static func _get_duration(sound_type: SoundType) -> float:
	match sound_type:
		SoundType.MOVE: return 0.15
		SoundType.CAPTURE_SWORD, SoundType.CAPTURE_BITE: return 0.35
		SoundType.CAPTURE_CLAW: return 0.4
		SoundType.CAPTURE_SMASH: return 0.5
		SoundType.CAPTURE_FIRE: return 0.6
		SoundType.CAPTURE_MAGIC: return 0.5
		SoundType.DEATH: return 0.8
		SoundType.CHECK: return 0.6
		SoundType.VICTORY: return 1.5
		SoundType.UI_CLICK: return 0.05
	return 0.3

# === 各類音效的波形合成 ===

static func _emit_move(p: AudioStreamGeneratorPlayback, total: int) -> void:
	# 低頻腳步：100Hz → 80Hz 快速衰減
	for i in total:
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(total)
		var envelope: float = (1.0 - progress) * (1.0 - progress)
		var freq: float = lerp(100.0, 80.0, progress)
		var sample: float = sin(t * TAU * freq) * envelope * 0.3
		sample += randf_range(-0.05, 0.05) * envelope
		p.push_frame(Vector2(sample, sample))

static func _emit_sword_slash(p: AudioStreamGeneratorPlayback, total: int) -> void:
	# 金屬斬擊：白噪音掃過高通濾波器
	for i in total:
		var progress: float = float(i) / float(total)
		var envelope: float = sin(progress * PI) * 0.6  # 中段最強
		# 噪音 + 銳利金屬諧波
		var noise: float = randf_range(-1, 1)
		var metallic: float = sin(progress * TAU * 20.0) * 0.4
		var freq_sweep: float = lerp(2000.0, 800.0, progress)
		var tone: float = sin(float(i) / SAMPLE_RATE * TAU * freq_sweep)
		var sample: float = (noise * 0.5 + metallic + tone * 0.3) * envelope
		p.push_frame(Vector2(sample, sample))

static func _emit_claw(p: AudioStreamGeneratorPlayback, total: int) -> void:
	# 撕裂音：3 次快速刮擦
	var scratch_length := total / 3
	for scratch in 3:
		for i in scratch_length:
			var t_in_scratch: float = float(i) / float(scratch_length)
			var envelope: float = (1.0 - t_in_scratch) * 0.5
			var noise: float = randf_range(-1, 1)
			var high_freq: float = sin(t_in_scratch * TAU * 30.0) * 0.5
			var sample: float = (noise * 0.7 + high_freq) * envelope
			var idx: int = scratch * scratch_length + i
			if idx < total:
				p.push_frame(Vector2(sample, sample))

static func _emit_smash(p: AudioStreamGeneratorPlayback, total: int) -> void:
	# 重擊：低頻爆炸 + 高頻撞擊
	for i in total:
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(total)
		# 低頻爆炸（衰減快）
		var boom: float = sin(t * TAU * 60.0) * exp(-t * 8.0) * 0.8
		# 高頻撞擊（瞬間）
		var crash: float = randf_range(-1, 1) * exp(-t * 30.0) * 0.6
		# 餘震
		var rumble: float = sin(t * TAU * 40.0) * (1.0 - progress) * 0.3
		var sample: float = boom + crash + rumble
		p.push_frame(Vector2(sample, sample))

static func _emit_fire(p: AudioStreamGeneratorPlayback, total: int) -> void:
	# 火焰爆裂：噪音 + 低頻咆哮
	for i in total:
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(total)
		# 噪音火焰
		var noise: float = randf_range(-1, 1) * 0.4
		# 低頻咆哮
		var roar: float = sin(t * TAU * lerp(80.0, 50.0, progress)) * 0.5
		var envelope: float = sin(progress * PI) * 0.7
		var crackle: float = 0.0
		if randf() < 0.1:
			crackle = randf_range(-0.5, 0.5) * envelope
		var sample: float = (noise + roar + crackle) * envelope
		p.push_frame(Vector2(sample, sample))

static func _emit_magic(p: AudioStreamGeneratorPlayback, total: int) -> void:
	# 魔法：上掃頻 + 鈴鐺諧波
	for i in total:
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(total)
		# 從低頻掃到高頻
		var freq: float = lerp(200.0, 1500.0, progress)
		var sweep: float = sin(t * TAU * freq) * 0.4
		# 鈴鐺諧波（奇數倍頻）
		var bell: float = sin(t * TAU * freq * 2.7) * 0.2 + sin(t * TAU * freq * 5.3) * 0.1
		var envelope: float = sin(progress * PI) * 0.5
		# 結尾華麗泛音
		var sparkle: float = 0.0
		if progress > 0.7:
			sparkle = sin(t * TAU * 3000.0) * 0.15 * (1.0 - progress) * 4.0
		var sample: float = (sweep + bell + sparkle) * envelope
		p.push_frame(Vector2(sample, sample))

static func _emit_death(p: AudioStreamGeneratorPlayback, total: int) -> void:
	# 死亡嘶吼：下滑頻 + 噪音
	for i in total:
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(total)
		# 從高頻滑到低頻
		var freq: float = lerp(400.0, 80.0, progress)
		var howl: float = sin(t * TAU * freq) * 0.5
		# 噪音喘息
		var breath: float = randf_range(-1, 1) * 0.2 * (1.0 - progress)
		# 衰減包絡
		var envelope: float = (1.0 - progress) * 0.6
		var sample: float = (howl + breath) * envelope
		p.push_frame(Vector2(sample, sample))

static func _emit_check(p: AudioStreamGeneratorPlayback, total: int) -> void:
	# 將軍警告：3 聲急促鐘響
	var bell_length := total / 3
	for bell_idx in 3:
		for i in bell_length:
			var t: float = float(i) / SAMPLE_RATE
			var progress: float = float(i) / float(bell_length)
			# 鐘聲諧波
			var fundamental: float = sin(t * TAU * 800.0) * 0.4
			var overtone1: float = sin(t * TAU * 1600.0) * 0.2
			var overtone2: float = sin(t * TAU * 2400.0) * 0.1
			var envelope: float = exp(-t * 4.0) * 0.6
			var sample: float = (fundamental + overtone1 + overtone2) * envelope
			var idx: int = bell_idx * bell_length + i
			if idx < total:
				p.push_frame(Vector2(sample, sample))

static func _emit_victory(p: AudioStreamGeneratorPlayback, total: int) -> void:
	# 勝利：上升三和弦
	# C-E-G 上行，每個音 0.4 秒
	var notes := [261.63, 329.63, 392.0, 523.25]  # C4 E4 G4 C5
	var note_length := total / notes.size()
	for note_idx in notes.size():
		var freq: float = notes[note_idx]
		for i in note_length:
			var t: float = float(i) / SAMPLE_RATE
			var progress: float = float(i) / float(note_length)
			# 主音 + 泛音
			var tone: float = sin(t * TAU * freq) * 0.4
			var harm: float = sin(t * TAU * freq * 2.0) * 0.15
			var envelope: float = sin(progress * PI) * 0.6
			var sample: float = (tone + harm) * envelope
			var idx: int = note_idx * note_length + i
			if idx < total:
				p.push_frame(Vector2(sample, sample))

static func _emit_click(p: AudioStreamGeneratorPlayback, total: int) -> void:
	# UI 點擊：短促高音
	for i in total:
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(total)
		var envelope: float = (1.0 - progress) * (1.0 - progress)
		var click: float = sin(t * TAU * 1500.0) * envelope * 0.4
		var sample: float = click
		p.push_frame(Vector2(sample, sample))

# === 高階 API：依怪獸類型自動選對的音效 ===
static func play_capture_sound(monster_type: String, position: Vector3 = Vector3.ZERO) -> void:
	var sound: SoundType = _type_to_capture_sound(monster_type)
	play_sound(sound, position)

static func _type_to_capture_sound(monster_type: String) -> SoundType:
	match monster_type:
		"dragon": return SoundType.CAPTURE_FIRE
		"spider": return SoundType.CAPTURE_CLAW
		"golem": return SoundType.CAPTURE_SMASH
		"troll": return SoundType.CAPTURE_MAGIC
		"wolf_knight": return SoundType.CAPTURE_SWORD
		"wolf_pup": return SoundType.CAPTURE_BITE
	return SoundType.CAPTURE_SWORD