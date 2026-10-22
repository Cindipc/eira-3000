extends CanvasLayer

@onready var resolutions_label: Label = $Root/TopLeft/Resolutions
@onready var files_label: Label = $Root/TopLeft/Files
@onready var level_label: Label = $Root/TopLeft/Level
@onready var health_bar: ProgressBar = $Root/TopRight/HealthBar
@onready var health_label: Label = $Root/TopRight/HealthLabel
@onready var ammo_label: Label = $Root/TopRight/Ammo
@onready var objective_label: Label = $Root/Bottom/Objective
@onready var prompt_label: Label = $Root/Center/Prompt
@onready var message_label: Label = $Root/Message
@onready var crosshair: Control = $Root/Center/Crosshair
@onready var hit_marker: Label = $Root/Center/HitMarker
@onready var boss_panel: Control = $Root/Boss
@onready var boss_bar: ProgressBar = $Root/Boss/BossBar
@onready var boss_label: Label = $Root/Boss/BossLabel

var lives_label: Label
var points_label: Label
var points_value: int = 0
var energy_label: Label
var energy_bar: ProgressBar
var mission_label: Label
var game_over_panel: Control
var game_over_stats: Label
var exit_hint: Label

var _message_time := 0.0
var _hit_time := 0.0
var _crosshair_color := Color(0.6, 0.95, 1.0)
var _points_flash := 0.0
var _heartbeat := 0.0
var _game_over := false
var _hint_time := 0.0

func _ready() -> void:
	_build_extras()
	_build_game_over()
	GameState.resolution_solved.connect(_on_resolutions)
	GameState.files_changed.connect(_on_files)
	GameState.health_changed.connect(_on_health)
	GameState.ammo_changed.connect(_on_ammo)
	GameState.objective_changed.connect(_on_objective)
	GameState.message.connect(_on_message)
	GameState.prompt_changed.connect(_on_prompt)
	GameState.boss_spawned.connect(_on_boss_spawned)
	GameState.boss_health_changed.connect(_on_boss_health)
	GameState.boss_defeated.connect(_on_boss_defeated)
	GameState.lives_changed.connect(_on_lives)
	GameState.points_changed.connect(_on_points)
	GameState.energy_changed.connect(_on_energy)
	GameState.mission_changed.connect(_on_mission)
	GameState.level_changed.connect(_on_level)
	GameState.game_over.connect(_on_game_over)
	GameState.level_finished.connect(_on_level_finished)
	boss_panel.visible = false
	_on_resolutions(GameState.resolutions_solved, GameState.resolutions_total)
	_on_files(GameState.files_collected.size(), GameState.files_total)
	_on_lives(GameState.lives, GameState.max_lives)
	_on_points(GameState.points, 0, "")
	_on_energy(GameState.energy, GameState.max_energy, GameState.energy_enabled)
	_on_mission(GameState.mission_index + 1, GameState.missions.size(), GameState.current_mission())
	level_label.text = "NIVEL %d" % GameState.current_level

func _build_extras() -> void:
	var top_left: Control = get_node("Root/TopLeft")
	top_left.offset_bottom = 168.0
	lives_label = _make_label(top_left, 88, Color(1.0, 0.55, 0.6))
	lives_label.text = "VIDAS  " + _hearts(GameState.lives)
	points_label = _make_label(top_left, 116, Color(1.0, 0.85, 0.35))
	points_label.text = "PUNTOS  0"
	points_label.add_theme_font_size_override("font_size", 24)

	ammo_label.visible = false
	var top_right: Control = get_node("Root/TopRight")
	top_right.offset_bottom = 150.0
	energy_bar = ProgressBar.new()
	energy_bar.name = "EnergyBar"
	energy_bar.layout_mode = 0
	energy_bar.offset_top = 56.0
	energy_bar.offset_right = 270.0
	energy_bar.offset_bottom = 83.0
	energy_bar.show_percentage = false
	energy_bar.max_value = 100.0
	energy_bar.value = 100.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.09, 0.07, 0.13, 0.9)
	bg.set_border_width_all(1)
	bg.border_color = Color(0.35, 0.2, 0.5, 1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.75, 0.35, 1.0, 0.95)
	fill.set_border_width_all(1)
	fill.border_color = Color(0.35, 0.2, 0.5, 1)
	energy_bar.add_theme_stylebox_override("background", bg)
	energy_bar.add_theme_stylebox_override("fill", fill)
	top_right.add_child(energy_bar)

	energy_label = _make_label(top_right, 88, Color(0.85, 0.6, 1.0))
	energy_label.text = "ENERGÍA CARDÍACA  100 / 100"

	# linea de mision (por encima del objetivo)
	mission_label = Label.new()
	mission_label.name = "Mission"
	mission_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	mission_label.offset_top = -104.0
	mission_label.offset_bottom = -70.0
	mission_label.offset_right = 1600.0
	mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_label.add_theme_font_size_override("font_size", 20)
	mission_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	mission_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	mission_label.add_theme_constant_override("shadow_offset_x", 2)
	mission_label.add_theme_constant_override("shadow_offset_y", 2)
	mission_label.visible = false
	add_child(mission_label)

	# indicador de la salida (distancia y direccion) cuando esta desbloqueada
	exit_hint = Label.new()
	exit_hint.name = "ExitHint"
	exit_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	exit_hint.offset_top = -142.0
	exit_hint.offset_bottom = -110.0
	exit_hint.offset_right = 1600.0
	exit_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exit_hint.add_theme_font_size_override("font_size", 22)
	exit_hint.add_theme_color_override("font_color", Color(0.4, 1.0, 0.8))
	exit_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	exit_hint.add_theme_constant_override("shadow_offset_x", 2)
	exit_hint.add_theme_constant_override("shadow_offset_y", 2)
	exit_hint.visible = false
	add_child(exit_hint)

