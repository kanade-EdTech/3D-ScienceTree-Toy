extends SceneTree
## Run: Godot --headless --path . --script res://tests/test_interactions.gd

var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func():
		push_error("Interaction tests timed out before completion")
		quit(2))
	call_deferred("run_tests")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func mouse_button(button: MouseButton, pressed: bool = true) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	root.push_input(event)

func run_tests() -> void:
	seed(42)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var camera = scene.get_node("Camera3D")
	camera.set_process(false)
	var manager = scene.get_node("TechTreeManager")
	var tooltip = manager.tooltip_ui
	manager.set_process(false)
	tooltip.set_process(false)

	# Exercise the engine's input dispatch, including button release events.
	var original_position: Vector3 = camera.global_position
	for i in range(10):
		camera.update_camera_transform()
	check(camera.global_position.is_equal_approx(original_position), "Repeated transforms must not drift")
	mouse_button(MOUSE_BUTTON_LEFT)
	mouse_button(MOUSE_BUTTON_LEFT, false)
	check(camera.global_position.is_equal_approx(original_position), "Left click must not move camera")

	var focus: Vector3 = camera.axis_center
	var distance_before: float = camera.global_position.distance_to(focus)
	var sample: Vector3 = manager.tech_nodes["astronomy_nav"].global_position
	var size_before: float = camera.unproject_position(sample).distance_to(camera.unproject_position(sample + Vector3.RIGHT))
	mouse_button(MOUSE_BUTTON_WHEEL_UP)
	check(camera.global_position.distance_to(focus) < distance_before, "Wheel up must approach focus")
	var size_after: float = camera.unproject_position(sample).distance_to(camera.unproject_position(sample + Vector3.RIGHT))
	check(size_after > size_before, "Wheel up must enlarge projected objects")
	var zoomed_position: Vector3 = camera.global_position
	mouse_button(MOUSE_BUTTON_WHEEL_UP, false)
	check(camera.global_position.is_equal_approx(zoomed_position), "Wheel release must not zoom again")
	mouse_button(MOUSE_BUTTON_WHEEL_DOWN)
	check(camera.global_position.is_equal_approx(original_position), "Opposite wheel steps must restore camera")
	for i in range(30):
		mouse_button(MOUSE_BUTTON_WHEEL_UP)
	check(is_equal_approx(camera.global_position.distance_to(focus), camera.min_distance), "Zoom in must clamp actual focus distance")
	for i in range(30):
		mouse_button(MOUSE_BUTTON_WHEEL_DOWN)
	check(is_equal_approx(camera.global_position.distance_to(focus), camera.max_distance), "Zoom out must clamp actual focus distance")

	camera.camera_distance = 45.0
	camera.update_camera_transform()
	mouse_button(MOUSE_BUTTON_LEFT)
	var motion = InputEventMouseMotion.new()
	motion.position = Vector2(30, 15)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion)
	mouse_button(MOUSE_BUTTON_LEFT, false)
	var panned_focus = camera.get_focus_point()
	check(is_equal_approx(camera.global_position.distance_to(panned_focus), camera.camera_distance), "Drag preserves distance to its translated focus")
	check(not camera.dragging, "Left release must stop dragging")
	mouse_button(MOUSE_BUTTON_LEFT)
	camera.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not camera.dragging, "Focus loss must cancel dragging")
	mouse_button(MOUSE_BUTTON_LEFT, false)
	mouse_button(MOUSE_BUTTON_LEFT)
	var escape = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	check(not camera.dragging, "Esc must cancel dragging")
	mouse_button(MOUSE_BUTTON_LEFT, false)

	# The live tooltip must agree with unlock and dependency state transitions.
	var first = manager.tech_nodes["astronomy_nav"]
	camera.look_at_from_position(first.global_position + Vector3(1.5, 1.5, 1.5), first.global_position, Vector3.UP)
	var picked: Array[String] = []
	first.node_clicked.connect(func(node): picked.append(node.tech_id))
	var pointer = InputEventMouseMotion.new()
	pointer.position = camera.unproject_position(first.global_position)
	pointer.global_position = pointer.position
	root.push_input(pointer, true)
	for i in range(3):
		await physics_frame
	var click = InputEventMouseButton.new()
	click.position = pointer.position
	click.global_position = pointer.position
	click.button_index = MOUSE_BUTTON_LEFT
	click.button_mask = MOUSE_BUTTON_MASK_LEFT
	click.pressed = true
	root.push_input(click, true)
	for i in range(3):
		await physics_frame
	click.pressed = false
	click.button_mask = 0
	root.push_input(click, true)
	await physics_frame
	check(picked == ["astronomy_nav"], "Viewport mouse click must reach 3D node")
	check(not first.is_unlocked and manager.tech_points == 0.0, "Insufficient points must block actual mouse unlock")
	manager.tech_points = 10000.0
	tooltip.show_tooltip(first, Vector2(500, 400))
	check(tooltip.status_label.text == "状态: 可解锁", "Initial available tooltip status")
	manager._on_tech_node_clicked(first)
	check(first.is_unlocked and tooltip.status_label.text == "状态: 已解锁", "Unlock must refresh visible tooltip")
	var points_after: float = manager.tech_points
	manager._on_tech_node_clicked(first)
	check(manager.unlocked_count == 1 and manager.tech_points == points_after, "Duplicate click must not spend or count again")
	var other = manager.tech_nodes["surveying_ballistics"]
	tooltip.show_tooltip(other, Vector2(500, 400))
	tooltip.hide_tooltip(first)
	check(tooltip.current_node == other and tooltip.tooltip_panel.visible, "Old node exit must not hide new node tooltip")
	manager._on_tech_node_hovered(first, false)
	check(tooltip.current_node == other and tooltip.tooltip_panel.visible, "Manager must correlate old node exit with the current tooltip")
	await process_frame
	var viewport_size: Vector2 = tooltip.get_viewport_rect().size
	tooltip.update_tooltip_position(viewport_size - Vector2.ONE)
	var panel_rect: Rect2 = tooltip.tooltip_panel.get_rect()
	check(panel_rect.position.x >= 0 and panel_rect.position.y >= 0 and panel_rect.end.x <= viewport_size.x and panel_rect.end.y <= viewport_size.y, "Tooltip must stay inside viewport at lower right")
	for control in tooltip.find_children("*", "Control", true, false):
		check(control.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Tooltip must not block picking: " + str(control.name))
	for path in ["Control", "Control/VBoxContainer", "Control/VBoxContainer/PanelContainer", "Control/VBoxContainer/PanelContainer/MarginContainer", "Control/VBoxContainer/PanelContainer/MarginContainer/InfoVBox"]:
		check(manager.ui_layer.get_node(path).mouse_filter == Control.MOUSE_FILTER_IGNORE, "HUD must not block picking: " + path)

	var locked = manager.tech_nodes["computer_science_ai"]
	manager._on_tech_node_clicked(locked)
	check(not locked.is_unlocked and manager.tech_points == points_after, "Unmet prerequisites must block unlock and spending")
	var next = manager.tech_nodes["analytic_geometry_calculus"]
	tooltip.show_tooltip(next, Vector2(500, 400))
	manager._on_tech_node_clicked(other)
	check(next.is_available and tooltip.status_label.text == "状态: 可解锁", "Dependency changes must refresh hovered node")
	var speed_values = []
	for i in range(4):
		manager.cycle_time_scale()
		speed_values.append(manager.time_scale)
	check(speed_values == [2.0, 4.0, 8.0, 1.0], "Speed cycle must return to 1x")
	var changed = true
	while changed:
		changed = false
		for id in manager.tech_nodes:
			var tech = manager.tech_nodes[id]
			if tech.can_unlock(int(manager.tech_points)):
				manager._on_tech_node_clicked(tech)
				changed = tech.is_unlocked or changed
	check(manager.unlocked_count == manager.tech_nodes.size(), "All nodes must be reachable")
	print("Interaction tests: ", checks, " checks; ", failures.size(), " failures")
	await create_timer(0.8).timeout
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
