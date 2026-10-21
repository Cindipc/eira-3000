extends CanvasLayer

@onready var resolutions_label: Label = $Root/TopLeft/Resolutions
@onready var files_label: Label = $Root/TopLeft/Files
@onready var level_label: Label = $Root/TopLeft/Level
@onready var health_bar: ProgressBar = $Root/TopRight/HealthBar
@onready var health_label: Label = $Root/TopRight/HealthLabel
@onready var ammo_label: Label = $Root/TopRight/Ammo
@onready var objective_label: Label = $Root/Bottom/Objective
@onready var prompt_label: Label = $Root/Center/Prompt
@onready var message_label: Label = $Root/Message
@onready var crosshair: Control = $Root/Center/Crosshair
@onready var hit_marker: Label = $Root/Center/HitMarker
@onready var boss_panel: Control = $Root/Boss
@onready var boss_bar: ProgressBar = $Root/Boss/BossBar
@onready var boss_label: Label = $Root/Boss/BossLabel

var _message_time := 0.0
var _hit_time := 0.0
var _crosshair_color := Color(0.6, 0.95, 1.0)

func _ready() -> void:
	GameState.resolution_solved.connect(_on_resolutions)
	GameState.files_changed.connect(_on_files)
	GameState.health_changed.connect(_on_health)
	GameState.ammo_changed.connect(_on_ammo)
	GameState.objective_changed.connect(_on_objective)
	GameState.message.connect(_on_message)
	GameState.prompt_changed.connect(_on_prompt)
	GameState.boss_spawned.connect(_on_boss_spawned)
	GameState.boss_health_changed.connect(_on_boss_health)
	GameState.boss_defeated.connect(_on_boss_defeated)
	boss_panel.visible = false
	_on_resolutions(GameState.resolutions_solved, GameState.resolutions_total)
	_on_files(GameState.files_collected.size(), GameState.files_total)
	level_label.text = "NIVEL %d" % GameState.current_level

func _process(delta: float) -> void:
	if _message_time > 0.0:
		_message_time -= delta
		message_label.modulate.a = clampf(_message_time, 0.0, 1.0)
	if _hit_time > 0.0:
		_hit_time -= delta
		hit_marker.modulate.a = clampf(_hit_time * 4.0, 0.0, 1.0)
		var weapon := _find_weapon()
		if weapon:
			var target: Variant = weapon.current_target
			var valid_target: bool = is_instance_valid(target) and target is Node
			var is_enemy: bool = valid_target and target.is_in_group("android")
			if is_enemy:
				_crosshair_color = Color(1.0, 0.45, 0.4)
			elif valid_target and target.is_in_group("boss"):
				_crosshair_color = Color(1.0, 0.7, 0.25)
			else:
				_crosshair_color = Color(0.6, 0.95, 1.0)
	for child in crosshair.get_children():
		if child is ColorRect:
			(child as ColorRect).color = _crosshair_color

func _find_weapon() -> Node:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return null
	return player.get_node_or_null("CameraPivot/Camera3D/Weapon")

func _on_resolutions(current: int, total: int) -> void:
	resolutions_label.text = "RESOLUCIONES  %d / %d" % [current, total]

func _on_files(current: int, total: int) -> void:
	files_label.text = "ARCHIVOS  %d / %d" % [current, total]

func _on_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "INTEGRIDAD  %d" % int(current)

func _on_ammo(magazine: int, reserve: int) -> void:
	ammo_label.text = "BALAS  %d / %d" % [magazine, reserve]

func _on_objective(text: String) -> void:
	objective_label.text = text

func _on_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = text != ""

func _on_message(text: String, color: Color) -> void:
	message_label.text = text
	message_label.modulate = color
	message_label.modulate.a = 1.0
	_message_time = 3.2

func _on_boss_spawned(_boss: Node) -> void:
	boss_panel.visible = true
	boss_label.text = "MÁQUINA ANALÍTICA"

func _on_boss_health(current: float, maximum: float) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = current

func _on_boss_defeated() -> void:
	boss_panel.visible = false
