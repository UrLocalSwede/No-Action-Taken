extends Panel


@export var title_bar_path: NodePath = "VBoxContainer/Titlebar"

var _dragging := false
var _offset := Vector2.ZERO

const EDGE := 14
const MIN_SIZE := Vector2(520, 440)

var _resizing := false
var _resize_dir := Vector2.ZERO
var _start_rect := Rect2()
var _start_mouse := Vector2.ZERO

func _ready():
	var bar = get_node(title_bar_path)
	bar.gui_input.connect(_on_bar_input)
	bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_window_input)
	
func _on_bar_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_dragging = true
		_offset = get_global_mouse_position() - global_position
		move_to_front()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false
		_resizing = false
	elif event is InputEventMouseMotion:
		if _resizing:
			var delta = get_global_mouse_position() - _start_mouse
			var pos = _start_rect.position
			var sz = _start_rect.size
			if _resize_dir.x > 0:
				sz.x = max(_start_rect.size.x + delta.x, MIN_SIZE.x)
			elif _resize_dir.x < 0:
				sz.x = max(_start_rect.size.x - delta.x, MIN_SIZE.x)
				pos.x = _start_rect.position.x + (_start_rect.size.x - sz.x)
	
			if _resize_dir.y > 0:
				sz.y = max(_start_rect.size.y + delta.y, MIN_SIZE.y)
			elif _resize_dir.y < 0:
				sz.y = max(_start_rect.size.y - delta.y, MIN_SIZE.y)
				pos.y = _start_rect.position.y + (_start_rect.size.y - sz.y)
				
			global_position = pos
			size = sz
			
		elif _dragging:
			var pos = get_global_mouse_position() - _offset
			var vp = get_viewport_rect().size
			pos.x = clamp(pos.x, -size.x + 120, vp.x - 120)
			pos.y = clamp(pos.y, 0, vp.y - 60)
			global_position = pos

func _edge_at(local_pos: Vector2) -> Vector2:
	var dir = Vector2.ZERO
	if local_pos.x >= size.x - EDGE: dir.x = 1
	elif local_pos.x <= EDGE:        dir.x = -1
	if local_pos.y >= size.y - EDGE: dir.y = 1
	elif local_pos.y <= EDGE:        dir.y = -1
	return dir

func _on_window_input(event):
	if event is InputEventMouseMotion and not _resizing:

		var d = _edge_at(event.position)
		if d == Vector2.ZERO:
			mouse_default_cursor_shape = Control.CURSOR_ARROW
		elif d.x != 0 and d.y != 0:
			mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		elif d.x != 0:
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
		else:
			mouse_default_cursor_shape = Control.CURSOR_VSIZE
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var d = _edge_at(event.position)
		if d != Vector2.ZERO:
			_resizing = true
			_resize_dir = d
			_start_rect = Rect2(global_position, size)
			_start_mouse = get_global_mouse_position()
			move_to_front()
	
