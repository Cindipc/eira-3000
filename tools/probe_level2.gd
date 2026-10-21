extends RefCounted

var tree: SceneTree
var config := {}
var problems: Array[String] = []

func configure(cfg: Dictionary) -> void:
	config = cfg

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	_remove_current_scene()
	var scene_path: String = str(config.get("scene", "res://scenes/Level2.tscn"))
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("no se pudo cargar " + scene_path)
		tree.quit()
		return
	var level: Node = packed.instantiate()
	tree.root.add_child(level)
	tree.current_scene = level
	for i in 20:
		await tree.physics_frame

	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state

	print("[probe] escena=%s" % scene_path)
	_check_corridor(space)
	_check_ground(space)
	_check_objects(space)
	_check_camera(space)

	if problems.is_empty():
		print("[probe] resultado=0 problemas")
	else:
		print("[probe] resultado=%d problemas" % problems.size())
		for p in problems:
			print("  - ", p)
	tree.quit()

func _all_nodes(root: Node) -> Array:
	var out: Array = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		out.append(cur)
		for c in cur.get_children():
			stack.append(c)
	return out

func _remove_current_scene() -> void:
	if tree.current_scene == null:
		return
	var old := tree.current_scene
	tree.current_scene = null
	tree.root.remove_child(old)
	for n in _all_nodes(old):
		for g in n.get_groups():
			n.remove_from_group(g)
	old.queue_free()

func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1
	return space.intersect_ray(q)

func _check_corridor(space: PhysicsDirectSpaceState3D) -> void:
	print("[corredor] linea de paso z=-7.3, cuerpo a y=1.0")
	var blocked := 0
	var interactive := 0
	var x := -50.0
	while x <= 50.0:
		var hit := _ray(space, Vector3(x, 1.0, -7.3), Vector3(x + 1.0, 1.0, -7.3))
		if not hit.is_empty():
			var col := hit["collider"] as Node
			if col != null and col.get_parent() != null and col.get_parent().is_in_group("terminal"):
				interactive += 1
			else:
				blocked += 1
				print("  obstaculo en x=%.1f -> %s" % [x, str(col.name)])
		x += 2.0
	print("  obstaculos: %d, terminales en el paso: %d" % [blocked, interactive])
	if blocked == 0:
		print("  ok: recorrido de acera despejado (50 tramos)")
	else:
		problems.append("%d obstaculos en la acera" % blocked)

	print("[corredor] linea de calzada z=-4.0")
	var road_blocked := 0
	x = -50.0
	while x <= 50.0:
		var hit := _ray(space, Vector3(x, 0.4, -4.0), Vector3(x + 1.0, 0.4, -4.0))
		if not hit.is_empty():
			road_blocked += 1
		x += 2.0
	print("  tramos bloqueados en la calzada: %d" % road_blocked)

func _check_ground(space: PhysicsDirectSpaceState3D) -> void:
	print("[suelo] muestreo bajo la acera")
	var heights: Array[float] = []
	var x := -48.0
	while x <= 48.0:
		var hit := _ray(space, Vector3(x, 2.4, -7.3), Vector3(x, -5.0, -7.3))
		if hit.is_empty():
			problems.append("sin suelo en x=%.1f" % x)
		else:
			heights.append(float((hit["position"] as Vector3).y))
		x += 4.0
	if not heights.is_empty():
		var lo := heights[0]
		var hi := heights[0]
		for h in heights:
			lo = minf(lo, h)
			hi = maxf(hi, h)
		print("  suelo y: min=%.2f max=%.2f (muestras=%d)" % [lo, hi, heights.size()])
		if hi - lo > 0.35:
			problems.append("suelo irregular en la acera (%.2f m)" % (hi - lo))

func _check_objects(space: PhysicsDirectSpaceState3D) -> void:
	print("[objetos] terminales, archivos, recogidas y salida")
	var player := tree.get_first_node_in_group("player") as Node3D
	for group in ["terminal", "data_file", "pickup", "level_exit", "barrier"]:
		var nodes := tree.get_nodes_in_group(group)
		for n in nodes:
			var n3 := n as Node3D
			if n3 == null:
				continue
			var p := n3.global_position
			var buried := false
			var shape := SphereShape3D.new()
			shape.radius = 0.35
			var params := PhysicsShapeQueryParameters3D.new()
			params.shape = shape
			params.transform = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.45)
			params.collision_mask = 1
			params.exclude = [player] if player else []
			var hits := space.intersect_shape(params, 2)
			for h in hits:
				var col := h["collider"] as Node
				if col == null or _is_child_of(col, n3):
					continue
				if col.name.to_lower().contains("street"):
					continue
				buried = true
			if buried:
				print("  %s %s en %s esta dentro de la geometria" % [group, n3.name, str(p.round())])
				problems.append("%s %s incrustado" % [group, n3.name])
			else:
				print("  ok: %s %s en %s" % [group, n3.name, str(p.round())])
		if nodes.is_empty():
			print("  (sin nodos en el grupo %s)" % group)

func _is_child_of(node: Node, root: Node) -> bool:
	var cur: Node = node
	while cur != null:
		if cur == root:
			return true
		cur = cur.get_parent()
	return false

func _check_camera(space: PhysicsDirectSpaceState3D) -> void:
	print("[camara] visibilidad desde el punto de inicio")
	var player := tree.get_first_node_in_group("player") as Node3D
	if player == null:
		problems.append("no hay jugador")
		return
	var origin := player.global_position + Vector3.UP * 1.6
	for group in ["terminal", "level_exit"]:
		for n in tree.get_nodes_in_group(group):
			var n3 := n as Node3D
			var target := n3.global_position + Vector3.UP * 1.2
			var hit := _ray(space, origin, target)
			var visible := hit.is_empty() or _is_child_of(hit["collider"] as Node, n3)
			var blocker := "-"
			if not hit.is_empty():
				blocker = "%s@%s" % [(hit["collider"] as Node).name, str((hit["position"] as Vector3).round())]
			print("  %s %s visible=%s dist=%.1f bloqueado_por=%s" % [group, n3.name, str(visible), origin.distance_to(n3.global_position), blocker])
