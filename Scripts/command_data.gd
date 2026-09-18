extends Node
class_name CommandData

# -- The command registry --
# ONE table. The dispatcher, the autocomplete ghost and 'help' all read it, so
# they cannot drift apart the way the old const COMMANDS list and the if-chain
# in submit_verdict() could.
#
# kind     VERDICT resolves the case and advances the queue.
#          INVESTIGATE prints to the console and changes nothing.
#          SYSTEM is console plumbing.
# when     WHEN_CASE      only while a case is on screen
#          WHEN_SHIFT_END only on the clock-out screen
#          WHEN_ANY       always
# unlock   first shift the command exists on.
# aliases  extra spellings, written WITH spaces for readability. The parser
#          strips them, and that is the whole reason 'no action' works --
#          nothing else in the codebase has to know about that special case.
#
# Declaration order is the order 'help' lists them AND the order the ghost tries
# prefixes in, so keep the common verdicts first and 'exit' last.

const VERDICT := 0
const INVESTIGATE := 1
const SYSTEM := 2

const WHEN_CASE := 0
const WHEN_SHIFT_END := 1
const WHEN_ANY := 2

const LOCKED_HINT := "'%s' isn't on your console yet."
const UNKNOWN_HINT := "Unrecognized command. Type 'help'."

const COMMANDS := {
	"remove": {
		"kind": VERDICT, "when": WHEN_CASE, "unlock": 1, "aliases": [],
		"usage": "remove", "blurb": "Take the post down.",
	},
	"noaction": {
		"kind": VERDICT, "when": WHEN_CASE, "unlock": 1,
		"aliases": ["no action", "no-action"],
		"usage": "noaction", "blurb": "Leave the post up.",
	},
	"escalate": {
		"kind": VERDICT, "when": WHEN_CASE, "unlock": 8, "aliases": [],
		"usage": "escalate", "blurb": "Hand the case up to Tier 2.",
	},
	"thread": {
		"kind": INVESTIGATE, "when": WHEN_CASE, "unlock": 2, "aliases": [],
		"usage": "thread", "blurb": "Read the replies under the post.",
	},
	"record": {
		"kind": INVESTIGATE, "when": WHEN_CASE, "unlock": 2, "aliases": [],
		"usage": "record <handle>", "blurb": "Pull an account's history.",
	},
	"source": {
		"kind": INVESTIGATE, "when": WHEN_CASE, "unlock": 4, "aliases": [],
		"usage": "source", "blurb": "Where the report came from.",
	},
	"precedent": {
		"kind": INVESTIGATE, "when": WHEN_CASE, "unlock": 6, "aliases": [],
		"usage": "precedent", "blurb": "How cases like this were decided.",
	},
	"file": {
		"kind": INVESTIGATE, "when": WHEN_CASE, "unlock": 9,
		"aliases": [],
		"usage": "file <id>", "blurb": "Open an internal case file.",
	},
	"help": {
		"kind": SYSTEM, "when": WHEN_ANY, "unlock": 1, "aliases": ["?"],
		"usage": "help", "blurb": "List what you can type.",
	},
	"clockout": {
		"kind": SYSTEM, "when": WHEN_SHIFT_END, "unlock": 1,
		"aliases": ["clock out"],
		"usage": "clockout", "blurb": "End the shift and go home.",
	},
	"exit": {
		"kind": SYSTEM, "when": WHEN_ANY, "unlock": 1, "aliases": [],
		"usage": "exit", "blurb": "Back to the main menu.",
	},
}

static var _aliases := {}
static var _max_words := 1

#-- Flattens COMMANDS into an alias -> canonical lookup on first use.
#   Aliases are keyed with their spaces removed, so 'no action' and 'noaction'
#   land on the same row. --
static func _build() -> void:
	if not _aliases.is_empty():
		return
	for name in COMMANDS:
		_aliases[normalize(name)] = name
		for a in COMMANDS[name]["aliases"]:
			var alias := String(a)
			_aliases[normalize(alias)] = name
			_max_words = maxi(_max_words, alias.split(" ", false).size())

#-- The one spelling rule for verbs: lowercase, no spaces, no hyphens. Alias
#   keys and lookups BOTH go through this, so 'no action', 'No-Action' and
#   'noaction' cannot disagree about which row they mean. --
static func normalize(s: String) -> String:
	return s.to_lower().replace(" ", "").replace("-", "")

#-- Canonical name for a raw verb token, or "" --
static func resolve(token: String) -> String:
	_build()
	return _aliases.get(normalize(token), "")

#-- How many words the parser has to try joining before it gives up --
static func max_verb_words() -> int:
	_build()
	return _max_words

static func is_unlocked(name: String, shift_number: int) -> bool:
	return COMMANDS.has(name) and shift_number >= int(COMMANDS[name]["unlock"])

#-- Canonical names the player can actually type right now, in declaration
#   order. The ghost and 'help' both read this. That is the point. --
static func available(shift_number: int, at_shift_end: bool) -> Array[String]:
	var out: Array[String] = []
	for name in COMMANDS:
		var spec: Dictionary = COMMANDS[name]
		if shift_number < int(spec["unlock"]):
			continue
		var w := int(spec["when"])
		if w == WHEN_CASE and at_shift_end:
			continue
		if w == WHEN_SHIFT_END and not at_shift_end:
			continue
		out.append(name)
	return out
