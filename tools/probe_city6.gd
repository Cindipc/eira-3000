extends SceneTree

func _initialize() -> void:
	var ps: PackedScene = load("res://assets/levels/Futuristic_City.fbx")
	var n: Node = ps.instantiate()
	get_root().add_child(n)
	await process_frame
	var stack: Array[Node] = [n]
	var names := ["cube_251", "cube_010", "ocean", "plane_plane_002"]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for c in cur.get_children():
			stack.append(c)
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			if mi.mesh == null:
				continue
			var lname := String(mi.name).to_lower()
			for want in names:
				if lname.contains(want):
					var verts := mi.mesh.get_surface_count()
					var vcount := 0
					for s in verts:
						vcount += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
					var aabb := mi.get_aabb()
					print(String(mi.name), " | superficies=", verts, " verts=", vcount, " aabb=", aabb)
	quit(0)
