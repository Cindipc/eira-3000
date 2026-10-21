extends SceneTree

func _init() -> void:
	var report: Array[String] = []
	for path in ["res://assets/characters/eira.glb", "res://assets/characters/nova.glb"]:
		var ps: PackedScene = load(path)
		if ps == null:
			report.append(path + " -> LOAD FAIL")
			continue
		var n: Node = ps.instantiate()
		# don't add to root, just use scene tree
		get_root().add_child(n)
		var aabb := AABB(Vector3.INF, Vector3.ZERO)
		var first := true
		var meshes := 0
		var walk: Array[Node] = [n]
		while not walk.is_empty():
			var cur: Node = walk.pop_back()
			for c in cur.get_children():
				walk.append(c)
			if cur is MeshInstance3D:
				meshes += 1
				var mi: MeshInstance3D = cur as MeshInstance3D
				var b: AABB = mi.get_aabb()
				var gt: Transform3D = mi.get_global_transform()
				b = gt * b
				if first:
					aabb = b
					first = false
				else:
					aabb = aabb.merge(b)
		var anims: Array[String] = []
		var pl: AnimationPlayer = _find_anim(n)
		if pl:
			for anim_name in pl.get_animation_list():
				anims.append(String(anim_name))
		report.append("%s -> meshes=%d size=(%.2f,%.2f,%.2f) min=(%.2f,%.2f,%.2f) anims=%s bones=%d" % [
			path, meshes, aabb.size.x, aabb.size.y, aabb.size.z,
			aabb.position.x, aabb.position.y, aabb.position.z, anims, _bone_count(n)])
		n.queue_free()
	for r in report:
		print(r)
	quit(0)

func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null

func _bone_count(n: Node) -> int:
	if n is Skeleton3D:
		var s: Skeleton3D = n as Skeleton3D
		return s.get_bone_count()
	for c in n.get_children():
		var r := _bone_count(c)
		if r > 0:
			return r
	return 0
