extends RefCounted

var tree: SceneTree
var failures: Array[String] = []

func _fail(msg: String) -> void:
	failures.append(msg)
	print("  FAIL: ", msg)

func _ok(msg: String) -> void:
	print("  ok: ", msg)

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	await tree.process_frame
	await tree.physics_frame

	var player := tree.get_first_node_in_group("player") as Node3D
	var weapon := player.get_node_or_null("CameraPivot/Camera3D/Weapon") as Node3D
	var pivot := player.get_node("CameraPivot") as Node3D
	var cam := player.get_node("CameraPivot/Camera3D") as Camera3D

	print("[flow] resolviendo terminales")
	var terminals := tree.get_nodes_in_group("terminal")
	terminals.sort_custom(func(a, b): return int(a.index) < int(b.index))
	for t in terminals:
		for code in t.required_codes:
			GameState.collect_file(code)
		player.global_position = t.global_position + Vector3(0, 0.2, 0)
		var waited := 0
		while not t._player_inside and waited < 20:
			await tree.physics_frame
			await tree.process_frame
			waited += 1
		Input.action_press("interact")
		await tree.process_frame
		await tree.process_frame
		Input.action_release("interact")
		await tree.process_frame
	if GameState.resolutions_solved == terminals.size():
		_ok("las %d resoluciones se completaron con [E]" % terminals.size())
	else:
		_fail("resoluciones=%d" % GameState.resolutions_solved)

	print("[flow] recogiendo botiquines")
	var health_before: float = player.health
	for pk in tree.get_nodes_in_group("pickup"):
		if int(pk.get("kind")) != 0:
			continue
		player.global_position = pk.global_position
		await tree.physics_frame
		await tree.process_frame
	_ok("botiquines recogidos: integridad %d -> %d" % [int(health_before), int(player.health)])

	var boss: Node3D = null
	var w := 0
	while boss == null and w < 200:
		await tree.physics_frame
		boss = tree.get_first_node_in_group("boss") as Node3D
		w += 1
	if boss == null:
		_fail("el jefe no apareció")
		return
	await tree.physics_frame
	_ok("Máquina Analítica activada")

	player.global_position = boss.global_position + Vector3(0, 0.2, -10.0)
	await tree.physics_frame
	var shots := 0
	var empty := false
	while not bool(boss.get("_dead")) and shots < 300:
		if GameState.energy_enabled and GameState.energy < weapon.energy_cost:
			empty = true
			break
		var weak: Dictionary = boss.weak_points[0]
		var target: Vector3 = (weak["node"] as Node3D).global_position
		if not bool(weak.get("alive")):
			target = boss.global_position + Vector3(0, 2.6, 0)
		_aim(player, pivot, cam, target)
		weapon._cooldown = 0.0
		weapon.try_fire()
		shots += 1
		await tree.process_frame
	if empty:
		_fail("el jugador se quedó sin energía tras %d disparos" % shots)
	elif bool(boss.get("_dead")):
		_ok("el jefe murió con %d disparos (energía restante: %d)" % [shots, int(GameState.energy)])
	else:
		_fail("el jefe sobrevivió a %d disparos" % shots)

	await tree.process_frame
	await tree.process_frame

	var exit_enabled := false
	for e in tree.get_nodes_in_group("level_exit"):
		if e.enabled:
			exit_enabled = true
	if exit_enabled:
		_ok("la salida se activó al derrotar al jefe")
	else:
		_fail("la salida no se activó")
	var closed := 0
	for b in tree.get_nodes_in_group("barrier"):
		if b.requires_boss and not b.is_open:
			closed += 1
	if closed == 0:
		_ok("la barrera final se abrió")
	else:
		_fail("la barrera final sigue cerrada")

	for e in tree.get_nodes_in_group("level_exit"):
		player.global_position = e.global_position + Vector3(0, 0.5, 0)
	await tree.physics_frame
	await tree.process_frame
	await tree.process_frame
	var changed := false
	for i in 180:
		await tree.process_frame
		if tree.current_scene != null and tree.current_scene.scene_file_path.ends_with("Level2.tscn"):
			changed = true
			break
	if changed:
		_ok("el portal de salida lleva al nivel 2")
	else:
		_fail("el portal de salida no cambió de escena")

	print("[flow] fallos=%d" % failures.size())

func _aim(player: Node3D, pivot: Node3D, cam: Camera3D, target: Vector3) -> void:
	for i in 2:
		var cam_pos := cam.global_position
		var d := (target - cam_pos).normalized()
		pivot.rotation.y = atan2(-d.x, -d.z)
		cam.rotation.x = asin(clampf(d.y, -1.0, 1.0))
		player._update_camera(0.016)
