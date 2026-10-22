extends RefCounted

## Capturas del Nivel 3: la ciudad con el Nucleo y el interior del Nucleo.

var tree: SceneTree
var config := {}
var shot := 0

func configure(cfg: Dictionary) -> void:
	config = cfg

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	DirAccess.make_dir_recursive_absolute("res://screenshots")
	_remove_current_scene()
	var scene_path: String = str(config.get("scene", "res://scenes/Level3.tscn"))
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("no se pudo cargar " + scene_path)
		tree.quit()
		return
	var level: Node = packed.instantiate()
	tree.root.add_child(level)
	tree.current_scene = level
	for i in 14:
		await tree.process_frame

	# ciudad: inicio y entrada del nucleo
	await _shot_at(Vector3(6.0, 2.2, -6.8), Vector3(40.0, 2.0, -6.0), 70.0, "l3_start")
	await _shot_at(Vector3(34.0, 2.4, -6.5), Vector3(48.0, 2.6, 0.5), 65.0, "l3_door")
	await _shot_at(Vector3(52.0, 3.0, -12.0), Vector3(46.0, 16.0, 10.0), 70.0, "l3_tower")
	await _shot_at(Vector3(-10.0, 40.0, -60.0), Vector3(20.0, 0.0, -4.0), 62.0, "l3_cityview")

	# interior (origen en x = 400)
	await _shot_at(Vector3(405.0, 2.0, 0.0), Vector3(430.0, 1.6, 0.0), 68.0, "l3_entry")
	await _shot_at(Vector3(430.0, 2.2, 0.0), Vector3(455.0, 1.6, -4.0), 68.0, "l3_security")
	await _shot_at(Vector3(458.0, 2.4, 0.0), Vector3(474.0, 1.8, 0.0), 70.0, "l3_arena")
	await _shot_at(Vector3(470.0, 3.0, 8.0), Vector3(476.0, 1.6, 0.0), 60.0, "l3_kael")
	await _shot_at(Vector3(500.0, 2.6, 0.0), Vector3(521.0, 3.0, 0.0), 70.0, "l3_core")
	await _shot_at(Vector3(409.0, 5.2, 0.0), Vector3(474.0, 1.4, 0.0), 80.0, "l3_interior_aerial")
	print("SHOTS DONE (%d)" % shot)
	tree.quit()

func _all_nodes(root: Node) -> Array:
	var out: Array = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		out.append(cur)
		for c in cur.get_children():
			stack.append(c)
	return out

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

func _shot_at(pos: Vector3, look: Vector3, fov: float, name: String) -> void:
	var cam := Camera3D.new()
	cam.fov = fov
	cam.far = 6000.0
	tree.root.add_child(cam)
	cam.global_position = pos
	cam.look_at_from_position(pos, look, Vector3.UP)
	cam.current = true
	for i in 8:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	var img := tree.root.get_texture().get_image()
	if img != null:
		var path := "res://screenshots/%s.png" % name
		img.save_png(path)
		shot += 1
		var lum := 0.0
		var step := 8
		var samples := 0
		for y in range(0, img.get_height(), step):
			for x in range(0, img.get_width(), step):
				var c := img.get_pixel(x, y)
				lum += 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
				samples += 1
		print("saved %s %s lum=%.3f" % [name, str(img.get_size()), lum / maxf(1.0, float(samples))])
	cam.queue_free()
