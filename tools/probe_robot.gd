extends SceneTree

func _initialize() -> void:
	var ps: PackedScene = load("res://assets/characters/robot.glb")
	var n: Node = ps.instantiate()
	_print(n, 0)
	quit(0)

func _print(n: Node, d: int) -> void:
	for c in n.get_children():
		var pad := ""
		for i in d:
			pad += "  "
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			if mi.mesh == null:
				print(pad, c.name, " NO_MESH")
			else:
				var b := mi.get_aabb()
				print(pad, c.name, " aabb pos=", b.position, " size=", b.size, " surf=", mi.mesh.get_surface_count())
		else:
			print(pad, c.name, " [", c.get_class(), "]")
		_print(c, d + 1)
