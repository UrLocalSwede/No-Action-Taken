extends Control

@onready var post_text = $Margin/Columns/QueuePanel/VBoxContainer/PostText
@onready var command_input = $Margin/Columns/QueuePanel/VBoxContainer/CommandInput
@onready var report_reason = $Margin/Columns/QueuePanel/VBoxContainer/ReportReason
@onready var hint_text = $Margin/Columns/QueuePanel/VBoxContainer/HintLabel
@onready var history_text = $Margin/Columns/QueuePanel/VBoxContainer/CommandHistory/HistoryText
@onready var account_info = $Margin/Columns/QueuePanel/VBoxContainer/AccountInfo
@onready var case_header = $Margin/Columns/QueuePanel/VBoxContainer/CaseHeader

var correct = "remove"
var history_lines: Array[String] = []

var cases = [
	{
		"post": "if I ever see @danfielding at the depot again I will put him in the ground. this is not a joke.",
		"reason": "Threats",
		"account": "4 years, 0 warnings",
		"correct": "remove"
	},
	{
		"post": "Anyone know a good place for tires on the north side? Getting quoted way too much.",
		"reason": "Personal information",
		"account": "8 months, 0 warnings",
		"correct": "noaction"
	},
]

var index = 0
var citations = 0

func _ready():
	command_input.text_submitted.connect(submit_verdict)
	command_input.grab_focus()
	
	hint_text.z_index = -1
	
func display_case():
	var c = cases[index]
	post_text.text = c["post"]
	report_reason.text = "REPORTED FOR    " + c["reason"]
	account_info.text = "ACCOUNT         " + c["account"]
	case_header.text = "CASE %02d / %02d" % [index + 1, cases.size()]
	
func hint():
	hint_text.z_index = 1
	hint_text.text = "Unrecognized command; Try using 'Remove' or 'No Action'"



func add_history(line: String):
	history_lines.append("> " + line)
	if history_lines.size() > 12:
		history_lines.pop_front()
	history_text.text = "\n".join(history_lines)

func submit_verdict(text):
	command_input.clear()
	add_history(text)
	var verb = text.strip_edges().to_lower()
	if verb == "remove" or verb == "noaction":
		if verb == correct:
			print("correct")
		else:
			print("not correct")
	else:
		hint()
		
		
