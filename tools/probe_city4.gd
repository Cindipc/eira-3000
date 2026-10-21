extends SceneTree

func _initialize() -> void:
	var ps: PackedScene = load("res://assets/levels/Futuristic_City.fbx")
	var n: Node = ps.instantiate()
	var on_plat := 0
	var near := {}
	var names := {}
	var stack: Array[Node] = [n]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for c in cur.get_children():
			stack.append(c)
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			if mi.mesh == null:
				continue
			var xform := _accumulate(mi, n)
			var laabb := mi.get_aabb()
			var mn := Vector3(INF, INF, INF)
			var mx := Vector3(-INF, -INF, -INF)
			for i in 8:
				var corner := Vector3(
					laabb.position.x if i & 1 else laabb.position.x + laabb.size.x,
					laabb.position.y if i & 2 else laabb.position.y + laabb.size.y,
					laabb.position.z if i & 4 else laabb.position.z + laabb.size.z)
				var w := xform * corner
				mn = mn.min(w)
				mx = mx.max(w)
			if mn.y > 38.0 and mx.y < 60.0:
				on_plat += 1
				var key := String(mi.name)
				names[key] = int(names.get(key, 0)) + 1
				var b := int(floor(mn.x / 20.0))
				near[b] = int(near.get(b, 0)) + 1
	print("meshes que tocan la plataforma (y 38..60): ", on_plat)
	var ks := near.keys()
	ks.sort()
	for k in ks:
		print("  x ", int(k) * 20, " -> ", near[k])
	var ns := names.keys()
	ns.sort()
	var shown := 0
	for k in ns:
		print("  name ", k, " -> ", names[k])
		shown += 1
		if shown > 25:
			break
	quit(0)

func _accumulate(node: Node, root: Node) -> Transform3D:
	var xform: Transform3D = (node as Node3D).transform
	var p := node.get_parent()
	while p != null and p != root:
		xform = (p as Node3D).transform * xform
		p = p.get_parent()
	return xform
