extends SceneTree

func _initialize() -> void:
	var ps: PackedScene = load("res://assets/levels/Futuristic_City.fbx")
	var n: Node = ps.instantiate()
	var small := 0
	var big := 0
	var xh := {}
	var zh := {}
	var ymin := INF
	var ymax := -INF
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
			var ex := mx.x - mn.x
			var ez := mx.z - mn.z
			var ey := mx.y - mn.y
			if maxf(ex, ez) > 8.0:
				big += 1
				continue
			small += 1
			ymin = minf(ymin, mn.y)
			ymax = maxf(ymax, mx.y)
			var xb := int(floor(mn.x / 20.0))
			var zb := int(floor(mn.z / 20.0))
			xh[xb] = int(xh.get(xb, 0)) + 1
			zh[zb] = int(zh.get(zb, 0)) + 1
	print("pequenos=", small, " grandes=", big, " y=", ymin, "..", ymax)
	var ks := xh.keys()
	ks.sort()
	for k in ks:
		print("  x ", int(k) * 20, " -> ", xh[k])
	var zs := zh.keys()
	zs.sort()
	for k in zs:
		print("  z ", int(k) * 20, " -> ", zh[k])
	quit(0)

func _accumulate(node: Node, root: Node) -> Transform3D:
	var xform: Transform3D = (node as Node3D).transform
	var p := node.get_parent()
	while p != null and p != root:
		xform = (p as Node3D).transform * xform
		p = p.get_parent()
	return xform
