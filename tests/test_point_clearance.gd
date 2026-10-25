extends SceneTree
## Every unrelated edge must clear node bodies in 3D and both default views.

var checks = 0
var failures: Array[String] = []

func _initialize():
	create_timer(30.0).timeout.connect(func(): quit(2))
	call_deferred("run")

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func inspect_layout(manager, camera):
	var minimum_space = INF
	var minimum_screen = INF
	var intrusions = []
	for node in manager.tech_nodes.values():
		var point: Vector2 = camera.unproject_position(node.global_position)
		var radius = point.distance_to(camera.unproject_position(node.global_position + camera.global_basis.x * 0.85))
		for link in manager.tech_links:
			if node.tech_id == link.source or node.tech_id == link.target:
				continue
			var a: Vector3 = manager.tech_nodes[link.source].global_position
			var b: Vector3 = manager.tech_nodes[link.target].global_position
			var spatial = node.global_position.distance_to(Geometry3D.get_closest_point_to_segment(node.global_position, a, b))
			var screen = point.distance_to(Geometry2D.get_closest_point_to_segment(point, camera.unproject_position(a), camera.unproject_position(b)))
			minimum_space = minf(minimum_space, spatial)
			minimum_screen = minf(minimum_screen, screen / radius)
			if spatial < 1.2 or screen < radius:
				intrusions.append(node.tech_id + " / " + link.source + " -> " + link.target)
	check(intrusions.is_empty(), "No node/edge intrusions in layout " + str(manager.current_layout) + ": " + str(intrusions))
	print("Layout ", manager.current_layout, ": minimum spatial clearance=", minimum_space, "; minimum screen margin ratio=", minimum_screen)
	for node in manager.tech_nodes.values():
		var settings: Dictionary = manager.layout_adjustments[node.tech_id]
		var key = "vertical" if manager.current_layout == manager.LayoutMode.VERTICAL else "horizontal"
		var d: Array = settings[key]
		check(Vector3(d[0], d[1], d[2]).length() <= 3.0, "Adjustment stays small: " + node.tech_id)
		var vertices = node.get_node("Area3D/CollisionShape3D").global_position
		check(vertices.is_equal_approx(node.global_position), "Picking follows adjusted point: " + node.tech_id)
	for child in manager.get_children():
		if child is MeshInstance3D and child.has_meta("source_node"):
			var v: PackedVector3Array = child.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			check(v[0].is_equal_approx(child.get_meta("source_node").position) and v[1].is_equal_approx(child.get_meta("target_node").position), "Line endpoints follow adjusted points")

func run():
	var reference = {}
	for random_seed in [48, 17, 902]:
		seed(random_seed)
		var game = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		await process_frame
		var manager = game.get_node("TechTreeManager")
		var camera = game.get_node("Camera3D")
		manager.points_per_second = 0
		check(manager.layout_adjustments.size() == 32, "All 32 authored point adjustments are loaded")
		for mode in [manager.LayoutMode.VERTICAL, manager.LayoutMode.HORIZONTAL, manager.LayoutMode.VERTICAL]:
			if manager.current_layout != mode:
				manager.toggle_layout()
				await create_timer(0.85).timeout
			inspect_layout(manager, camera)
			for node in manager.tech_nodes.values():
				var key = str(mode) + node.tech_id
				if reference.has(key):
					check(reference[key].is_equal_approx(node.position), "Restart and round trip preserve point: " + node.tech_id)
				else:
					reference[key] = node.position
		game.queue_free()
		await process_frame
	print("Point clearance tests: ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
