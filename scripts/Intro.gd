extends Node3D

const TO_LEVEL := "res://scenes/Level1.tscn"
const EIRA_MODEL := "res://assets/characters/eira.glb"
const NOVA_MODEL := "res://assets/characters/nova.glb"
const LAB_AT := Vector3(80.0, 0.0, 0.0)

var cam: Camera3D
var ui: CanvasLayer
var fade: ColorRect
var card: Label
var sub: Label
var hint: Label
var eira: Node3D
var nova: Node3D
var _skipping := false
var _finished := false
var _step := 0
var _look_target := Vector3.ZERO

var steps: Array[Dictionary] = [
	{"set": "a", "card": "2026", "text": "Eira despierta sudando después de un sueño fugaz.", "dur": 4.0,
	 "cam": Vector3(2.4, 1.7, 3.2), "look": Vector3(0.0, 1.2, 0.0)},
	{"set": "a", "card": "", "text": "Siente una extraña carga en el pecho, como si su cuerpo pesara de golpe.", "dur": 4.5,
	 "cam": Vector3(-2.8, 1.6, 2.6), "look": Vector3(0.0, 1.1, 0.0)},
	{"set": "a", "card": "", "text": "…pero no lo piensa demasiado y sigue su vida.", "dur": 4.0,
	 "cam": Vector3(-1.6, 1.9, -3.4), "look": Vector3(0.4, 1.0, 0.0)},
	{"set": "a", "card": "", "text": "Ese mismo día, su corazón se detiene.", "dur": 4.5, "black": true,
	 "cam": Vector3(0.6, 1.4, -1.8), "look": Vector3(0.0, 1.1, 0.0)},
	{"set": "b", "card": "AÑO 3000", "text": "", "dur": 3.0, "hold_black": true},
	{"set": "b", "card": "", "text": "Eira despierta sobre una plataforma metálica, en lo que queda de un edificio abandonado.", "dur": 5.0,
	 "cam": Vector3(LAB_AT.x + 4.0, 1.4, LAB_AT.z + 6.0), "look": LAB_AT + Vector3(0, 1.3, 0)},
	{"set": "b", "card": "", "text": "Paredes de cables, máquinas destruidas y pantallas encendidas en la oscuridad.", "dur": 4.5,
	 "cam": Vector3(LAB_AT.x - 6.0, 2.6, LAB_AT.z + 5.0), "look": LAB_AT + Vector3(-2.0, 1.6, -2.0)},
	{"set": "b", "card": "", "dialog": "NOVA", "text": "— ¿Despiertas? Soy NOVA. Creo que llevo esperándote cien años.", "dur": 5.0,
	 "cam": Vector3(LAB_AT.x + 2.2, 1.5, LAB_AT.z - 3.0), "look": LAB_AT + Vector3(1.6, 1.2, 0.4)},
	{"set": "b", "card": "", "dialog": "NOVA", "text": "— Anomalía detectada en mi circuito: soy un androide desechado, como este lugar.", "dur": 5.0,
	 "cam": Vector3(LAB_AT.x + 3.4, 1.9, LAB_AT.z - 1.6), "look": LAB_AT + Vector3(1.4, 1.3, 0.6)},
	{"set": "b", "card": "", "dialog": "NOVA", "text": "— Los humanos desaparecieron. Tú eres la última esperanza, Eira.", "dur": 5.0,
	 "cam": Vector3(LAB_AT.x - 1.5, 1.7, LAB_AT.z + 4.2), "look": LAB_AT + Vector3(0.5, 1.4, 0.0)},
	{"set": "b", "card": "", "text": "Eira sale a buscar respuestas a lo que pasó con los humanos.", "dur": 5.5,
	 "cam": Vector3(LAB_AT.x + 5.5, 3.2, LAB_AT.z + 7.5), "look": LAB_AT + Vector3(0.0, 2.4, -4.0)},
]

func _ready() -> void:
	_build_ui()
	_build_environment()
	_build_set_a()
	_build_set_b()
	cam = Camera3D.new()
	cam.name = "IntroCamera"
	cam.fov = 55.0
	add_child(cam)
	cam.current = true
	cam.position = Vector3(2.4, 1.7, 3.2)
	_look_target = Vector3(0.0, 1.2, 0.0)
	cam.look_at(_look_target, Vector3.UP)
	_run()

