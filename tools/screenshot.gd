extends RefCounted

var tree: SceneTree
var level: Node
var shot := 0

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	level = (load("res://scenes/Level1.tscn") as PackedScene).instantiate()
	tree.root.add_child(level)
	await tree.process_frame
	await tree.physics_frame
	for i in 30:
		await tree.process_frame

	DirAccess.make_dir_recursive_absolute("res://screenshots")
	await _shot_player("06_thirdperson")
	await _shot_at(Vector3(-4, 4.5, -2), Vector3(16, 1.6, -6), 70.0, "07_files")
	await _shot_at(Vector3(14, 3.0, 4), Vector3(14, 1.4, -7.5), 60.0, "08_terminal")
	await _shot_at(Vector3(60, 6.0, 12), Vector3(80, 2.0, -4), 70.0, "09_combatzone")
	await _shot_at(Vector3(112, 6.0, 14), Vector3(124, 3.0, 0), 70.0, "10_arena")
	await _shot_at(Vector3(150, 4.0, 8), Vector3(168, 2.4, 0), 65.0, "11_exit")
	print("SHOTS DONE (%d)" % shot)
	tree.quit()

func _shot_player(name: String) -> void:
	var player := level.get_node("Player")
	var cam: Camera3D = player.get_node("CameraPivot/Camera3D")
	cam.current = true
	await _wait(6)
	await _save("res://screenshots/%s.png" % name)

func _shot_at(pos: Vector3, look: Vector3, fov: float, name: String) -> void:
	var cam := Camera3D.new()
	cam.fov = fov
	cam.far = 500.0
	level.add_child(cam)
	cam.global_position = pos
	cam.look_at_from_position(pos, look, Vector3.UP)
	cam.current = true
	await _wait(8)
	await _save("res://screenshots/%s.png" % name)
	cam.queue_free()

func _wait(n: int) -> void:
	for i in n:
		await tree.process_frame
	await RenderingServer.frame_post_draw

func _save(path: String) -> void:
	var img := tree.root.get_texture().get_image()
	if img == null:
		print("no image for ", path)
		return
	img.save_png(path)
	shot += 1
	print("saved ", path, " ", img.get_size())
