extends Node

## Director del Nivel 3 "La ultima guerra".
##
## Orquesta la entrada al Nucleo, los androides controlados, los sistemas de
## seguridad, el combate contra Kael en cuatro fases, el acceso al sistema
## central con la sangre de Eira, la decision final (humanos / androides /
## libertad) y el epilogo.

const MISSIONS: Array[String] = [
	"Entra en el Nucleo Central",
	"Derrota a los androides controlados [6]",
	"Desactiva los sistemas de seguridad [3]",
	"Enfrentate a Kael",
	"Llega hasta el sistema central",
	"Elige el destino de humanos y androides",
]

const CONTROLLED_NEEDED := 6
const SECURITY_NEEDED := 3

var started := false
var in_interior := false
var controlled_killed := 0
var security_disabled := 0
var rebels_rescued := 0
var files_found := 0
var core_accessed := false
var choice_made := false
var completed := false
var kael_downed := false
var no_death := true

@export var kael: Node3D = null
@export var core_terminal: Node = null
@export var arena_spawn: Node3D = null
@export var interior_spawn: Node3D = null
var consoles := {}

var _lives_at_start := 5
var _cinematic_running := false
var _choice_stage := 0

func _ready() -> void:
	add_to_group("l3_director")
	_resolve_refs()
	GameState.reset_level(3, 0, 0, MISSIONS)
	_lives_at_start = GameState.max_lives
	GameState.set_objective("OBJETIVO: Entra en el Nucleo Central de la ciudad")
	GameState.notify("NIVEL 3 - LA ULTIMA GUERRA", Color(1.0, 0.45, 0.35))

func _resolve_refs() -> void:
	## Las referencias a nodos se guardan como NodePath en la escena; este metodo
	## garantiza que existan aunque el director se instancie desde codigo.
	var root := get_parent()
	if kael == null:
		kael = get_tree().get_first_node_in_group("kael") as Node3D
	if root != null:
		if core_terminal == null:
			core_terminal = root.get_node_or_null("Interior/Geometry/CoreTerminal")
		if arena_spawn == null:
			arena_spawn = root.get_node_or_null("Interior/Markers/ArenaSpawn")
		if interior_spawn == null:
			interior_spawn = root.get_node_or_null("Interior/Markers/EntranceSpawn")
	if consoles.is_empty() or consoles.get("humans") == null:
		var humans: Node = null
		var androids: Node = null
		var freedom: Node = null
		if root != null:
			humans = root.get_node_or_null("Interior/Geometry/Consoles/ConsoleHumans")
			androids = root.get_node_or_null("Interior/Geometry/Consoles/ConsoleAndroids")
			freedom = root.get_node_or_null("Interior/Geometry/Consoles/ConsoleFreedom")
		consoles = {"humans": humans, "androids": androids, "freedom": freedom}

func _narrator() -> Node:
	return get_tree().get_first_node_in_group("narrator")

func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D

# ------------------------------------------------------------------ entrada
func on_entered_interior() -> void:
	if in_interior:
		return
	in_interior = true
	started = true
	_complete_mission("Nucleo accessed")
	GameState.notify("SISTEMAS DEL NUCLEO EN LINEA", Color(1.0, 0.4, 0.4))
	var n := _narrator()
	if n and n.has_method("say"):
		n.call("say", "NOVA: estamos dentro, Eira. Kael controla la ciudad desde aqui.", 5.0)

# ------------------------------------------------------------------ misiones
func on_controlled_killed(node: Node = null) -> void:
	if controlled_killed >= CONTROLLED_NEEDED:
		return
	controlled_killed += 1
	GameState.award("enemy")
	if controlled_killed >= CONTROLLED_NEEDED:
		_complete_mission("Mision")
		GameState.set_objective("OBJETIVO: Desactiva los 3 sistemas de seguridad")
		var n := _narrator()
		if n and n.has_method("say"):
			n.call("say", "NOVA: sala despejada. Ahora los sistemas de seguridad.", 4.0)
	else:
		GameState.set_objective("OBJETIVO: Derrota a los androides controlados (%d/%d)" % [controlled_killed, CONTROLLED_NEEDED])

func on_security_disabled(node: Node = null) -> void:
	security_disabled += 1
	if security_disabled >= SECURITY_NEEDED:
		_complete_mission("Mision")
		GameState.set_objective("OBJETIVO: Enfrentate a Kael")
		var n := _narrator()
		if n and n.has_method("say"):
			n.call("say", "NOVA: seguridad caida. Kael te espera en la camara del Nucleo.", 4.5)
		_open_arena()
	else:
		GameState.set_objective("OBJETIVO: Desactiva los sistemas de seguridad (%d/%d)" % [security_disabled, SECURITY_NEEDED])

