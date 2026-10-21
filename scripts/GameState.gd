extends Node

signal files_changed(collected: int, total: int)
signal resolution_solved(index: int, total: int)
signal health_changed(current: float, maximum: float)
signal ammo_changed(magazine: int, reserve: int)
signal objective_changed(text: String)
signal message(text: String, color: Color)
signal combat_started()
signal boss_spawned(boss: Node)
signal boss_health_changed(current: float, maximum: float)
signal boss_defeated()
signal prompt_changed(text: String)

var files_collected: Array[String] = []
var files_total: int = 0
var resolutions_solved: int = 0
var resolutions_total: int = 6
var combat_active: bool = false
var boss_active: bool = false
var boss_max_health: float = 1.0
var boss_health: float = 1.0
var current_level: int = 1
var prompt_text: String = ""

func reset_level(level: int, resolutions: int, files: int) -> void:
	current_level = level
	resolutions_solved = 0
	resolutions_total = resolutions
	files_total = files
	files_collected.clear()
	combat_active = false
	boss_active = false
	boss_health = 1.0
	boss_max_health = 1.0
	prompt_text = ""
	emit_signal("files_changed", 0, files_total)
	emit_signal("resolution_solved", 0, resolutions_total)
	emit_signal("health_changed", 100.0, 100.0)
	emit_signal("ammo_changed", 0, 0)
	emit_signal("prompt_changed", "")
	emit_signal("objective_changed", "")

func collect_file(code: String) -> void:
	if files_collected.has(code):
		return
	files_collected.append(code)
	emit_signal("files_changed", files_collected.size(), files_total)
	emit_signal("message", "Archivo recuperado: %s" % code, Color(0.4, 1.0, 0.7))

func has_file(code: String) -> bool:
	return files_collected.has(code)

func solve_resolution(index: int) -> void:
	resolutions_solved = maxi(resolutions_solved, index + 1)
	emit_signal("resolution_solved", resolutions_solved, resolutions_total)
	emit_signal("message", "Resolución %d/%d completada" % [resolutions_solved, resolutions_total], Color(0.3, 0.9, 1.0))

func set_health(current: float, maximum: float) -> void:
	emit_signal("health_changed", current, maximum)

func set_ammo(magazine: int, reserve: int) -> void:
	emit_signal("ammo_changed", magazine, reserve)

func set_objective(text: String) -> void:
	emit_signal("objective_changed", text)

func set_prompt(text: String) -> void:
	if text == prompt_text:
		return
	prompt_text = text
	emit_signal("prompt_changed", text)

func notify(text: String, color: Color = Color(1, 1, 1)) -> void:
	emit_signal("message", text, color)

func start_combat() -> void:
	if combat_active:
		return
	combat_active = true
	emit_signal("combat_started")

func spawn_boss(boss: Node, max_health: float) -> void:
	boss_active = true
	boss_max_health = max_health
	boss_health = max_health
	emit_signal("boss_spawned", boss)

func set_boss_health(current: float, maximum: float) -> void:
	boss_health = current
	boss_max_health = maximum
	emit_signal("boss_health_changed", current, maximum)

func boss_down() -> void:
	boss_active = false
	emit_signal("boss_defeated")
