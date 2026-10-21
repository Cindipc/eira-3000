extends SceneTree

func _initialize() -> void:
	var ps: PackedScene = load("res://assets/levels/Futuristic_City.fbx")
	var n: Node = ps.instantiate()
	var rows := []
	var gmin := Vector3(INF, INF, INF)
	var gmax := Vector3(-INF, -INF, -INF)
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
			gmin = gmin.min(mn)
			gmax = gmax.max(mx)
			rows.append({"n": String(mi.name), "mn": mn, "mx": mx})
	print("model bounds: ", gmin, " .. ", gmax)
	var rows2 := rows.duplicate()
	rows2.sort_custom(func(a, b):
		var va: float = (a["mx"] - a["mn"]).x * (a["mx"] - a["mn"]).y * (a["mx"] - a["mn"]).z
		var vb: float = (b["mx"] - b["mn"]).x * (b["mx"] - b["mn"]).y * (b["mx"] - b["mn"]).z
		return va > vb)
	for i in mini(rows2.size(), 25):
		var r: Dictionary = rows2[i]
		print(i, " ", r["n"], " min=", str(r["mn"]), " max=", str(r["mx"]))
	quit(0)

func _accumulate(node: Node, root: Node) -> Transform3D:
	var xform: Transform3D = (node as Node3D).transform
	var p := node.get_parent()
	while p != null and p != root:
		xform = (p as Node3D).transform * xform
		p = p.get_parent()
	return xform
