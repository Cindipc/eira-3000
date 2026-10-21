extends Area3D

var direction := Vector3.FORWARD
var damage := 10.0
var speed := 16.0
var life := 5.0
var _age := 0.0

@onready var visual: Node3D = $Visual
@onready var light: OmniLight3D = $Visual/PlasmaLight

func setup(dir: Vector3, dmg: float, spd: float) -> void:
	direction = dir.normalized()
	damage = dmg
	speed = spd

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_age += delta
	global_position += direction * speed * delta
	visual.rotation.y += delta * 6.0
	if light:
		light.light_energy = 3.0 + sin(_age * 20.0) * 1.0
	if _age > life:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
	_explode()

func _explode() -> void:
	if light:
		light.light_energy = 10.0
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector3.ONE * 2.2, 0.12)
	tw.parallel().tween_property(light, "light_energy", 0.0, 0.18)
	tw.tween_callback(queue_free)
