extends SceneTree

func _initialize() -> void:
	var ps: PackedScene = load("res://assets/levels/Futuristic_City.fbx")
	if ps == null:
		print("LOAD FAIL")
		quit(1)
		return
	var n: Node = ps.instantiate()
	var aabb := AABB(Vector3.INF, Vector3.ZERO)
	var first := true
	var meshes := 0
	var tris := 0
	var mats := {}
	var nodes := 0
	var walk: Array[Node] = [n]
	while not walk.is_empty():
		var cur: Node = walk.pop_back()
		nodes += 1
		for c in cur.get_children():
			walk.append(c)
		if cur is MeshInstance3D:
			meshes += 1
			var mi: MeshInstance3D = cur as MeshInstance3D
			var m := mi.mesh
			if m == null:
				print("NULL MESH: ", cur.get_path())
				continue
			if m.get_surface_count() == 0:
				print("EMPTY MESH: ", cur.get_path(), " name=", cur.name)
				continue
			for s in m.get_surface_count():
				var arr := m.surface_get_arrays(s)
				if arr.is_empty():
					continue
				var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				if verts.size() > 0:
					var gt := mi.get_global_transform()
					for v in verts:
						var wv := gt * v
						if first:
							aabb = AABB(wv, Vector3.ZERO)
							first = false
						else:
							aabb = aabb.expand(wv)
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
				if idx.size() > 0:
					tris += idx.size() / 3
				var mat := m.surface_get_material(s)
				if mat:
					mats[mat.resource_name] = true
	print("nodes=", nodes, " meshes=", meshes, " tris=", tris)
	if not first:
		print("AABB pos=", aabb.position, " size=", aabb.size)
	print("materials=", mats.keys())
	_print_tree(n, 0)
	quit(0)

func _print_tree(n: Node, depth: int) -> void:
	if depth > 4:
		return
	for c in n.get_children():
		var extra := ""
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			if mi.mesh:
				extra = " surfaces=%d" % mi.mesh.get_surface_count()
			else:
				extra = " NO_MESH"
		var pad := ""
		for i in depth:
			pad += "  "
		print(pad, c.name, " [", c.get_class(), "]", extra)
		_print_tree(c, depth + 1)
