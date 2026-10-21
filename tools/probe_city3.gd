extends SceneTree

func _initialize() -> void:
	var ps: PackedScene = load("res://assets/levels/Futuristic_City.fbx")
	var n: Node = ps.instantiate()
	var rows := []
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
			rows.append({"n": String(mi.name), "mn": mn, "mx": mx})
	print("== corte en x (props con |mx.x| < 6 y altura < 12) ==")
	var zc := {}
	for r in rows:
		var rr: Dictionary = r
		var mn: Vector3 = rr["mn"]
		var mx: Vector3 = rr["mx"]
		if absf(mn.x) > 6.0 and absf(mx.x) > 6.0:
			continue
		if mx.y - mn.y > 12.0:
			continue
		var b := int(floor(mn.z / 5.0))
		zc[b] = int(zc.get(b, 0)) + 1
	var zs := zc.keys()
	zs.sort()
	for k in zs:
		print("  z ", int(k) * 5, " -> ", zc[k])
	print("== corte en z (props con |mn.z + 60| < 6) ==")
	var xc := {}
	for r in rows:
		var rr: Dictionary = r
		var mn: Vector3 = rr["mn"]
		var mx: Vector3 = rr["mx"]
		if absf(mn.z + 60.0) > 6.0 and absf(mx.z + 60.0) > 6.0:
			continue
		if mx.y - mn.y > 12.0:
			continue
		var b := int(floor(mn.x / 5.0))
		xc[b] = int(xc.get(b, 0)) + 1
	var xs := xc.keys()
	xs.sort()
	for k in xs:
		print("  x ", int(k) * 5, " -> ", xc[k])
	quit(0)

func _accumulate(node: Node, root: Node) -> Transform3D:
	var xform: Transform3D = (node as Node3D).transform
	var p := node.get_parent()
	while p != null and p != root:
		xform = (p as Node3D).transform * xform
		p = p.get_parent()
	return xform
