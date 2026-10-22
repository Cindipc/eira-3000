extends RefCounted

## Sonda del nivel 1: resuelve los terminales, mata al jefe con el arma real
## y comprueba que la salida lleva al nivel 2.

var tree: SceneTree
var fails := 0

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	await tree.process_frame
	await tree.physics_frame

	var player := tree.get_first_node_in_group("player") as Node3D
	if player == null:
		_fail("no hay jugador")
		_summary()
		return
	var weapon := player.get_node_or_null("CameraPivot/Camera3D/Weapon") as Node3D
	var pivot := player.get_node("CameraPivot") as Node3D
	var cam := player.get_node("CameraPivot/Camera3D") as Camera3D

	# --- terminales ------------------------------------------------------
	var terminals := tree.get_nodes_in_group("terminal")
	terminals.sort_custom(func(a, b): return int(a.index) < int(b.index))
	print("[l1] terminales: %d" % terminals.size())
	for t in terminals:
		for code in t.required_codes:
			GameState.collect_file(code)
		player.global_position = t.global_position + Vector3(0, 0.2, 0)
		var waited := 0
		while not t._player_inside and waited < 30:
			await tree.physics_frame
			await tree.process_frame
			waited += 1
		Input.action_press("interact")
		await tree.process_frame
		await tree.process_frame
		Input.action_release("interact")
		await tree.process_frame
	print("[l1] resoluciones: %d / %d" % [GameState.resolutions_solved, GameState.resolutions_total])
	if GameState.resolutions_solved != terminals.size():
		_fail("no se completaron todas las resoluciones")

	# --- espera al jefe --------------------------------------------------
	var boss: Node3D = null
	var w := 0
	while boss == null and w < 400:
		await tree.physics_frame
		boss = tree.get_first_node_in_group("boss") as Node3D
		w += 1
	if boss == null:
		_fail("el jefe no aparecio")
		_summary()
		return
	await tree.physics_frame
	print("[l1] jefe activo, androides vivos: %d" % tree.get_nodes_in_group("android").size())

	# --- dispara al jefe como lo haria el jugador -------------------------
	var shots := 0
	var hp_before: float = boss.health
	while not bool(boss.get("_dead")) and shots < 400:
		var target := boss.global_position + Vector3(0, 2.6, 0)
		var weak: Dictionary = boss.weak_points[0]
		if bool(weak.get("alive")):
			target = (weak["node"] as Node3D).global_position
		_aim(pivot, cam, target)
		weapon._cooldown = 0.0
		weapon.try_fire()
		shots += 1
		await tree.process_frame
		if shots % 50 == 0:
			print("[l1] disparos %d, vida del jefe %.1f" % [shots, boss.health])
	if bool(boss.get("_dead")):
		print("[l1] jefe destruido en %d disparos (vida inicial %.0f)" % [shots, hp_before])
	else:
		_fail("el jefe sobrevivio a %d disparos (vida %.1f)" % [shots, boss.health])

	await tree.process_frame
	await tree.process_frame

	# --- estado de la salida ---------------------------------------------
	var exit_enabled := false
	for e in tree.get_nodes_in_group("level_exit"):
		if e.enabled:
			exit_enabled = true
	print("[l1] salida activada: %s" % exit_enabled)
	if not exit_enabled:
		_fail("la salida no se activo")
	var closed := 0
	for b in tree.get_nodes_in_group("barrier"):
		if b.requires_boss and not b.is_open:
			closed += 1
	print("[l1] barreras de jefe cerradas: %d" % closed)
	if closed > 0:
		_fail("la barrera final sigue cerrada")

	# --- camina al portal ------------------------------------------------
	for e in tree.get_nodes_in_group("level_exit"):
		print("[l1] portal en %s -> %s" % [str(e.global_position), str(e.next_scene)])
		player.global_position = e.global_position + Vector3(0, 0.5, 0)
	await tree.physics_frame
	await tree.process_frame
	await tree.process_frame
	var changed := false
	for i in 240:
		await tree.process_frame
		if tree.current_scene != null and tree.current_scene.scene_file_path.ends_with("Level2.tscn"):
			changed = true
			break
	if changed:
		print("[l1] OK: el portal lleva al nivel 2")
	else:
		_fail("el portal no cambio de escena")
	_summary()

func _aim(pivot: Node3D, cam: Camera3D, target: Vector3) -> void:
	var cam_pos := cam.global_position
	var d := (target - cam_pos).normalized()
	pivot.rotation.y = atan2(-d.x, -d.z)
	cam.rotation.x = asin(clampf(d.y, -1.0, 1.0))

func _fail(msg: String) -> void:
	fails += 1
	print("  FALLO: ", msg)

func _summary() -> void:
	print("[l1] fallos=%d" % fails)
