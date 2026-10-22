extends RefCounted

## Sonda realista del nivel 1: resuelve los terminales, pelea de verdad y
## LUEGO CAMINA hacia la salida con el mando simulado (sin teletransportes)
## para comprobar que el portal realmente cambia de escena.

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
	print("[real] resoluciones: %d / %d" % [GameState.resolutions_solved, GameState.resolutions_total])

	# --- jefe ------------------------------------------------------------
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
	var shots := 0
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
	print("[real] jefe destruido: %s (%d disparos)" % [str(bool(boss.get("_dead"))), shots])

	# --- limpieza de androides -------------------------------------------
	var guard := 0
	while tree.get_nodes_in_group("android").size() > 0 and guard < 800:
		guard += 1
		for a in tree.get_nodes_in_group("android"):
			a.take_damage(999.0, a.global_position)
		await tree.process_frame

	await tree.process_frame
	await tree.create_timer(0.8).timeout
	var exit_enabled := false
	for e in tree.get_nodes_in_group("level_exit"):
		if bool(e.get("enabled")):
			exit_enabled = true
	print("[real] salida activada: %s" % exit_enabled)
	if not exit_enabled:
		_fail("la salida no se activo")
	await tree.create_timer(0.5).timeout
	var hint := _exit_hint()
	if hint != null and hint.visible:
		print("[real] indicador de salida: %s" % hint.text)
	else:
		_fail("el HUD no indica donde esta la salida")

	# --- camina a la salida ----------------------------------------------
	var portal: Node3D = null
	for e in tree.get_nodes_in_group("level_exit"):
		portal = e
	if portal == null:
		_fail("no hay portal")
		_summary()
		return
	print("[real] el portal esta en %s" % str(portal.global_position))
	# mira hacia el portal (yaw para avanzar en +x)
	var to_portal := portal.global_position - player.global_position
	pivot.rotation.y = atan2(-to_portal.x, -to_portal.z)
	Input.action_press("move_forward")
	var start_x: float = player.global_position.x
	var changed := false
	var stuck := false
	var last_x: float = player.global_position.x
	for i in 2400:
		await tree.physics_frame
		await tree.process_frame
		if tree.current_scene != null and tree.current_scene.scene_file_path.ends_with("Level2.tscn"):
			changed = true
			break
		if i % 60 == 0:
			print("[real] t=%ds pos=%s en_suelo=%s dist_portal=%.2f" % [i / 60, str(player.global_position.snappedf(0.1)), str(player.is_on_floor()), player.global_position.distance_to(portal.global_position)])
		if absf(player.global_position.x - last_x) < 0.01 and i > 60:
			stuck = true
			print("[real] el jugador no avanza mas (x=%.1f)" % player.global_position.x)
			break
		last_x = player.global_position.x
	Input.action_release("move_forward")
	if is_instance_valid(player):
		print("[real] inicio x=%.1f -> final x=%.1f" % [start_x, player.global_position.x])
	if stuck:
		_fail("el jugador se quedo bloqueado en el camino a la salida")
	if changed:
		print("[real] OK: el portal llevo al nivel 2")
	else:
		_fail("el portal no cambio de escena")
	_summary()

func _aim(pivot: Node3D, cam: Camera3D, target: Vector3) -> void:
	var d := (target - cam.global_position).normalized()
	pivot.rotation.y = atan2(-d.x, -d.z)
	cam.rotation.x = asin(clampf(d.y, -1.0, 1.0))

func _exit_hint() -> Label:
	for n in _all(tree.current_scene):
		if n is Label and n.name == "ExitHint":
			return n
	return null

func _all(root: Node) -> Array:
	var out: Array = []
	if root == null:
		return out
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		out.append(cur)
		for c in cur.get_children():
			stack.append(c)
	return out

func _fail(msg: String) -> void:
	fails += 1
	print("  FALLO: ", msg)

func _summary() -> void:
	print("[real] fallos=%d" % fails)
