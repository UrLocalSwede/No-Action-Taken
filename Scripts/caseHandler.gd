extends Control

# -- The game loop --
# Owns the queue, the console and the clock. Content comes from CaseData,
# the command table from CommandData, anything that outlives the scene from
# GameState.

@onready var post_text = %PostText
@onready var command_input = %CommandInput
@onready var report_reason = %ReportReason
@onready var posted_by = %PostedBy
@onready var hint_text = %HintLabel
@onready var history_text = %HistoryText
@onready var account_info = %AccountInfo
@onready var case_header = %CaseHeader
@onready var rule_text = %RuleText
@onready var chat_box = %ChatBox
@onready var ghost_label = %GhostLabel
@onready var shift_subtitle = %ShiftSubtitle
@onready var rule_subtitle = %RuleSubtitle
@onready var chat_subtitle = %ChatSubtitle

# -- Per-shift state. NOTHING is bound at declaration: that runs before
#    _ready() and so could never respond to a shift change. load_shift() owns
#    every one of these. --
var shift_number := 0
var shift := {}
var cases: Array = []       # merged and flag-filtered case dicts
var index := 0              # current case
var citations := 0          # citations this shift
var stamp := ""

var history_lines: Array[String] = []

var _case := {}             # cases[index], cached for the investigation handlers
var _shift_over := false    # the clock-out screen is up
var _busy := false          # a verdict's message run is in flight

var _skip_typing = false
var typing_ids = {}
var _ghost_cmd = ""

const CONSOLE_MAX_LINES := 200
const DIM := "#5A6270"
const ACCENT := "#4C8DF6"

const VERDICT_ECHO := {
	"remove": "POST REMOVED",
	"noaction": "POST CLEARED",
	"escalate": "ESCALATED - TIER 2",
}


#-- Runs on scene start --
func _ready():
	command_input.text_submitted.connect(submit_verdict)
	command_input.text_changed.connect(_on_text_changed)

	if OS.is_debug_build():
		for problem in CaseData.validate():
			push_warning("CaseData: " + problem)

	load_shift(mini(GameState.shift_number, CaseData.last_shift()))

#-- Binds every per-shift value and redraws the desktop.
#   This is the ONLY place shift state is set: _ready() calls it with whatever
#   shift GameState remembers, clock_out() calls it with the next one. The
#   desktop is deliberately NOT reloaded -- change_scene_to_file() would re-run
#   windowsHandler._layout_windows() and throw away every window the player
#   moved, and would free this node out from under any coroutine still
#   suspended on a timer. --
func load_shift(n: int) -> void:
	shift_number = n
	shift = CaseData.shift(n)
	cases = _build_queue()
	index = 0
	citations = 0
	_case = {}
	_shift_over = false
	_skip_typing = false

	GameState.shift_number = n
	GameState.save()

	var now = Time.get_time_dict_from_system()
	stamp = "%02d:%02d" % [now["hour"], now["minute"]]

	# Bumping both claims cancels any typing run left over from the shift that
	# just ended; those coroutines return on their next check instead of writing
	# into the cleared labels.
	_claim(chat_box)
	_claim(post_text)
	chat_box.text = ""
	history_lines.clear()
	history_text.text = ""
	hint_text.hide()
	ghost_label.text = ""
	_ghost_cmd = ""

	command_input.editable = true
	command_input.placeholder_text = "Enter Command"
	command_input.clear()
	command_input.grab_focus()

	shift_subtitle.text = "SHIFT %02d" % n
	rule_subtitle.text = "%d SECTIONS IN FORCE" % shift["rules"].size()
	chat_subtitle.text = String(shift["chat_name"]).to_upper()
	display_rules()

	# The clock-in patter finishes before case 1's own messages start, so two
	# runs never fight over %ChatBox.
	_busy = true
	if not await play_messages(shift["messages_on_clock_in"]):
		return                  # another shift loaded under us
	_busy = false
	display_case()

#-- The cases actually in play this shift. A case can be gated on a flag the
#   player set on an earlier shift ('requires_flag') or hidden once they have
#   ('excludes_flag'), so the queue is filtered here ONCE and everything
#   downstream -- the CASE nn / NN header, the accuracy denominator -- counts
#   the filtered list rather than the authored one. --
func _build_queue() -> Array:
	var out: Array = []
	for i in CaseData.case_count(shift_number):
		var c := CaseData.case(shift_number, i)
		if c["requires_flag"] != "" and not GameState.has_flag(c["requires_flag"]):
			continue
		if c["excludes_flag"] != "" and GameState.has_flag(c["excludes_flag"]):
			continue
		out.append(c)
	return out

