extends Node

# -- Cross-shift state --
# The project's first autoload. Everything here has to survive
# 'exit' -> main menu -> CLOCK IN, which is why it cannot live on caseHandler:
# change_scene_to_file() frees that node.
#
# Registered in project.godot as:
#   [autoload]
#   GameState="*res://Scripts/game_state.gd"
#
# Deliberately NO class_name. An autoload name and a global class name share one
# namespace, so 'class_name GameState' plus an autoload called GameState is a
# hard parse error. CaseData and CommandData keep their class_name because they
# are const tables nobody needs an instance of.

const SAVE_PATH := "user://progress.cfg"
const SAVE_VERSION := 1

var shift_number := 1

# Whatever the player typed at the sign-in screen. Doubles as the first-launch
# flag: main_menu sends you to Login while this is empty, which is idempotent
# in a way shift_number is not -- caseHandler saves on entry to shift 1, so
# shift_number == 1 is not proof of a fresh install. The company's own records
# only ever call you MOD-4471; this is just what the account is named.
var username := ""

# Used as a set: flags[name] == true. Written by verdicts, read by content
# gating in caseHandler._build_queue(). This is what makes the shift-one
# Copse Lane promise payable in shift three.
var flags := {}

# One entry per finished shift:
#   { "shift": 1, "cases": 6, "citations": 1, "accuracy": 83 }
var shift_results: Array = []

# One entry per resolved case, in order:
#   { "shift": 1, "index": 4, "verb": "noaction", "correct": "remove",
#     "was_correct": false }
# Nothing reads this yet, on purpose. It is the hook a strike / suspension
# system grows from later without any content having to change shape.
var case_log: Array = []


func _ready() -> void:
	load_progress()

# ---------------------------------------------------------------- flags

func set_flag(flag: String) -> void:
	if flag == "":
		return
	flags[flag] = true
	save()

func has_flag(flag: String) -> bool:
	return flags.get(flag, false)

# ---------------------------------------------------------------- recording

#-- Called once per resolved case, before the queue advances --
func record_case(shift: int, index: int, verb: String, correct: String, was_correct: bool) -> void:
	case_log.append({
		"shift": shift,
		"index": index,
		"verb": verb,
		"correct": correct,
		"was_correct": was_correct,
	})

#-- Called from end_shift() when the summary goes up --
func finish_shift(shift: int, total: int, citations: int, accuracy: int) -> void:
	for r in shift_results:
		if r["shift"] == shift:
			return                  # summary redrawn; don't double-count
	shift_results.append({
		"shift": shift,
		"cases": total,
		"citations": citations,
		"accuracy": accuracy,
	})
	save()

func total_citations() -> int:
	var n := 0
	for r in shift_results:
		n += int(r["citations"])
	return n

# ---------------------------------------------------------------- persistence

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", SAVE_VERSION)
	cfg.set_value("progress", "shift_number", shift_number)
	cfg.set_value("progress", "username", username)
	cfg.set_value("progress", "flags", PackedStringArray(flags.keys()))
	cfg.set_value("progress", "shift_results", shift_results)
	cfg.set_value("progress", "case_log", case_log)
	cfg.save(SAVE_PATH)

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	if int(cfg.get_value("meta", "version", 0)) != SAVE_VERSION:
		return                  # older layout: start clean rather than guess
	shift_number = int(cfg.get_value("progress", "shift_number", 1))
	username = String(cfg.get_value("progress", "username", ""))
	flags.clear()
	for f in cfg.get_value("progress", "flags", PackedStringArray()):
		flags[String(f)] = true
	shift_results = cfg.get_value("progress", "shift_results", [])
	case_log = cfg.get_value("progress", "case_log", [])

#-- Wipes progress. Called by the RESET PROGRESS control in the Settings app,
#   behind a two-step confirm. --
func reset() -> void:
	shift_number = 1
	username = ""          # sends the next BEGIN SHIFT back through sign-in
	flags.clear()
	shift_results.clear()
	case_log.clear()
	save()
