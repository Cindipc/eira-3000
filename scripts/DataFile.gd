extends Area3D

@export var code: String = "ALFA-00"
@export var beacon_enabled: bool = true

var collected := false

@onready var visual: Node3D = $Visual
@onready var beacon: Node3D = $Beacon
@onready var beacon_light: OmniLight3D = $Beacon/BeaconLight
@onready var label: Label3D = $Label

var _spin: float = 0.0

func _ready() -> void:
	add_to_group("data_file")
	body_entered.connect(_on_body_entered)
	label.text = code
	_refresh_beacon()

func _process(delta: float) -> void:
	if collected:
		return
	_spin += delta * 1.6
	visual.rotation.y = _spin
	visual.position.y = 1.15 + sin(_spin * 1.7) * 0.09
	if beacon.visible:
		beacon_light.light_energy = 2.0 + sin(_spin * 2.4) * 1.2

func set_beacon(enabled: bool) -> void:
	beacon_enabled = enabled
	_refresh_beacon()

func _refresh_beacon() -> void:
	if beacon == null:
		return
	beacon.visible = beacon_enabled and not collected
	if beacon_light:
		beacon_light.visible = beacon.visible

func _on_body_entered(body: Node3D) -> void:
	if collected:
		return
	if not body.is_in_group("player"):
		return
	collected = true
	GameState.collect_file(code)
	_refresh_beacon()
	label.visible = false
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector3.ZERO, 0.25)
	tw.parallel().tween_property(self, "position:y", position.y + 0.8, 0.25)
	tw.tween_callback(queue_free)