# -- Handles what case the user is on --
func display_case() -> void:
	if index >= cases.size():
		end_shift()
		return

	_case = cases[index]
	var c := _case

	# Deliberately NOT awaited: the post should appear while Teo talks, and
	# type_text is guarded per-label by _claim, so it cannot interleave.
	type_text(post_text, c["post"])
	posted_by.text = "POSTED BY       @" + c["handle"]
	report_reason.text = "REPORTED FOR    " + c["reason"]
	account_info.text = "ACCOUNT         " + c["account"]
	case_header.text = "CASE %02d / %02d" % [index + 1, cases.size()]

	await play_messages(c["messages_before"])

#-- Renders the rules in force this shift into %RuleText.
#   Shifts carry rule IDs, not rule text, so nothing is restated; §2's shift-7
#   amendment is resolved by CaseData.rule() and marked here. RuleText is
#   bbcode_enabled, so section headings get the theme's synthesised bold face
#   (IBM Plex Mono ships Regular only -- [b] would otherwise fall through to
#   Godot's built-in sans) and the amendment mark gets the accent blue the rest
#   of the UI already uses for 'pay attention'. --
func display_rules() -> void:
	var out := ""
	for id in shift["rules"]:
		var r := CaseData.rule(id, shift_number)
		out += "[b]§%d — %s[/b]" % [r["id"], r["title"]]
		if r["amended"]:
			if int(r["amended_on"]) == shift_number:
				out += "   [color=%s]%s TODAY[/color]" % [ACCENT, r["label"]]
			else:
				out += "   [color=%s]%s SHIFT %02d[/color]" % [DIM, r["label"], r["amended_on"]]
		out += "\n" + r["text"] + "\n\n"
	rule_text.text = out

#-- Splits raw input into a canonical verb and a raw argument string.
#
#   The old parser did text.strip_edges().to_lower().replace(" ", "") on the
#   WHOLE line. That is why 'no action' worked and why 'record dan fielding'
#   could never work -- it arrived as 'recorddanfielding'. The space-stripping
#   now happens per CANDIDATE VERB instead: join the first N words with no
#   separator, look that up in the alias table, longest first. 'no action'
#   resolves because it is a registered alias of noaction; no other code has to
#   know about the two-word case. --
func _parse_command(raw: String) -> Dictionary:
	var parts := raw.strip_edges().split(" ", false)
	if parts.is_empty():
		return {"verb": "", "arg": "", "head": ""}

	var n := mini(parts.size(), CommandData.max_verb_words())
	while n > 0:
		var head := ""
		for i in n:
			head += parts[i]
		var name := CommandData.resolve(head.to_lower())
		if name != "":
			var rest := PackedStringArray()
			for i in range(n, parts.size()):
				rest.append(parts[i])
			return {"verb": name, "arg": " ".join(rest), "head": head}
		n -= 1
	return {"verb": "", "arg": "", "head": parts[0].to_lower()}

#-- Checks user input against the registry and routes it.
#   Every gate -- exists, unlocked, available right now -- reads CommandData, so
#   a command that autocompletes is a command that dispatches. --
func submit_verdict(text):
	if text.strip_edges() == "":
		return                  # empty Enter is the typing-skip, not a command

	_skip_typing = false
	hint_text.hide()
	ghost_label.text = ""
	_ghost_cmd = ""
	command_input.clear()
	add_history(text)

	var parsed := _parse_command(text)
	var verb: String = parsed["verb"]

	if verb == "":
		hint(CommandData.UNKNOWN_HINT)
		return
	if not CommandData.is_unlocked(verb, shift_number):
		hint(CommandData.LOCKED_HINT % parsed["head"])
		return

	var spec: Dictionary = CommandData.COMMANDS[verb]
	var when := int(spec["when"])
	if when == CommandData.WHEN_CASE and _shift_over:
		hint("Shift's done. Type 'clockout' when you're ready.")
		return
	if when == CommandData.WHEN_SHIFT_END and not _shift_over:
		hint("You can't clock out mid-shift.")
		return

	match int(spec["kind"]):
		CommandData.VERDICT:
			correction(verb)
		CommandData.INVESTIGATE:
			_run_investigation(verb, parsed["arg"])
		CommandData.SYSTEM:
			_run_system(verb, parsed["arg"])

