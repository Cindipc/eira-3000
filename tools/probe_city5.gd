extends SceneTree

func _initialize() -> void:
	var ps: PackedScene = load("res://assets/levels/Futuristic_City.fbx")
	var n: Node = ps.instantiate()
	get_root().add_child(n)
	await process_frame
	var checked := 0
	var stack: Array[Node] = [n]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for c in cur.get_children():
			stack.append(c)
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			if mi.mesh == null:
				continue
			var laabb := mi.get_aabb()
			var mn := Vector3(INF, INF, INF)
			var mx := Vector3(-INF, -INF, -INF)
			for i in 8:
				var corner := Vector3(
					laabb.position.x if i & 1 else laabb.position.x + laabb.size.x,
					laabb.position.y if i & 2 else laabb.position.y + laabb.size.y,
					laabb.position.z if i & 4 else laabb.position.z + laabb.size.z)
				var w := mi.global_transform * corner
				mn = mn.min(w)
				mx = mx.max(w)
			var mine := _bounds(mi, n)
			var d: float = (mine["mn"] - mn).length() + (mine["mx"] - mx).length()
			print(String(mi.name), " tree=", str(mn), " .. ", str(mx), "  |  acum=", str(mine["mn"]), " .. ", str(mine["mx"]), "  diff=", d)
			checked += 1
			if checked > 6:
				quit(0)
				return
	quit(0)

func _bounds(mi: MeshInstance3D, root: Node) -> Dictionary:
	var xform := _accumulate(mi, root)
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
	return {"mn": mn, "mx": mx}

func _accumulate(node: Node, root: Node) -> Transform3D:
	var xform: Transform3D = (node as Node3D).transform
	var p := node.get_parent()
	while p != null and p != root:
		xform = (p as Node3D).transform * xform
		p = p.get_parent()
	return xform
