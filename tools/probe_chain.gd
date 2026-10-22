extends RefCounted

## Sonda de la cadena de niveles: Intro -> Nivel 1 -> Nivel 2 -> Nivel 3.
##
## Comprueba los destinos configurados y hace una transicion real en vivo
## desde la salida del nivel 2 hasta el nivel 3.

var tree: SceneTree
var fails := 0
var log_lines: Array[String] = []

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	_remove_current_scene()

	# --- enlaces estaticos ---------------------------------------------
	var intro := load("res://scripts/Intro.gd") as GDScript
	var intro_const := ""
	if intro:
		intro_const = str(intro.get_script_constant_map().get("TO_LEVEL", ""))
	_check(intro_const == "res://scenes/Level1.tscn", "Intro lleva al nivel 1 (%s)" % intro_const)

	var l1 := load("res://scenes/Level1.tscn") as PackedScene
	var l2 := load("res://scenes/Level2.tscn") as PackedScene
	var l3 := load("res://scenes/Level3.tscn") as PackedScene
	_check(l1 != null and l2 != null and l3 != null, "las tres escenas cargan")

	# --- salida del nivel 1 (transicion en vivo) ------------------------
	if l1:
		var r1 := l1.instantiate()
		tree.root.add_child(r1)
		tree.current_scene = r1
		for i in 6:
			await tree.process_frame
		var e1 := _first_exit(r1)
		_check(e1 != null and e1.next_scene == "res://scenes/Level2.tscn", "la salida del nivel 1 lleva al nivel 2")
		if e1:
			e1.activate()
			var p1 := tree.get_first_node_in_group("player") as Node3D
			if p1:
				p1.global_position = e1.global_position + Vector3(0, 0.5, 0)
			await tree.create_timer(2.5).timeout
			var to_l2 := false
			for i in 60:
				await tree.process_frame
				if tree.current_scene != null and tree.current_scene.scene_file_path.ends_with("Level2.tscn"):
					to_l2 = true
					break
			_check(to_l2, "la transicion en vivo lleva del nivel 1 al nivel 2")
		for i in 10:
			await tree.process_frame

	# --- salida del nivel 2 --------------------------------------------
	if l2:
		var r2 := l2.instantiate()
		tree.root.add_child(r2)
		tree.current_scene = r2
		for i in 6:
			await tree.process_frame
		var e2 := _first_exit(r2)
		_check(e2 != null, "el nivel 2 tiene salida")
		if e2:
			_check(e2.next_scene == "res://scenes/Level3.tscn", "la salida del nivel 2 lleva al nivel 3 (%s)" % e2.next_scene)
			e2.activate()
			var player := tree.get_first_node_in_group("player") as Node3D
			_check(player != null, "el nivel 2 tiene jugador")
			if player:
				player.global_position = e2.global_position + Vector3(0, 0.5, 0)
			await tree.create_timer(2.5).timeout
			var changed := false
			for i in 60:
				await tree.process_frame
				if tree.current_scene != null and tree.current_scene.scene_file_path.ends_with("Level3.tscn"):
					changed = true
					break
			_check(changed, "la transicion en vivo lleva al nivel 3")
			for i in 20:
				await tree.process_frame
			var d3 := tree.get_first_node_in_group("l3_director")
			_check(d3 != null, "el nivel 3 arranca con su director")
			_check(GameState.current_level == 3, "el estado global marca el nivel 3 (%d)" % GameState.current_level)
			_check(GameState.max_lives == 5, "el nivel 3 usa 5 vidas (%d)" % GameState.max_lives)
		else:
			r2.queue_free()

	_summary()

func _first_exit(root: Node) -> Node:
	for n in _all_nodes(root):
		if n.is_in_group("level_exit"):
			return n
	return null

func _check(cond: bool, what: String) -> void:
	if cond:
		log_lines.append("OK    " + what)
	else:
		log_lines.append("FALLO " + what)
		fails += 1

func _summary() -> void:
	print("\n=== CADENA DE NIVELES ===")
	for l in log_lines:
		print(l)
	print("fallos: ", fails)

func _remove_current_scene() -> void:
	if tree.current_scene == null:
		return
	var old := tree.current_scene
	tree.current_scene = null
	tree.root.remove_child(old)
	for n in _all_nodes(old):
		for g in n.get_groups():
			n.remove_from_group(g)
	old.queue_free()

func _all_nodes(root: Node) -> Array:
	var out: Array = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		out.append(cur)
		for c in cur.get_children():
			stack.append(c)
	return out
