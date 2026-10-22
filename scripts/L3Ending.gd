extends CanvasLayer

## Final del Nivel 3: sacrificio, epilogo 50 anos despues, creditos y
## pantalla de puntuacion final. Todo en paneles sobre la misma escena.

var _bg: ColorRect
var _title: Label
var _body: Label
var _credits: Label
var _score_box: VBoxContainer
var _score_title: Label
var _score_lines: Label
var _options: Label

var _credits_t := 0.0
var _credits_active := false
var _credits_base := 0.0

const CREDIT_LINES := [
	"EIRA 3000 - LA ULTIMA GUERRA",
	"",
	"NIVEL 3 - EL NUCLEO CENTRAL",
	"",
	"Eira ............... protagonista",
	"NOVA .............. voz yElectrocardiograma",
	"Kael ............. el ultimo amo",
	"ORIGEN ........... la primera conciencia",
	"",
	"ESCENARIO ........ ciudad de 3000",
	"NUCLEO ........... camara central",
	"",
	"MISIONES ......... entrada al Nucleo",
	"ANDROIDES ....... 6 unidades controladas",
	"SISTEMAS ......... 3 nodos de seguridad",
	"DECISION ......... humanos / androides / libertad",
	"",
	"GRACIAS POR JUGAR",
]

func _ready() -> void:
	layer = 80
	add_to_group("l3_ending")
	visible = false
	_build_ui()

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.name = "Background"
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0.01, 0.01, 0.03, 0.94)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_title = Label.new()
	_title.name = "Title"
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = 70.0
	_title.offset_bottom = 140.0
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 52)
	_title.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0))
	_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_title.text = ""
	add_child(_title)

	_body = Label.new()
	_body.name = "Body"
	_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body.offset_top = 190.0
	_body.offset_bottom = -170.0
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_body.add_theme_font_size_override("font_size", 30)
	_body.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98))
	_body.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_body.add_theme_constant_override("line_spacing", 12)
	_body.text = ""
	add_child(_body)

	_credits = Label.new()
	_credits.name = "Credits"
	_credits.set_anchors_preset(Control.PRESET_FULL_RECT)
	_credits.offset_top = -60.0
	_credits.offset_bottom = 60.0
	_credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_credits.add_theme_font_size_override("font_size", 26)
	_credits.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	_credits.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_credits.add_theme_constant_override("line_spacing", 8)
	_credits.text = ""
	_credits.visible = false
	add_child(_credits)

	_score_box = VBoxContainer.new()
	_score_box.name = "ScoreBox"
	_score_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_score_box.offset_top = 150.0
	_score_box.offset_bottom = -120.0
	_score_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_score_box.visible = false
	add_child(_score_box)

	_score_title = Label.new()
	_score_title.name = "ScoreTitle"
	_score_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_title.add_theme_font_size_override("font_size", 46)
	_score_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	_score_box.add_child(_score_title)

	_score_lines = Label.new()
	_score_lines.name = "ScoreLines"
	_score_lines.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_lines.add_theme_font_size_override("font_size", 28)
	_score_lines.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_score_lines.add_theme_constant_override("line_spacing", 10)
	_score_box.add_child(_score_lines)

	_options = Label.new()
	_options.name = "Options"
	_options.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_options.offset_top = -90.0
	_options.offset_bottom = -40.0
	_options.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_options.add_theme_font_size_override("font_size", 24)
	_options.add_theme_color_override("font_color", Color(0.65, 0.9, 1.0))
	_options.visible = false
	add_child(_options)

func _process(delta: float) -> void:
	if not _credits_active:
		return
	_credits_t += delta
	_credits.position.y = _credits_base - _credits_t * 55.0
	if _credits.position.y < -900.0:
		_credits_active = false
		_credits.visible = false

func play(points: int, lives: int, no_death: bool) -> void:
	visible = true
	_bg.color = Color(0.01, 0.01, 0.03, 0.0)
	var tw := create_tween()
	tw.tween_property(_bg, "color:a", 0.94, 1.2)

	_panel("SACRIFICIO", "Eira inserta su mano en el nucleo central.\nSu corazon se detiene, pero la conexion permanece:\nlos androides reciben la libertad que nunca les negaron.\n\nNOVA: te perdi... Eira. Ha funcionado.", 4.6)
	await get_tree().create_timer(5.4).timeout

	_panel("50 ANOS DESPUES", "ANIO 3050.\n\nLa ciudad destruida ha sido reconstruida.\nLos androides caminan por las calles sin ordenes,\npor decision propia.\n\nY en cada uno de ellos late un recuerdo\nde una chica que aprendio a luchar con su corazon.", 5.2)
	await get_tree().create_timer(6.0).timeout

	_run_credits()
	await get_tree().create_timer(16.0).timeout

	_show_score(points, lives, no_death)

func _panel(title: String, body: String, seconds: float) -> void:
	_title.text = title
	_body.text = body
	_title.visible = true
	_body.visible = true
	var tw := create_tween()
	tw.tween_property(_title, "modulate:a", 1.0, 0.8)
	tw.parallel().tween_property(_body, "modulate:a", 1.0, 0.8)

func _run_credits() -> void:
	_title.text = "CREDITOS"
	_title.visible = true
	_body.visible = false
	_credits.text = "\n".join(CREDIT_LINES)
	_credits.visible = true
	_credits.position.y = 620.0
	_credits_base = 620.0
	_credits_t = 0.0
	_credits_active = true

func _show_score(points: int, lives: int, no_death: bool) -> void:
	_credits.visible = false
	_credits_active = false
	_title.visible = false
	_body.visible = false
	_score_title.text = "PUNTUACIÓN FINAL"
	var rank := _rank(points, no_death)
	var lines := "PUNTOS ............... %d" % points
	lines += "\nVIDAS RESTANTES ...... %d / 5" % lives
	if no_death:
		lines += "\nBONUS SIN MORIR ...... +1000"
	lines += "\n\nRANGO ................ %s" % rank
	_score_lines.text = lines
	_score_box.visible = true
	_options.text = "[R] Reiniciar el nivel        [ESC] Volver al Nivel 2"
	_options.visible = true

func _rank(points: int, no_death: bool) -> String:
	if points >= 10000:
		return "LEGADO DE EIRA"
	if points >= 8500:
		return "GUARDIANA DE LA LIBERTAD"
	if points >= 7000:
		return "ANDROIDES LIBRES"
	return "EL NUCLEO RESISTE"

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _options.visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/Level2.tscn")
