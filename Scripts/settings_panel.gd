extends VBoxContainer

# -- The settings form --
# Its own scene so the desktop window and the main-menu overlay are the same
# implementation. Music autoplays at launch, so there has to be a volume slider
# reachable before the player is inside a shift.
#
# Every discrete choice is a segmented row of plain Buttons rather than a
# CheckBox or an OptionButton: Button is already styled in all five states and
# its 'pressed' box reads as selected, so the whole app needs exactly one new
# theme type (HSlider) instead of four.

@onready var master_slider: HSlider = %SetMasterSlider
@onready var music_slider: HSlider = %SetMusicSlider
@onready var sfx_slider: HSlider = %SetSfxSlider

@onready var master_value: Label = %SetMasterValue
@onready var music_value: Label = %SetMusicValue
@onready var sfx_value: Label = %SetSfxValue

@onready var mode_row: HBoxContainer = %SetModeRow
@onready var res_row: HBoxContainer = %SetResRow
@onready var speed_row: HBoxContainer = %SetSpeedRow

@onready var res_note: Label = %SetResNote
@onready var reset_button: Button = %SetResetButton
@onready var reset_note: Label = %SetResetNote

# Seconds the reset button stays armed before it goes back to being harmless.
const CONFIRM_WINDOW := 6.0

var _reset_armed := false
var _reset_timer: SceneTreeTimer = null


func _ready() -> void:
	_build_segment(mode_row, Settings.WINDOW_MODE_NAMES, _on_mode_picked)
	_build_segment(res_row, Settings.RESOLUTION_NAMES, _on_resolution_picked)
	_build_segment(speed_row, Settings.TEXT_SPEED_NAMES, _on_speed_picked)

	_bind_slider(master_slider, Settings.BUS_MASTER)
	_bind_slider(music_slider, Settings.BUS_MUSIC)
	_bind_slider(sfx_slider, Settings.BUS_SFX)

	reset_button.pressed.connect(_on_reset_pressed)

	# The music window carries its own volume slider on the same bus, so the two
	# can be open at once and must not drift apart.
	Settings.changed.connect(refresh)
	refresh()

# ---------------------------------------------------------------- building

#-- Fills a row with mutually exclusive buttons. A ButtonGroup rather than bare
#   toggles, so exactly one is always lit and clicking the lit one cannot turn
#   the whole row off. --
func _build_segment(row: HBoxContainer, labels: Array, on_pick: Callable) -> void:
	var group := ButtonGroup.new()
	for i in labels.size():
		var b := Button.new()
		b.text = String(labels[i])
		b.toggle_mode = true
		b.button_group = group
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		# 'pressed' fires on real input only -- set_pressed() emits 'toggled'
		# instead -- so _select() below cannot loop back through here.
		b.pressed.connect(on_pick.bind(i))
		row.add_child(b)

func _select(row: HBoxContainer, index: int) -> void:
	for i in row.get_child_count():
		var b := row.get_child(i) as Button
		if b:
			b.button_pressed = (i == index)

func _bind_slider(slider: HSlider, bus: StringName) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value_changed.connect(func(v: float) -> void: Settings.set_volume(bus, v))

# ---------------------------------------------------------------- state

#-- Pushes Settings back into the controls. set_value_no_signal keeps this from
#   bouncing straight back out through value_changed. --
func refresh() -> void:
	master_slider.set_value_no_signal(Settings.master_volume)
	music_slider.set_value_no_signal(Settings.music_volume)
	sfx_slider.set_value_no_signal(Settings.sfx_volume)

	master_value.text = _percent(Settings.master_volume)
	music_value.text = _percent(Settings.music_volume)
	sfx_value.text = _percent(Settings.sfx_volume)

	_select(mode_row, Settings.window_mode)
	_select(res_row, Settings.resolution_index)
	_select(speed_row, Settings.text_speed_index)

	var res := Settings.resolution()
	res_note.text = "%d x %d — APPLIES IN WINDOWED MODE" % [res.x, res.y]
	# Greyed out either because only windowed mode has a size of its own to
	# set, or because the monitor is not that big.
	var windowed := Settings.window_mode == Settings.WindowMode.WINDOWED
	for i in res_row.get_child_count():
		(res_row.get_child(i) as Button).disabled = not windowed or not Settings.fits_screen(i)

func _percent(v: float) -> String:
	return "OFF" if v <= Settings.SILENCE else "%d%%" % roundi(v * 100.0)

# ---------------------------------------------------------------- handlers

func _on_mode_picked(index: int) -> void:
	Settings.set_window_mode(index)

func _on_resolution_picked(index: int) -> void:
	Settings.set_resolution_index(index)

func _on_speed_picked(index: int) -> void:
	Settings.set_text_speed_index(index)

#-- Two presses, because this is the one control in the app that destroys
#   something. The arm expires on its own so a stray click cannot leave a live
#   trigger sitting there. --
func _on_reset_pressed() -> void:
	if not _reset_armed:
		_arm_reset()
		return
	_disarm_reset()
	GameState.reset()
	reset_note.text = "PROGRESS CLEARED. SHIFT 01, NO CREDENTIALS ON FILE."

func _arm_reset() -> void:
	_reset_armed = true
	reset_button.text = "CONFIRM — THIS CANNOT BE UNDONE"
	reset_note.text = "EVERY SHIFT, CITATION AND SIGN-IN WILL BE ERASED."
	_reset_timer = get_tree().create_timer(CONFIRM_WINDOW)
	_reset_timer.timeout.connect(_on_confirm_expired.bind(_reset_timer))

func _disarm_reset() -> void:
	_reset_armed = false
	_reset_timer = null
	reset_button.text = "RESET PROGRESS"

func _on_confirm_expired(timer: SceneTreeTimer) -> void:
	# A newer arm supersedes this one; only the timer still on record may fire.
	if timer != _reset_timer:
		return
	_disarm_reset()
	reset_note.text = "WIPES SHIFT PROGRESS AND YOUR SIGN-IN."
