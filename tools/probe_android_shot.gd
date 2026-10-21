extends RefCounted

var tree: SceneTree

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	await tree.process_frame
	await tree.physics_frame

	var player := tree.get_first_node_in_group("player") as Node3D
	var weapon := player.get_node_or_null("CameraPivot/Camera3D/Weapon") as Node3D
	var pivot := player.get_node("CameraPivot") as Node3D
	var cam := player.get_node("CameraPivot/Camera3D") as Camera3D

	# Forzar el combate para que aparezcan androides.
	for t in tree.get_nodes_in_group("terminal"):
		for code in t.required_codes:
			GameState.collect_file(code)
	GameState.solve_resolution(0)
	GameState.solve_resolution(1)
	GameState.solve_resolution(2)
	await tree.physics_frame

	var android: Node3D = null
	var w := 0
	while android == null and w < 200:
		await tree.physics_frame
		var list := tree.get_nodes_in_group("android")
		if list.size() > 0:
			android = list[0]
		w += 1
	if android == null:
		print("[android] no aparecieron androides")
		return
	print("[android] androide en ", android.global_position)

	# Forzar el escenario: el HUD consulta weapon.current_target cada frame.
	weapon.current_target = android
	android.take_damage(999.0, android.global_position + Vector3.UP, Vector3.FORWARD)
	print("[android] current_target = ", weapon.current_target)
	await tree.create_timer(1.0).timeout
	for i in 5:
		await tree.process_frame
	print("[android] current_target tras 1s = ", weapon.current_target)
	print("[android] vivo = ", is_instance_valid(weapon.current_target))
