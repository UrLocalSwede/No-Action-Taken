extends PanelContainer

@onready var rule_icon = $HBoxContainer/RuleBookWindowIcon/RuleBtn
@onready var review_icon = $HBoxContainer/QueueWindowIcon/QueueBtn
@onready var chat_icon = $HBoxContainer/ChatWindowIcon/ChatBtn


@onready var review_queue = $"../Windows/QueueWindow"
@onready var rulebook = $"../Windows/RulebookWindow"
@onready var chat_window = $"../Windows/ChatWindow"

var front_window = null


func _ready():
	rule_icon.pressed.connect(_on_pressed.bind(rulebook))
	review_icon.pressed.connect(_on_pressed.bind(review_queue))
	chat_icon.pressed.connect(_on_pressed.bind(chat_window))
		
func _on_pressed(win):
	win.visible = not win.visible