func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	var pressed := false
	if event is InputEventKey and event.pressed and not event.echo:
		pressed = true
	elif event is InputEventMouseButton and event.pressed:
		pressed = true
	if pressed:
		_skipping = true

func _run() -> void:
	await _fade_from_black(1.4)
	for i in steps.size():
		if _skipping:
			break
		_step = i
		await _play_step(steps[i])
	if _finished:
		return
	await _go_black(0.6)
	_finish()

func _play_step(step: Dictionary) -> void:
	var dur := float(step.get("dur", 3.0))
	var set_change := step.get("set", "a") as String
	card.text = str(step.get("card", ""))
	var txt := str(step.get("text", ""))
	var who := str(step.get("dialog", ""))
	if who != "":
		sub.text = "%s:  %s" % [who, txt]
		sub.modulate = Color(0.55, 0.95, 1.0)
	else:
		sub.text = txt
		sub.modulate = Color(0.95, 0.97, 1.0)
	card.visible = card.text != ""
	sub.visible = txt != ""

	if set_change == "b":
		eira.global_position = LAB_AT + Vector3(0.0, 0.05, 0.0)
		_face(eira, Vector3(0, 0, -1))
		nova.global_position = LAB_AT + Vector3(1.8, 0.0, 0.6)
		_face(nova, Vector3(-1, 0, 0))
	if step.has("cam"):
		var to_cam := step["cam"] as Vector3
		var to_look := step["look"] as Vector3
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(cam, "position", to_cam, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_method(_look_at, _look_target, to_look, 1.6)
		_look_target = to_look

	if bool(step.get("hold_black", false)):
		await get_tree().create_timer(dur).timeout
		await _fade_from_black(0.9)
		return

	await get_tree().create_timer(minf(0.35, dur)).timeout
	if bool(step.get("black", false)):
		await get_tree().create_timer(dur - 0.35).timeout
		await _go_black(1.1)
		await get_tree().create_timer(1.4).timeout
		return
	if _skipping:
		return
	var left := dur
	while left > 0.0:
		await get_tree().process_frame
		left -= get_process_delta_time()
		if _skipping:
			return

func _go_black(time: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, time)
	await tw.finished

func _fade_from_black(time: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, time)
	await tw.finished

func _finish() -> void:
	if _finished:
		return
	_finished = true
	card.visible = false
	sub.visible = false
	hint.visible = false
	get_tree().change_scene_to_file(TO_LEVEL)

func _face(node: Node3D, dir: Vector3) -> void:
	if dir.length_squared() > 0.001:
		node.rotation.y = atan2(dir.x, dir.z)

func _look_at(v: Variant) -> void:
	if is_instance_valid(cam) and v is Vector3:
		cam.look_at(v as Vector3, Vector3.UP)

# ------------------------------------------------------------------ ui
func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.name = "IntroUI"
	add_child(ui)

	fade = ColorRect.new()
	fade.name = "Fade"
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 1.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)

	card = _label(64, Color(0.75, 0.95, 1.0))
	card.name = "Card"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_top = -120.0
	card.offset_bottom = -40.0
	card.offset_left = -700.0
	card.offset_right = 700.0
	card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.visible = false

	sub = _label(26, Color(0.95, 0.97, 1.0))
	sub.name = "Sub"
	sub.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sub.offset_top = -140.0
	sub.offset_bottom = -70.0
	sub.offset_left = 160.0
	sub.offset_right = -160.0
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	hint = _label(16, Color(1, 1, 1, 0.55))
	hint.name = "Hint"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_left = -420.0
	hint.offset_top = -44.0
	hint.offset_right = -24.0
	hint.offset_bottom = -20.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.text = "CUALQUIER TECLA · Saltar introducción"

func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# ----------------------------------------------------------- entorno
func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.28, 0.32, 0.42)
	env.ambient_light_energy = 0.8
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.06, 0.09)
	env.fog_density = 0.015
	var we := WorldEnvironment.new()
	we.name = "Env"
	we.environment = env
	add_child(we)

