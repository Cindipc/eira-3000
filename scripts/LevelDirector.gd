extends Node

@export var total_resolutions: int = 6
@export var combat_after: int = 3
@export var max_alive: int = 6
@export var level_index: int = 1
@export var android_scene: PackedScene = null
@export var boss_scene: PackedScene = null
@export var projectile_scene: PackedScene = null

var terminals: Array[Node] = []
var files: Array[Node] = []
var barriers: Array[Node] = []
var spawn_points: Array[Node3D] = []
var boss_spawn_point: Node3D = null

var _combat_started := false
var _boss_spawned := false
var _spawn_timer := 0.0
var _wave_index := 0
var _active_terminal: Node = null
var _exit_activated := false
var _check_pending := false

func _ready() -> void:
	add_to_group("level_director")
	_collect()
	GameState.reset_level(level_index, total_resolutions, files.size())
	GameState.resolution_solved.connect(_on_resolution_solved)
	GameState.boss_defeated.connect(_on_boss_defeated)
	GameState.files_changed.connect(_on_files_changed)
	_refresh_active_terminal()

func _collect() -> void:
	terminals.clear()
	for t in get_tree().get_nodes_in_group("terminal"):
		terminals.append(t)
	terminals.sort_custom(func(a, b): return int(a.index) < int(b.index))
	files.clear()
	for f in get_tree().get_nodes_in_group("data_file"):
		files.append(f)
	barriers.clear()
	for b in get_tree().get_nodes_in_group("barrier"):
		barriers.append(b)
	spawn_points.clear()
	var holder := get_parent().get_node_or_null("SpawnPoints")
	if holder:
		for s in holder.get_children():
			if s is Node3D:
				spawn_points.append(s as Node3D)
	var marker := get_parent().get_node_or_null("BossSpawn")
	if marker is Node3D:
		boss_spawn_point = marker as Node3D

func _refresh_active_terminal() -> void:
	_active_terminal = null
	for t in terminals:
		if not is_instance_valid(t):
			continue
		if not t.solved:
			_active_terminal = t
			break
	_update_beacons()
	_update_objective()

func _update_beacons() -> void:
	_prune_files()
	var active_codes: Array[String] = []
	var next_codes: Array[String] = []
	var found_active := false
	for t in terminals:
		if not is_instance_valid(t):
			continue
		if t.solved:
			continue
		if t == _active_terminal:
			found_active = true
			active_codes.append_array(t.required_codes)
		elif found_active:
			next_codes.append_array(t.required_codes)
	for f in files:
		if not is_instance_valid(f):
			continue
		var code: String = f.code
		f.set_beacon(active_codes.has(code) or next_codes.has(code))

func _prune_files() -> void:
	for i in range(files.size() - 1, -1, -1):
		if not is_instance_valid(files[i]):
			files.remove_at(i)

func _update_objective() -> void:
	if _active_terminal == null or not is_instance_valid(_active_terminal):
		if GameState.boss_active:
			GameState.set_objective("OBJETIVO: Destruye la Máquina Analítica")
		elif _combat_started:
			GameState.set_objective("OBJETIVO: Elimina a los androides de seguridad")
		else:
			GameState.set_objective("OBJETIVO: Analiza los datos del nivel")
		return
	var missing: Array[String] = _active_terminal.missing_codes()
	var text := "RESOLUCIÓN %d/%d - %s" % [_active_terminal.index + 1, total_resolutions, _active_terminal.display_name]
	if missing.is_empty():
		text += " | Pulsa [E] en el terminal"
	else:
		text += " | Archivos pendientes: %s" % ", ".join(missing)
	GameState.set_objective(text)

func _on_files_changed(_collected: int, _total: int) -> void:
	_prune_files()
	if _active_terminal and is_instance_valid(_active_terminal):
		_active_terminal.update_prompt()
	_update_objective()

func _on_resolution_solved(count: int, _total: int) -> void:
	_open_barriers(count)
	if count >= combat_after and not _combat_started:
		_start_combat()
	if count >= total_resolutions and not _boss_spawned and boss_scene != null:
		_spawn_boss()
	_refresh_active_terminal()
	call_deferred("_check_exit", 0.3)

func _open_barriers(count: int) -> void:
	for b in barriers:
		if b.requires_boss:
			continue
		if count >= b.required_resolutions and not b.is_open:
			b.open_barrier()
			GameState.notify("Barrera deshabilitada", Color(0.4, 1.0, 0.7))

