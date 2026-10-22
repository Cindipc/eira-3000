extends RefCounted

## Sonda del nivel 1 (parte 2): comprueba el estado de la salida y de la
## barrera cuando los androides normales ya estan muertos pero el jefe sigue vivo,
## y comprueba que pasa cuando el jugador pierde todas las vidas.

var tree: SceneTree
var fails := 0

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	await tree.process_frame
	await tree.physics_frame

	var player := tree.get_first_node_in_group("player") as Node3D
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

	# --- espera al jefe y comprueba el objetivo --------------------------
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
	await tree.process_frame
	print("[l1b] objetivo tras resolver: %s" % _objective())

	# --- mata solo a los androides normales (no al jefe) -----------------
	var guard := 0
	while tree.get_nodes_in_group("android").size() > 0 and guard < 400:
		guard += 1
		for a in tree.get_nodes_in_group("android"):
			a.take_damage(999.0, a.global_position)
		await tree.process_frame
	await tree.process_frame
	await tree.process_frame
	print("[l1b] androides restantes: %d, jefe vivo: %s" % [
		tree.get_nodes_in_group("android").size(), not bool(boss.get("_dead"))])
	print("[l1b] objetivo: %s" % _objective())

	var exit_enabled := false
	for e in tree.get_nodes_in_group("level_exit"):
		if e.enabled:
			exit_enabled = true
	print("[l1b] SALIDA activada con el jefe vivo: %s" % exit_enabled)
	var closed := 0
	for b in tree.get_nodes_in_group("barrier"):
		if not b.is_open:
			closed += 1
	print("[l1b] barreras todavia cerradas: %d" % closed)

	# --- el jugador camina al portal con la barrera cerrada --------------
	for e in tree.get_nodes_in_group("level_exit"):
		player.global_position = e.global_position + Vector3(0, 0.5, 0)
	await tree.physics_frame
	await tree.process_frame
	await tree.process_frame
	var changed := false
	for i in 60:
		await tree.process_frame
		if tree.current_scene != null and tree.current_scene.scene_file_path.ends_with("Level2.tscn"):
			changed = true
			break
	print("[l1b] el portal cambia de escena con la barrera cerrada: %s" % changed)
	if not changed:
		print("[l1b] -> el jugador se queda atascado en la barrera del jefe")

	# --- muerte del jugador: softlock ------------------------------------
	print("[l1b] --- prueba de softlock por muerte ---")
	player.take_damage(9999.0)
	await tree.process_frame
	await tree.process_frame
	print("[l1b] vidas tras morir: %d, jugador dead: %s" % [GameState.lives, str(player.dead)])
	for i in 3:
		player.take_damage(9999.0)
		await tree.process_frame
		await tree.process_frame
	print("[l1b] vidas: %d, dead: %s" % [GameState.lives, str(player.dead)])
	await tree.create_timer(3.0).timeout
	print("[l1b] tras 3s el jugador revive: %s (vivas %d)" % [str(not player.dead), GameState.lives])
	if player.dead and GameState.lives <= 0:
		_fail("softlock: el jugador queda muerto para siempre sin opcion de reinicio")
	_summary()

func _objective() -> String:
	var hud := tree.get_first_node_in_group("hud")
	if hud == null:
		for n in _all(tree.current_scene):
			if n is CanvasLayer and n.get_script() != null and str(n.get_script().resource_path).ends_with("HUD.gd"):
				hud = n
				break
	if hud == null:
		return "(sin hud)"
	var lbl := hud.get_node_or_null("Root/Bottom/Objective") as Label
	return lbl.text if lbl else "(sin etiqueta)"

func _all(root: Node) -> Array:
	var out: Array = []
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
	print("[l1b] fallos=%d" % fails)
