extends RefCounted

var tree: SceneTree

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	var level := tree.current_scene
	await tree.process_frame
	await tree.physics_frame
	var terminals := tree.get_nodes_in_group("terminal")
	terminals.sort_custom(func(a, b): return int(a.index) < int(b.index))
	var t = terminals[0]
	var player := tree.get_first_node_in_group("player") as Node3D
	print("terminal pos ", t.global_position, " player pos ", player.global_position)
	player.global_position = t.global_position + Vector3(0, 0.2, 0)
	for i in 12:
		await tree.physics_frame
		await tree.process_frame
		print("f%d inside=%s solved=%s overlaps=%d pressed=%s just=%s player=%s" % [i, str(t._player_inside), str(t.solved), t.get_overlapping_bodies().size(), str(Input.is_action_pressed("interact")), str(Input.is_action_just_pressed("interact")), str(player.global_position)])
	print("--- probando interact ---")
	Input.action_press("interact")
	for i in 6:
		await tree.process_frame
		print("f%d inside=%s solved=%s pressed=%s" % [i, str(t._player_inside), str(t.solved), str(Input.is_action_pressed("interact"))])
	Input.action_release("interact")
	tree.quit()