func _build_game_over() -> void:
	game_over_panel = Control.new()
	game_over_panel.name = "GameOver"
	game_over_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_panel.visible = false
	add_child(game_over_panel)

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.02, 0.01, 0.04, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_panel.add_child(bg)

	var title := Label.new()
	title.name = "Title"
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.offset_top = -130.0
	title.offset_bottom = -50.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.32, 0.38))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.text = "FIN DE PARTIDA"
	game_over_panel.add_child(title)

	game_over_stats = Label.new()
	game_over_stats.name = "Stats"
	game_over_stats.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_stats.offset_top = -40.0
	game_over_stats.offset_bottom = 60.0
	game_over_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_stats.add_theme_font_size_override("font_size", 26)
	game_over_stats.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	game_over_stats.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	game_over_stats.add_theme_constant_override("shadow_offset_x", 2)
	game_over_stats.add_theme_constant_override("shadow_offset_y", 2)
	game_over_panel.add_child(game_over_stats)

func _make_label(parent: Control, top: float, color: Color) -> Label:
	var l := Label.new()
	l.layout_mode = 0
	l.offset_top = top
	l.offset_bottom = top + 26.0
	l.offset_right = 420.0
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(l)
	return l

func _hearts(lives: int) -> String:
	var s := ""
	for i in GameState.max_lives:
		s += "♥ " if i < lives else "· "
	return s.strip_edges()

func _process(delta: float) -> void:
	if _message_time > 0.0:
		_message_time -= delta
		message_label.modulate.a = clampf(_message_time, 0.0, 1.0)
	if _hit_time > 0.0:
		_hit_time -= delta
		hit_marker.modulate.a = clampf(_hit_time * 4.0, 0.0, 1.0)
		var weapon := _find_weapon()
		if weapon:
			var target: Variant = weapon.current_target
			var valid_target: bool = is_instance_valid(target) and target is Node
			var is_enemy: bool = valid_target and target.is_in_group("android")
			if is_enemy:
				_crosshair_color = Color(1.0, 0.45, 0.4)
			elif valid_target and target.is_in_group("boss"):
				_crosshair_color = Color(1.0, 0.7, 0.25)
			else:
				_crosshair_color = Color(0.6, 0.95, 1.0)
	for child in crosshair.get_children():
		if child is ColorRect:
			(child as ColorRect).color = _crosshair_color
	if _points_flash > 0.0:
		_points_flash = maxf(0.0, _points_flash - delta)
		var pulse := 1.0 + _points_flash * 0.35
		points_label.scale = Vector2.ONE * pulse
		points_label.pivot_offset = Vector2(points_label.size.x * 0.0, 12.0)
	_update_critical_lives(delta)
	_hint_time -= delta
	if _hint_time <= 0.0:
		_hint_time = 0.2
		_update_exit_hint()

func _update_exit_hint() -> void:
	if exit_hint == null:
		return
	var target: Node3D = null
	for e in get_tree().get_nodes_in_group("level_exit"):
		if bool(e.get("enabled")):
			target = e
			break
	if target == null:
		exit_hint.visible = false
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		exit_hint.visible = false
		return
	var to_exit := target.global_position - player.global_position
	to_exit.y = 0.0
	var dist := to_exit.length()
	var yaw := 0.0
	var pivot := player.get_node_or_null("CameraPivot") as Node3D
	if pivot:
		yaw = pivot.rotation.y
	var local := Basis(Vector3.UP, yaw).inverse() * to_exit
	var angle := atan2(local.x, -local.z)
	var side := "DELANTE"
	if angle > 2.2 or angle < -2.2:
		side = "DETRAS"
	elif angle > 0.6:
		side = "A LA DERECHA"
	elif angle < -0.6:
		side = "A LA IZQUIERDA"
	exit_hint.visible = true
	exit_hint.text = "SALIDA  %d m  ·  %s" % [int(round(dist)), side]

