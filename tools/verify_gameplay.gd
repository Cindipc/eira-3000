extends RefCounted

var tree: SceneTree
var level: Node
var failures: Array[String] = []
var config := {}
var exp := {"scene": "res://scenes/Level1.tscn", "terminals": 6, "files": 14, "barriers": 4, "boss": true, "level": 1}

func configure(cfg: Dictionary) -> void:
	config = cfg
	for k in config.keys():
		if not exp.has(k):
			continue
		var v: Variant = config[k]
		if v is String:
			var s := String(v)
			if s == "true":
				exp[k] = true
			elif s == "false":
				exp[k] = false
			elif s.is_valid_int():
				exp[k] = int(s)
			elif s.is_valid_float():
				exp[k] = float(s)
			else:
				exp[k] = s
		else:
			exp[k] = v

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	print("[verify] escena=%s nivel=%s" % [str(exp["scene"]), str(exp["level"])])
	if tree.current_scene != null:
		if str(exp["scene"]) == str(tree.current_scene.scene_file_path):
			level = tree.current_scene
		else:
			var old := tree.current_scene
			tree.current_scene = null
			tree.root.remove_child(old)
			for n in _all_nodes(old):
				for g in n.get_groups():
					n.remove_from_group(g)
			old.queue_free()
	if level == null:
		level = (load(str(exp["scene"])) as PackedScene).instantiate()
		tree.root.add_child(level)
	tree.current_scene = level
	await tree.process_frame
	await tree.physics_frame
	await tree.process_frame

	_check_structure()
	await _check_ground()
	await _simulate_puzzles()
	await _check_combat()
	if bool(exp["boss"]):
		await _check_boss()
	else:
		await _check_exit_no_boss()
	_report()

func _all_nodes(root: Node) -> Array:
	var out: Array = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		out.append(cur)
		for c in cur.get_children():
			stack.append(c)
	return out

func _fail(msg: String) -> void:
	failures.append(msg)
	print("  FAIL: ", msg)

func _ok(msg: String) -> void:
	print("  ok: ", msg)

func _check_structure() -> void:
	print("[structure]")
	var terminals := tree.get_nodes_in_group("terminal")
	var files := tree.get_nodes_in_group("data_file")
	var barriers := tree.get_nodes_in_group("barrier")
	if terminals.size() == int(exp["terminals"]):
		_ok("%d terminales de resolución" % terminals.size())
	else:
		_fail("terminales=%d (se esperaban %d)" % [terminals.size(), int(exp["terminals"])])
	if files.size() == int(exp["files"]):
		_ok("%d archivos repartidos por el nivel" % files.size())
	else:
		_fail("archivos=%d (se esperaban %d)" % [files.size(), int(exp["files"])])
	if barriers.size() == int(exp["barriers"]):
		_ok("%d barreras de progresión" % barriers.size())
	else:
		_fail("barreras=%d (se esperaban %d)" % [barriers.size(), int(exp["barriers"])])
	var player := tree.get_first_node_in_group("player")
	if player == null:
		_fail("no hay jugador")
		return
	var weapon := player.get_node_or_null("CameraPivot/Camera3D/Weapon")
	if weapon and weapon.get_child_count() > 0:
		_ok("arma equipada con %d nodos" % weapon.get_child_count())
	else:
		_fail("arma no encontrada en la cámara")
	var hud := level.get_node_or_null("HUD")
	if hud:
		_ok("HUD presente")
	else:
		_fail("HUD ausente")
	var director := level.get_node_or_null("Gameplay/LevelDirector")
	if director:
		_ok("director de nivel presente")
	else:
		_fail("director de nivel ausente")
	var exits := tree.get_nodes_in_group("level_exit")
	if exits.size() == 1:
		_ok("portal de salida presente")
	else:
		_fail("salidas=%d" % exits.size())

func _check_ground() -> void:
	print("[suelo]")
	var player := tree.get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var start := player.global_position
	for i in 30:
		await tree.physics_frame
	var after := player.global_position
	if after.y > start.y - 3.0:
		_ok("la jugadora se mantiene sobre el suelo (y=%.2f -> %.2f)" % [start.y, after.y])
	else:
		_fail("la jugadora cayó por el suelo (%.2f -> %.2f)" % [start.y, after.y])

