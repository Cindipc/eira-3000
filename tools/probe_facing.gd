extends SceneTree

func _init() -> void:
	var ps: PackedScene = load("res://assets/characters/eira.glb")
	var n: Node = ps.instantiate()
	get_root().add_child(n)
	var sk: Skeleton3D = _find_skel(n)
	if sk == null:
		print("NO SKELETON")
		quit(0)
		return
	print("bones=", sk.get_bone_count())
	for i in range(sk.get_bone_count()):
		var bn := sk.get_bone_name(i)
		var rest := sk.get_bone_rest(i)
		var gp := (sk.global_transform * sk.get_bone_global_pose(i)).origin
		print("  %2d %-22s rest=(%.3f,%.3f,%.3f) global=(%.3f,%.3f,%.3f)" % [
			i, bn, rest.origin.x, rest.origin.y, rest.origin.z, gp.x, gp.y, gp.z])
	quit(0)

func _find_skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for c in n.get_children():
		var r := _find_skel(c)
		if r != null:
			return r
	return null
