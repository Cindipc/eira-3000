extends RefCounted

var tree: SceneTree
var config := {}

func configure(cfg: Dictionary) -> void:
	config = cfg

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	var ps := load("res://assets/characters/kael.fbx") as PackedScene
	if ps == null:
		print("[kael] FAIL: no se pudo cargar kael.fbx")
		return
	var root := ps.instantiate()
	print("[kael] raiz: ", root.get_class(), " hijos=", root.get_child_count())
	for c in root.get_children():
		print("[kael]   hijo: ", c.name, " (", c.get_class(), ")")
	var stack: Array[Node] = [root]
	var meshes := 0
	var skeletons := 0
	var anims := 0
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for c in cur.get_children():
			stack.append(c)
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			meshes += 1
			if meshes <= 4:
				print("[kael]   malla: ", mi.name, " aabb=", mi.get_aabb())
		if cur is Skeleton3D:
			skeletons += 1
			var sk := cur as Skeleton3D
			var names: Array[String] = []
			for i in mini(sk.get_bone_count(), 60):
				names.append(sk.get_bone_name(i))
			print("[kael]   esqueleto: ", sk.name, " huesos=", sk.get_bone_count())
			print("[kael]   nombres: ", ", ".join(names))
		if cur is AnimationPlayer:
			anims += 1
			var ap := cur as AnimationPlayer
			print("[kael]   animaciones: ", ", ".join(ap.get_animation_list()))
	print("[kael] resumen: mallas=", meshes, " esqueletos=", skeletons, " animplayers=", anims)
	root.free()
	print("[kael] listo")