func _build_set_a() -> void:
	var root := Node3D.new()
	root.name = "Set2026"
	add_child(root)

	var wall := _mat(Color(0.10, 0.11, 0.14), 0.1, 0.9)
	var floor_mat := _mat(Color(0.07, 0.07, 0.09), 0.1, 0.85)
	_box(root, Vector3(14, 0.3, 14), floor_mat, Vector3(0, -0.15, 0))
	_box(root, Vector3(14, 4.0, 0.3), wall, Vector3(0, 2.0, -5.0))
	_box(root, Vector3(0.3, 4.0, 14), wall, Vector3(-5.0, 2.0, 0))
	_box(root, Vector3(14, 4.0, 0.3), wall, Vector3(0, 2.0, 5.0))

	var window_mat := _mat(Color(0.35, 0.5, 0.7), 0.2, 0.4, Color(0.35, 0.55, 0.85), 1.6)
	_box(root, Vector3(3.2, 2.0, 0.12), window_mat, Vector3(-1.4, 2.1, -4.82))
	var wl := OmniLight3D.new()
	wl.light_color = Color(0.5, 0.65, 0.95)
	wl.light_energy = 2.4
	wl.omni_range = 9.0
	wl.position = Vector3(-1.4, 2.1, -3.8)
	root.add_child(wl)

	var bed := _mat(Color(0.16, 0.16, 0.19), 0.0, 0.9)
	_box(root, Vector3(2.4, 0.55, 1.3), bed, Vector3(0.0, 0.28, -3.2))
	_box(root, Vector3(2.4, 0.25, 0.4), _mat(Color(0.5, 0.5, 0.55), 0.0, 0.9), Vector3(0.0, 0.62, -3.65))
	_box(root, Vector3(0.15, 0.9, 1.3), _mat(Color(0.12, 0.12, 0.14), 0.2, 0.8), Vector3(-1.2, 0.45, -3.2))

	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.8, 0.55)
	lamp.light_energy = 2.0
	lamp.omni_range = 7.0
	lamp.position = Vector3(2.2, 2.4, -2.4)
	root.add_child(lamp)

	eira = _spawn_model(EIRA_MODEL, Vector3(0.6, 0.0, -1.4))
	eira.name = "Eira"
	root.add_child(eira)
	_face(eira, Vector3(0, 0, -1))
	_play_anim(eira, "idle")

