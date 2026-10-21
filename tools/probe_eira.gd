extends SceneTree

func _initialize() -> void:
	var ps: PackedScene = load("res://assets/characters/eira.glb")
	if ps == null:
		print("LOAD FAIL")
		quit(1)
		return
	var n: Node = ps.instantiate()
	_print_tree(n, 0)
	quit(0)

func _print_tree(node: Node, depth: int) -> void:
	var extra := ""
	if node is Skeleton3D:
		var sk := node as Skeleton3D
		extra = " bones=%d" % sk.get_bone_count()
		for i in sk.get_bone_count():
			extra += "\n%s   bone %d: %s" % ["    ".repeat(depth + 1), i, sk.get_bone_name(i)]
	if node is AnimationPlayer:
		var ap := node as AnimationPlayer
		extra = " anims=%s" % str(ap.get_animation_list())
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			extra = " aabb=%s" % str(mi.get_aabb())
	print("  ".repeat(depth), node.name, " [", node.get_class(), "]", extra)
	for c in node.get_children():
		_print_tree(c, depth + 1)
