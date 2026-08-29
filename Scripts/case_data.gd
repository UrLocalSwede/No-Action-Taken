extends Node
class_name CaseData

# Access from anywhere with:  CaseData.SHIFTS[1]["cases"]

const SHIFTS = {

	1: {
		"title": "SHIFT 01",
		"rules": [
			{
				"id": 1,
				"title": "Threats",
				"text": "Remove any post that threatens violence against a specific person."
			},
			{
				"id": 2,
				"title": "Personal information",
				"text": "Remove any post that publishes a private individual's home address, phone number, or workplace."
			},
		],
		"cases": [
			{
				"post": "if I ever see @danfielding at the depot again I will put him in the ground. this is not a joke.",
				"reason": "Threats",
				"account": "4 years, 0 warnings",
				"correct": "remove",
				"rule": 1,
				"flag": "",
				"messages_before": ["New here? Okay so. The policy's on your right, and that's the whole job; you read the post, you check it against what's written there, and you decide. That's it. The thing nobody tells you is that most of what gets reported doesn't actually break anything. People report stuff they're annoyed by. You'll see a lot of that."],
				"messages_after_correct": ["Good. You're a natural"],
				"messages_after_wrong": ["Oh uh, try to read it more carfully"]
			},
			{
				"post": "Anyone know a good place for tires on the north side? Getting quoted way too much.",
				"reason": "Personal information",
				"account": "8 months, 0 warnings",
				"correct": "noaction",
				"rule": 0,
				"flag": "",
				"messages_before": [],
				"messages_after_correct": [],
				"messages_after_wrong": []
			},
			{
				"post": "my ex is a piece of shit and everyone should know it. worst human being alive. hope his life falls apart.",
				"reason": "Threats",
				"account": "2 years, 1 prior warning",
				"correct": "noaction",
				"rule": 0,
				"flag": "",
				"messages_before": [],
				"messages_after_correct": [],
				"messages_after_wrong": []
			},
			{
				"post": "Reminder that Karen Vasquez works at the Riverside branch, weekdays, and she's the one who denied my claim. Just so everyone knows where to find her.",
				"reason": "Personal information",
				"account": "3 weeks, 0 warnings",
				"correct": "remove",
				"rule": 2,
				"flag": "",
				"messages_before": [],
				"messages_after_correct": [],
				"messages_after_wrong": []
			},
			{
				"post": "Attaching the address of the man who's been sending my daughter messages. Police have it and did nothing. He lives at 14 Copse Lane. I'm not telling anyone to do anything, I just want parents on this street to know.",
				"reason": "Personal information",
				"account": "6 years, 0 warnings",
				"correct": "remove",
				"rule": 2,
				"flag": "copse_lane",
				"messages_before": [],
				"messages_after_correct": [],
				"messages_after_wrong": []
			},
			{
				"post": "Third night in a row I can't sleep. Does anyone else just sit up and watch the ceiling.",
				"reason": "Threats",
				"account": "1 year, 0 warnings",
				"correct": "noaction",
				"rule": 0,
				"flag": "",
				"messages_before": [],
				"messages_after_correct": [],
				"messages_after_wrong": []
			},
		]
	},

	# ------------------------------------------------------------------
	# SHIFT 02 — template. New rule added; keep §1 and §2 active.
	# Write 8-10 cases here. Aim for: 4 routine, 3 tricky, 1 that hurts.
	# ------------------------------------------------------------------

	2: {
		"title": "SHIFT 02",
		"rules": [
			{
				"id": 1,
				"title": "Threats",
				"text": "Remove any post that threatens violence against a specific person."
			},
			{
				"id": 2,
				"title": "Personal information",
				"text": "Remove any post that publishes a private individual's home address, phone number, or workplace."
			},
			{
				"id": 3,
				"title": "Coordinated activity",
				"text": "Remove any post that organises others to contact, gather at, or act against a named individual or business."
			},
		],
		"cases": [
			{
				"post": "",
				"reason": "",
				"account": "",
				"correct": "",
				"rule": 0,
				"flag": "",
				"messages_before": [""],
				"messages_after_correct": [""],
				"messages_after_wrong": [""]
			},
		]
	},

}
