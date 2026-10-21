extends RefCounted

var tree: SceneTree
var config := {}
var shot := 0

func configure(cfg: Dictionary) -> void:
	config = cfg

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	DirAccess.make_dir_recursive_absolute("res://screenshots")
	_remove_current_scene()
	var scene_path: String = str(config.get("scene", "res://scenes/Level2.tscn"))
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("no se pudo cargar " + scene_path)
		tree.quit()
		return
	var level: Node = packed.instantiate()
	tree.root.add_child(level)
	tree.current_scene = level
	for i in 12:
		await tree.process_frame

	await _shot_at(Vector3(-46.0, 2.2, -6.8), Vector3(10.0, 1.4, -6.4), 70.0, "l2_start")
	await _shot_at(Vector3(-30.0, 1.75, -7.3), Vector3(30.0, 1.4, -7.0), 70.0, "l2_street")
	await _shot_at(Vector3(-33.0, 1.8, -5.2), Vector3(-35.0, 1.3, -7.0), 62.0, "l2_terminal")
	await _shot_at(Vector3(30.0, 2.4, -6.0), Vector3(48.0, 1.2, -4.0), 70.0, "l2_exit")
	await _shot_at(Vector3(0.0, 70.0, -55.0), Vector3(0.0, 0.0, -4.0), 62.0, "l2_aerial")
	for b in tree.get_nodes_in_group("barrier"):
		if b.has_method("open_barrier"):
			b.open_barrier()
	for i in 20:
		await tree.process_frame
	await _shot_at(Vector3(-30.0, 1.75, -7.3), Vector3(30.0, 1.4, -7.0), 70.0, "l2_open")
	await _shot_at(Vector3(-8.0, 1.75, -4.0), Vector3(40.0, 2.0, -6.0), 70.0, "l2_cityview")
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