func _build_set_b() -> void:
	var root := Node3D.new()
	root.name = "Set3000"
	add_child(root)
	root.position = LAB_AT

	var steel := _mat(Color(0.14, 0.15, 0.18), 0.85, 0.45)
	var dark := _mat(Color(0.06, 0.065, 0.08), 0.7, 0.7)
	var rust := _mat(Color(0.18, 0.11, 0.08), 0.5, 0.9)

	_box(root, Vector3(40, 0.4, 40), _mat(Color(0.05, 0.05, 0.06), 0.4, 0.9), Vector3(0, -0.2, 0))
	_box(root, Vector3(9, 0.6, 9), steel, Vector3(0, 0.3, 0))
	for i in 4:
		var a := float(i) * PI * 0.5
		var px := cos(a) * 4.1
		var pz := sin(a) * 4.1
		_box(root, Vector3(0.16, 1.1, 0.16), steel, Vector3(px, 1.1, pz))
		_box(root, Vector3(3.0, 0.1, 0.1), steel, Vector3(px * 0.45 - pz * 0.45 * 0.0, 1.6, pz))

	var wall_back := _box(root, Vector3(26, 9, 0.6), dark, Vector3(0, 4.5, -9.5))
	_box(root, Vector3(0.6, 9, 26), dark, Vector3(-12.0, 4.5, 0))
	_box(root, Vector3(0.6, 9, 26), rust, Vector3(12.0, 4.5, 0))
	_box(root, Vector3(26, 9, 0.6), dark, Vector3(0, 4.5, 11.5))

	_screen(root, Vector3(0, 3.4, -9.1), Vector3(7.0, 3.0, 0.0), "AÑO 3000", Color(1.0, 0.35, 0.25), 3.2)
	_screen(root, Vector3(-6.5, 2.4, -9.1), Vector3(3.0, 1.8, 0.0), "SYS.ERR", Color(1.0, 0.7, 0.2), 1.6)
	_screen(root, Vector3(7.0, 4.6, -9.1), Vector3(2.6, 1.4, 0.0), "NOVA//", Color(0.2, 0.9, 1.0), 1.8)
	_screen(root, Vector3(11.6, 3.0, -3.0), Vector3(2.2, 1.6, 0.0), "OFF", Color(0.6, 0.2, 0.9), 1.4)

	var cable := _mat(Color(0.04, 0.04, 0.05), 0.3, 0.9)
	for i in 9:
		var x := -10.0 + float(i) * 2.4
		_box(root, Vector3(0.14, 6.5, 0.14), cable, Vector3(x, 5.5, -9.0), Vector3(0, 0, randf_range(-0.25, 0.25)))
		_box(root, Vector3(0.12, 0.12, 9.0), cable, Vector3(x + 0.6, 7.6, -4.6), Vector3(randf_range(-0.1, 0.1), 0, 0))

	for i in 6:
		var ang := randf() * TAU
		var p := Vector3(cos(ang) * randf_range(5.5, 9.5), 0.0, sin(ang) * randf_range(5.5, 9.5))
		var m := _mat(Color(0.1, 0.1, 0.12), 0.7, 0.6)
		_box(root, Vector3(randf_range(1.2, 2.4), randf_range(1.0, 2.2), randf_range(1.0, 1.8)), m,
			p + Vector3(0, 0.6, 0), Vector3(randf_range(-0.5, 0.5), randf_range(0, TAU), randf_range(-0.4, 0.4)))
		_screen(root, p + Vector3(0, 1.3, 0.9), Vector3(1.0, 0.7, 0.0), "", Color(1.0, 0.3, 0.25), 1.2)

	var red := OmniLight3D.new()
	red.light_color = Color(1.0, 0.28, 0.2)
	red.light_energy = 3.0
	red.omni_range = 14.0
	red.position = Vector3(0, 3.6, -8.4)
	root.add_child(red)
	var blue := OmniLight3D.new()
	blue.light_color = Color(0.25, 0.6, 1.0)
	blue.light_energy = 2.6
	blue.omni_range = 12.0
	blue.position = Vector3(6.5, 4.0, -8.4)
	root.add_child(blue)
	var plat := OmniLight3D.new()
	plat.light_color = Color(0.6, 0.8, 1.0)
	plat.light_energy = 2.0
	plat.omni_range = 8.0
	plat.position = Vector3(0, 3.0, 2.0)
	root.add_child(plat)

	eira = _spawn_model(EIRA_MODEL, LAB_AT + Vector3(0, 0.6, 0))
	eira.name = "Eira3000"
	add_child(eira)
	_play_anim(eira, "idle")

	nova = _spawn_model(NOVA_MODEL, LAB_AT + Vector3(1.8, 0.6, 0.6))
	nova.name = "Nova"
	add_child(nova)

func _screen(parent: Node, pos: Vector3, size: Vector3, text: String, color: Color, energy: float) -> void:
	var body := Node3D.new()
	body.position = pos
	parent.add_child(body)
	_box(body, Vector3(size.x, size.y, 0.1), _mat(Color(0.03, 0.03, 0.04), 0.3, 0.8), Vector3.ZERO)
	var glow := _mat(color * 0.35, 0.1, 0.5, color, energy)
	_box(body, Vector3(size.x - 0.2, size.y - 0.2, 0.06), glow, Vector3(0, 0, 0.09))
	if text != "":
		var l := Label3D.new()
		l.text = text
		l.font_size = 220
		l.pixel_size = 0.01
		l.modulate = color
		l.outline_size = 12
		l.position = Vector3(0, 0, 0.2)
		l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		body.add_child(l)

func _spawn_model(path: String, pos: Vector3) -> Node3D:
	var wrapper := Node3D.new()
	wrapper.position = pos
	var ps := load(path) as PackedScene
	if ps == null:
		return wrapper
	var model := ps.instantiate()
	wrapper.add_child(model)
	return wrapper

func _play_anim(root: Node, anim_name: String) -> void:
	var ap := root.find_children("*", "AnimationPlayer", true, false)
	if ap.is_empty():
		return
	var player := ap[0] as AnimationPlayer
	if player and player.has_animation(anim_name):
		for a in player.get_animation_list():
			var res := player.get_animation(a)
			if res:
				res.loop_mode = Animation.LOOP_LINEAR
		player.play(anim_name)

func _mat(albedo: Color, metallic: float, roughness: float, emission: Color = Color(0, 0, 0), energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = metallic
	m.roughness = roughness
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m

func _box(parent: Node, size: Vector3, mat: StandardMaterial3D, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi
