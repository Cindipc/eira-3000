extends Area3D

@export var index: int = 0
@export var required_codes: Array[String] = []
@export var display_name: String = "Terminal"

var solved := false
var _player_inside := false
var _interact_held := false

@onready var screen: MeshInstance3D = $Screen
@onready var light: OmniLight3D = $ScreenLight
@onready var label: Label3D = $Label

func _ready() -> void:
	add_to_group("terminal")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.text = "%s %d" % [display_name, index + 1]

func missing_codes() -> Array[String]:
	var missing: Array[String] = []
	for c in required_codes:
		if not GameState.has_file(c):
			missing.append(c)
	return missing

func _on_body_entered(body: Node3D) -> void:
	if solved or not body.is_in_group("player"):
		return
	_player_inside = true
	update_prompt()

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = false
	if not solved:
		GameState.set_prompt("")

func _refresh_inside() -> void:
	var inside := false
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			inside = true
			break
	if inside == _player_inside:
		return
	_player_inside = inside
	if inside:
		update_prompt()
	elif not solved:
		GameState.set_prompt("")

func _process(_delta: float) -> void:
	if solved:
		return
	_refresh_inside()
	var held := Input.is_action_pressed("interact")
	var pressed := held and not _interact_held
	_interact_held = held
	if pressed and _player_inside:
		var pending := missing_codes()
		if pending.is_empty():
			_solve()
		else:
			GameState.notify("Faltan archivos: %s" % ", ".join(pending), Color(1.0, 0.7, 0.25))
		return
	var missing := missing_codes()
	if missing.is_empty():
		label.modulate = Color(0.4, 1.0, 0.6)
	elif _player_inside:
		label.modulate = Color(1.0, 0.75, 0.3)
	else:
		label.modulate = Color(1.0, 0.45, 0.35)

func update_prompt() -> void:
	if solved:
		return
	var missing := missing_codes()
	if missing.is_empty():
		GameState.set_prompt("[E] Resolver %s" % display_name)
	else:
		GameState.set_prompt("Archivos faltantes: %s" % ", ".join(missing))

func _solve() -> void:
	solved = true
	GameState.set_prompt("")
	GameState.solve_resolution(index)
	var mat := screen.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(0.05, 0.35, 0.2)
		mat.emission = Color(0.2, 1.0, 0.5)
		mat.emission_energy_multiplier = 4.0
	light.light_color = Color(0.3, 1.0, 0.5)
	label.modulate = Color(0.4, 1.0, 0.6)
	label.text = "%s %d - RESUELTO" % [display_name, index + 1]
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.set_respawn_point(global_position + Vector3(0, 0.2, 0))
