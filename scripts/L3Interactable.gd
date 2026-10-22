class_name L3Interactable
extends Area3D

## Base de los objetos interactuables del Nivel 3 (tecla E).

@export var prompt: String = "[E] Interactuar"
@export var enabled: bool = true
@export var one_shot: bool = true

var _used := false
var _interact_held := false

func _ready() -> void:
	add_to_group("interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func can_interact() -> bool:
	return enabled and not (one_shot and _used)

func reset_use() -> void:
	## Permite volver a usar el objeto (reinicio de la linea temporal).
	_used = false
	_interact_held = false

func activate() -> void:
	if not can_interact():
		return
	if one_shot:
		_used = true
	on_activate()

func on_activate() -> void:
	pass

func _player_inside() -> bool:
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

func _process(_delta: float) -> void:
	if not is_inside_tree():
		return
	var inside := _player_inside()
	if inside and can_interact():
		GameState.set_prompt(prompt)
		var held := Input.is_action_pressed("interact")
		if held and not _interact_held:
			_interact_held = true
			activate()
		elif not held:
			_interact_held = false
	else:
		_interact_held = false
		if inside and not can_interact() and GameState.prompt_text == prompt:
			GameState.set_prompt("")

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and can_interact():
		GameState.set_prompt(prompt)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and GameState.prompt_text == prompt:
		GameState.set_prompt("")
