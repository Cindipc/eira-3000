extends CanvasLayer

## Capa de narracion del Nivel 3: subtitulos, fundidos a negro, flashes de
## pantalla y el cartel de "la historia se repite".

var _subtitle: Label
var _subtitle_bg: ColorRect
var _fade: ColorRect
var _flash: ColorRect
var _subtitle_time := 0.0
var _flash_time := 0.0

func _ready() -> void:
	layer = 60
	add_to_group("narrator")

	_flash = ColorRect.new()
	_flash.name = "Flash"
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0, 0, 0, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	_subtitle_bg = ColorRect.new()
	_subtitle_bg.name = "SubtitleBG"
	_subtitle_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_subtitle_bg.offset_top = -132.0
	_subtitle_bg.offset_bottom = -76.0
	_subtitle_bg.color = Color(0.02, 0.02, 0.05, 0.72)
	_subtitle_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle_bg.visible = false
	add_child(_subtitle_bg)

	_subtitle = Label.new()
	_subtitle.name = "Subtitle"
	_subtitle.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_subtitle.offset_top = -126.0
	_subtitle.offset_bottom = -82.0
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 26)
	_subtitle.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	_subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_subtitle.add_theme_constant_override("shadow_offset_x", 2)
	_subtitle.add_theme_constant_override("shadow_offset_y", 2)
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle.visible = false
	add_child(_subtitle)

func _process(delta: float) -> void:
	if _subtitle_time > 0.0:
		_subtitle_time -= delta
		if _subtitle_time <= 0.0:
			_subtitle.visible = false
			_subtitle_bg.visible = false
	if _flash_time > 0.0:
		_flash_time = maxf(0.0, _flash_time - delta)
		var a := clampf(_flash_time, 0.0, 1.0)
		_flash.color = Color(_flash.color.r, _flash.color.g, _flash.color.b, a * 0.55)

func say(text: String, seconds := 4.0) -> void:
	_subtitle.text = text
	_subtitle.visible = true
	_subtitle_bg.visible = true
	_subtitle_time = seconds

func hide_subtitle() -> void:
	_subtitle_time = 0.0
	_subtitle.visible = false
	_subtitle_bg.visible = false

func flash(color: Color = Color(1, 0.2, 0.2), seconds := 0.4) -> void:
	_flash.color = Color(color.r, color.g, color.b, 1.0)
	_flash_time = seconds

func fade_to_black(seconds := 0.8) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, seconds)

func fade_from_black(seconds := 0.8) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, seconds)

func set_fade(alpha: float) -> void:
	_fade.color = Color(0, 0, 0, alpha)

func glitch_card(text: String = "LA HISTORIA SE REPITE") -> void:
	flash(Color(0.9, 0.15, 0.45), 0.9)
	say(text, 3.2)
