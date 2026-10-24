extends SceneTree
## An equal pointer path must not depend on mouse event sampling frequency.

var checks = 0
var failures: Array[String] = []

func _initialize() -> void:
	create_timer(20.0).timeout.connect(func():
		push_error("Drag sampling tests timed out")
		quit(2))
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func drag(delta: Vector2, samples: int):
	var start = Vector2(500, 350)
	var press = InputEventMouseButton.new()
	press.position = start
	press.global_position = start
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	root.push_input(press, true)
	for i in range(1, samples + 1):
		var motion = InputEventMouseMotion.new()
		motion.position = start + delta * (float(i) / samples)
		motion.global_position = motion.position
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(motion, true)
	var release = InputEventMouseButton.new()
	release.position = start + delta
	release.global_position = release.position
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	root.push_input(release, true)

func run_tests() -> void:
	seed(49)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var camera = game.get_node("Camera3D")
	var manager = game.get_node("TechTreeManager")
	manager.points_per_second = 0.0
	for layout in [camera.LayoutMode.VERTICAL, camera.LayoutMode.HORIZONTAL]:
		for delta in [Vector2(10, 0), Vector2(0, 10), Vector2(100, 0), Vector2(0, 100)]:
			camera._on_layout_changed(layout)
			drag(delta, 1)
			var coarse_position: Vector3 = camera.global_position
			var coarse_basis: Basis = camera.global_basis
			var coarse_pan: float = camera.pan_offset
			var coarse_rotation: float = camera.rotation_angle
			camera._on_layout_changed(layout)
			drag(delta, 20)
			check(camera.global_position.is_equal_approx(coarse_position) and camera.global_basis.is_equal_approx(coarse_basis) and is_equal_approx(camera.pan_offset, coarse_pan) and is_equal_approx(camera.rotation_angle, coarse_rotation), "Equal pointer path has equal response for layout " + str(layout) + " delta " + str(delta))
		camera._on_layout_changed(layout)
		var before: Transform3D = camera.global_transform
		drag(Vector2(3, 3), 20)
		check(camera.global_transform.is_equal_approx(before), "Sub-threshold jitter does not move layout " + str(layout))
	check(manager.unlocked_count == 0, "Sampling tests do not purchase nodes")
	print("1.3.0 drag sampling tests: ", checks, " checks; ", failures.size(), " failures")
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
