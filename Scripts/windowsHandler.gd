extends PanelContainer

# -- Window manager --
# Lives on the Taskbar and owns every window under ../Windows:
# dragging, edge resizing, and the minimize / open animations.

@onready var rule_icon = $HBoxContainer/RuleBtn
@onready var review_icon = $HBoxContainer/QueueBtn
@onready var chat_icon = $HBoxContainer/ChatBtn

@onready var review_queue = $"../Windows/QueueWindow"
@onready var rulebook = $"../Windows/RulebookWindow"
@onready var chat_window = $"../Windows/ChatWindow"

const TITLE_BAR := "Titlebar"
const MIN_BUTTON := "Titlebar/Row/MinimizeButton"

const EDGE := 14
const MIN_SIZE := Vector2(520, 440)

const GUTTER := 24.0
const BAR_H := 56.0
const CONTENT_GAP := 20   # breathing room between titlebar and window content

const MINIMIZE_TIME := 0.18
const OPEN_TIME := 0.26
const DOCKED_SCALE := 0.35

const BODY_IDLE := &"WindowBody"
const BODY_ACTIVE := &"WindowBodyActive"
const BTN_IDLE := &"TaskbarButton"
const BTN_ACTIVE := &"TaskbarButtonActive"

enum State { OPEN, MINIMIZED, MINIMIZING, OPENING }

var front_window: Control = null

var _active: Control = null # window being dragged / resized
var _dragging := false
var _offset := Vector2.ZERO

var _resizing := false
var _resize_dir := Vector2.ZERO
var _start_rect := Rect2()
var _start_mouse := Vector2.ZERO

var _state := {}    # window -> State
var _home := {}     # window -> position to fly back to
var _tweens := {}   # window -> running Tween
var _buttons := {}  # window -> taskbar button


func _ready():
	_register(review_queue, review_icon)
	_register(rulebook, rule_icon)
	_register(chat_window, chat_icon)
	_layout_windows()
	_bring_to_front(review_queue)

#-- Tiles the windows across whatever viewport we actually got.
#   The offsets authored in the scene are design-time only; the game runs
#   maximized with no stretch mode, so the viewport is the monitor size. --
func _layout_windows():
	var vp := get_viewport_rect().size
	var cols := 3.0
	var w: float = max((vp.x - GUTTER * (cols + 1.0)) / cols, MIN_SIZE.x)
	var h: float = max(vp.y - BAR_H - GUTTER * 2.0, MIN_SIZE.y)
	var order := [review_queue, rulebook, chat_window]
	for i in order.size():
		var win: Control = order[i]
		win.size = Vector2(w, h)
		win.global_position = Vector2(GUTTER + (w + GUTTER) * i, GUTTER)
		_home[win] = win.global_position

#-- Hooks a window up to its taskbar button and input handlers --
func _register(win: Control, button: Button):
	_buttons[win] = button
	_state[win] = State.OPEN if win.visible else State.MINIMIZED
	_home[win] = win.global_position
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_icon_pressed.bind(win))
	_set_button_state(win, win.visible)

	var bar: Control = win.get_node(TITLE_BAR)
	bar.gui_input.connect(_on_bar_input.bind(win))
	bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	# The titlebar is a PanelContainer, so its height comes from its content,
	# not from the offset authored in the scene. Keep the body inset in step
	# with it instead of hardcoding a number that silently drifts.
	bar.resized.connect(_sync_body_inset.bind(win))
	_sync_body_inset(win)

	var min_btn := win.get_node_or_null(MIN_BUTTON) as Button
	if min_btn:
		min_btn.focus_mode = Control.FOCUS_NONE
		min_btn.pressed.connect(minimize_window.bind(win))

	win.mouse_filter = Control.MOUSE_FILTER_STOP
	win.gui_input.connect(_on_window_input.bind(win))

#-- Push the content container below whatever height the titlebar settled at --
func _sync_body_inset(win: Control):
	var bar := win.get_node_or_null(TITLE_BAR) as Control
	var body := win.get_node_or_null("Body") as MarginContainer
	if bar and body:
		body.add_theme_constant_override("margin_top", int(bar.size.y) + CONTENT_GAP)

#-- The taskbar tile looks different when its window is open --
func _set_button_state(win: Control, is_open: bool):
	var b: Button = _buttons.get(win)
	if b:
		b.theme_type_variation = BTN_ACTIVE if is_open else BTN_IDLE


# ---------------------------------------------------------------- minimize / open

func _on_icon_pressed(win: Control):
	if _state.get(win, State.OPEN) in [State.OPEN, State.OPENING]:
		minimize_window(win)
	else:
		open_window(win)

