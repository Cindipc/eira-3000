extends RefCounted

var tree: SceneTree

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	var ps := load("res://assets/levels/Futuristic_City.fbx") as PackedScene
	if ps == null:
		print("[city] FAIL: no se pudo cargar el FBX")
		return
	var root := ps.instantiate() as Node3D
	var stack: Array[Node] = [root]
	var names := ["ocean", "cube_251", "cube_009", "cube_010"]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for c in cur.get_children():
			stack.append(c)
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			if mi.mesh == null:
				continue
			var lname := String(mi.name).to_lower()
			for n in names:
				if lname.contains(n):
					var gt := _accumulate(mi, root)
					var aabb := _world_aabb(mi, gt)
					print("[city] %s -> %s" % [mi.name, str(aabb)])
	print("[city] listo")

func _accumulate(node: Node, root: Node) -> Transform3D:
	var xform: Transform3D = (node as Node3D).transform
	var p := node.get_parent()
	while p != null and p != root:
		xform = (p as Node3D).transform * xform
		p = p.get_parent()
	return xform

func _world_aabb(mi: MeshInstance3D, gt: Transform3D) -> AABB:
	var laabb := mi.get_aabb()
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for i in 8:
		var corner := Vector3(
			laabb.position.x if i & 1 else laabb.position.x + laabb.size.x,
			laabb.position.y if i & 2 else laabb.position.y + laabb.size.y,
			laabb.position.z if i & 4 else laabb.position.z + laabb.size.z)
		var w := gt * corner
		mn = mn.min(w)
		mx = mx.max(w)
	return AABB(mn, mx - mn)