#-- Resolves the current case and advances the queue.
#   _busy is the fix for the double-advance: a second verdict typed while Teo is
#   still talking used to run this again and move 'index' twice. Rejecting it
#   also sets _skip_typing, so pressing the verdict again reads as 'hurry up'
#   rather than as a dead key. --
func correction(verb) -> void:
	if _busy:
		_skip_typing = true
		hint("One second.")
		return
	_busy = true

	var c := _case
	var was_correct: bool = verb == c["correct"]

	if was_correct:
		add_history("%s - %s" % [verb, VERDICT_ECHO.get(verb, "LOGGED")])
	else:
		add_history(verb + " - CITATION")
		citations += 1

	# Flags record what the player DID, not what the case offered, so a later
	# shift can ask about the decision rather than about the post.
	var explicit: Dictionary = c["sets_flag_on"]
	if explicit.has(verb):
		GameState.set_flag(explicit[verb])
	elif c["flag"] != "":
		GameState.set_flag("%s_%s" % [c["flag"], verb])

	GameState.record_case(shift_number, index, verb, c["correct"], was_correct)

	#Handle messages for 'ChatBox' after user input
	var key := "messages_after_correct" if was_correct else "messages_after_wrong"
	if not await play_messages(c[key]):
		return                  # a new shift loaded under us; don't advance

	index += 1
	_busy = false
	display_case()

#-- Closes the shift out. Not terminal any more: the input stays live and only
#   accepts clockout / help / exit until the player uses it. --
func end_shift() -> void:
	_shift_over = true
	_busy = false
	_case = {}
	case_header.text = "SHIFT COMPLETE"
	posted_by.text = ""
	report_reason.text = ""
	account_info.text = ""

	var total := cases.size()
	var accuracy := int(float(total - citations) / total * 100) if total > 0 else 100

	var summary := "CASES PROCESSED    %d / %d\n" % [total, total]
	summary += "CITATIONS          %d\n" % citations
	summary += "ACCURACY           %d%%\n\n" % accuracy
	if shift_number < CaseData.last_shift():
		summary += "Thank you. Please return tomorrow at 22:00.\n"
		summary += "Type 'clockout' to end your shift."
	else:
		summary += "No further shifts are scheduled."

	type_text(post_text, summary)
	GameState.finish_shift(shift_number, total, citations, accuracy)

#-- Clock out and walk into the next shift, in place --
func clock_out() -> void:
	if _busy:
		hint("One second.")
		return
	var next := shift_number + 1
	if next > CaseData.last_shift():
		GameState.save()
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
		return
	load_shift(next)

# ---------------------------------------------------------------- investigation

#-- Investigation commands read the case out loud and do not resolve it.
#   Everything lands in the console, nothing touches 'index', and nothing here
#   can produce a citation -- a wrong guess costs time, not accuracy. --
func _run_investigation(verb: String, arg: String) -> void:
	var c := _case
	match verb:
		"thread":
			_show_block(c["thread"], "THREAD", "Replies are disabled on this post.")
		"record":
			_show_record(c, arg)
		"source":
			_show_block(c["source"], "REPORT SOURCE", "No source metadata attached.")
		"precedent":
			_show_block(c["precedent"], "PRECEDENT", "No prior decisions match this case.")
		"file":
			_show_lookup(verb, c["file"], arg, "CASE FILE", "No internal file for this case.")

#-- Prints an optional payload, or says so. Every investigation command that is
#   just 'dump a list' shares this, which is why adding a sixth costs two lines
#   in CommandData and one in the match above. --
func _show_block(lines: Array, title: String, empty_msg: String) -> void:
	if lines.is_empty():
		console_block(title, [empty_msg])
		return
	console_block(title, lines)

#-- 'record'. Bare 'record' means the account on screen, which is the whole
#   reason the handle is displayed in the queue -- having to guess it, or to run
#   the command once just to be told what to type, was busywork. --
func _show_record(c: Dictionary, arg: String) -> void:
	var store: Dictionary = c["record"]
	var handle := _arg_key(c["handle"])
	var key := _arg_key(arg) if arg.strip_edges() != "" else handle

	if store.has(key):
		console_block("ACCOUNT RECORD — " + key, _with_others(store[key], store, key))
		return

	# The poster always has a record, even when no story hangs off it. A console
	# that answers 'nothing on file' about an account it is currently displaying
	# reads as broken, so a thin one is synthesised from the case.
	if key == handle and handle != "":
		console_block("ACCOUNT RECORD — " + handle, _with_others([
			"Handle            @" + handle,
			"Account           " + (String(c["account"]) if c["account"] != "" else "no detail on file"),
			"Actions           none on file",
		], store, key))
		return

	console_block("ACCOUNT RECORD", ["No record for '%s'." % arg.strip_edges()])

