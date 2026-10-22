extends Control

@onready var video: VideoStreamPlayer = $VideoStreamPlayer
@onready var panel: Panel = $UI/Panel
@onready var btn_jugar: Button = $UI/Panel/VBox/BtnJugar
@onready var btn_creditos: Button = $UI/Panel/VBox/BtnCreditos
@onready var btn_salir: Button = $UI/Panel/VBox/BtnSalir
@onready var hint: Label = $UI/Hint

const TO_INTRO := "res://scenes/Intro.tscn"

func _ready() -> void:
	btn_jugar.pressed.connect(_on_jugar)
	btn_creditos.pressed.connect(_on_creditos)
	btn_salir.pressed.connect(_on_salir)
	var mp4 := load("res://assets/menu/menu_intro.mp4")
	if mp4:
		video.stream = mp4
	if video:
		video.play()
		if video.stream:
			video.finished.connect(_on_video_finished)
	if panel:
		panel.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(panel, "modulate:a", 1.0, 0.8).set_delay(0.6)
	if btn_jugar:
		btn_jugar.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_start_intro()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()

func _on_jugar() -> void:
	_start_intro()

func _start_intro() -> void:
	if video and video.is_playing():
		video.stop()
	get_tree().change_scene_to_file(TO_INTRO)

func _on_video_finished() -> void:
	pass

func _on_creditos() -> void:
	var dlg := AcceptDialog.new()
	dlg.dialog_text = "EIRA 3000\n\nDesarrollo: Proyecto Eira\nMotor: Godot 4.7"
	add_child(dlg)
	dlg.popup_centered()

func _on_salir() -> void:
	get_tree().quit()
