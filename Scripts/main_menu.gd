extends Control

@onready var start_button = %StartButton
@onready var quit_button = %QuitButton
@onready var status_label = %Status

func _ready() -> void:
	start_button.pressed.connect(_on_start)
	quit_button.pressed.connect(_on_quit)
	start_button.grab_focus()

	# GameState has already loaded the save by now -- autoloads are ready before
	# the main scene is.
	status_label.text = "CONNECTION SECURE — SHIFT %02d" % GameState.shift_number
	start_button.text = "BEGIN SHIFT" if GameState.shift_number == 1 else "CLOCK IN"
	
func _on_start():
	get_tree().change_scene_to_file("res://Scenes/case_review.tscn")
	
func _on_quit():
	get_tree().quit()
