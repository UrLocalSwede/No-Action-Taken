extends Control

@onready var start_button = %StartButton
@onready var settings_button = %SettingsButton
@onready var quit_button = %QuitButton
@onready var status_label = %Status

@onready var settings_overlay = %SettingsOverlay
@onready var close_settings_button = %CloseSettingsButton

func _ready() -> void:
	start_button.pressed.connect(_on_start)
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(_on_quit)
	close_settings_button.pressed.connect(_close_settings)
	start_button.grab_focus()

	# GameState has already loaded the save by now -- autoloads are ready before
	# the main scene is.
	status_label.text = "CONNECTION SECURE — SHIFT %02d" % GameState.shift_number
	if GameState.username != "":
		status_label.text += " — %s" % GameState.username.to_upper()
	start_button.text = "BEGIN SHIFT" if GameState.shift_number == 1 else "CLOCK IN"

#-- Sign-in happens once, on a save with no username on it. Both routes out of
#   a shift -- clocking out past the last one, and the 'exit' command -- come
#   back through here, so this has to stay idempotent. --
func _on_start():
	if GameState.username == "":
		get_tree().change_scene_to_file("res://Scenes/Login.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/case_review.tscn")

func _on_quit():
	get_tree().quit()

# ---------------------------------------------------------------- settings

#-- The same SettingsPanel scene the desktop window uses. It is reachable from
#   here because the soundtrack starts playing at launch, and somebody who
#   wants it quieter should not have to clock in first to say so. --
func _open_settings():
	settings_overlay.visible = true
	close_settings_button.grab_focus()

func _close_settings():
	settings_overlay.visible = false
	start_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if settings_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_settings()
		get_viewport().set_input_as_handled()
