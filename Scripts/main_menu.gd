extends Control

@onready var start_button = $PanelContainer/CenterContainer/VBoxContainer/StartButton
@onready var quit_button = $PanelContainer/CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start)
	quit_button.pressed.connect(_on_quit)
	start_button.grab_focus()
	
func _on_start():
	get_tree().change_scene_to_file("res://Scenes/case_review.tscn")
	
func _on_quit():
	get_tree().quit()
