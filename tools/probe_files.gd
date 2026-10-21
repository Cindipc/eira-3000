extends RefCounted

var tree: SceneTree

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	await tree.process_frame
	await tree.physics_frame

	var player := tree.get_first_node_in_group("player") as Node3D
	var files := tree.get_nodes_in_group("data_file")
	files.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	print("[files] total=%d" % files.size())

	var uncollected: Array[String] = []
	for f in files:
		var code: String = f.get("code")
		var pos: Vector3 = f.global_position
		player.global_position = Vector3(pos.x, pos.y + 0.2, pos.z)
		for i in 6:
			await tree.physics_frame
			await tree.process_frame
		var ok: bool = bool(f.get("collected"))
		if not ok:
			uncollected.append(code)
		print("  %-12s pos=%s  collected=%s" % [code, str(pos.snapped(Vector3(0.1, 0.1, 0.1))), str(ok)])

	print("[files] no recogidos: %s" % str(uncollected))

	var terminals := tree.get_nodes_in_group("terminal")
	terminals.sort_custom(func(a, b): return int(a.index) < int(b.index))
	for t in terminals:
		var missing: Array = []
		for code in t.required_codes:
			if not GameState.has_file(code):
				missing.append(code)
		print("  terminal %d %s  faltan=%s" % [int(t.index), str(t.get("display_name")), str(missing)])
