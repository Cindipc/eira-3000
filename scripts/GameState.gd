extends Node

signal files_changed(collected: int, total: int)
signal resolution_solved(index: int, total: int)
signal health_changed(current: float, maximum: float)
signal ammo_changed(magazine: int, reserve: int)
signal objective_changed(text: String)
signal message(text: String, color: Color)
signal combat_started()
signal boss_spawned(boss: Node, title: String)
signal boss_health_changed(current: float, maximum: float)
signal boss_defeated()
signal prompt_changed(text: String)
signal lives_changed(current: int, maximum: int)
signal points_changed(points: int, gained: int, reason: String)
signal energy_changed(current: float, maximum: float, enabled: bool)
signal mission_changed(index: int, total: int, text: String)
signal level_changed(level: int)
signal level_finished(level: int)
signal game_over()

const PTS_INFO := 50
const PTS_PUZZLE := 100
const PTS_DISABLE := 100
const PTS_AVOID := 150
const PTS_MISSION := 500
const PTS_KILL := 100
const PTS_REBEL := 200
const PTS_HACK := 150
const PTS_FILE := 200
const PTS_SECONDARY := 250
const PTS_LEVEL2 := 1000

const TABLE_L1 := {
	"info": PTS_INFO, "puzzle": PTS_PUZZLE, "disable": PTS_DISABLE,
	"avoid": PTS_AVOID, "mission": PTS_MISSION, "kill": 0, "rebel": 0,
	"hack": PTS_PUZZLE, "secondary": PTS_AVOID, "level_end": PTS_MISSION,
}
const TABLE_L2 := {
	"info": PTS_FILE, "puzzle": PTS_HACK, "disable": 0,
	"avoid": 0, "mission": PTS_SECONDARY, "kill": PTS_KILL, "rebel": PTS_REBEL,
	"hack": PTS_HACK, "secondary": PTS_SECONDARY, "level_end": PTS_LEVEL2,
}

# Nivel 3 "La ultima guerra": enemigo +100, rescate +200, mision +500,
# archivo secreto +300, nivel sin morir +1000, Kael +2000, liberar el Nucleo +5000.
const PTS_ENEMY := 100
const PTS_RESCATE := 200
const PTS_SECRETO := 300
const PTS_SIN_MORIR := 1000
const PTS_KAEL := 2000
const PTS_NUCLEO := 5000
const TABLE_L3 := {
	"info": PTS_SECRETO, "puzzle": PTS_HACK, "disable": PTS_MISSION,
	"avoid": 0, "mission": PTS_MISSION, "kill": PTS_ENEMY, "rebel": PTS_RESCATE,
	"hack": PTS_HACK, "secondary": PTS_SECONDARY, "level_end": PTS_NUCLEO,
	"enemy": PTS_ENEMY, "secret_file": PTS_SECRETO, "no_death": PTS_SIN_MORIR,
	"kael": PTS_KAEL, "core": PTS_NUCLEO,
}

const MAX_LIVES := 3
const MAX_LIVES_L3 := 5

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

var lives: int = MAX_LIVES
var max_lives: int = MAX_LIVES
var points: int = 0
var energy: float = 100.0
var max_energy: float = 100.0
var energy_enabled: bool = false

var mission_index: int = 0
var missions: Array[String] = []
var pts: Dictionary = TABLE_L1
var _point_burst: int = 0

const PTS_LABEL := {
	"info": "información", "puzzle": "acertijo", "disable": "máquina desactivada",
	"avoid": "evasión", "mission": "misión", "kill": "androide neutralizado",
	"rebel": "rebelde rescatado", "hack": "hackeo", "secondary": "misión secundaria",
	"level_end": "nivel completado", "enemy": "androide controlado",
	"secret_file": "archivo secreto", "no_death": "nivel sin morir",
	"kael": "derrotar a Kael", "core": "liberar el Núcleo",
}

