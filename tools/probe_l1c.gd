extends RefCounted

## Sonda: que pasa cuando el jugador pierde las tres vidas (game over).
## Antes el juego se quedaba bloqueado para siempre sin ninguna salida.

var tree: SceneTree
var fails := 0

func run(p_tree: SceneTree) -> void:
	tree = p_tree
	await tree.process_frame
	await tree.physics_frame
	var player := tree.get_first_node_in_group("player") as Node3D
	if player == null:
		_fail("no hay jugador")
		_summary()
		return

	print("[l1c] vidas iniciales: %d / %d" % [GameState.lives, GameState.max_lives])
	for i in 3:
		if not is_instance_valid(player):
			break
		if player.dead:
			await tree.create_timer(5.0).timeout
		else:
			await tree.create_timer(3.0).timeout
		player.take_damage(9999.0)
		await tree.process_frame
		await tree.process_frame
		print("[l1c] muerte %d -> vidas %d, dead=%s" % [i + 1, GameState.lives, str(player.dead)])

	await tree.create_timer(2.0).timeout
	if is_instance_valid(player):
		print("[l1c] jugador: dead=%s, vidas=%d" % [str(player.dead), GameState.lives])

	var panel := _game_over_panel()
	if panel != null and panel.visible:
		print("[l1c] OK: la pantalla de fin de partida aparece")
	else:
		_fail("no aparece la pantalla de fin de partida")

	# reinicio con [R]
	if is_instance_valid(player):
		_press(KEY_R)
		await tree.create_timer(0.5).timeout
		await tree.process_frame
		var player2 := tree.get_first_node_in_group("player") as Node3D
		if player2 != null:
			print("[l1c] tras [R]: nivel reiniciado, vidas=%d, jugador dead=%s" % [GameState.lives, str(player2.dead)])
			if GameState.lives == GameState.max_lives:
				_ok("el reinicio restaura las vidas")
			else:
				_fail("el reinicio no restaura las vidas (%d)" % GameState.lives)
		else:
			_fail("[R] no reinicio el nivel")
	_summary()

func _press(key: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.physical_keycode = key
	ev.pressed = true
	Input.parse_input_event(ev)
	await tree.process_frame
	var up := InputEventKey.new()
	up.keycode = key
	up.physical_keycode = key
	up.pressed = false
	Input.parse_input_event(up)

func _game_over_panel() -> Control:
	for n in _all(tree.current_scene):
		if n is Control and n.name == "GameOver":
			return n
	return null

func _all(root: Node) -> Array:
	var out: Array = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		out.append(cur)
		for c in cur.get_children():
			stack.append(c)
	return out

func _ok(msg: String) -> void:
	print("  ok: ", msg)

func _fail(msg: String) -> void:
	fails += 1
	print("  FALLO: ", msg)

func _summary() -> void:
	print("[l1c] fallos=%d" % fails)