func on_rebel_rescued(node: Node = null) -> void:
	rebels_rescued += 1
	GameState.award("rebel")

func on_secret_file(node: Node = null) -> void:
	files_found += 1
	GameState.award("secret_file")

func _complete_mission(label: String) -> void:
	GameState.advance_mission(-1, label)

# ------------------------------------------------------------------ Kael
func on_kael_phase(phase: int) -> void:
	match phase:
		2:
			GameState.set_objective("OBJETIVO: Kael invoca androides controlados: sobrevive")
			var n := _narrator()
			if n and n.has_method("say"):
				n.call("say", "NOVA: Kael esta reclutando androides. Elimina a los controlados.", 4.0)
		3:
			GameState.set_objective("OBJETIVO: Kael usa el poder del Nucleo: resiste")
			var n2 := _narrator()
			if n2 and n2.has_method("say"):
				n2.call("say", "NOVA: el Nucleo esta descargando. No te acerques a las ondas.", 4.0)

func on_kael_downed() -> void:
	if kael_downed:
		return
	kael_downed = true
	_complete_mission("Mision")
	GameState.award("kael")
	GameState.set_objective("OBJETIVO: Llega hasta el sistema central")
	_run_final_phase_cinematic()

func _open_arena() -> void:
	if kael == null:
		kael = get_tree().get_first_node_in_group("kael")
	if kael == null:
		return
	if arena_spawn and kael is Node3D:
		(kael as Node3D).global_position = arena_spawn.global_position
	if kael.has_method("arm"):
		kael.call("arm", self)
	if kael.has_method("open_arena"):
		kael.call("open_arena")
	GameState.spawn_boss(kael, 900.0, "KAEL")

# ------------------------------------------------------------------ fase 4
func _run_final_phase_cinematic() -> void:
	if _cinematic_running:
		return
	_cinematic_running = true
	var n := _narrator()
	var player := _player()
	if player and player.has_method("set_input_locked"):
		player.call("set_input_locked", true)
	var kael_node := kael as Node3D
	if player and kael_node:
		var to_kael := kael_node.global_position - player.global_position
		to_kael.y = 0.0
		var yaw := atan2(-to_kael.x, -to_kael.z)
		if player.has_method("cinematic_camera"):
			player.call("cinematic_camera", yaw, -0.08)
	await get_tree().create_timer(1.6).timeout
	if n and n.has_method("say"):
		n.call("say", "KAEL: Se acabo.", 2.6)
	await get_tree().create_timer(2.4).timeout
	# el corazon falla: Eira se desploma
	if n and n.has_method("flash"):
		n.call("flash", Color(0.9, 0.1, 0.15), 0.9)
	if player and player.has_method("cinematic_rise"):
		player.call("cinematic_rise", -1.1)
	if player and player.has_method("cinematic_camera"):
		player.call("cinematic_camera", player.get_node("CameraPivot").rotation.y, -0.45)
	GameState.set_health(18.0, 100.0)
	await get_tree().create_timer(2.6).timeout
	# Eira se levanta
	if player and player.has_method("cinematic_rise"):
		player.call("cinematic_rise", 0.0)
	if player and player.has_method("cinematic_camera"):
		player.call("cinematic_camera", player.get_node("CameraPivot").rotation.y, -0.1)
	if n and n.has_method("say"):
		n.call("say", "EIRA: Mi corazon nunca fue mi debilidad... fue la razon por la que aprendi a luchar.", 5.0)
	await get_tree().create_timer(4.6).timeout
	if n and n.has_method("say"):
		n.call("say", "NOVA: Eira... ve. El sistema central esta al fondo de la camara.", 4.5)
	if player and player.has_method("set_input_locked"):
		player.call("set_input_locked", false)
	if core_terminal and core_terminal.has_method("unlock"):
		core_terminal.call("unlock")
	_cinematic_running = false

# ------------------------------------------------------------------ decision
func on_core_accessed() -> void:
	if core_accessed:
		return
	core_accessed = true
	_complete_mission("Mision")
	GameState.set_objective("OBJETIVO: Elige el destino de humanos y androides")
	_reveal_choices()

