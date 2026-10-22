extends RefCounted

## Sonda del HUD: comprueba que los paneles, el nivel, las vidas, los puntos,
## las misiones y el panel de jefe se actualizan correctamente.

var tree: SceneTree
var fails := 0
var log_lines: Array[String] = []

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	var ps := load("res://scenes/Level3.tscn") as PackedScene
	if ps == null:
		print("[hud] FAIL: no se pudo cargar Level3.tscn")
		return
	var root := ps.instantiate() as Node3D
	tree.root.add_child(root)
	tree.current_scene = root
	for i in 6:
		await tree.process_frame

	var hud := root.get_node_or_null("HUD") as CanvasLayer
	_check(hud != null, "el HUD esta en la escena")
	if hud == null:
		_summary()
		return

	var level_label := hud.get_node_or_null("Root/TopLeft/Level") as Label
	var objective := hud.get_node_or_null("Root/Bottom/Objective") as Label
	var mission := hud.get_node_or_null("Mission") as Label
	var boss_panel := hud.get_node_or_null("Root/Boss") as Control
	_check(level_label != null and level_label.text == "NIVEL 3", "muestra el nivel 3 (%s)" % (level_label.text if level_label else "-"))
	_check(mission != null and mission.visible and mission.text.begins_with("MISIÓN"), "muestra la mision (%s)" % (mission.text if mission else "-"))
	_check(objective != null and objective.text.begins_with("OBJETIVO"), "muestra el objetivo (%s)" % (objective.text if objective else "-"))
	_check(boss_panel != null and not boss_panel.visible, "el panel de jefe empieza oculto")

	var lives_label: Label = hud.get("lives_label")
	var points_label: Label = hud.get("points_label")
	_check(lives_label != null and lives_label.text.contains("♥"), "muestra las vidas (%s)" % (lives_label.text if lives_label else "-"))

	# puntos
	GameState.add_points(250, "prueba")
	await tree.process_frame
	_check(points_label != null and points_label.text.contains("250"), "actualiza los puntos (%s)" % (points_label.text if points_label else "-"))

	# vidas
	GameState.lose_life()
	await tree.process_frame
	_check(lives_label != null and lives_label.text.count("♥") == 4, "actualiza los corazones (%s)" % (lives_label.text if lives_label else "-"))

	# panel de jefe
	var kael := root.get_node_or_null("Interior/Kael")
	if kael:
		GameState.spawn_boss(kael, 900.0, "KAEL")
		await tree.process_frame
		_check(boss_panel != null and boss_panel.visible, "el panel de jefe aparece")
		var boss_label := hud.get_node_or_null("Root/Boss/BossLabel") as Label
		_check(boss_label != null and boss_label.text == "KAEL", "el panel de jefe muestra el titulo (%s)" % (boss_label.text if boss_label else "-"))
		GameState.boss_down()
		await tree.process_frame
		_check(boss_panel != null and not boss_panel.visible, "el panel de jefe se oculta al caer")

	# cambio de nivel
	GameState.reset_level(2, 0, 0, ["mision de prueba"])
	await tree.process_frame
	_check(level_label != null and level_label.text == "NIVEL 2", "el HUD reacciona al cambio de nivel (%s)" % (level_label.text if level_label else "-"))

	_summary()

func _check(cond: bool, what: String) -> void:
	if cond:
		log_lines.append("OK    " + what)
	else:
		log_lines.append("FALLO " + what)
		fails += 1

func _summary() -> void:
	print("\n=== HUD ===")
	for l in log_lines:
		print(l)
	print("fallos: ", fails)
