extends Control

@onready var post_text = $Margin/Columns/QueuePanel/VBoxContainer/PostText
@onready var command_input = $Margin/Columns/QueuePanel/VBoxContainer/CommandInput
@onready var report_reason = $Margin/Columns/QueuePanel/VBoxContainer/ReportReason
@onready var hint_text = $Margin/Columns/QueuePanel/VBoxContainer/HintLabel
@onready var history_text = $Margin/Columns/QueuePanel/VBoxContainer/CommandHistory/HistoryText
@onready var account_info = $Margin/Columns/QueuePanel/VBoxContainer/AccountInfo
@onready var case_header = $Margin/Columns/QueuePanel/VBoxContainer/CaseHeader

var history_lines: Array[String] = []
var index = 0
var citations = 0
var shift_number = 1
var shift = CaseData.SHIFTS[shift_number]
var cases = shift["cases"]
var typing_tween: Tween

func _ready():
	command_input.text_submitted.connect(submit_verdict)
	command_input.grab_focus()
	
	hint_text.z_index = -1
	
	display_case()
	
func check_progress():
	return

func display_case():
	if index < cases.size():
		var c = cases[index]
		type_text(post_text, c["post"]) 
		report_reason.text = "REPORTED FOR    " + c["reason"]
		account_info.text = "ACCOUNT         " + c["account"]
		case_header.text = "CASE %02d / %02d" % [index + 1, cases.size()]
	else:
		end_shift()
	
	
func submit_verdict(text):
	command_input.clear()
	add_history(text)
	var verb = text.strip_edges().to_lower()
	if verb == "remove" or verb == "noaction":
		correction(verb)
	else:
		hint()
		
func correction(verb):
	if verb == cases[index]["correct"]:
		if cases[index]["correct"] == "remove":
			add_history(verb + " - Post removed")
		else:
			add_history(verb + " - Post cleared")
		index += 1
		display_case()
	else:
		add_history(verb + " - CITATION")
		citations += 1
		
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
	
# Features
	
func hint():
	hint_text.z_index = 1
	hint_text.text = "Unrecognized command; Try using 'Remove' or 'No Action'"

func add_history(line: String):
	history_lines.append("> " + line)
	if history_lines.size() > 12:
		history_lines.pop_front()
	history_text.text = "\n".join(history_lines)

func type_text(label, content):
	if typing_tween:
		typing_tween.kill()
	label.text = content
	label.visible_ratio = 0.0
	var duration = content.length() * 0.02
	typing_tween = create_tween()
	typing_tween.tween_property(label, "visible_ratio", 1.0, duration)
		
		
