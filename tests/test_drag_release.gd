extends SceneTree
## 2.0.0 fixed-axis gestures, release-only purchase, and interruption behavior.

var checks = 0
var failures: Array[String] = []

func _initialize() -> void:
	create_timer(25.0).timeout.connect(func():
		push_error("Drag release tests timed out")
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

func motion(position: Vector2, held: bool = true):
	var event = InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(event, true)

func run_tests() -> void:
	seed(46)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var manager = scene.get_node("TechTreeManager")
	var camera = scene.get_node("Camera3D")
	manager.points_per_second = 0.0
	check(ProjectSettings.get_setting("application/config/version", "") == "2.0.0", "Project version is 2.0.0")
	check(manager.current_layout == manager.LayoutMode.VERTICAL and camera.current_layout == camera.LayoutMode.VERTICAL, "2.0.0 starts top-to-bottom")
	var expected_axis = Vector3(0, -manager.VERTICAL_TIER_SPACING * 2.0, 0)
	print("Startup axis=", camera.axis_center, "; expected=", expected_axis)
	check(camera.axis_center.is_equal_approx(expected_axis), "Startup camera must initialize the tree's fixed axis center")
	# Re-enter the current layout callback to isolate drag math from startup setup.
	camera._on_layout_changed(manager.current_layout)
	var axis: Vector3 = camera.axis_center
	var distance: float = camera.camera_distance
	var before: Vector3 = camera.global_position
	button(Vector2(2, 2), true)
	motion(Vector2(82, 22))
	check(not camera.global_position.is_equal_approx(before), "Blank-area drag rotates view")
	check(camera.axis_center.is_equal_approx(axis), "Drag preserves fixed axis")
	var panned_focus = camera.get_focus_point()
	check(is_equal_approx(camera.global_position.distance_to(panned_focus), distance), "Drag preserves distance to translated focus")
	button(Vector2(82, 22), false)
	check(not camera.dragging, "Button release ends drag")
	before = camera.global_position
	motion(Vector2(90, 30), false)
	check(camera.global_position.is_equal_approx(before), "Mouse movement after release does not rotate")

	button(Vector2(2, 2), true)
	camera.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not camera.dragging, "Focus loss cancels current drag")
	before = camera.global_position
	motion(Vector2(102, 2), false)
	check(camera.global_position.is_equal_approx(before), "Movement without button after focus loss cannot keep rotating")
	button(Vector2(102, 2), false)
	camera._on_layout_changed(manager.current_layout)
	for i in range(3):
		button(Vector2(600, 600), true)
		motion(Vector2(600, 100))
		button(Vector2(600, 100), false)
	check(is_zero_approx(camera.rotation_angle) and not is_zero_approx(camera.pan_offset), "Vertical axial drag translates without changing rotation")

	# Real viewport -> Area3D -> node signal, with enough points to expose spending.
	manager.tech_points = 1000.0
	var target = manager.tech_nodes["astronomy_nav"]
	camera.look_at_from_position(target.global_position + Vector3(1.5, 1.5, 1.5), target.global_position, Vector3.UP)
	var pointer: Vector2 = camera.unproject_position(target.global_position)
	motion(pointer, false)
	for i in range(2):
		await physics_frame
	button(pointer, true)
	for i in range(2):
		await physics_frame
	print("After press, before release: unlocked=", target.is_unlocked, "; points=", manager.tech_points)
	check(not target.is_unlocked and manager.tech_points == 1000.0, "Pressing node must wait for release before purchase")
	motion(pointer + Vector2(100, 40))
	for i in range(2):
		await physics_frame
	button(pointer + Vector2(100, 40), false)
	for i in range(2):
		await physics_frame
	check(not target.is_unlocked and manager.tech_points == 1000.0, "Drag gesture must never purchase its starting node")
	check(manager.unlocked_count == 0, "Dragging must not increment unlock count")

	# Cancellation must discard the pending target, even if released over it.
	var click_events: Array[String] = []
	target.node_clicked.connect(func(node): click_events.append(node.tech_id))
	camera.look_at_from_position(target.global_position + Vector3(1.5, 1.5, 1.5), target.global_position, Vector3.UP)
	pointer = camera.unproject_position(target.global_position)
	motion(pointer, false)
	button(pointer, true)
	var escape = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	button(pointer, false)
	check(not target.is_unlocked and manager.tech_points == 1000.0 and click_events.is_empty(), "Esc cancels a pending purchase")
	button(pointer, true)
	camera.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	button(pointer, false)
	check(not target.is_unlocked and manager.tech_points == 1000.0 and click_events.is_empty(), "Focus loss cancels a pending purchase")

	# A legitimate click tolerates minor hand jitter, then purchases once on release.
	button(pointer, true)
	check(not target.is_unlocked and click_events.is_empty(), "Ordinary click still waits for release")
	motion(pointer + Vector2(2, 1))
	button(pointer + Vector2(2, 1), false)
	check(target.is_unlocked and manager.tech_points == 1000.0 - target.tech_cost, "Release with small jitter purchases at the exact cost")
	check(click_events == [target.tech_id] and manager.unlocked_count == 1, "One release emits exactly one purchase signal")
	button(pointer + Vector2(2, 1), false)
	check(click_events.size() == 1 and manager.unlocked_count == 1, "Orphaned duplicate release cannot purchase again")

	var second = manager.tech_nodes["surveying_ballistics"]
	var balance: float = manager.tech_points
	camera.look_at_from_position(second.global_position + Vector3(1.5, 1.5, 1.5), second.global_position, Vector3.UP)
	pointer = camera.unproject_position(second.global_position)
	motion(pointer, false)
	button(pointer, true)
	manager.toggle_layout()
	button(pointer, false)
	await create_timer(0.95).timeout
	check(not second.is_unlocked and manager.tech_points == balance, "Direction switch cancels a pending purchase")
	for i in range(3):
		button(Vector2(600, 600), true)
		motion(Vector2(600, 100))
		button(Vector2(600, 100), false)
	check(not is_zero_approx(camera.rotation_angle) and is_zero_approx(camera.pan_offset), "Horizontal up drag rotates without translating")
	for i in range(3):
		button(Vector2(600, 100), true)
		motion(Vector2(600, 600))
		button(Vector2(600, 600), false)
	check(camera.global_position.is_finite() and is_zero_approx(camera.rotation_angle), "Opposite horizontal drags restore rotation")
	print("2.0.0 drag tests: ", checks, " checks; ", failures.size(), " failures")
	await create_timer(0.7).timeout
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

