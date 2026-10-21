extends StaticBody3D

@export var required_resolutions: int = 1
@export var requires_boss: bool = false

var is_open := false

@onready var panel: Node3D = $Panel
@onready var light: OmniLight3D = $Panel/BarrierLight

func _ready() -> void:
	add_to_group("barrier")
	collision_layer = 1
	collision_mask = 0

func open_barrier() -> void:
	if is_open:
		return
	is_open = true
	if light:
		light.light_color = Color(0.3, 1.0, 0.5)
	var tw := create_tween()
	tw.tween_property(panel, "position:y", panel.position.y - 5.6, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "scale", Vector3(1, 0.05, 1), 0.6)
	tw.tween_callback(func() -> void:
		collision_layer = 0
		for c in get_children():
			if c is CollisionShape3D:
				(c as CollisionShape3D).set_deferred("disabled", true))
