extends Area3D

@export var next_scene: String = "res://scenes/Level2.tscn"
@export var requires_boss: bool = false
@export var enabled: bool = false

var _changing := false
var _player_inside := false

@onready var visual: Node3D = $Visual
@onready var light: OmniLight3D = $Visual/ExitLight
@onready var label: Label3D = $Label

func _ready() -> void:
	add_to_group("level_exit")
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.text = "SALIDA"

func _process(delta: float) -> void:
	visual.rotation.y += delta * 0.8
	if light:
		light.light_energy = 2.5 + sin(Time.get_ticks_msec() * 0.003) * 1.2
	if not enabled or _changing:
		return
	if _player_inside:
		_change_scene()
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_change_scene()
			return
	# red de seguridad: si el jugador esta junto al portal pero el area no lo capturo
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		var to_portal := player.global_position - global_position
		to_portal.y = 0.0
		if to_portal.length() <= 4.0:
			_change_scene()
			return

func activate() -> void:
	if enabled:
		return
	if requires_boss and GameState.boss_active:
		return
	enabled = true
	collision_layer = 16
	collision_mask = 2
	label.modulate = Color(0.4, 1.0, 0.7)
	label.text = "SALIDA DESBLOQUEADA"

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	if enabled:
		_change_scene()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _change_scene() -> void:
	if _changing:
		return
	_changing = true
	GameState.finish_level()
	var tree := get_tree()
	var layer := CanvasLayer.new()
	layer.layer = 100
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	tree.root.add_child(layer)
	var tw := create_tween()
	tw.tween_property(rect, "color", Color(0, 0, 0, 1), 0.5)
	tw.tween_callback(func() -> void:
		tree.change_scene_to_file(next_scene))
