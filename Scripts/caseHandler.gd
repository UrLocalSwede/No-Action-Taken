extends Control

@onready var post_text = %PostText
@onready var command_input = %CommandInput
@onready var report_reason = %ReportReason
@onready var hint_text = %HintLabel
@onready var history_text = %HistoryText
@onready var account_info = %AccountInfo
@onready var case_header = %CaseHeader
@onready var rule_text = %RuleText
@onready var chat_box = %ChatBox
@onready var ghost_label = %GhostLabel

# -- Values that should not be changed --
var history_lines: Array[String] = []

var index = 0 #current case
var citations = 0 #amount of citations
var shift_number = 1 #current shift
var shift = CaseData.SHIFTS[shift_number]

var cases = shift["cases"]
var rules = shift["rules"]

var now = Time.get_time_dict_from_system()
var stamp = "%02d:%02d" % [now["hour"], now["minute"]]

var _skip_typing = false
var typing_id = 0
var typing_ids = {}
var _ghost_cmd = ""

const COMMANDS = ["remove", "noaction", "exit"]


#-- Runs on scene start --
func _ready():
	command_input.text_submitted.connect(submit_verdict)
	command_input.text_changed.connect(_on_text_changed)
	command_input.grab_focus()
	chat_box.text = ""

	hint_text.hide()

	display_case()
	display_rules()

# -- Handles what case the user is on --
func display_case():
	if index < cases.size():
		var c = cases[index]
		type_text(post_text, c["post"]) 
		report_reason.text = "REPORTED FOR    " + c["reason"]
		account_info.text = "ACCOUNT         " + c["account"]
		case_header.text = "CASE %02d / %02d" % [index + 1, cases.size()]
		
		#Handle messages for 'ChatBox' before user input
		for msg in c["messages_before"]:
			await append_typed(chat_box, "\n\nTeo  %s\n%s" % [stamp, msg])
			await get_tree().create_timer(1.2).timeout
	else:
		end_shift()
		
#-- Handles what rules the player currently has --
func display_rules():
	var text = ""
	for rule in shift["rules"]:
		text += "§%d — %s\n" % [rule["id"], rule["title"]]
		text += rule["text"] + "\n\n"
	rule_text.text = text

#-- Checks user input for a valid command --
func submit_verdict(text):
	_skip_typing = false
	hint_text.hide()
	ghost_label.text = ""
	_ghost_cmd = ""
	command_input.clear()
	add_history(text)
	var verb = text.strip_edges().to_lower().replace(" ", "")
	if verb == "remove" or verb == "noaction":
		correction(verb)
	elif verb == "exit":
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	else:
		hint()

#-- Cycles cases based on user input --
func correction(verb):
	var c = cases[index]
	var was_correct = verb == c["correct"]
	if was_correct:
		add_history(verb + (" - POST REMOVED" if c["correct"] == "remove" else " - POST CLEARED"))
	else:
		add_history(verb + " - CITATION")
		citations += 1
		
	#Handle messages for 'ChatBox' after user input
	var key = "messages_after_correct" if was_correct else "messages_after_wrong"
	for msg in c[key]:
		await append_typed(chat_box, "\n\nTeo  %s\n%s" % [stamp, msg])
		await get_tree().create_timer(1.2).timeout
			
	index += 1
	display_case()

#-- Cycles shifts -- 
func end_shift():
	case_header.text = "SHIFT COMPLETE"
	report_reason.text = ""
	account_info.text = ""
	
	var total = cases.size()
	var accuracy = int(float(total - citations) / total * 100)
	
	var summary = "CASES PROCESSED    %d / %d\n" % [total, total]
	summary += "CITATIONS          %d\n" % citations
	summary += "ACCURACY           %d%%\n\n" % accuracy
	summary += "Thank you. Please return tomorrow at 22:00."
	
	type_text(post_text, summary)
	command_input.editable = false
	command_input.placeholder_text = ""
	
#-- Handle autocomplete ghost text.
#   GhostLabel overlays CommandInput and draws on top of it, so only the
#   UNTYPED tail is rendered; the typed part is padded out with spaces.
#   IBM Plex Mono is monospace, so the pad lands on the exact character cell. --
func _on_text_changed(new_text):
	var typed = new_text.to_lower()
	ghost_label.text = ""
	_ghost_cmd = ""
	if typed == "":
		return
	for cmd in COMMANDS:
		if cmd.begins_with(typed):
			_ghost_cmd = cmd
			ghost_label.text = " ".repeat(new_text.length()) + cmd.substr(new_text.length())
			break

#-- Handle autocomplete on tab and skip on enter --
func _input(event):
	if event.is_action_pressed("ui_focus_next") and _ghost_cmd != "":
		command_input.text = _ghost_cmd
		command_input.caret_column = command_input.text.length()
		ghost_label.text = ""
		_ghost_cmd = ""
		get_viewport().set_input_as_handled()
		
	if event.is_action_pressed("ui_accept"):
		finish_typing()

#-- Hints towards valid commands --	
func hint():
	hint_text.text = "Unrecognized command; try 'Remove' or 'No Action'"
	hint_text.show()

#-- Handles command history --
func add_history(line: String):
	history_lines.append("> " + line)
	if history_lines.size() > 6:
		history_lines.pop_front()
	history_text.text = "\n".join(history_lines)

func _claim(label) -> int:
	typing_ids[label] = typing_ids.get(label, 0) + 1
	return typing_ids[label]

#-- Typing effect --
func type_text(label, content, speed := 0.02):
	var my_id = _claim(label)
	
	label.text = content
	label.visible_ratio = 0.0
	var total = content.length()
	var shown = 0
	
	while shown < total:
		if my_id != typing_ids[label]:
			return
		if _skip_typing:
			label.visible_ratio = 1.0
			return
		shown += 1
		label.visible_ratio = float(shown) / total
		
		var delay = speed
		var ch = content[shown -1]
		
		if ch in [".", "!", "?"]:
			delay = speed * 12
		elif ch in [",", ";", ":"]:
			delay = speed * 6
		elif randf() < 0.04:
			delay = speed * randf_range(4.0, 9.0)
		else:
			delay = speed * randf_range(0.6, 1.5)
		
		await get_tree().create_timer(delay).timeout
		
#-- Typing effect put appends instead of replacing --
func append_typed(label, content, speed := 0.02):
	var my_id = _claim(label)
	
	var existing = label.text
	var full = existing + content
	label.text = full
	
	var start = float(existing.length()) / full.length()
	var shown = existing.length()
	label.visible_ratio = start
	
	while shown < full.length():
		if my_id != typing_ids[label]:
			return
		if _skip_typing:
			label.visible_ratio = 1.0
			return
		shown += 1
		label.visible_ratio = float(shown) / full.length()
		await get_tree().create_timer(speed * randf_range(0.6, 1.5)).timeout
	
	label.visible_ratio = 1.0
	
func finish_typing():
	print("finished called")
	_skip_typing = true
		
		
		
