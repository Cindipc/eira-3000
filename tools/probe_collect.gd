extends RefCounted

var tree: SceneTree
var last_objective := ""

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	GameState.objective_changed.connect(func(text: String) -> void: last_objective = text)
	await tree.process_frame
	await tree.physics_frame

	var player := tree.get_first_node_in_group("player") as Node3D
	var director := tree.current_scene.get_node_or_null("Gameplay/LevelDirector")

	print("[collect] recogiendo archivos por contacto")
	var files := tree.get_nodes_in_group("data_file")
	for f in files:
		player.global_position = (f as Node3D).global_position
		await tree.physics_frame
		await tree.process_frame
		await tree.process_frame
	print("[collect] archivos en GameState = ", GameState.files_collected.size())
	print("[collect] objetivo antes = ", GameState.prompt_text)

	var terminals := tree.get_nodes_in_group("terminal")
	terminals.sort_custom(func(a, b): return int(a.index) < int(b.index))
	var t = terminals[0]
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
	await tree.process_frame

	print("[collect] terminal resuelto = ", t.solved)
	print("[collect] terminal activo en el director = ", director._active_terminal)
	print("[collect] objetivo = ", last_objective)
	print("[collect] prompt = ", GameState.prompt_text)
	var alive := 0
	for f in director.files:
		if is_instance_valid(f):
			alive += 1
	print("[collect] referencias del director: %d (vivas %d)" % [director.files.size(), alive])
