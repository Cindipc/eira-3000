extends SceneTree

func _initialize() -> void:
	var level: Node3D = load("res://scenes/Level1.tscn").instantiate()
	root.add_child(level)
	await process_frame
	await physics_frame
	for i in 30:
		await physics_frame

	var player := level.get_node("Player")
	var anim: AnimationPlayer = player.get_node("Visual/Eira/AnimationPlayer")
	var cam: Camera3D = player.get_node("CameraPivot/Camera3D")
	var pivot: Node3D = player.get_node("CameraPivot")

	print("spawn pos: ", player.global_position)
	print("cam: ", cam.global_position, " look: ", -cam.global_transform.basis.z)
	print("anim: ", anim.current_animation)

	# forward must go +X (camera looks +X)
	var p0: Vector3 = player.global_position
	Input.action_press("move_forward")
	for i in 90:
		await physics_frame
	Input.action_release("move_forward")
	print("forward -> delta: ", player.global_position - p0, " anim: ", anim.current_animation, " y: ", player.global_position.y)
	print("visual rot: ", player.get_node("Visual").rotation.y)

	# backward
	var p1: Vector3 = player.global_position
	Input.action_press("move_back")
	for i in 60:
		await physics_frame
	Input.action_release("move_back")
	print("backward -> delta: ", player.global_position - p1, " y: ", player.global_position.y)

	# strafe right should be +Z
	var p2: Vector3 = player.global_position
	Input.action_press("move_right")
	for i in 60:
		await physics_frame
	Input.action_release("move_right")
	print("right -> delta: ", player.global_position - p2, " y: ", player.global_position.y)

	# run
	var p3: Vector3 = player.global_position
	Input.action_press("run")
	Input.action_press("move_forward")
	for i in 90:
		await physics_frame
	Input.action_release("run")
	Input.action_release("move_forward")
	print("run -> delta: ", player.global_position - p3, " anim: ", anim.current_animation, " y: ", player.global_position.y)

	# jump
	var y0: float = player.global_position.y
	var peak := y0
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	for i in 60:
		await physics_frame
		peak = maxf(peak, player.global_position.y)
	print("jump: peak y=%.3f -> now %.3f  pos=%s" % [peak, player.global_position.y, player.global_position])
	print("anim after jump: ", anim.current_animation, " playing=", anim.is_playing())
	print("anim list: ", anim.get_animation_list())

	print("cam after: ", cam.global_position, " look: ", -cam.global_transform.basis.z)
	print("nova: ", level.get_node("Nova").global_position)
	print("fps/nodes: ", level.get_child_count())
	quit()