#-- Shrinks the window down into its taskbar icon, then hides it --
func minimize_window(win: Control):
	var state = _state.get(win, State.OPEN)
	if state in [State.MINIMIZED, State.MINIMIZING]:
		return
	if state == State.OPEN:
		_home[win] = win.global_position # remember where it sat
	if _active == win:
		_dragging = false
		_resizing = false
		_active = null

	_kill_tween(win)
	_state[win] = State.MINIMIZING
	_set_button_state(win, false)
	win.pivot_offset = win.size * 0.5

	var t = _new_tween(win)
	t.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(win, "global_position", _dock_position(win), MINIMIZE_TIME)
	t.parallel().tween_property(win, "scale", Vector2.ONE * DOCKED_SCALE, MINIMIZE_TIME)
	t.parallel().tween_property(win, "modulate:a", 0.0, MINIMIZE_TIME * 0.8)
	t.chain().tween_callback(_on_minimized.bind(win))

func _on_minimized(win: Control):
	win.visible = false
	_reset_transform(win)
	_state[win] = State.MINIMIZED

#-- Grows the window out of its taskbar icon and back into place --
func open_window(win: Control):
	var state = _state.get(win, State.OPEN)
	if state in [State.OPEN, State.OPENING]:
		return

	_kill_tween(win)
	var home = _home.get(win, win.global_position)
	win.pivot_offset = win.size * 0.5
	win.global_position = _dock_position(win)
	win.scale = Vector2.ONE * DOCKED_SCALE
	win.modulate.a = 0.0
	win.visible = true
	_bring_to_front(win)
	_state[win] = State.OPENING
	_set_button_state(win, true)

	var t = _new_tween(win)
	t.tween_property(win, "global_position", home, OPEN_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(win, "scale", Vector2.ONE, OPEN_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(win, "modulate:a", 1.0, OPEN_TIME * 0.6) \
		.set_trans(Tween.TRANS_LINEAR)
	t.chain().tween_callback(_on_opened.bind(win))

func _on_opened(win: Control):
	_reset_transform(win)
	_state[win] = State.OPEN

#-- Centre of the window's taskbar icon, as a window position --
func _dock_position(win: Control) -> Vector2:
	var button = _buttons.get(win)
	if button == null:
		return win.global_position
	return button.get_global_rect().get_center() - win.size * 0.5

func _reset_transform(win: Control):
	win.scale = Vector2.ONE
	win.modulate.a = 1.0
	win.global_position = _home.get(win, win.global_position)

func _new_tween(win: Control) -> Tween:
	var t = create_tween()
	_tweens[win] = t
	return t

func _kill_tween(win: Control):
	var t = _tweens.get(win)
	if t != null and t.is_valid():
		t.kill()
	_tweens.erase(win)

func _bring_to_front(win: Control):
	if front_window == win:
		return
	if front_window != null and is_instance_valid(front_window):
		front_window.theme_type_variation = BODY_IDLE
	win.move_to_front()
	win.theme_type_variation = BODY_ACTIVE
	front_window = win

#-- A window busy animating shouldn't be draggable --
func _is_settled(win: Control) -> bool:
	return _state.get(win, State.OPEN) == State.OPEN


# ---------------------------------------------------------------- drag / resize

func _on_bar_input(event, win: Control):
	if not _is_settled(win):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_active = win
		_dragging = true
		_offset = win.get_global_mouse_position() - win.global_position
		_bring_to_front(win)

func _on_window_input(event, win: Control):
	if not _is_settled(win):
		return

	if event is InputEventMouseMotion and not _resizing:
		var d = _edge_at(win, event.position)
		if d == Vector2.ZERO:
			win.mouse_default_cursor_shape = Control.CURSOR_ARROW
		elif d.x != 0 and d.y != 0:
			win.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		elif d.x != 0:
			win.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		else:
			win.mouse_default_cursor_shape = Control.CURSOR_VSIZE

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var d = _edge_at(win, event.position)
		if d != Vector2.ZERO:
			_active = win
			_resizing = true
			_resize_dir = d
			_start_rect = Rect2(win.global_position, win.size)
			_start_mouse = win.get_global_mouse_position()
		_bring_to_front(win)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _dragging and _active != null:
			_home[_active] = _active.global_position
		_dragging = false
		_resizing = false
		_active = null
	elif event is InputEventMouseMotion and _active != null:
		if _resizing:
			var delta = _active.get_global_mouse_position() - _start_mouse
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

			_active.global_position = pos
			_active.size = sz
			_home[_active] = pos

		elif _dragging:
			var pos = _active.get_global_mouse_position() - _offset
			var vp = get_viewport_rect().size
			pos.x = clamp(pos.x, -_active.size.x + 120, vp.x - 120)
			pos.y = clamp(pos.y, 0, vp.y - 60)
			_active.global_position = pos

func _edge_at(win: Control, local_pos: Vector2) -> Vector2:
	var dir = Vector2.ZERO
	if local_pos.x >= win.size.x - EDGE: dir.x = 1
	elif local_pos.x <= EDGE:            dir.x = -1
	if local_pos.y >= win.size.y - EDGE: dir.y = 1
	elif local_pos.y <= EDGE:            dir.y = -1
	return dir
