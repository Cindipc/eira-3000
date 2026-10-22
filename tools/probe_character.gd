extends SceneTree

func _initialize() -> void:
	var ps: PackedScene = load("res://assets/characters/character.fbx")
	var model: Node = ps.instantiate()
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for c in cur.get_children():
			stack.append(c)
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			if mi.mesh == null:
				continue
			var arrays: Array = mi.mesh.surface_get_arrays(0)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var surf_mat := ""
			if mi.mesh.get_surface_count() > 0:
				var m := mi.mesh.surface_get_material(0) as BaseMaterial3D
				if m:
					surf_mat = " albedo=%s" % str(m.albedo_color)
			print("%-16s verts=%d aabb=%s skin=%s skel_path=%s%s" % [
				mi.name, verts.size(), str(mi.get_aabb()),
				str(mi.skin != null), str(mi.skeleton), surf_mat])
			# muestra de normales medias en zona pecho para deducir orientacion
			var nrm: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			if not nrm.is_empty():
				var s := Vector3.ZERO
				var n := 0
				for i in verts.size():
					if verts[i].y > 1.2 and verts[i].y < 1.45 and absf(verts[i].x) < 0.16:
						s += nrm[i]
						n += 1
				if n > 0:
					print("    normal media torso: ", (s / float(n)).normalized())
	# orientacion de huesos: eje Z local de Head y Spine2
	var skel: Skeleton3D = null
	stack = [model]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for c in cur.get_children():
			stack.append(c)
		if cur is Skeleton3D:
			skel = cur as Skeleton3D
	if skel:
		for bn in ["mixamorig_Head", "mixamorig_Spine2", "mixamorig_LeftToeBase", "mixamorig_LeftHand"]:
			var idx: int = skel.get_bone_index(bn)
			if idx >= 0:
				var r := skel.get_bone_rest(idx)
				print("bone %-24s rest basis.z=%s basis.x=%s origin=%s" % [bn, str(r.basis.z), str(r.basis.x), str(r.origin)])
	quit(0)