#-- Appends the other handles this case can answer for, so a player who only
#   knows the poster still finds the reply-chain accounts and the subject. --
func _with_others(lines: Array, store: Dictionary, shown: String) -> Array:
	var others := PackedStringArray()
	for k in store:
		if String(k) != shown:
			others.append("@" + String(k))
	if others.is_empty():
		return lines
	var out: Array = lines.duplicate()
	out.append("")
	out.append("Also on file      " + ", ".join(others))
	return out

#-- A keyed lookup the player has to name. With no argument it takes the only
#   entry if there is just one, and otherwise lists what is there. --
func _show_lookup(verb: String, store: Dictionary, arg: String, title: String, empty_msg: String) -> void:
	if store.is_empty():
		console_block(title, [empty_msg])
		return
	var key := _arg_key(arg)
	if key == "":
		if store.size() == 1:
			key = String(store.keys()[0])
		else:
			console_block(title, [
				"Usage: " + String(CommandData.COMMANDS[verb]["usage"]),
				"On file: " + ", ".join(PackedStringArray(store.keys())),
			])
			return
	if not store.has(key):
		console_block(title, ["No record for '%s'." % arg.strip_edges()])
		return
	console_block("%s — %s" % [title, key], store[key])

#-- Normalises an argument into a lookup key. This is where the old
#   replace(" ", "") lives now: on the ARGUMENT, where collapsing spaces is
#   harmless, instead of on the whole line, where it broke arguments. --
func _arg_key(arg: String) -> String:
	return arg.to_lower().strip_edges().replace(" ", "").replace("@", "")

#-- Console plumbing: nothing here touches the case --
func _run_system(verb: String, _arg: String) -> void:
	match verb:
		"help":
			_show_help()
		"clockout":
			clock_out()
		"exit":
			GameState.save()
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

#-- Reads the same table the dispatcher and the ghost read, so it can never
#   advertise a command that does not exist or hide one that does. The %-22s
#   padding lands on exact character cells because IBM Plex Mono is monospace --
#   same reasoning as the GhostLabel overlay. --
func _show_help() -> void:
	var lines: Array[String] = []
	for name in CommandData.available(shift_number, _shift_over):
		var spec: Dictionary = CommandData.COMMANDS[name]
		lines.append("%-22s %s" % [spec["usage"], spec["blurb"]])
	console_block("COMMANDS — SHIFT %02d" % shift_number, lines)

# ---------------------------------------------------------------- console

#-- The one way anything reaches the console, so the trim happens in exactly one
#   place. HistoryText used to cap at 6 lines as a command echo; it is a
#   scrollback now, and the scene sets fit_content = false to give it real
#   internal scrolling. --
func console_print(line: String) -> void:
	history_lines.append(line)
	while history_lines.size() > CONSOLE_MAX_LINES:
		history_lines.pop_front()
	history_text.text = "\n".join(history_lines)

#-- Echo of what the player typed. Escaped: HistoryText is bbcode_enabled now,
#   so a stray '[' in typed input would eat the rest of the line. --
func add_history(line: String) -> void:
	console_print("[color=%s]>[/color] %s" % [DIM, _escape_bb(line)])

func _escape_bb(s: String) -> String:
	return s.replace("[", "[lb]")

#-- Investigation output: a headed, indented block with blank lines around it,
#   so ten lines of account record read as one object instead of as ten stray
#   log lines next to the command echo. Instant, not typed -- the console is a
#   machine, Teo is a person. --
func console_block(title: String, lines: Array) -> void:
	console_print("")
	console_print("[b]%s[/b]" % _escape_bb(title))
	for l in lines:
		var s := String(l)
		console_print("" if s == "" else "  " + _escape_bb(s))
	console_print("")

# ---------------------------------------------------------------- input

#-- Handle autocomplete ghost text.
#   GhostLabel overlays CommandInput and draws on top of it, so only the
#   UNTYPED tail is rendered; the typed part is padded out with spaces.
#   IBM Plex Mono is monospace, so the pad lands on the exact character cell.
#
#   The candidate list is CommandData.available(), the same list the dispatcher
#   and 'help' read, so locked commands never appear. Matching is on the
#   space-STRIPPED head, which is what makes typing 'no a' ghost the remaining
#   'ction'. --
func _on_text_changed(new_text):
	ghost_label.text = ""
	_ghost_cmd = ""
	if new_text == "":
		return
	var head := CommandData.normalize(new_text)
	if head == "":
		return
	for cmd in CommandData.available(shift_number, _shift_over):
		if cmd.begins_with(head):
			_ghost_cmd = cmd
			ghost_label.text = " ".repeat(new_text.length()) + cmd.substr(head.length())
			break

