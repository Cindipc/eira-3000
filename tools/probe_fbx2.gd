extends SceneTree

func _initialize() -> void:
	var ps: PackedScene = load("res://assets/levels/Futuristic_City.fbx")
	var n: Node = ps.instantiate()
	print("ROOT: ", n.name, " xform=", n.transform)
	var rows := []
	var total_min := Vector3(INF, INF, INF)
	var total_max := Vector3(-INF, -INF, -INF)
	var zero_scale := 0
	var walk: Array[Node] = [n]
	var meshes := 0
	while not walk.is_empty():
		var cur: Node = walk.pop_back()
		for c in cur.get_children():
			walk.append(c)
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			if mi.mesh == null:
				continue
			meshes += 1
			var s := mi.scale
			if s.x == 0.0 or s.y == 0.0 or s.z == 0.0:
				zero_scale += 1
			var laabb := mi.get_aabb()
			var gt := mi.global_transform
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
			total_min = total_min.min(mn)
			total_max = total_max.max(mx)
			rows.append({"n": cur.name, "size": laabb.size, "min": mn, "max": mx, "p": cur.get_path()})
	rows.sort_custom(func(a, b): return (a["size"].length() * a["size"].length()) > (b["size"].length() * b["size"].length()))
	print("meshes=", meshes, " zero_scale=", zero_scale)
	print("TOTAL min=", total_min, " max=", total_max, " size=", total_max - total_min)
	for i in mini(rows.size(), 15):
		var r: Dictionary = rows[i]
		print(i, " ", r["n"], " size=", r["size"], " min=", r["min"], " max=", r["max"])
	quit(0)
