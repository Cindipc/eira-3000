extends RefCounted

var tree: SceneTree
var player: Node3D
var pivot: Node3D
var failures: Array[String] = []

func _fail(m: String) -> void:
	failures.append(m)
	print("  FAIL: ", m)

func _ok(m: String) -> void:
	print("  ok: ", m)

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	await tree.process_frame
	await tree.physics_frame
	player = tree.get_first_node_in_group("player") as Node3D
	pivot = player.get_node("CameraPivot") as Node3D

	var terminals := tree.get_nodes_in_group("terminal")
	terminals.sort_custom(func(a, b): return int(a.index) < int(b.index))

	for t in terminals:
		var name_s: String = str(t.get("display_name"))
		print("[walk]terminal %d %s pos=%s" % [int(t.index), name_s, str(t.global_position)])
		for code in t.required_codes:
			var f := _find_file(code)
			if f == null:
				_fail("%s: no existe el archivo %s" % [name_s, code])
				continue
			var ok := await _walk_to(f.global_position, 0.7)
			if not ok:
				_fail("%s: no se puede llegar al archivo %s" % [name_s, code])
				continue
			var got: bool = GameState.has_file(code)
			if not got:
				_fail("%s: el archivo %s no se recogio al pisarlo" % [name_s, code])
		var reached := await _walk_to(t.global_position + Vector3(0, 0, 0), 2.2, t)
		if not reached:
			_fail("%s: no se puede llegar al terminal" % name_s)
			continue
		var inside: bool = bool(t.get("_player_inside"))
		if not inside:
			_fail("%s: el area del terminal no detecta a la jugadora" % name_s)
			continue
		Input.action_press("interact")
		await tree.process_frame
		await tree.process_frame
		Input.action_release("interact")
		await tree.process_frame
		if not bool(t.get("solved")):
			_fail("%s: [E] no resolvio el nodo" % name_s)
		else:
			_ok("%s resuelto" % name_s)
	print("[walk] fallos=%d" % failures.size())

func _find_file(code: String) -> Node3D:
	for f in tree.get_nodes_in_group("data_file"):
		if str(f.get("code")) == code:
			return f
	return null

func _walk_to(target: Vector3, stop_at: float, term: Node = null) -> bool:
	var t := 0.0
	var last_pos := Vector3.ZERO
	while t < 25.0:
		if term != null and bool(term.get("_player_inside")):
			Input.action_release("move_forward")
			await tree.physics_frame
			return true
		var p := player.global_position
		last_pos = p
		var flat := Vector3(target.x - p.x, 0.0, target.z - p.z)
		var dist := flat.length()
		if dist <= stop_at and term == null:
			Input.action_release("move_forward")
			await tree.physics_frame
			return true
		var d := flat.normalized()
		pivot.rotation.y = atan2(-d.x, -d.z)
		if not Input.is_action_pressed("move_forward"):
			Input.action_press("move_forward")
		await tree.physics_frame
		t += 0.05
	Input.action_release("move_forward")
	print("    (bloqueado en %s, dist=%.2f, objetivo %s)" % [str(last_pos.snapped(Vector3(0.1,0.1,0.1))), Vector3(target.x - last_pos.x, 0.0, target.z - last_pos.z).length(), str(target.snapped(Vector3(0.1,0.1,0.1)))])
	return false