#-- Handle autocomplete on tab and skip on enter --
func _input(event):
	if event.is_action_pressed("ui_focus_next") and _ghost_cmd != "":
		command_input.text = _ghost_cmd
		command_input.caret_column = command_input.text.length()
		ghost_label.text = ""
		_ghost_cmd = ""
		get_viewport().set_input_as_handled()

	# Node._input runs BEFORE the focused LineEdit gets the key, so Enter on a
	# non-empty line used to set _skip_typing = true and then have
	# submit_verdict() immediately reset it -- the skip never worked except on an
	# empty line. Only skip when there is nothing to submit.
	if event.is_action_pressed("ui_accept") and command_input.text.strip_edges() == "":
		finish_typing()

#-- Hints towards valid commands. Takes its text now: with eleven commands on
#   unlock schedules, "try 'Remove' or 'No Action'" would be a lie from shift
#   two onward. --
func hint(msg: String) -> void:
	hint_text.text = msg
	hint_text.show()

# ---------------------------------------------------------------- typing

func _claim(label) -> int:
	typing_ids[label] = typing_ids.get(label, 0) + 1
	return typing_ids[label]

#-- Prints a run of chat messages in order under a SINGLE claim.
#   Returns false if a newer run (or a new shift) took %ChatBox part-way
#   through, so the caller knows not to carry on. This is what stops the
#   overlap: the old code re-claimed per message, so a superseded run kept
#   stealing the label back between timers instead of stopping. --
func play_messages(msgs: Array) -> bool:
	var my_id := _claim(chat_box)
	var who: String = shift.get("chat_name", "Teo")
	for msg in msgs:
		if my_id != typing_ids[chat_box]:
			return false
		await _append_typed_as(chat_box, my_id, "\n\n%s  %s\n%s" % [who, stamp, msg])
		if my_id != typing_ids[chat_box]:
			return false
		# _skip_typing turns the gap into a rush rather than a skip, so pressing
		# the verdict again while Teo talks feels like impatience. It is per-shift
		# runtime state, NOT the text-speed preference -- Settings owns that.
		await get_tree().create_timer(0.15 if _skip_typing else Settings.message_gap()).timeout
	return my_id == typing_ids[chat_box]

#-- Typing effect --
#   'speed' is seconds per character and every delay below is a multiple of it,
#   so the one scalar drives the whole effect. A negative value means "whatever
#   the player picked in Settings", which is how all three typing functions
#   read the preference without any call site passing it down. --
func type_text(label, content, speed := -1.0):
	var my_id = _claim(label)
	var per_char: float = Settings.type_speed() if speed < 0.0 else speed

	label.text = content
	# INSTANT is 0.0 s/char. Reveal and leave here, before the first await, so
	# there is no window for another run to interleave and steal the claim.
	if per_char <= 0.0:
		label.visible_ratio = 1.0
		return
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

		var delay = per_char
		var ch = content[shown -1]

		if ch in [".", "!", "?"]:
			delay = per_char * 12
		elif ch in [",", ";", ":"]:
			delay = per_char * 6
		elif randf() < 0.04:
			delay = per_char * randf_range(4.0, 9.0)
		else:
			delay = per_char * randf_range(0.6, 1.5)

		await get_tree().create_timer(delay).timeout

	label.visible_ratio = 1.0

#-- Typing effect that appends instead of replacing --
func append_typed(label, content, speed := -1.0):
	await _append_typed_as(label, _claim(label), content, speed)

#-- The body of append_typed, running under a claim its caller already took.
#   Lets a multi-message run hold one id across several appends, so a newer run
#   cancels the whole sequence instead of just the message in flight. --
func _append_typed_as(label, my_id: int, content, speed := -1.0):
	if my_id != typing_ids[label]:
		return
	var per_char: float = Settings.type_speed() if speed < 0.0 else speed

	var existing = label.text
	var full = existing + content
	label.text = full

	if per_char <= 0.0:
		label.visible_ratio = 1.0
		return

	var shown = existing.length()
	label.visible_ratio = float(shown) / full.length()

	while shown < full.length():
		if my_id != typing_ids[label]:
			return
		if _skip_typing:
			label.visible_ratio = 1.0
			return
		shown += 1
		label.visible_ratio = float(shown) / full.length()
		await get_tree().create_timer(per_char * randf_range(0.6, 1.5)).timeout

	label.visible_ratio = 1.0

func finish_typing():
	_skip_typing = true