func _reveal_choices() -> void:
	var n := _narrator()
	var humans: Node = consoles.get("humans")
	var androids: Node = consoles.get("androids")
	var freedom: Node = consoles.get("freedom")
	if humans and humans.has_method("reveal"):
		humans.call("reveal", Color(1.0, 0.55, 0.35))
	if n and n.has_method("say"):
		n.call("say", "EIRA: Los humanos primero... pero el nucleo volveria a decidir por nosotros.", 5.0)
	await get_tree().create_timer(4.2).timeout
	if androids and androids.has_method("reveal"):
		androids.call("reveal", Color(0.6, 0.6, 1.0))
	if n and n.has_method("say"):
		n.call("say", "EIRA: Los androides... son mis hermanos. Tampoco puedo condenarlos.", 5.0)
	await get_tree().create_timer(4.2).timeout
	if freedom and freedom.has_method("reveal"):
		freedom.call("reveal", Color(0.35, 1.0, 0.6))
	if n and n.has_method("say"):
		n.call("say", "EIRA: Ni unos ni otros. LIBERTAD para todos.", 4.5)

func on_choice(option: int) -> void:
	if choice_made or completed:
		return
	if option == 2:
		choice_made = true
		_complete_mission("Mision")
		GameState.award("core")
		no_death = GameState.lives >= _lives_at_start
		if no_death:
			GameState.award("no_death")
			GameState.notify("Nivel sin morir +1000", Color(1.0, 0.85, 0.35))
		GameState.set_objective("OBJETIVO: Eira se ofrece al Nucleo")
		_run_ending()
	else:
		_wrong_choice(option)

func _wrong_choice(option: int) -> void:
	var n := _narrator()
	var line := "EIRA: los humanos primero..."
	if option == 1:
		line = "EIRA: los androides primero..."
	if n and n.has_method("say"):
		n.call("say", line, 3.0)
	await get_tree().create_timer(2.4).timeout
	if n and n.has_method("fade_to_black"):
		n.call("fade_to_black", 0.7)
	await get_tree().create_timer(0.9).timeout
	if n and n.has_method("glitch_card"):
		n.call("glitch_card", "LA HISTORIA SE REPITE")
	await get_tree().create_timer(2.6).timeout
	_reset_for_loop()
	if n and n.has_method("fade_from_black"):
		n.call("fade_from_black", 0.8)

func _reset_for_loop() -> void:
	## La linea temporal se reinicia: Kael vuelve a la arena y el jugador
	## vuelve a la entrada de la camara.
	choice_made = false
	core_accessed = false
	_reveal_consoles_reset()
	var player := _player()
	if arena_spawn and player:
		player.global_position = arena_spawn.global_position + Vector3(0, 0.2, 7.5)
		player.set("velocity", Vector3.ZERO)
		if player.has_method("set_respawn_point"):
			player.call("set_respawn_point", player.global_position)
	if kael == null:
		kael = get_tree().get_first_node_in_group("kael")
	if kael and kael.has_method("reset_boss"):
		kael.call("reset_boss")
	if kael is Node3D and arena_spawn:
		(kael as Node3D).global_position = arena_spawn.global_position
	GameState.set_objective("OBJETIVO: Llega hasta el sistema central")
	GameState.notify("La linea temporal se reinicia", Color(1.0, 0.35, 0.5))
	if core_terminal and core_terminal.has_method("reset_access"):
		core_terminal.call("reset_access")
	if core_terminal and core_terminal.has_method("unlock"):
		core_terminal.call("unlock")

func _reveal_consoles_reset() -> void:
	for key in consoles:
		var c: Node = consoles[key]
		if c and c.has_method("reveal"):
			c.set("revealed", false)
			c.set("visible", false)
			c.set("enabled", false)

# ------------------------------------------------------------------ final
func _run_ending() -> void:
	if completed:
		return
	completed = true
	var n := _narrator()
	var player := _player()
	if player and player.has_method("set_input_locked"):
		player.call("set_input_locked", true)
	if n:
		n.call("fade_to_black", 1.0)
	await get_tree().create_timer(1.2).timeout
	if n and n.has_method("say"):
		n.call("say", "EIRA: si el nucleo debe vivir... que viva con mi corazon.", 4.5)
	await get_tree().create_timer(4.0).timeout
	if n:
		n.call("fade_from_black", 1.2)
	var ending := get_tree().get_first_node_in_group("l3_ending")
	if ending and ending.has_method("play"):
		ending.call("play", GameState.points, GameState.lives, no_death)