func reset_level(level: int, resolutions: int, files: int, mission_list: Array[String] = []) -> void:
	current_level = level
	emit_signal("level_changed", level)
	resolutions_solved = 0
	resolutions_total = resolutions
	files_total = files
	files_collected.clear()
	combat_active = false
	boss_active = false
	boss_health = 1.0
	boss_max_health = 1.0
	prompt_text = ""
	max_lives = MAX_LIVES_L3 if level >= 3 else MAX_LIVES
	lives = max_lives
	points = 0
	energy = 100.0
	max_energy = 100.0
	energy_enabled = level >= 2
	pts = TABLE_L1 if level < 2 else (TABLE_L2 if level < 3 else TABLE_L3)
	_point_burst = 0
	missions = mission_list
	mission_index = 0
	emit_signal("files_changed", 0, files_total)
	emit_signal("resolution_solved", 0, resolutions_total)
	emit_signal("health_changed", 100.0, 100.0)
	emit_signal("ammo_changed", 0, 0)
	emit_signal("prompt_changed", "")
	emit_signal("objective_changed", "")
	emit_signal("lives_changed", lives, max_lives)
	emit_signal("points_changed", 0, 0, "")
	emit_signal("energy_changed", energy, max_energy, energy_enabled)
	_update_mission()

func collect_file(code: String) -> void:
	if files_collected.has(code):
		return
	files_collected.append(code)
	emit_signal("files_changed", files_collected.size(), files_total)
	emit_signal("message", "Archivo recuperado: %s" % code, Color(0.4, 1.0, 0.7))
	award("info")

func has_file(code: String) -> bool:
	return files_collected.has(code)

func solve_resolution(index: int) -> void:
	var advanced := index + 1 > resolutions_solved
	resolutions_solved = maxi(resolutions_solved, index + 1)
	emit_signal("resolution_solved", resolutions_solved, resolutions_total)
	emit_signal("message", "Resolución %d/%d completada" % [resolutions_solved, resolutions_total], Color(0.3, 0.9, 1.0))
	if advanced:
		award("puzzle")

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

func spawn_boss(boss: Node, max_health: float, title: String = "") -> void:
	boss_active = true
	boss_max_health = max_health
	boss_health = max_health
	emit_signal("boss_spawned", boss, title)

func set_boss_health(current: float, maximum: float) -> void:
	boss_health = current
	boss_max_health = maximum
	emit_signal("boss_health_changed", current, maximum)

func boss_down() -> void:
	boss_active = false
	emit_signal("boss_defeated")

func award(key: String) -> int:
	var amount := int(pts.get(key, 0))
	if amount <= 0:
		return 0
	add_points(amount, str(PTS_LABEL.get(key, key)))
	return amount

func add_points(amount: int, reason: String = "") -> void:
	if amount <= 0:
		return
	points += amount
	_point_burst += amount
	emit_signal("points_changed", points, amount, reason)

func get_burst() -> int:
	return _point_burst

func clear_burst() -> void:
	_point_burst = 0

func lose_life(reason: String = "") -> bool:
	lives = maxi(0, lives - 1)
	emit_signal("lives_changed", lives, max_lives)
	if reason != "":
		emit_signal("message", reason, Color(1.0, 0.4, 0.45))
	return lives <= 0

func set_lives(value: int) -> void:
	lives = clampi(value, 0, max_lives)
	emit_signal("lives_changed", lives, max_lives)

func add_life(count: int = 1) -> void:
	set_lives(lives + count)

func set_energy(current: float, maximum: float = -1.0) -> void:
	if maximum > 0.0:
		max_energy = maximum
	energy = clampf(current, 0.0, max_energy)
	emit_signal("energy_changed", energy, max_energy, energy_enabled)

func drain_energy(amount: float) -> bool:
	if not energy_enabled:
		return true
	if energy <= 0.0:
		return false
	energy = maxf(0.0, energy - amount)
	emit_signal("energy_changed", energy, max_energy, energy_enabled)
	return energy > 0.0

func set_missions(list: Array[String]) -> void:
	missions = list
	mission_index = 0
	_update_mission()

func advance_mission(points_award: int = -1, label: String = "") -> void:
	if mission_index >= missions.size():
		return
	if points_award >= 0:
		add_points(points_award, str(PTS_LABEL.get("mission", "misión")))
	else:
		award("mission")
	mission_index += 1
	_update_mission()
	if label != "":
		emit_signal("message", label, Color(1.0, 0.85, 0.35))

func has_mission() -> bool:
	return mission_index < missions.size()

func current_mission() -> String:
	if missions.is_empty() or mission_index >= missions.size():
		return ""
	return missions[mission_index]

func _update_mission() -> void:
	var text := current_mission()
	if text == "":
		return
	var formatted := "MISIÓN %d/%d — %s" % [mission_index + 1, missions.size(), text]
	emit_signal("mission_changed", mission_index + 1, missions.size(), text)
	emit_signal("objective_changed", formatted)

func finish_level() -> void:
	emit_signal("level_finished", current_level)
