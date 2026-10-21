extends SceneTree

func _init() -> void:
	var scene: PackedScene = load("res://assets/characters/eira.glb")
	var inst: Node3D = scene.instantiate()
	root.add_child(inst)
	await process_frame
	var sk: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	if sk == null:
		print("no skeleton")
		quit()
		return
	for n in ["mixamorig_Hips", "mixamorig_Head", "mixamorig_LeftToe_End", "mixamorig_RightToe_End"]:
		var i: int = sk.find_bone(n)
		if i >= 0:
			print(n, " rest=", sk.get_bone_rest(i).origin, " global=", sk.get_bone_global_pose(i).origin)
	var hi: int = sk.find_bone("mixamorig_Hips")
	var hd: int = sk.find_bone("mixamorig_Head")
	var to: int = sk.find_bone("mixamorig_LeftToe_End")
	var hips: Vector3 = sk.get_bone_global_pose(hi).origin
	var head: Vector3 = sk.get_bone_global_pose(hd).origin
	var toe: Vector3 = sk.get_bone_global_pose(to).origin
	print("FORWARD(head-hips)=", (head - hips).cross(Vector3.UP).normalized())
	print("TOE(hips)=", (toe - hips).cross(Vector3.UP).normalized())
	print("HEAD.y-hips.y=", (head - hips).y)
	var mi: MeshInstance3D = inst.find_child("MESH Maria_J_J_Ong", true, false)
	if mi:
		print("body origin=", mi.global_transform.origin)
		print("body aabb=", mi.get_aabb())
	quit()
