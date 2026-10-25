extends SceneTree
## 2.0.0: 30-degree views and content-following grab translation.

var checks = 0
var failures: Array[String] = []

func _initialize() -> void:
	create_timer(25.0).timeout.connect(func():
		push_error("Fixed-axis tests timed out")
		quit(2))
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func button(position: Vector2, pressed: bool):
	var event = InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	root.push_input(event, true)

func drag(delta: Vector2):
	var start = Vector2(500, 350)
	button(start, true)
	var event = InputEventMouseMotion.new()
	event.position = start + delta
	event.global_position = event.position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event, true)
	button(event.position, false)

func focus(camera) -> Vector3:
	return camera.get_focus_point()

func valid_view(camera) -> bool:
	var direction = (focus(camera) - camera.global_position).normalized()
	return camera.global_position.is_finite() and absf(camera.global_basis.determinant() - 1.0) < 0.0001 and (-camera.global_basis.z).dot(direction) > 0.9999 and is_equal_approx(camera.global_position.distance_to(focus(camera)), camera.camera_distance)

func run_tests() -> void:
	seed(47)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var manager = game.get_node("TechTreeManager")
	var camera = game.get_node("Camera3D")
	manager.points_per_second = 0.0
	check(camera.current_layout == manager.current_layout, "Initial camera direction agrees with manager")
	check(camera.global_position.y > camera.axis_center.y, "Default camera observes from above the axis")
	check(camera.axis_center.is_equal_approx(Vector3(0, -30, 0)), "Default axis center uses the full tier range")
	var initial_rect = root.get_visible_rect()
	var all_visible = true
	for node in manager.tech_nodes.values():
		var visible = not camera.is_position_behind(node.global_position) and initial_rect.has_point(camera.unproject_position(node.global_position))
		all_visible = all_visible and visible
		if node.tier == 0:
			check(visible, "Starting technology is visible on launch: " + node.tech_id)
	check(all_visible, "Initial overview includes all node centers")
	var startup_offset: Vector3 = camera.global_position - focus(camera)
	check(is_equal_approx(atan2(startup_offset.y, Vector2(startup_offset.x, startup_offset.z).length()), PI / 6.0), "Default overhead view preserves the new 30-degree angle")

	camera._on_layout_changed(camera.LayoutMode.VERTICAL)
	var initial_position: Vector3 = camera.global_position
	drag(Vector2(100, 0))
	check(is_equal_approx(camera.rotation_angle, -100.0 * camera.rotation_speed) and is_zero_approx(camera.pan_offset), "Vertical sideways drag only rotates")
	check(valid_view(camera), "Vertical rotation keeps a valid view at fixed radius")
	drag(Vector2(-100, 0))
	check(camera.global_position.is_equal_approx(initial_position), "Opposite vertical sideways drags restore view")
	var initial_focus = focus(camera)
	var initial_basis: Basis = camera.global_basis
	var screen_before: Vector2 = camera.unproject_position(initial_focus)
	drag(Vector2(0, -100))
	print("Vertical up drag: focus delta=", focus(camera) - initial_focus)
	check((focus(camera) - initial_focus).is_equal_approx(Vector3(0, -5, 0)), "Vertical grab compensates camera translation")
	var screen_after: Vector2 = camera.unproject_position(initial_focus)
	check(screen_after.y < screen_before.y and is_equal_approx(screen_after.x, screen_before.x), "Vertical scene content follows upward pointer drag")
	check(is_zero_approx(camera.rotation_angle), "Vertical axial drag does not rotate")
	check(camera.global_basis.is_equal_approx(initial_basis), "Vertical translation preserves orientation")
	check(valid_view(camera), "Vertical translation keeps the correct focus distance")
	drag(Vector2(0, 100))
	check(camera.global_position.is_equal_approx(initial_position), "Opposite vertical axial drags restore position")

	camera._on_layout_changed(camera.LayoutMode.HORIZONTAL)
	check(camera.axis_center.is_equal_approx(Vector3(24, 0, 0)), "Horizontal axis properties match data")
	initial_position = camera.global_position
	initial_focus = focus(camera)
	initial_basis = camera.global_basis
	var side_offset: Vector3 = camera.global_position - initial_focus
	check(is_equal_approx(atan2(side_offset.y, side_offset.z), -PI / 6.0), "Horizontal view preserves the new 30-degree angle")
	screen_before = camera.unproject_position(initial_focus)
	drag(Vector2(100, 0))
	check((focus(camera) - initial_focus).is_equal_approx(Vector3(-5, 0, 0)), "Horizontal grab compensates camera translation")
	screen_after = camera.unproject_position(initial_focus)
	check(screen_after.x > screen_before.x and is_equal_approx(screen_after.y, screen_before.y), "Horizontal scene content follows rightward pointer drag")
	check(is_zero_approx(camera.rotation_angle) and camera.global_basis.is_equal_approx(initial_basis), "Horizontal axial drag does not rotate")
	check(valid_view(camera), "Horizontal translation keeps the correct focus distance")
	drag(Vector2(-100, 0))
	check(camera.global_position.is_equal_approx(initial_position), "Opposite horizontal axial drags restore position")
	drag(Vector2(0, -100))
	check(is_equal_approx(camera.rotation_angle, 100.0 * camera.rotation_speed) and is_zero_approx(camera.pan_offset), "Horizontal up drag only rotates")
	check(valid_view(camera), "Horizontal orbit keeps a valid view")
	drag(Vector2(0, 100))
	check(camera.global_position.is_equal_approx(initial_position), "Opposite horizontal rotational drags restore position")

	# Check both poles and orientation on either side of them through a full orbit.
	for degrees in [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 360]:
		camera.rotation_angle = deg_to_rad(degrees)
		camera.update_camera_transform()
		check(valid_view(camera), "Horizontal full orbit remains valid at " + str(degrees) + " degrees")
	for pole in [120.0, 300.0]:
		camera.rotation_angle = deg_to_rad(pole - 0.01)
		camera.update_camera_transform()
		var up_before: Vector3 = camera.global_basis.y
		camera.rotation_angle = deg_to_rad(pole + 0.01)
		camera.update_camera_transform()
		check(up_before.dot(camera.global_basis.y) > 0.9999, "No up-vector flip across orbit pole " + str(pole))
	camera.rotation_angle = TAU
	camera.update_camera_transform()
	check(camera.global_position.is_equal_approx(initial_position) and camera.global_basis.is_equal_approx(initial_basis), "Horizontal full revolution restores the entire transform")
	camera._on_layout_changed(camera.LayoutMode.VERTICAL)
	initial_position = camera.global_position
	initial_basis = camera.global_basis
	for degrees in [0, 90, 180, 270, 360]:
		camera.rotation_angle = deg_to_rad(degrees)
		camera.update_camera_transform()
		check(valid_view(camera), "Vertical full orbit remains valid at " + str(degrees) + " degrees")
	check(camera.global_position.is_equal_approx(initial_position) and camera.global_basis.is_equal_approx(initial_basis), "Vertical full revolution restores the entire transform")

	camera.pan_offset = 8.0
	camera.rotation_angle = 0.7
	camera.update_camera_transform()
	var wheel = InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	root.push_input(wheel)
	check(is_equal_approx(camera.pan_offset, 8.0) and is_equal_approx(camera.rotation_angle, 0.7), "Zoom preserves axial translation and rotation")
	check(valid_view(camera), "Zoom after mixed motion keeps the correct focus")
	button(Vector2(2, 2), true)
	camera.notification(Node.NOTIFICATION_WM_MOUSE_EXIT)
	check(not camera.dragging, "Leaving the window cancels the active gesture")
	button(Vector2(2, 2), false)
	manager.toggle_layout()
	check(camera.current_layout == manager.current_layout and is_zero_approx(camera.pan_offset) and is_zero_approx(camera.rotation_angle), "Direction switch synchronizes and resets motion")
	await create_timer(0.95).timeout
	check(valid_view(camera), "View remains valid after direction animation")
	check(manager.unlocked_count == 0, "Navigation does not purchase nodes")
	print("2.0.0 fixed-axis tests: ", checks, " checks; ", failures.size(), " failures")
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

