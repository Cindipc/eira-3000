extends RefCounted

var tree: SceneTree

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	await tree.process_frame
	await tree.physics_frame
	var nova := tree.root.find_child("Nova", true, false) as Node3D
	if nova == null:
		print("[tree] no se encontro Nova")
		return
	_dump(nova, 0)
	print("[tree] jugador:")
	var player := tree.get_first_node_in_group("player") as Node3D
	_dump(player.get_node("Visual"), 1)

func _dump(n: Node, depth: int) -> void:
	var t := n.get_class()
	var extra := ""
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		extra = " mesh=" + str(mi.mesh.resource_name if mi.mesh else "")
		if mi.mesh:
			var aabb: AABB = mi.mesh.get_aabb()
			extra += " aabb_pos=%s size=%s" % [str(aabb.position.snapped(Vector3(0.01,0.01,0.01))), str(aabb.size.snapped(Vector3(0.01,0.01,0.01)))]
	print("  ".repeat(depth) + "- " + n.name + " [" + t + "]" + extra)
	for c in n.get_children():
		_dump(c, depth + 1)
