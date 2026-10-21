extends SceneTree

func _init() -> void:
	print("autoload setting: ", ProjectSettings.get_setting("autoload/GameState", "MISSING"))
	print("has autoload node: ", root.has_node("GameState"))
	var s := load("res://scripts/GameState.gd")
	print("script loaded: ", s)
	quit(0)
