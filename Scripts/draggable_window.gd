extends Panel


@export var title_bar_path: NodePath = "VBoxContainer/Titlebar"

var _dragging := false
var _offset := Vector2.ZERO

func _ready():
	var bar = get_node(title_bar_path)
	bar.gui_input.connect(_on_bar_input)
	bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	
func _on_bar_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_dragging = true
		_offset = get_global_mouse_position() - global_position
		move_to_front()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		var pos = get_global_mouse_position() - _offset
		var vp = get_viewport_rect().size
		pos.x = clamp(pos.x, -size.x + 120, vp.x - 120)
		pos.y = clamp(pos.y, 0, vp.y - 60)
		global_position = pos
	
