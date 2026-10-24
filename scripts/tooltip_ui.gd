extends Control

@onready var tooltip_panel: PanelContainer = $TooltipPanel
@onready var name_label: Label = $TooltipPanel/VBoxContainer/NameLabel
@onready var cost_label: Label = $TooltipPanel/VBoxContainer/CostLabel
@onready var status_label: Label = $TooltipPanel/VBoxContainer/StatusLabel
@onready var prereq_label: Label = $TooltipPanel/VBoxContainer/PrereqLabel

var current_node: TechNode = null

func _ready():
	tooltip_panel.visible = false
	# This overlay only displays information; it must not intercept node picking.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for control in find_children("*", "Control", true, false):
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta):
	if tooltip_panel.visible:
		if not is_instance_valid(current_node):
			hide_tooltip()
		else:
			update_tooltip_position(get_global_mouse_position())

func show_tooltip(node: TechNode, mouse_pos: Vector2):
	current_node = node
	refresh_tooltip()
	tooltip_panel.visible = true
	update_tooltip_position(mouse_pos)

func refresh_tooltip():
	if not is_instance_valid(current_node):
		hide_tooltip()
		return
	var node = current_node

	name_label.text = node.tech_name
	cost_label.text = "消耗: %d 科技点" % node.tech_cost

	if node.is_unlocked:
		status_label.text = "状态: 已解锁"
		status_label.modulate = Color.GREEN
	elif node.is_available:
		status_label.text = "状态: 可解锁"
		status_label.modulate = Color.YELLOW
	else:
		status_label.text = "状态: 锁定"
		status_label.modulate = Color.GRAY

	if node.prerequisites.size() > 0:
		prereq_label.text = "需要前置科技: %d 个" % node.prerequisites.size()
		prereq_label.visible = true
	else:
		prereq_label.visible = false

	tooltip_panel.reset_size()

func update_tooltip_position(mouse_pos: Vector2):
	var viewport_size = get_viewport_rect().size
	var panel_size = tooltip_panel.size
	var desired_position = mouse_pos + Vector2(10, 10)
	if desired_position.x + panel_size.x > viewport_size.x:
		desired_position.x = mouse_pos.x - panel_size.x - 10
	if desired_position.y + panel_size.y > viewport_size.y:
		desired_position.y = mouse_pos.y - panel_size.y - 10
	var max_position = (viewport_size - panel_size).max(Vector2.ZERO)
	tooltip_panel.position = desired_position.clamp(Vector2.ZERO, max_position)

func hide_tooltip(node: TechNode = null):
	if node != null and node != current_node:
		return
	tooltip_panel.visible = false
	current_node = null
