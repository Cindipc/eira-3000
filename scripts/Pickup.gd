extends Area3D

enum Kind { HEALTH, AMMO }

@export var kind: int = Kind.HEALTH
@export var amount: int = 25

@onready var visual: Node3D = $Visual
@onready var light: OmniLight3D = $Visual/PickupLight

var _spin := 0.0

func _ready() -> void:
	add_to_group("pickup")
	collision_layer = 16
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	if light:
		light.light_color = Color(0.3, 1.0, 0.5) if kind == Kind.HEALTH else Color(1.0, 0.8, 0.3)

func _process(delta: float) -> void:
	_spin += delta * 1.2
	visual.rotation.y = _spin
	visual.position.y = 0.55 + sin(_spin * 1.6) * 0.07

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if kind == Kind.HEALTH:
		if body.has_method("heal"):
			body.heal(amount)
			GameState.notify("+ %d de integridad" % amount, Color(0.3, 1.0, 0.5))
	else:
		var weapon := _find_weapon(body)
		if weapon and weapon.has_method("add_ammo"):
			weapon.add_ammo(amount)
		else:
			GameState.notify("+ %d balas" % amount, Color(1.0, 0.85, 0.4))
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector3.ZERO, 0.2)
	tw.tween_callback(queue_free)

func _find_weapon(body: Node) -> Node:
	var found := body.get_node_or_null("CameraPivot/Camera3D/Weapon")
	return found
