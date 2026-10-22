extends RefCounted

## Sonda del Nivel 3: carga la escena, comprueba que todo el contenido del
## Nucleo esta presente y lista un informe por consola.

var tree: SceneTree

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	var ps := load("res://scenes/Level3.tscn") as PackedScene
	if ps == null:
		print("[l3] FAIL: no se pudo cargar Level3.tscn")
		return
	var root := ps.instantiate() as Node3D
	tree.current_scene = root
	tree.root.add_child(root)
	await tree.process_frame
	await tree.process_frame

	print("[l3] raiz: ", root.name)
	print("[l3] hijos: ", _child_names(root))

	var interior := root.get_node_or_null("Interior") as Node3D
	if interior == null:
		print("[l3] FAIL: no existe Interior")
		return
	print("[l3] interior en ", interior.position)

	var counts := {
		"andrones controlados": _count_by_prefix(interior, "ControlledAndroids", "Controlled_"),
		"nodos de seguridad": _count_by_prefix(interior, "SecurityNodes", "SecurityNode_"),
		"rebeldes": _count_by_prefix(interior, "Rebels", "Rebel_"),
		"archivos secretos": _count_by_prefix(interior, "SecretFiles", "SecretFile_"),
	}
	for k in counts:
		print("[l3] %s: %d" % [k, counts[k]])

	var consoles := interior.get_node_or_null("Geometry/Consoles")
	print("[l3] consolas: ", _child_names(consoles) if consoles else "FALTA")
	var terminal := interior.get_node_or_null("Geometry/CoreTerminal")
	print("[l3] terminal central: ", "OK" if terminal else "FALTA")
	var origen := interior.get_node_or_null("Origen/OrigenEntity")
	print("[l3] ORIGEN: ", "OK" if origen else "FALTA")
	var kael := interior.get_node_or_null("Kael")
	print("[l3] Kael: ", "OK" if kael else "FALTA")
	if kael:
		print("[l3] Kael tiene modelo: ", kael.get("model_scene") != null)
		print("[l3] Kael puntos de invocacion: ", (kael.get("spawn_points") as Array).size())
		var model := kael.get_node_or_null("Visual/KaelModel")
		if model:
			print("[l3] modelo escala: ", model.scale, " pos: ", model.position)
			print("[l3] modelo AABB local: ", _model_aabb(model))
			print("[l3] modelo AABB global: ", _global_aabb(model))
		var rig := kael.get_node_or_null("Visual/KaelModel/Rig")
		if rig:
			print("[l3] rig con huesos: ", rig.call("has_bones"))
	var door := root.get_node_or_null("NucleoExterior/NucleoDoor")
	print("[l3] puerta del nucleo: ", "OK" if door else "FALTA")
	if door:
		print("[l3] puerta -> interior: ", door.get("interior_spawn"))
	var director := root.get_node_or_null("L3Director")
	print("[l3] director: ", "OK" if director else "FALTA")
	print("[l3] vidas: ", GameState.max_lives, " | nivel: ", GameState.current_level)
	print("[l3] misiones: ", GameState.missions.size())
	print("[l3] puntos: ", GameState.points)

	# prueba de interaccion: cuenta las areas interactuables
	var areas := 0
	for n in _all_nodes(root):
		if n is Area3D and n.is_in_group("interactable"):
			areas += 1
	print("[l3] areas interactuables: ", areas)
	print("[l3] OK")

func _child_names(node: Node) -> String:
	var names := []
	for c in node.get_children():
		names.append(String(c.name))
	return ", ".join(names)

func _count_by_prefix(interior: Node3D, group: String, prefix: String) -> int:
	var holder := interior.get_node_or_null(group)
	if holder == null:
		return 0
	var n := 0
	for c in holder.get_children():
		if String(c.name).begins_with(prefix):
			n += 1
	return n

func _all_nodes(node: Node) -> Array:
	var out: Array = []
	var stack: Array = [node]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		out.append(cur)
		for c in cur.get_children():
			stack.append(c)
	return out

func _model_aabb(node: Node3D) -> AABB:
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	var found := false
	for n in _all_nodes(node):
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh == null:
				continue
			found = true
			var la := mi.get_aabb()
			mn = mn.min(la.position)
			mx = mx.max(la.position + la.size)
	if not found:
		return AABB()
	return AABB(mn, mx - mn)

func _global_aabb(node: Node3D) -> AABB:
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for n in _all_nodes(node):
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh == null:
				continue
			var la := mi.get_aabb()
			var xf := mi.global_transform
			for i in 8:
				var corner := Vector3(
					la.position.x if i & 1 else la.position.x + la.size.x,
					la.position.y if i & 2 else la.position.y + la.size.y,
					la.position.z if i & 4 else la.position.z + la.size.z)
				var w := xf * corner
				mn = mn.min(w)
				mx = mx.max(w)
	return AABB(mn, mx - mn)
