extends SceneTree

func _initialize() -> void:
	for path in ["res://assets/characters/robot.glb", "res://assets/characters/nova.glb"]:
		var ps: PackedScene = load(path)
		if ps == null:
			print(path, " -> LOAD FAIL")
			continue
		var n: Node = ps.instantiate()
		var total_min := Vector3(INF, INF, INF)
		var total_max := Vector3(-INF, -INF, -INF)
		var meshes := 0
		var skels := 0
		var anims: Array[String] = []
		var walk: Array[Node] = [n]
		while not walk.is_empty():
			var cur: Node = walk.pop_back()
			for c in cur.get_children():
				walk.append(c)
			if cur is AnimationPlayer:
				var ap: AnimationPlayer = cur as AnimationPlayer
				for a in ap.get_animation_list():
					anims.append(String(a))
			if cur is Skeleton3D:
				skels += 1
			if cur is MeshInstance3D:
				var mi := cur as MeshInstance3D
				if mi.mesh == null:
					continue
				meshes += 1
				var laabb := mi.get_aabb()
				var gt := mi.global_transform
				for i in 8:
					var corner := Vector3(
						laabb.position.x if i & 1 else laabb.position.x + laabb.size.x,
						laabb.position.y if i & 2 else laabb.position.y + laabb.size.y,
						laabb.position.z if i & 4 else laabb.position.z + laabb.size.z)
					var w := gt * corner
					total_min = total_min.min(w)
					total_max = total_max.max(w)
		print(path, " meshes=", meshes, " skeletons=", skels)
		print("   bounds min=", total_min, " max=", total_max, " size=", total_max - total_min)
		print("   anims=", anims)
	quit(0)
