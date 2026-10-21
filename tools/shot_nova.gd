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
	for i in 40:
		await tree.process_frame
	var nova := level.find_child("Nova", true, false) as Node3D
	var player := level.get_node("Player") as Node3D
	print("nova en ", str(nova.global_position), " jugador en ", str(player.global_position))
	DirAccess.make_dir_recursive_absolute("res://screenshots")
	await _shot_at(nova.global_position + Vector3(1.6, 1.2, 1.8), nova.global_position + Vector3(0, 1.1, 0), 55.0, "nova_antes")
	await _shot_at(nova.global_position + Vector3(0.1, 1.7, 1.5), nova.global_position + Vector3(0, 1.6, 0), 40.0, "nova_cabeza")
	print("SHOTS DONE (%d)" % shot)
	tree.quit()

func _shot_at(pos: Vector3, look: Vector3, fov: float, name: String) -> void:
	var cam := Camera3D.new()
	cam.fov = fov
	cam.far = 500.0
	level.add_child(cam)
	cam.global_position = pos
	cam.look_at_from_position(pos, look, Vector3.UP)
	cam.current = true
	for i in 8:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	var img := tree.root.get_texture().get_image()
	if img == null:
		print("no image for ", name)
		return
	img.save_png("res://screenshots/%s.png" % name)
	shot += 1
	print("saved ", name, " ", img.get_size())
	cam.queue_free()
