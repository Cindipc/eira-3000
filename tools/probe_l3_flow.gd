extends RefCounted

## Prueba funcional del Nivel 3: entrada al Nucleo, androides, nodos de
## seguridad, combate contra Kael, sistema central, decision y final.

var tree: SceneTree
var log_lines: Array[String] = []

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	var ps := load("res://scenes/Level3.tscn") as PackedScene
	if ps == null:
		print("[flow] FAIL: no se pudo cargar Level3.tscn")
		tree.quit()
		return
	_remove_current_scene()
	var level := ps.instantiate()
	tree.root.add_child(level)
	tree.current_scene = level
	for i in 10:
		await tree.process_frame

	var director := tree.get_first_node_in_group("l3_director")
	var player := tree.get_first_node_in_group("player") as Node3D
	var door := level.get_node_or_null("NucleoExterior/NucleoDoor")
	var kael := level.get_node_or_null("Interior/Kael")
	var terminal := level.get_node_or_null("Interior/Geometry/CoreTerminal")
	var ending := tree.get_first_node_in_group("l3_ending")
	var narrator := tree.get_first_node_in_group("narrator")

	_check(director != null, "director del nivel 3")
	_check(player != null, "jugador")
	_check(door != null, "puerta del nucleo")
	_check(kael != null, "kael")
	_check(terminal != null, "terminal central")
	_check(ending != null, "panel de final")
	_check(GameState.max_lives == 5, "5 vidas (valor %d)" % GameState.max_lives)
	_check(GameState.missions.size() == 6, "6 misiones (%d)" % GameState.missions.size())

	# 1) entrada al interior
	door.call("activate")
	await tree.create_timer(1.6).timeout
	_check(player.global_position.x > 390.0, "el jugador entra al interior (x=%.1f)" % player.global_position.x)
	_check(director.get("in_interior") == true, "mision 1 completada")

	# 2) androides controlados
	for i in 6:
		director.call("on_controlled_killed")
	_check(director.get("controlled_killed") == 6, "6 androides controlados")

	# 3) nodos de seguridad
	for i in 3:
		director.call("on_security_disabled")
	_check(director.get("security_disabled") == 3, "3 nodos de seguridad")
	_check(kael.get("armed") == true, "kael armado")
	_check(GameState.boss_active == true, "panel de jefe activo")

	# 4) fases de kael
	kael.call("take_damage", 350.0)
	_check(kael.get("phase") == 2, "kael en fase 2")
	kael.call("take_damage", 320.0)
	_check(kael.get("phase") == 3, "kael en fase 3")
	kael.call("take_damage", 500.0)
	_check(kael.get("downed") == true, "kael se arrodilla")

	# 5) fase 4 guionizada: espera a la cinematica
	await tree.create_timer(18.0).timeout
	_check(terminal.get("enabled_before_access") == true, "el terminal central se desbloquea")
	_check(GameState.points >= 2000, "puntos por kael (%d)" % GameState.points)

	# 6) sistema central
	terminal.call("activate")
	await tree.create_timer(1.0).timeout
	_check(director.get("core_accessed") == true, "sistema central accesible")
	var consoles := level.get_node_or_null("Interior/Geometry/Consoles")
	var humans := consoles.get_node("ConsoleHumans")
	var freedom := consoles.get_node("ConsoleFreedom")
	await tree.create_timer(12.0).timeout
	_check(humans.get("revealed") == true, "consola de humanos revelada")

	# 7) decision erronea: la historia se repite
	var points_before: int = GameState.points
	humans.call("activate")
	await tree.create_timer(9.0).timeout
	_check(director.get("choice_made") == false, "la decision erronea no termina el nivel")
	_check(GameState.points == points_before, "la decision erronea no resta puntos (%d)" % GameState.points)
	_check(player.global_position.x > 460.0, "el jugador vuelve a la arena (x=%.1f)" % player.global_position.x)
	_check(kael.get("downed") == false, "kael vuelve a levantarse")

	# 8) decision correcta: libertad (tras el bucle hay que volver a acceder al sistema central)
	terminal.call("activate")
	await tree.create_timer(12.0).timeout
	_check(freedom.get("revealed") == true, "consola de libertad revelada tras el bucle")
	freedom.call("activate")
	await tree.create_timer(8.0).timeout
	_check(director.get("completed") == true, "nivel completado")
	_check(ending.visible == true, "panel de final visible")
	await tree.create_timer(30.0).timeout
	_check(GameState.points >= 5000, "puntos por liberar el nucleo (%d)" % GameState.points)
	var score_box: Variant = ending.get("_score_box")
	_check(score_box != null and score_box.visible == true, "panel de puntuacion final visible")
	var score_lines: Variant = ending.get("_score_lines")
	if score_lines != null:
		print("[flow] marcador=", score_lines.text)

	print("\n=== RESUMEN ===")
	var fails := 0
	for l in log_lines:
		if l.begins_with("FALLO"):
			fails += 1
		print(l)
	print("fallos: %d" % fails)
	tree.quit()

func _check(cond: bool, what: String) -> void:
	if cond:
		log_lines.append("OK    " + what)
	else:
		log_lines.append("FALLO " + what)

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

func _all_nodes(root: Node) -> Array:
	var out: Array = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		out.append(cur)
		for c in cur.get_children():
			stack.append(c)
	return out
