extends Control

@onready var horizontal_arrows: Control = $HorizontalArrows
@onready var vertical_arrows: Control = $VerticalArrows

enum LayoutMode { HORIZONTAL, VERTICAL }

func _ready():
	# Initially show horizontal mode indicators
	show_horizontal()

	# Connect to layout changes
	var tech_tree = get_node("../../TechTreeManager")
	if tech_tree:
		tech_tree.layout_changed.connect(_on_layout_changed)

func _on_layout_changed(new_layout):
	if new_layout == LayoutMode.HORIZONTAL:
		show_horizontal()
	else:
		show_vertical()

func show_horizontal():
	if horizontal_arrows:
		horizontal_arrows.visible = true
	if vertical_arrows:
		vertical_arrows.visible = false

func show_vertical():
	if horizontal_arrows:
		horizontal_arrows.visible = false
	if vertical_arrows:
		vertical_arrows.visible = true
