extends Control

@onready var post_text = $Margin/Columns/QueuePanel/VBoxContainer/PostText
@onready var command_input = $Margin/Columns/QueuePanel/VBoxContainer/CommandInput
@onready var report_reason = $Margin/Columns/QueuePanel/VBoxContainer/ReportReason
@onready var hint_text = $Margin/Columns/QueuePanel/VBoxContainer/HintLabel
@onready var history_text = $Margin/Columns/QueuePanel/VBoxContainer/CommandHistory/HistoryText
@onready var account_info = $Margin/Columns/QueuePanel/VBoxContainer/AccountInfo
@onready var case_header = $Margin/Columns/QueuePanel/VBoxContainer/CaseHeader
@onready var rule_text = $Margin/Columns/RulebookPanel/VBoxContainer/RuleText
@onready var chat_box = $Margin/Columns/RulebookPanel/VBoxContainer/ChatBox

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


#-- Runs on scene start --
func _ready():
	command_input.text_submitted.connect(submit_verdict)
	command_input.grab_focus()
	chat_box.text = ""
	
	hint_text.z_index = -1
	
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
			print("before")
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
	command_input.clear()
	add_history(text)
	var verb = text.strip_edges().to_lower().replace(" ", "")
	if verb == "remove" or verb == "noaction":
		correction(verb)
	else:
		hint()

#-- Cycles cases based on user input --
func correction(verb):
	var c = cases[index]
	if verb == cases[index]["correct"]:
		if cases[index]["correct"] == "remove":
			add_history(verb + " - Post removed")
		else:
			add_history(verb + " - Post cleared")
		index += 1
		display_case()
		
		#Handle messages for 'ChatBox' after user input
		for msg in c["messages_after_correct"]:
			await append_typed(chat_box, "\n\nTeo  %s\n%s" % [stamp, msg])
			await get_tree().create_timer(1.2).timeout
			print("correct")
	else:
		add_history(verb + " - CITATION")
		citations += 1
		index += 1
		
		#Handle messages for 'ChatBox' before user input
		for msg in c["messages_after_wrong"]:
			await append_typed(chat_box, "\n\nTeo  %s\n%s" % [stamp, msg])
			await get_tree().create_timer(1.2).timeout
			print("wrong")

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
	

#-- Hints towards valid commands --	
func hint():
	hint_text.z_index = 1
	hint_text.text = "Unrecognized command; Try using 'Remove' or 'No Action'"

#-- Handles command history --
func add_history(line: String):
	history_lines.append("> " + line)
	if history_lines.size() > 12:
		history_lines.pop_front()
	history_text.text = "\n".join(history_lines)


#-- Typing effect --
func type_text(label, content, speed := 0.02):
	label.text = content
	label.visible_ratio = 0.0
	var total = content.length()
	var shown = 0
	
	while shown < total:
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
	var existing = label.text
	var full = existing + content
	label.text = full
	
	var start = float(existing.length()) / full.length()
	var shown = existing.length()
	label.visible_ratio = start
	
	while shown < full.length():
		shown += 1
		label.visible_ratio = float(shown) / full.length()
		await get_tree().create_timer(speed * randf_range(0.6, 1.5)).timeout
		
		
		