func _update_critical_lives(delta: float) -> void:
	if lives_label == null:
		return
	if GameState.lives <= 1 and GameState.max_lives > 1:
		_heartbeat += delta
		var beat := absf(sin(_heartbeat * 4.2))
		lives_label.modulate = Color(1.0, 0.35 + 0.25 * beat, 0.4)
		var s := 1.0 + 0.12 * beat
		lives_label.scale = Vector2(s, s)
		lives_label.pivot_offset = Vector2(0.0, 12.0)
	else:
		_heartbeat = 0.0
		lives_label.modulate = Color(1.0, 1.0, 1.0)
		lives_label.scale = Vector2.ONE

func _find_weapon() -> Node:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return null
	return player.get_node_or_null("CameraPivot/Camera3D/Weapon")

func _on_resolutions(current: int, total: int) -> void:
	resolutions_label.text = "RESOLUCIONES  %d / %d" % [current, total]

func _on_files(current: int, total: int) -> void:
	files_label.text = "ARCHIVOS  %d / %d" % [current, total]

func _on_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "INTEGRIDAD  %d" % int(current)

func _on_ammo(_magazine: int, _reserve: int) -> void:
	pass

func _on_lives(current: int, _maximum: int) -> void:
	if lives_label:
		lives_label.text = "VIDAS  " + _hearts(current)

func _on_points(points: int, gained: int, reason: String) -> void:
	points_value = points
	if points_label:
		points_label.text = "PUNTOS  %d" % points
		if gained > 0:
			_points_flash = 0.6
			points_label.modulate = Color(1.0, 1.0, 0.6)
			var badge := points_label.get_node_or_null("Badge") as Label
			if badge:
				badge.queue_free()
			badge = Label.new()
			badge.name = "Badge"
			badge.layout_mode = 0
			badge.offset_top = 0.0
			badge.offset_bottom = 24.0
			badge.offset_left = 170.0
			badge.offset_right = 340.0
			badge.add_theme_font_size_override("font_size", 20)
			badge.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
			badge.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
			badge.text = "+%d %s" % [gained, reason]
			points_label.add_child(badge)
			var tw := badge.create_tween()
			tw.tween_interval(1.4)
			tw.tween_property(badge, "modulate:a", 0.0, 0.5)
			tw.tween_callback(badge.queue_free)

func _on_energy(current: float, maximum: float, enabled: bool) -> void:
	if energy_bar:
		energy_bar.visible = enabled
		energy_bar.max_value = maximum
		energy_bar.value = current
	if energy_label:
		energy_label.visible = enabled
		energy_label.text = "ENERGÍA CARDÍACA  %d / %d" % [int(current), int(maximum)]
		if current <= 1.0:
			energy_label.modulate = Color(1.0, 0.35, 0.4) if int(Time.get_ticks_msec() / 250) % 2 == 0 else Color(1, 1, 1)
		else:
			energy_label.modulate = Color(1, 1, 1)

func _on_mission(index: int, total: int, text: String) -> void:
	if mission_label == null:
		return
	if total <= 0 or text == "":
		mission_label.visible = false
		mission_label.text = ""
		return
	mission_label.visible = true
	mission_label.text = "MISIÓN %d/%d — %s" % [index, total, text]

func _on_objective(text: String) -> void:
	objective_label.text = text

func _on_level(level: int) -> void:
	level_label.text = "NIVEL %d" % level

func _on_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = text != ""

func _on_message(text: String, color: Color) -> void:
	message_label.text = text
	message_label.modulate = color
	message_label.modulate.a = 1.0
	_message_time = 3.2

func _on_boss_spawned(_boss: Node, title: String = "") -> void:
	boss_panel.visible = true
	boss_label.text = title if title != "" else "MÁQUINA GUARDIANA"

func _on_boss_health(current: float, maximum: float) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = current

func _on_boss_defeated() -> void:
	boss_panel.visible = false

func _on_level_finished(level: int) -> void:
	_on_message("NIVEL %d COMPLETADO" % level, Color(0.4, 1.0, 0.8))

func _on_game_over() -> void:
	if _game_over:
		return
	_game_over = true
	if game_over_panel:
		game_over_panel.visible = true
	if game_over_stats:
		game_over_stats.text = "NIVEL %d   ·   PUNTOS %d\n\n[R] Reiniciar el nivel        [ESC] Volver al inicio" % [GameState.current_level, GameState.points]
	GameState.set_prompt("")

func _unhandled_input(event: InputEvent) -> void:
	if not _game_over:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/Intro.tscn")
