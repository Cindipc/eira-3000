extends RefCounted

var tree: SceneTree

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	await tree.process_frame
	await tree.physics_frame
	var player := tree.get_first_node_in_group("player") as Node3D
	var cam := player.get_node("CameraPivot/Camera3D") as Camera3D
	var nova := tree.root.find_child("Nova", true, false) as Node3D
	var visual := player.get_node("Visual") as Node3D

	print("[fps] camara global = %s" % str(cam.global_position))
	print("[fps] camara local en el pivote = %s" % str(cam.position))
	print("[fps] jugador global = %s" % str(player.global_position))
	print("[fps] pivote global = %s" % str(player.get_node("CameraPivot").global_position))
	print("[fps] cull_mask = %d" % cam.cull_mask)
	for n in visual.find_children("*", "VisualInstance3D", true, false):
		var vi := n as VisualInstance3D
		print("[fps] cuerpo %s layers=%d visible=%s" % [vi.name, vi.layers, str(vi.visible)])

	print("[fps] nova global = %s" % str(nova.global_position))
	print("[fps] jugador global = %s" % str(player.global_position))
	print("[fps] offset nova-jugadora = %s" % str((nova.global_position - player.global_position).snapped(Vector3(0.01, 0.01, 0.01))))
	print("[fps] rotacion nova = %.2f  visual eira = %.2f" % [nova.rotation.y, visual.rotation.y])
	for n in nova.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		print("[fps] nova malla %s visible=%s" % [mi.name, str(mi.visible)])

	await tree.create_timer(2.0).timeout
	print("[fps] nova global (tras 2s) = %s" % str(nova.global_position))
	print("[fps] offset = %s" % str((nova.global_position - player.global_position).snapped(Vector3(0.01, 0.01, 0.01))))
	print("[fps] rotacion nova = %.2f  visual eira = %.2f" % [nova.rotation.y, visual.rotation.y])
