extends SceneTree
## Disc-layout controls, geometry, and retained state; no legacy pan assumptions.

var checks = 0
var failures: Array[String] = []

func _initialize() -> void:
	create_timer(25.0).timeout.connect(func():
		push_error("Disc layout tests timed out")
		quit(2))
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func key_state(key: Key, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	if key == KEY_Q or key == KEY_E:
		root.push_input(event)
	else:
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func toggle_view() -> void:
	var event = InputEventKey.new()
	event.keycode = KEY_PAGEDOWN
	event.pressed = true
	root.push_input(event)

func disconnected_lines(manager) -> int:
	var count = 0
	for child in manager.get_children():
		if child is MeshInstance3D and child.has_meta("source_node"):
			var vertices: PackedVector3Array = child.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			if not vertices[0].is_equal_approx(child.get_meta("source_node").position) or not vertices[1].is_equal_approx(child.get_meta("target_node").position):
				count += 1
	return count

func disc_position_matches(node, manager) -> bool:
	var radius = manager.TIER_RADIUS_BASE + node.tier * 2.0
	if manager.current_layout == manager.LayoutMode.HORIZONTAL:
		return is_equal_approx(node.position.x, node.tier * manager.TIER_SPACING) and absf(Vector2(node.position.y, node.position.z).length() - radius) <= 1.51
	return absf(node.position.y + node.tier * manager.VERTICAL_TIER_SPACING) <= 1.51 and is_equal_approx(Vector2(node.position.x, node.position.z).length(), radius)

func positions_match(manager) -> bool:
	for node in manager.tech_nodes.values():
		if not disc_position_matches(node, manager):
			return false
	return true

func line_colors_match(manager) -> bool:
	var count = 0
	for child in manager.get_children():
		if child is MeshInstance3D and child.has_meta("source_node"):
			count += 1
			var source = child.get_meta("source_node")
			var target = child.get_meta("target_node")
			var expected = Color(0.3, 0.3, 0.3, 0.4)
			if source.is_unlocked and target.is_unlocked:
				expected = Color(0.5, 1.0, 0.5, 0.8)
			elif source.is_unlocked:
				expected = Color(1.0, 1.0, 0.5, 0.6)
			var material = child.get_surface_override_material(0)
			if material == null or not material.albedo_color.is_equal_approx(expected):
				return false
	return count == manager.tech_links.size()

func run_tests() -> void:
	seed(45)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var manager = scene.get_node("TechTreeManager")
	var camera = scene.get_node("Camera3D")
	manager.points_per_second = 0.0
	manager.tech_points = 1000.0
	manager._on_tech_node_clicked(manager.tech_nodes["astronomy_nav"])
	var balance: float = manager.tech_points
	var original_positions = {}
	for id in manager.tech_nodes:
		original_positions[id] = manager.tech_nodes[id].position
	check(manager.current_layout == manager.LayoutMode.VERTICAL, "Default layout is top-to-bottom")
	check(manager.tech_nodes.size() == 32 and manager.tech_links.size() == 69, "Load all nodes and links")
	for node in manager.tech_nodes.values():
		check(disc_position_matches(node, manager), "Initial disc geometry: " + node.tech_id)
	check(disconnected_lines(manager) == 0, "Initial lines align")
	toggle_view()
	await create_timer(0.4).timeout
	check(disconnected_lines(manager) == 0, "Lines follow moving nodes during direction switch")
	check(line_colors_match(manager), "Animation retains line materials and colors")
	await create_timer(0.6).timeout
	check(manager.current_layout == manager.LayoutMode.HORIZONTAL and positions_match(manager), "Switch to left-to-right geometry")
	check(camera.current_layout == camera.LayoutMode.HORIZONTAL, "Camera agrees with left-to-right direction")
	check(manager.layout_label.text == "发展方向: 从左到右", "Left-to-right label")
	check(disconnected_lines(manager) == 0, "Completed lines align")
	check(is_equal_approx(manager.tech_points, balance) and manager.unlocked_count == 1, "Direction switch retains progress")
	toggle_view()
	await create_timer(0.95).timeout
	check(manager.current_layout == manager.LayoutMode.VERTICAL and positions_match(manager), "Switch back to top-to-bottom geometry")
	check(manager.layout_label.text == "发展方向: 从上到下", "Top-to-bottom label")
	var round_trip_matches = true
	for id in original_positions:
		if not manager.tech_nodes[id].position.is_equal_approx(original_positions[id]):
			round_trip_matches = false
	check(round_trip_matches, "Direction round trip retains exact node variation")
	for i in range(10):
		toggle_view()
		await create_timer(0.03).timeout
	await create_timer(0.95).timeout
	check(positions_match(manager), "Rapid direction switching settles correctly")
	check(disconnected_lines(manager) == 0 and line_colors_match(manager), "Rapid switching retains geometry and colors")
	check(manager.unlocked_count == 1 and is_equal_approx(manager.tech_points, balance), "Rapid switching retains progress")
	print("Direction layout tests: ", checks, " checks; ", failures.size(), " failures")
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
