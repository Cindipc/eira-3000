extends RefCounted

## Sonda del nivel 2: resuelve los terminales, limpia los androides y comprueba
## que la salida lleva al nivel 3.

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

	var terminals := tree.get_nodes_in_group("terminal")
	terminals.sort_custom(func(a, b): return int(a.index) < int(b.index))
	print("[l2] terminales: %d" % terminals.size())
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
	print("[l2] resoluciones: %d / %d" % [GameState.resolutions_solved, GameState.resolutions_total])
	if GameState.resolutions_solved != terminals.size():
		_fail("no se completaron todas las resoluciones")
	print("[l2] objetivo: %s" % _objective())

	# limpia los androides
	var guard := 0
	while tree.get_nodes_in_group("android").size() > 0 and guard < 500:
		guard += 1
		for a in tree.get_nodes_in_group("android"):
			a.take_damage(999.0, a.global_position)
		await tree.process_frame
	await tree.process_frame
	await tree.process_frame
	await tree.create_timer(0.6).timeout
	await tree.process_frame
	var exit_enabled := false
	for e in tree.get_nodes_in_group("level_exit"):
		if bool(e.get("enabled")):
			exit_enabled = true
	print("[l2] salida activada: %s" % exit_enabled)
	if not exit_enabled:
		_fail("la salida no se activo tras limpiar los androides")
	print("[l2] objetivo: %s" % _objective())

	for e in tree.get_nodes_in_group("level_exit"):
		player.global_position = e.global_position + Vector3(0, 0.5, 0)
	await tree.physics_frame
	await tree.process_frame
	await tree.process_frame
	var changed := false
	for i in 300:
		await tree.process_frame
		if tree.current_scene != null and tree.current_scene.scene_file_path.ends_with("Level3.tscn"):
			changed = true
			break
	if changed:
		print("[l2] OK: el portal lleva al nivel 3")
	else:
		_fail("el portal no cambio de escena")
	_summary()

func _objective() -> String:
	for n in _all(tree.current_scene):
		if n is CanvasLayer and n.get_script() != null and str(n.get_script().resource_path).ends_with("HUD.gd"):
			var lbl := n.get_node_or_null("Root/Bottom/Objective") as Label
			return lbl.text if lbl else "(sin etiqueta)"
	return "(sin hud)"

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
	print("[l2] fallos=%d" % fails)
