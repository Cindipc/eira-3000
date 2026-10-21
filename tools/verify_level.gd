extends SceneTree

func _initialize() -> void:
	var ps: PackedScene = load("res://scenes/Level1.tscn")
	var level := ps.instantiate()
	root.add_child(level)
	await process_frame
	await physics_frame
	await process_frame

	var counts := {}
	_count(level, counts)

	var player := level.get_node_or_null("Player")
	var nova := level.get_node_or_null("Nova")
	print("Level1 children: ", level.get_child_count())
	print("Player pos: ", player.global_position)
	print("Player visual rot: ", player.get_node("Visual").rotation.y)
	print("Cam global: ", player.get_node("CameraPivot/Camera3D").global_position)
	print("Cam dir: ", -player.get_node("CameraPivot/Camera3D").global_transform.basis.z)
	print("Player anim: ", player.get_node_or_null("Visual/Eira/AnimationPlayer") != null)
	print("Player skel: ", player.get_node_or_null("Visual/Eira/Armature/Skeleton3D") != null)
	print("Eira root pos: ", player.get_node("Visual/Eira").global_position)
	print("Nova pos: ", nova.global_position)
	print("Nova target: ", nova.target)
	print("Player in group: ", player.is_in_group("player"))
	print("Counts: ", counts)

	var skeleton := player.get_node_or_null("Visual/Eira/Armature/Skeleton3D") as Skeleton3D
	if skeleton:
		var bi := skeleton.find_bone("mixamorig:Hips")
		var bt := skeleton.get_bone_global_pose(bi)
		print("Hips global pose: ", bt.origin)
		print("Head bone idx: ", skeleton.find_bone("mixamorig:Head"))

	quit()

func _count(n: Node, c: Dictionary) -> void:
	for ch in n.get_children():
		var k := ch.get_class()
		c[k] = c.get(k, 0) + 1
		_count(ch, c)
