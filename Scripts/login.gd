extends Control

# -- First-launch sign-in --
# Sits between the main menu and the desktop, and only on a save with no
# username on it. GameState.username is both the credential and the flag; see
# the note on it in game_state.gd for why shift_number could not be either.
#
# The password is never validated and never stored. Clicking the field fills
# it, because the company already has it.

@onready var username_field: LineEdit = %UsernameField
@onready var password_field: LineEdit = %PasswordField
@onready var sign_in_button: Button = %SignInButton
@onready var back_button: Button = %BackButton
@onready var status_label: Label = %Status

# Length is the only thing about this that reaches the screen -- the field is
# secret, so it renders as bullets whatever it holds.
const ON_FILE := "............"


func _ready() -> void:
	username_field.text_submitted.connect(_on_submitted)
	password_field.text_submitted.connect(_on_submitted)
	password_field.focus_entered.connect(_fill_password)
	sign_in_button.pressed.connect(_submit)
	back_button.pressed.connect(_on_back)
	username_field.grab_focus()

func _on_submitted(_text: String) -> void:
	_submit()

func _fill_password() -> void:
	if password_field.text != "":
		return
	password_field.text = ON_FILE
	status_label.text = "PASSWORD RETRIEVED FROM YOUR PERSONNEL FILE."

func _submit() -> void:
	var name := username_field.text.strip_edges()
	if name == "":
		# A line in the status label rather than a popup: the console never
		# interrupts itself anywhere else in the game.
		status_label.text = "USERNAME REQUIRED — THE ACCOUNT MUST HAVE A NAME."
		username_field.grab_focus()
		return
	_fill_password()

	GameState.username = name
	GameState.save()
	get_tree().change_scene_to_file("res://Scenes/case_review.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