func _start_combat() -> void:
	_combat_started = true
	GameState.start_combat()
	GameState.set_prompt("")
	GameState.notify("ADVERTENCIA: sistemas de seguridad en línea", Color(1.0, 0.5, 0.35))
	_spawn_timer = 2.0
	for i in 2:
		_spawn_android()
	call_deferred("_check_exit", 0.5)

func _check_exit(delay := 0.0) -> void:
	if delay > 0.0:
		if not is_inside_tree():
			return
		await get_tree().create_timer(delay).timeout
		if not is_inside_tree():
			return
	_check_pending = false
	if _exit_activated or not _combat_started:
		return
	if get_tree().get_nodes_in_group("android").size() > 0:
		return
	if GameState.boss_active:
		return
	_activate_exit()

var _spawned_total := 0

func _process(delta: float) -> void:
	if _combat_started and not _boss_spawned and GameState.resolutions_solved < GameState.resolutions_total:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = maxf(2.5, 6.0 - 0.5 * GameState.resolutions_solved)
			var alive := get_tree().get_nodes_in_group("android").size()
			var cap := maxi(2, max_alive - int(_wave_index / 3))
			if alive < cap:
				_spawn_android()
				_wave_index += 1
	if _exit_activated or not _combat_started or _check_pending:
		return
	_check_pending = true
	call_deferred("_check_exit", 0.25)

func _spawn_android() -> void:
	if android_scene == null:
		android_scene = load("res://scenes/Android.tscn") as PackedScene
	if android_scene == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	if spawn_points.is_empty():
		var dummy := Node3D.new()
		var ang := randf() * TAU
		dummy.global_position = player.global_position + Vector3(cos(ang) * 12, 2.0, sin(ang) * 12)
		get_tree().current_scene.add_child(dummy)
		spawn_points = [dummy]
	var best: Node3D = null
	var best_score := -1.0e9
	for s in spawn_points:
		var d := s.global_position.distance_to(player.global_position)
		var score := -absf(d - 26.0)
		if d < 14.0:
			score -= 50.0
		score += randf() * 6.0
		if score > best_score:
			best_score = score
			best = s
	if best == null:
		return
	var base_pos := best.global_position + Vector3(0, 2.0, 0)
	var count := 1
	if GameState.resolutions_solved >= maxi(2, GameState.resolutions_total - 1):
		count = 2
	for i in range(count):
		var android := android_scene.instantiate() as Node3D
		android.set("projectile_scene", load("res://scenes/Projectile.tscn"))
		get_tree().current_scene.add_child(android)
		var offset := Vector3(randf_range(-0.8, 0.8), randf_range(-0.2, 0.2), randf_range(-0.8, 0.8))
		android.global_position = base_pos + offset
		if randf() < 0.3:
			android.setup(1, 70.0, 2.8, 9.0, false)
		else:
			android.setup(0, 35.0, 3.4, 6.0, true)

func _spawn_boss() -> void:
	if _boss_spawned or boss_scene == null:
		return
	_boss_spawned = true
	var pos := Vector3(124.0, 0.0, 0.0)
	if boss_spawn_point:
		pos = boss_spawn_point.global_position
	var boss := boss_scene.instantiate() as Node3D
	boss.set("projectile_scene", projectile_scene)
	boss.set("android_scene", android_scene)
	get_tree().current_scene.add_child(boss)
	boss.global_position = pos
	GameState.set_objective("OBJETIVO: Destruye la Máquina Analítica")

func _on_boss_defeated() -> void:
	for b in barriers:
		if b.requires_boss and not b.is_open:
			b.open_barrier()
			GameState.notify("Acceso al nivel 2 desbloqueado", Color(0.4, 1.0, 0.8))
	_activate_exit(true)

func _activate_exit(force := false) -> void:
	if _exit_activated:
		return
	for e in get_tree().get_nodes_in_group("level_exit"):
		if not e.has_method("activate") or bool(e.get("enabled")):
			continue
		if not force and bool(e.get("requires_boss")) and GameState.boss_active:
			continue
		e.call("activate")
		_exit_activated = true
		GameState.notify("Salida desbloqueada", Color(0.4, 1.0, 0.8))
		GameState.set_objective("OBJETIVO: Alcanza la salida del nivel")