func _simulate_puzzles() -> void:
	print("[puzzles]")
	var terminals := tree.get_nodes_in_group("terminal")
	terminals.sort_custom(func(a, b): return int(a.index) < int(b.index))
	var player := tree.get_first_node_in_group("player") as Node3D
	for t in terminals:
		for code in t.required_codes:
			GameState.collect_file(code)
		player.global_position = t.global_position + Vector3(0, 0.2, 0)
		var waited := 0
		while not t._player_inside and waited < 20:
			await tree.physics_frame
			await tree.process_frame
			waited += 1
		if not t._player_inside:
			_fail("el terminal %d no detectó a la jugadora" % t.index)
		Input.action_press("interact")
		await tree.process_frame
		await tree.process_frame
		Input.action_release("interact")
		await tree.process_frame
		if t.solved:
			print("  terminal %d resuelto (%s)" % [t.index, t.display_name])
		else:
			_fail("terminal %d no se resolvió (faltan %s)" % [t.index, str(t.missing_codes())])
	await tree.process_frame
	if GameState.resolutions_solved == int(exp["terminals"]):
		_ok("%d resoluciones completadas" % GameState.resolutions_solved)
	else:
		_fail("resoluciones=%d (se esperaban %d)" % [GameState.resolutions_solved, int(exp["terminals"])])
	if GameState.files_collected.size() == int(exp["files"]):
		_ok("%d archivos recolectados" % GameState.files_collected.size())
	else:
		_fail("archivos recolectados=%d (se esperaban %d)" % [GameState.files_collected.size(), int(exp["files"])])

func _check_combat() -> void:
	print("[combat]")
	await tree.physics_frame
	await tree.physics_frame
	var androids := tree.get_nodes_in_group("android")
	if androids.size() > 0:
		_ok("androides activos: %d" % androids.size())
	else:
		_fail("no hay androides activos")
	var player := tree.get_first_node_in_group("player") as Node3D
	var android := androids[0] if androids.size() > 0 else null
	if android:
		var before: float = android.health
		android.take_damage(25.0, android.global_position + Vector3.UP, Vector3.FORWARD)
		if android.health < before:
			_ok("los androides reciben daño")
		else:
			_fail("el androide no recibió daño")
		player.take_damage(12.0, player.global_position)
		if player.health < 100.0:
			_ok("la jugadora recibe daño")
		else:
			_fail("la jugadora no recibió daño")
	# limpiar los androides: la salida se desbloquea cuando no queda ninguno
	for a in tree.get_nodes_in_group("android"):
		if is_instance_valid(a) and a.has_method("take_damage"):
			a.take_damage(9999.0, a.global_position)
	await tree.create_timer(1.5).timeout

func _check_boss() -> void:
	print("[boss]")
	var boss := tree.get_first_node_in_group("boss")
	if boss == null:
		_fail("la Máquina Analítica no apareció")
		return
	_ok("Máquina Analítica activa")
	if GameState.boss_health > 0.0 and GameState.boss_health < 600.0:
		_ok("barra de vida del jefe activa")
	var weak: Dictionary = boss.weak_points[0]
	var wp_node: Node3D = weak["node"]
	var killed: bool = boss.take_damage(200.0, wp_node.global_position, Vector3.FORWARD)
	if killed:
		_fail("el jefe murio de un golpe (deberia requerir varios impactos)")
	else:
		_ok("el jefe resiste el dano inicial")
	for wp in boss.weak_points:
		var node: Node3D = wp["node"]
		if bool(wp.get("alive")):
			boss.take_damage(200.0, node.global_position, Vector3.FORWARD)
	for i in 8:
		if boss.take_damage(300.0, Vector3.ZERO, Vector3.FORWARD):
			break
	await tree.process_frame
	var active := false
	for e in tree.get_nodes_in_group("level_exit"):
		if e.enabled:
			active = true
	if active:
		_ok("la salida al nivel 2 se activa al derrotar a la Máquina Analítica")
	else:
		_fail("la salida no se activó")
	for b in tree.get_nodes_in_group("barrier"):
		if b.requires_boss and not b.is_open:
			_fail("la barrera final sigue cerrada")
			break

func _check_exit_no_boss() -> void:
	print("[salida]")
	await tree.process_frame
	await tree.process_frame
	var active := false
	for e in tree.get_nodes_in_group("level_exit"):
		if e.enabled:
			active = true
	if active:
		_ok("la salida se activa al completar las resoluciones")
	else:
		_fail("la salida no se activó")
	if tree.get_nodes_in_group("boss").size() > 0:
		_fail("aparece un jefe en un nivel sin jefe")
	for b in tree.get_nodes_in_group("barrier"):
		if not b.is_open:
			_fail("una barrera sigue cerrada: %s" % b.name)
			break

func _report() -> void:
	print("[resultado] fallos=%d" % failures.size())
	for f in failures:
		print(" - ", f)
