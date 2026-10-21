extends SceneTree

func _init() -> void:
	var gs_script: GDScript = load("res://scripts/GameState.gd")
	var gs: Node = gs_script.new()
	gs.name = "GameState"
	root.add_child(gs)
	add_named_global_constant("GameState", gs)
	var h: GDScript = load("res://scripts/HUD.gd")
	print("hud script: ", h)
	var p: GDScript = load("res://scripts/PuzzleTerminal.gd")
	print("terminal script: ", p)
	quit(0)
