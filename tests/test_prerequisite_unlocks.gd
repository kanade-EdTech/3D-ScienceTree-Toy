extends SceneTree
## Exercises real viewport input -> Area3D -> manager, without bypassing clicks.

var failures: Array[String] = []
var checks: int = 0
var clicked_ids: Array[String] = []

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func():
		push_error("Prerequisite tests timed out before completion")
		quit(2))
	call_deferred("run_tests")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func create_game():
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var manager = scene.get_node("TechTreeManager")
	manager.set_process(false)
	scene.get_node("Camera3D").set_process(false)
	for id in manager.tech_nodes:
		manager.tech_nodes[id].node_clicked.connect(func(node): clicked_ids.append(node.tech_id))
	var desired_layout = manager.LayoutMode.VERTICAL if OS.get_cmdline_user_args().has("--vertical") else manager.LayoutMode.HORIZONTAL
	if manager.current_layout != desired_layout:
		manager.toggle_layout()
		await create_timer(0.95).timeout
	check(manager.current_layout == desired_layout, "Prerequisite test uses requested layout")
	var geometry_ready = true
	for node in manager.tech_nodes.values():
		if desired_layout == manager.LayoutMode.VERTICAL:
			if absf(node.position.y + node.tier * manager.VERTICAL_TIER_SPACING) > 1.51:
				geometry_ready = false
		elif not is_equal_approx(node.position.x, node.tier * manager.TIER_SPACING):
			geometry_ready = false
	check(geometry_ready, "Prerequisite test requires actual requested geometry")
	if not geometry_ready:
		print("Prerequisite test BLOCKED: layout state and geometry disagree")
		scene.queue_free()
		await process_frame
		quit(1)
		return null
	return scene

func click_node(node, camera) -> void:
	# Keep gesture handling enabled; only move the test camera to avoid occlusion.
	# Close inspection prevents another node on the new ring from occluding it.
	camera.look_at_from_position(node.global_position + Vector3(1.5, 1.5, 1.5), node.global_position, Vector3.UP)
	var pointer = InputEventMouseMotion.new()
	pointer.position = camera.unproject_position(node.global_position)
	pointer.global_position = pointer.position
	root.push_input(pointer, true)
	for i in range(2):
		await physics_frame
	var hits_before = clicked_ids.size()
	var event = InputEventMouseButton.new()
	event.position = pointer.position
	event.global_position = pointer.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.pressed = true
	root.push_input(event, true)
	for i in range(2):
		await physics_frame
	event.pressed = false
	event.button_mask = 0
	root.push_input(event, true)
	for i in range(2):
		await physics_frame
	check(clicked_ids.size() == hits_before + 1 and clicked_ids.back() == node.tech_id, "Mouse must hit requested node: " + node.tech_id)

func prerequisites_met(manager, id: String) -> bool:
	# Derive the oracle from JSON links, independently of cached availability.
	for link in manager.tech_data.links:
		if link.target == id and not manager.tech_nodes[link.source].is_unlocked:
			return false
	return true

func run_tests() -> void:
	seed(43)
	print("Prerequisite mode: ", "vertical" if OS.get_cmdline_user_args().has("--vertical") else "horizontal")
	var scene = await create_game()
	if scene == null:
		return
	var manager = scene.get_node("TechTreeManager")
	var camera = scene.get_node("Camera3D")
	var target = manager.tech_nodes["analytic_geometry_calculus"]
	var first = manager.tech_nodes["astronomy_nav"]
	var second = manager.tech_nodes["surveying_ballistics"]
	manager.tech_points = 1000.0
	check(not target.is_available, "Calculus starts locked")
	await click_node(target, camera)
	check(not target.is_unlocked and manager.tech_points == 1000.0, "No prerequisites: click must not unlock or spend")
	await click_node(first, camera)
	check(first.is_unlocked and not target.is_available, "Only astronomy unlocked: calculus remains locked")
	var balance: float = manager.tech_points
	await click_node(target, camera)
	check(not target.is_unlocked and manager.tech_points == balance, "Missing surveying: click must not unlock or spend")
	await click_node(second, camera)
	check(second.is_unlocked and target.is_available and not target.is_unlocked, "Last prerequisite activates calculus without automatically purchasing it")
	print("Calculus: both prerequisite clicks completed; available=", target.is_available)
	manager.tech_points = target.tech_cost - 0.1
	balance = manager.tech_points
	await click_node(target, camera)
	check(not target.is_unlocked and is_equal_approx(manager.tech_points, balance), "All prerequisites but insufficient points: no unlock or spending")
	manager.tech_points = float(target.tech_cost)
	var count_before: int = manager.unlocked_count
	await click_node(target, camera)
	check(target.is_unlocked and is_zero_approx(manager.tech_points), "Exact cost: calculus unlocks and deducts exactly once")
	check(manager.unlocked_count == count_before + 1, "Unlock count increases once")
	check(manager.tooltip_ui.status_label.text == "状态: 已解锁", "Mouse-hover tooltip reflects completed unlock")
	await click_node(target, camera)
	check(is_zero_approx(manager.tech_points) and manager.unlocked_count == count_before + 1, "Repeated click cannot spend or increment again")
	print("Calculus: actual mouse purchase succeeded; points=", manager.tech_points)
	await create_timer(0.7).timeout
	scene.queue_free()
	await process_frame

	# Reverse JSON order so a single iteration cannot assume parents came first.
	scene = await create_game()
	if scene == null:
		return
	manager = scene.get_node("TechTreeManager")
	camera = scene.get_node("Camera3D")
	manager.tech_points = 10000.0
	var total_spent = 0
	var ids: Array = manager.tech_nodes.keys()
	ids.reverse()
	var changed = true
	while changed:
		changed = false
		for id in ids:
			var node = manager.tech_nodes[id]
			if node.is_unlocked:
				continue
			var expected = prerequisites_met(manager, id)
			check(node.is_available == expected, "Cached availability agrees with all JSON prerequisites: " + id)
			if expected:
				balance = manager.tech_points
				await click_node(node, camera)
				check(node.is_unlocked, "Available node unlocks through actual mouse picking: " + id)
				check(is_equal_approx(balance - manager.tech_points, float(node.tech_cost)), "Exact cost deducted: " + id)
				total_spent += node.tech_cost
				changed = node.is_unlocked or changed
	check(manager.unlocked_count == manager.total_count and manager.total_count == 32, "All 32 nodes unlock through prerequisite-respecting mouse clicks")
	check(is_equal_approx(manager.tech_points, 10000.0 - total_spent), "Full-game spending agrees with sum of node costs")
	print("Full mouse progression: ", manager.unlocked_count, "/", manager.total_count, "; total spent=", total_spent)
	print("Prerequisite tests: ", checks, " checks; ", failures.size(), " failures")
	await create_timer(0.7).timeout
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
