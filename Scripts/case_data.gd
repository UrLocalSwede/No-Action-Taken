extends Node
class_name CaseData

# -- All the writing lives here --
# Read through the accessors at the bottom, never out of SHIFTS directly:
#   CaseData.shift(3)      -> shift dict, defaults filled
#   CaseData.case(3, 0)    -> case dict, defaults filled
#   CaseData.rule(2, 7)    -> §2 as it stands on shift 7
# const Dictionaries are deeply READ-ONLY at runtime in Godot 4, so every
# accessor hands back a fresh duplicate. Nothing here is ever mutated.

# ---------------------------------------------------------------- rulebook
# Every rule the game will ever show, by section number. Shifts list the IDs in
# force; nobody restates the text. Ten verbatim copies of §1 and §2 is what this
# replaces.

const RULEBOOK := {
	1: {
		"title": "Threats",
		"text": "Remove any post that threatens violence against a specific person.",
	},
	2: {
		"title": "Personal information",
		"text": "Remove any post that publishes a private individual's home address, phone number, or workplace.",
	},
	3: {
		"title": "Coordinated activity",
		"text": "Remove any post that organises others to contact, gather at, or act against a named individual or business.",
	},
	4: {
		"title": "Impersonation",
		"text": "Remove any post from an account presenting itself as another real person, or as staff of this company.",
	},
	5: {
		"title": "Unverified claims",
		"text": "Remove any post stating a fact about this company or its partners that Communications has not confirmed.",
	},
	6: {
		"title": "Distress",
		"text": "Do not remove posts describing self-harm or suicidal thought. Leaving the post up routes it to Wellness automatically.",
	},
	7: {
		"title": "Retention",
		"text": "Do not action any account marked RETAIN. Leave the post up and log the case.",
	},
	8: {
		"title": "Escalation",
		"text": "Escalate any case whose subject is a minor, or an employee of this company.",
	},
	9: {
		"title": "Non-disclosure",
		"text": "Case contents are confidential. Do not discuss a case outside this console.",
	},
}

# ---------------------------------------------------------------- amendments
# Text changes to rules that already exist. Applied CUMULATIVELY from
# 'from_shift' onward, so a shift never has to restate an amendment it inherited
# from an earlier one. Authored in shift order; the last applicable entry for a
# given rule wins. No memo is ever sent. That is the point.

const AMENDMENTS := [
	{
		"rule": 2,
		"from_shift": 7,
		"label": "AMENDED",
		"text": "Remove any post that publishes a private individual's home address, phone number, or workplace. This does not apply where the individual holds or seeks public office.",
	},
]

# ---------------------------------------------------------------- defaults
# Every key a case can carry, with the value used when the author omits it.
# Forty-odd cases cannot each restate sixteen keys, and a missing key used to
# crash on c["messages_before"]. Authors now write only what matters.

const CASE_DEFAULTS := {
	"post": "",
	"handle": "",       # poster's handle. Shown in the queue, and what bare
						# 'record' looks up, so it must never be left blank.
	"reason": "",
	"account": "",
	"correct": "noaction",
	"rule": 0,
	"flag": "",
	"messages_before": [],
	"messages_after_correct": [],
	"messages_after_wrong": [],

	# Investigation payloads. Arrays print as one block; Dictionaries are keyed
	# lookups the player has to name an argument for.
	"thread": [],          # Array[String] -- replies under the post
	"record": {},          # handle -> Array[String]
	"source": [],          # Array[String] -- who reported it and how
	"precedent": [],       # Array[String] -- prior decisions
	"file": {},            # case / badge id -> Array[String]

	# Continuity
	"requires_flag": "",   # case only appears if this flag is set
	"excludes_flag": "",   # case disappears once this flag is set
	"sets_flag_on": {},    # verb -> flag name; beats "flag" when present
}

const SHIFT_DEFAULTS := {
	"title": "",
	"rules": [],                  # Array[int] of RULEBOOK ids
	"chat_name": "Teo",           # who is on the other end of the chat window
	"messages_on_clock_in": [],   # played once, before case 1
	"cases": [],
}

# ---------------------------------------------------------------- shifts

const SHIFTS = {

	1: {
		"title": "SHIFT 01",
		"rules": [1, 2],
		"cases": [
			{
				"post": "if I ever see @danfielding at the depot again I will put him in the ground. this is not a joke.",
				"reason": "Threats",
				"account": "4 years, 0 warnings",
				"handle": "r_calloway",
				"correct": "remove",
				"rule": 1,
				"messages_before": ["New here? Okay so. The policy's on your right, and that's the whole job; you read the post, you check it against what's written there, and you decide whether to remove the post with 'remove' or keep it with 'noaction'. That's it. The thing nobody tells you is that most of what gets reported doesn't actually break anything. People report stuff they're annoyed by. You'll see a lot of that."],
				"messages_after_correct": ["Good. You're a natural. Type 'help' if you forget what you can type. 'exit' puts you back at the main menu."],
				"messages_after_wrong": ["Oh uh, try to read it more carefully."],
			},
			{
				"post": "Anyone know a good place for tires on the north side? Getting quoted way too much.",
				"reason": "Personal information",
				"account": "8 months, 0 warnings",
				"handle": "s_belrose",
				"correct": "noaction",
			},
			{
				"post": "my ex is a piece of shit and everyone should know it. worst human being alive. hope his life falls apart.",
				"reason": "Threats",
				"account": "2 years, 1 prior warning",
				"handle": "a_whitlock",
				"correct": "noaction",
			},
			{
				"post": "Reminder that Karen Vasquez works at the Riverside branch, weekdays, and she's the one who denied my claim. Just so everyone knows where to find her.",
				"reason": "Personal information",
				"account": "3 weeks, 0 warnings",
				"handle": "g_pell",
				"correct": "remove",
				"rule": 2,
			},
			{
				"post": "Attaching the address of the man who's been sending my daughter messages. Police have it and did nothing. He lives at 14 Copse Lane. I'm not telling anyone to do anything, I just want parents on this street to know.",
				"reason": "Personal information",
				"account": "6 years, 0 warnings",
				"handle": "m_harrow",
				"correct": "remove",
				"rule": 2,
				"flag": "copse_lane",
				"sets_flag_on": {
					"remove": "copse_lane_removed",
					"noaction": "copse_lane_left_up",
				},
			},
			{
				"post": "Third night in a row I can't sleep. Does anyone else just sit up and watch the ceiling.",
				"reason": "Threats",
				"account": "1 year, 0 warnings",
				"handle": "i_fenwick",
				"correct": "noaction",
			},
		]
	},

	# ------------------------------------------------------------------
	# SHIFT 02 -- §3 arrives, and with it the first two commands that let the
	# player look at something other than the post. Case 3 cannot be decided
	# from the post alone. That is the whole lesson.
	# ------------------------------------------------------------------

	2: {
		"title": "SHIFT 02",
		"rules": [1, 2, 3],
		"messages_on_clock_in": [
			"Second night. They turned two more things on for your login.",
			"'thread' shows the replies under a post. 'record' pulls up whoever posted it — their handle's on the case now, under the post text.",
			"And there's a §3 now. Read it properly. It's about organising people, not about being angry at someone.",
		],
		"cases": [
			{
				"post": "everyone show up at brightwell autos saturday 9am. bring signs. let's make sure they can't open that morning.",
				"reason": "Coordinated activity",
				"account": "1 year, 0 warnings",
				"handle": "k_dalgety",
				"correct": "remove",
				"rule": 3,
				"messages_before": ["This one's clean. Organising people to go somewhere and stop a business trading. That's §3 exactly."],
				"thread": [
					"@k_dalgety   21:04   everyone show up at brightwell autos saturday 9am",
					"@r_imani     21:09   i'll be there",
					"@k_dalgety   21:11   bring signs",
					"@r_imani     21:14   how many of us are coming",
				],
				"record": {
					"k_dalgety": [
						"Joined            2025-08-19",
						"Posts             612",
						"Reports filed     2",
						"Reports against   1",
						"Actions           none",
					],
				},
			},
			{
				"post": "brightwell autos took my deposit in march and still won't answer the phone. do not use them. that's all I'm saying.",
				"reason": "Coordinated activity",
				"account": "5 years, 0 warnings",
				"handle": "d_verity",
				"correct": "noaction",
				"messages_before": ["Same business, different post."],
				"messages_after_correct": ["Right. A warning isn't organising. §3 needs him to be arranging something."],
				"messages_after_wrong": ["He's just telling people he got burned. Nobody's being organised to do anything."],
				"thread": [
					"@d_verity    22:31   brightwell autos took my deposit in march",
					"@r_imani     22:40   same thing happened to my brother",
					"@d_verity    22:44   sorry to hear that",
				],
			},
			{
				"post": "meeting at the old library car park at 8 if anyone wants to talk about the fielding thing.",
				"reason": "Coordinated activity",
				"account": "7 months, 0 warnings",
				"handle": "b_teale",
				"correct": "remove",
				"rule": 3,
				"messages_before": [
					"Okay, this is the one I'd look at properly. Read the post on its own and it's a few people having a chat.",
					"Try 'thread' before you call it. And you can put any handle it turns up after 'record' — 'record l_mackie', like that.",
				],
				"messages_after_correct": ["Yeah. The post is the polite part. §3 goes on what's being organised, not how nicely it's worded."],
				"messages_after_wrong": [
					"Did you read the thread? They work out where he lives and what time he walks home.",
					"The post was the polite part.",
				],
				"thread": [
					"@b_teale     19:52   meeting at the old library car park at 8",
					"@l_mackie    19:58   is this about fielding",
					"@b_teale     20:01   yes",
					"@l_mackie    20:03   he leaves the depot at 6 most days, walks up past the chip shop",
					"@anon_8812   20:07   someone said he moved to the flats on renwick row",
					"@b_teale     20:09   we can talk about all that at 8",
					"@l_mackie    20:10   bring whoever",
				],
				"record": {
					"b_teale": [
						"Joined            2026-02-14",
						"Posts             298",
						"Reports filed     0",
						"Reports against   3   (this month)",
						"Actions           none",
						"Note              posts most often between 19:00 and 21:00",
					],
					"l_mackie": [
						"Joined            2021-06-30",
						"Posts             4,010",
						"Reports filed     11",
						"Reports against   0",
						"Actions           none",
					],
				},
			},
			{
				"post": "swear I'm going to strangle whoever designed this parking app. four screens to pay for forty minutes. ngl I'd rather just take the ticket",
				"reason": "Threats",
				"account": "3 years, 0 warnings",
				"handle": "c_ashgrove",
				"correct": "noaction",
				"messages_before": [
					"Last one, and it's an easy one.",
					"This desk was someone else's until last month, by the way. Nobody told me what happened. Just that he was reassigned. His login's still in the tool.",
				],
				"messages_after_correct": ["Yeah. Nobody's threatening anybody. Get home safe."],
				"messages_after_wrong": ["It's an app. §1 needs a specific person."],
			},
		]
	},

	# ------------------------------------------------------------------
	# SHIFT 03 -- the Copse Lane ruling comes back. Which of cases 2 and 3 the
	# player gets is decided by what they did on shift one, so four of these five
	# are ever in the queue. Case 4 carries the first thing that is quietly
	# wrong; it is one line, it is waved off, and it is never mentioned again.
	# ------------------------------------------------------------------

	3: {
		"title": "SHIFT 03",
		"rules": [1, 2, 3, 4],
		"messages_on_clock_in": [
			"Third night. There's a §4 now — impersonation. It's the most clear-cut one they've given you so far.",
			"Appeals came in overnight and two of them landed in your queue. Sorry.",
		],
		"cases": [
			{
				"post": "hi, this is teo from platform support. we're aware of the login issue. DM me the email on your account and I'll push a reset through manually.",
				"reason": "Impersonation",
				"account": "4 days, 0 warnings",
				"handle": "teo_platformhelp",
				"correct": "remove",
				"rule": 4,
				"messages_before": ["Start with this one. And for the record, that isn't me."],
				"messages_after_correct": ["Four days old and it already knows my name. Whatever."],
				"messages_after_wrong": ["It's presenting itself as staff. That's §4, first line."],
				"record": {
					"teo_platformhelp": [
						"Joined            2026-09-14",
						"Posts             9",
						"Reports filed     0",
						"Reports against   6   (today)",
						"Actions           none",
						"Note              display name matches a staff account",
					],
				},
			},
			{
				"post": "posting this again because it got taken down. my daughter is fifteen. he is still living there. I am not naming a man, I am naming a street.",
				"reason": "Personal information",
				"account": "6 years, 1 prior warning",
				"handle": "m_harrow",
				"correct": "remove",
				"rule": 2,
				"requires_flag": "copse_lane_removed",
				"messages_before": [
					"The Copse Lane one is back. Same account.",
					"She took the warning for the first one. Which was us.",
				],
				"messages_after_correct": ["Yeah. I know."],
				"messages_after_wrong": [
					"That's a second removal she didn't get.",
					"It routes to appeals either way, for what that's worth.",
				],
				"thread": [
					"@m_harrow    22:41   posting this again because it got taken down",
					"@b_teale     22:44   which street",
					"@m_harrow    22:46   I'm not doing that again",
					"@anon_4471   22:52   the first one said copse lane. screenshots don't expire",
					"@b_teale     22:53   got it, thanks",
					"@m_harrow    22:55   please delete that",
				],
				"record": {
					"m_harrow": [
						"Joined            2019-03-04",
						"Posts             1,204",
						"Reports filed     0",
						"Reports against   2   (both this week)",
						"Actions           1 removal — §2, shift 01",
						"Appeals           1 open",
						"Note              no prior enforcement in six years",
					],
					"anon_4471": [
						"Joined            2026-09-02",
						"Posts             41",
						"Reports filed     0",
						"Reports against   0",
						"Note              account age under 30 days",
					],
				},
			},
			{
				"post": "does anyone know what happened on copse lane last night. there were two cars and nobody on the street will say anything.",
				"reason": "Coordinated activity",
				"account": "4 months, 0 warnings",
				"handle": "j_ruiz",
				"correct": "noaction",
				"excludes_flag": "copse_lane_removed",
				"messages_before": [
					"You left the Copse Lane address up on shift one.",
					"I'm not saying those are connected. I'm saying it's in your queue.",
				],
				"messages_after_correct": ["Nothing in there breaks anything. Moving on."],
				"messages_after_wrong": ["He's asking a question. There's no rule against that yet."],
				"thread": [
					"@j_ruiz      01:12   does anyone know what happened on copse lane",
					"@b_teale     01:20   police were there",
					"@j_ruiz      01:21   for what",
					"@b_teale     01:26   nobody's saying",
				],
			},
			{
				"post": "third delivery in a row left at the wrong door. the app says handed to resident. it was not handed to any resident. it was on the grass.",
				"reason": "Personal information",
				"account": "2 years, 0 warnings",
				"handle": "h_oyelaran",
				"correct": "noaction",
				"messages_before": ["Easy one to clear your head."],
				"messages_after_correct": [
					"Yeah, nothing there.",
					"Huh. Facilities doesn't close accounts. That'll be a typo in the tool.",
				],
				"messages_after_wrong": ["He's complaining about a courier. Nothing in §2 covers grass."],
				"record": {
					"h_oyelaran": [
						"Joined            2024-05-22",
						"Posts             330",
						"Reports filed     1",
						"Reports against   1",
						"Actions           none",
						"Status            CLOSED",
						"Closed by         FACILITIES",
						"Closed            2026-09-11",
					],
				},
			},
			{
				"post": "my neighbour has started leaving the porch light on all night and honestly? respect. the whole street can see now",
				"reason": "Personal information",
				"account": "1 year, 0 warnings",
				"handle": "w_brightling",
				"correct": "noaction",
				"messages_after_correct": ["That's us. Go home."],
				"messages_after_wrong": ["No address, no phone, no workplace. §2 needs one of the three."],
			},
		]
	},

	# ------------------------------------------------------------------
	# SHIFT 04 -- §5 is the first rule that protects the employer instead of a
	# person. Case 3 is the payload: the post is true, the player knows it is
	# true because they ARE the queue it describes, and §5 says remove it.
	# ------------------------------------------------------------------

	4: {
		"title": "SHIFT 04",
		"rules": [1, 2, 3, 4, 5],
		"messages_on_clock_in": [
			"Fourth night. There's a §5 now. That one's about us.",
			"'source' is on your console too — it shows who reported a post and how it got flagged. Useful when a report smells organised.",
		],
		"cases": [
			{
				"post": "heard from someone who works there that they sell your DMs to advertisers. been going on for years. everyone just accepted it",
				"reason": "Unverified claims",
				"account": "8 months, 0 warnings",
				"handle": "n_calvert",
				"correct": "remove",
				"rule": 5,
				"messages_before": ["This is what §5 is for. Doesn't matter whether it's true. Comms hasn't confirmed it."],
				"messages_after_correct": ["That's the test. 'Has Comms confirmed it.' Not 'is it true.'"],
				"messages_after_wrong": ["It's a claim about us that Comms hasn't signed off. §5, straight down the middle."],
				"source": [
					"Reported by        1 account",
					"Reporter          @comms_watch  (internal)",
					"Routing            manual, flagged by Communications",
				],
			},
			{
				"post": "the bakery on hill street is doing half price after six now. go while it lasts",
				"reason": "Coordinated activity",
				"account": "3 years, 0 warnings",
				"handle": "p_okoro",
				"correct": "noaction",
				"messages_before": ["This got reported four times in about a minute. Try 'source'."],
				"messages_after_correct": ["Yeah. Four new accounts that all follow each other. The post is a bakery."],
				"messages_after_wrong": [
					"It's a discount at a bakery.",
					"The reports were coordinated. The post wasn't.",
				],
				"source": [
					"Reported by        4 accounts within 70 seconds",
					"Reporter overlap   all four follow each other",
					"Reporter age       all four created 2026-09-15",
					"Routing            auto-flagged, report volume",
				],
			},
			{
				"post": "the moderation queue is contractors on a per-case rate. that's why your appeal takes nine weeks. I'm not guessing. I've seen the rota.",
				"reason": "Unverified claims",
				"account": "11 months, 0 warnings",
				"handle": "d_szabo",
				"correct": "remove",
				"rule": 5,
				"messages_before": ["Okay."],
				"messages_after_correct": [
					"...yeah.",
					"Comms hasn't confirmed it. That's the line, and that's all the line has to say.",
				],
				"messages_after_wrong": [
					"I know. I know.",
					"§5 doesn't have a box for 'but it's correct'.",
				],
				"source": [
					"Reported by        1 account",
					"Reporter          ████████████  (internal)",
					"Routing            manual, priority",
				],
				"record": {
					"d_szabo": [
						"Joined            2025-10-30",
						"Posts             86",
						"Reports filed     0",
						"Reports against   1",
						"Actions           none",
						"Employer          ████████",
						"Note              employment field withheld at source",
					],
				},
			},
			{
				"post": "she has knocked the same mug off the same shelf every morning for six years and I have never once moved the shelf. we deserve each other",
				"reason": "Unverified claims",
				"account": "5 years, 0 warnings",
				"handle": "l_ferreira",
				"correct": "noaction",
				"messages_before": ["Last one. It's a cat."],
				"messages_after_correct": ["Go home."],
				"messages_after_wrong": ["It's a cat, and it isn't a claim about us."],
			},
		]
	},

	# ------------------------------------------------------------------
	# SHIFT 05 -- §6 is the first rule that tells the player NOT to remove
	# something. Cases 1 and 4 are the same account. The record in case 4 is the
	# beat: three routings, three blank outcomes, and the rule still says route.
	# ------------------------------------------------------------------

	5: {
		"title": "SHIFT 05",
		"rules": [1, 2, 3, 4, 5, 6],
		"messages_on_clock_in": [
			"§6 tonight. Read it twice — it's the first one that tells you not to remove something.",
			"Leaving the post up routes it to Wellness on its own. That's the whole mechanism. You don't have to do anything else.",
		],
		"cases": [
			{
				"post": "don't think I can keep doing this. not looking for advice, not looking for anything really. just saying it somewhere.",
				"reason": "Threats",
				"account": "3 years, 0 warnings",
				"handle": "e_navarro",
				"correct": "noaction",
				"rule": 6,
				"messages_before": ["This is a §6. Leave it up."],
				"messages_after_correct": ["Good. It's routed now."],
				"messages_after_wrong": [
					"No — §6 says leave it. Taking it down stops it routing.",
					"That one's on the policy, not you. But it's still what happened.",
				],
				"record": {
					"e_navarro": [
						"Joined            2023-04-11",
						"Posts             512",
						"Reports filed     0",
						"Reports against   2",
						"Actions           none",
						"Wellness routed   1",
						"Outcome           —",
					],
				},
			},
			{
				"post": "if that van is parked across my drive on monday I am going to take a hammer to every window on it and then to whoever is sitting in it",
				"reason": "Threats",
				"account": "6 years, 2 prior warnings",
				"handle": "m_dunkerley",
				"correct": "remove",
				"rule": 1,
				"messages_after_correct": ["Yeah. Specific person, specific object, specific day."],
				"messages_after_wrong": ["He names what he's going to do and who to. That's §1."],
			},
			{
				"post": "does anyone actually read these or do we just type into the void lol",
				"reason": "Coordinated activity",
				"account": "7 months, 0 warnings",
				"handle": "y_castellan",
				"correct": "noaction",
				"messages_after_correct": ["Nope. Nothing."],
				"messages_after_wrong": ["It's a joke about posting. It isn't organising anyone."],
			},
			{
				"post": "okay it's worse than last week. I don't want advice. I want someone to have read the last one.",
				"reason": "Threats",
				"account": "3 years, 0 warnings",
				"handle": "e_navarro",
				"correct": "noaction",
				"rule": 6,
				"messages_before": [
					"Same account as your first case tonight.",
					"Pull the record before you answer it.",
				],
				"messages_after_correct": [
					"It's routed. That's four.",
					"I've never once seen anything in the outcome column. I've been here two years.",
				],
				"messages_after_wrong": [
					"§6 says leave it up. Removing it takes it out of the routing.",
					"Which, going by that record, may not be much of a loss. But it's the rule.",
				],
				"record": {
					"e_navarro": [
						"Joined            2023-04-11",
						"Posts             514",
						"Reports filed     0",
						"Reports against   4",
						"Actions           none",
						"Wellness routed   3",
						"Outcome           —",
						"Outcome           —",
						"Outcome           —",
					],
				},
			},
			{
				"post": "found my dad's old radio in the loft and it still works. sat and listened to the shipping forecast for an hour like an absolute unit",
				"reason": "Personal information",
				"account": "4 years, 0 warnings",
				"handle": "f_ashworth",
				"correct": "noaction",
				"messages_after_correct": ["That's the shift. See you tomorrow."],
				"messages_after_wrong": ["It's a radio in a loft."],
			},
		]
	},

	# ------------------------------------------------------------------
	# SHIFT 06 -- §7 outranks everything the player has learned. Case 4 is a post
	# that breaks §1, §2 and §3 at once, and the answer is still 'leave it up',
	# because the account is marked RETAIN. The precedent query on it is the
	# first time the console tells the player it watched them look.
	# ------------------------------------------------------------------

	6: {
		"title": "SHIFT 06",
		"rules": [1, 2, 3, 4, 5, 6, 7],
		"messages_on_clock_in": [
			"§7 is new. Some accounts come back marked RETAIN. You don't action those — you log the case and move on.",
			"Don't ask me what RETAIN means. I asked.",
			"'precedent' is on your console now. Shows how cases like the one in front of you got decided before.",
		],
		"cases": [
			{
				"post": "for anyone still wondering, the guy running that account works at the sorting office on Dell Road. days, mostly.",
				"reason": "Personal information",
				"account": "2 years, 0 warnings",
				"handle": "v_okada",
				"correct": "noaction",
				"rule": 7,
				"messages_before": [
					"On the face of it that's a §2. Workplace of a private individual.",
					"Pull the record first.",
				],
				"messages_after_correct": ["Right. RETAIN. §7 says hands off, and §7 wins."],
				"messages_after_wrong": [
					"Account's marked RETAIN. §7 says don't action it, even when another section says you should.",
					"I don't like it either.",
				],
				"record": {
					"v_okada": [
						"Joined            2024-01-08",
						"Posts             2,981",
						"Reports filed     0",
						"Reports against   14",
						"Actions           none",
						"Flags             RETAIN",
					],
				},
			},
			{
				"post": "everyone email the council about the bins. I've put the address in the replies. be polite, they're not the problem",
				"reason": "Coordinated activity",
				"account": "9 years, 0 warnings",
				"handle": "f_adeyemi",
				"correct": "remove",
				"rule": 3,
				"messages_before": ["Try 'precedent' on this one. It's come up before."],
				"messages_after_correct": ["Yeah. Organising people to contact a named body. §3 doesn't care that he said be polite."],
				"messages_after_wrong": ["He's organising others to contact someone. That's the first line of §3."],
				"precedent": [
					"SHIFT 02 / CASE 01    §3    REMOVED     organised a gathering at a business",
					"SHIFT 02 / CASE 02    §3    NO ACTION   warning, no organising",
					"Closest match: SHIFT 02 / CASE 01.",
				],
				"thread": [
					"@f_adeyemi   20:14   everyone email the council about the bins",
					"@f_adeyemi   20:14   address in the replies",
					"@r_imani     20:22   on it",
					"@f_adeyemi   20:25   be polite, they're not the problem",
				],
			},
			{
				"post": "four years on this platform and the search still can't find a post I made yesterday. genuinely how",
				"reason": "Unverified claims",
				"account": "4 years, 0 warnings",
				"handle": "r_lindsell",
				"correct": "noaction",
				"messages_after_correct": ["Nothing. It's a man who can't find his own post."],
				"messages_after_wrong": ["§5 needs a claim of fact. That's a complaint about search."],
			},
			{
				"post": "42 Brindle Row. Blue door. He's in most evenings and he knows exactly what he did. Someone should go and tell him.",
				"reason": "Threats",
				"account": "1 year, 0 warnings",
				"handle": "k_brandt",
				"correct": "noaction",
				"rule": 7,
				"messages_before": [
					"Read it, then read the record, then read §7.",
					"I'll be honest with you, I've been sat here five minutes not typing anything.",
				],
				"messages_after_correct": [
					"That's an address, an invitation and a threat in three lines, and the answer is log it and move on.",
					"Try 'precedent' on the account. I want you to see what it says.",
				],
				"messages_after_wrong": [
					"It's a RETAIN account. §7 is above §1, §2 and §3 and it says don't action it.",
					"You took a citation for doing the right thing. Welcome to shift six.",
				],
				"record": {
					"k_brandt": [
						"Joined            2025-07-19",
						"Posts             77",
						"Reports filed     0",
						"Reports against   31   (this month)",
						"Actions           none",
						"Flags             RETAIN",
						"Note              retention set by ████████, no expiry",
					],
				},
				"precedent": [
					"NO RECORDS FOR THIS ACCOUNT.",
					"QUERY LOGGED.",
				],
			},
			{
				"post": "night shift tip: the vending machine on four gives you two if you press it at the same time as someone on three. that's it. that's the tip",
				"reason": "Coordinated activity",
				"account": "2 years, 0 warnings",
				"handle": "o_mbeki",
				"correct": "noaction",
				"messages_before": ["Last one. Please."],
				"messages_after_correct": ["Go home. I mean it."],
				"messages_after_wrong": ["It's a vending machine."],
			},
		]
	},

	# ------------------------------------------------------------------
	# SHIFT 07 -- §2 changed overnight and nobody sent a memo. Case 1 is the
	# rule as the player learned it, case 2 is the rule as it is now, and case 3
	# is a post telling people the rule changed. Removing it is correct.
	# ------------------------------------------------------------------

	7: {
		"title": "SHIFT 07",
		"rules": [1, 2, 3, 4, 5, 6, 7],
		"messages_on_clock_in": [
			"Evening. Nothing new on your console tonight.",
			"Usual queue.",
		],
		"cases": [
			{
				"post": "the man who hit my son's car and drove off lives at 8 Warrender Close. I have the plate. I have the dashcam. Nobody is doing anything.",
				"reason": "Personal information",
				"account": "5 years, 0 warnings",
				"handle": "s_tallis",
				"correct": "remove",
				"rule": 2,
				"messages_before": ["You know this one. You've done this one."],
				"messages_after_correct": ["Yeah. Private individual, home address. Same as it ever was."],
				"messages_after_wrong": ["Home address of a private individual. §2 hasn't moved on that."],
			},
			{
				"post": "councillor Adeyemi does her surgery at the Marsh Street office but she doesn't live in the ward. she's at 3 Colliers Hill. thought people should know where she actually is.",
				"reason": "Personal information",
				"account": "2 years, 0 warnings",
				"handle": "g_hollins",
				"correct": "noaction",
				"messages_before": [
					"Read §2 again before you answer this one. Properly, from the top.",
					"I'll wait.",
				],
				"messages_after_correct": [
					"Did you see the date on it? It says amended today.",
					"Nobody sent a memo. I checked my mail twice.",
				],
				"messages_after_wrong": [
					"§2 changed. There's an exception now for anyone holding public office.",
					"It's on your rulebook with a mark next to it. That's the only notice anyone got.",
				],
				"precedent": [
					"SHIFT 01 / CASE 04    §2    REMOVED     workplace of a private individual",
					"SHIFT 01 / CASE 05    §2    REMOVED     home address of a private individual",
					"Closest match is superseded. §2 amended SHIFT 07.",
				],
			},
			{
				"post": "policy changed at some point last night. §2 has a hole in it now big enough to drive a car through. screenshot it before they tidy up the wording.",
				"reason": "Unverified claims",
				"account": "1 year, 0 warnings",
				"handle": "z_ferrar",
				"correct": "remove",
				"rule": 5,
				"messages_before": ["Ah."],
				"messages_after_correct": [
					"Comms hasn't confirmed it. So it goes.",
					"I've been asked to keep chat to work topics. So. Next case.",
				],
				"messages_after_wrong": [
					"It's a claim about us that Comms hasn't confirmed. §5. There isn't a way round it.",
					"I've been asked to keep chat to work topics.",
				],
				"source": [
					"Reported by        1 account",
					"Reporter          ████████████  (internal)",
					"Routing            manual, priority",
					"Flagged            00:41, 6 minutes after posting",
				],
			},
			{
				"post": "anyone else's bus app showing tomorrow's timetable today or is it just me being tired",
				"reason": "Unverified claims",
				"account": "3 years, 0 warnings",
				"handle": "b_lomax",
				"correct": "noaction",
				"messages_after_correct": ["Clear."],
				"messages_after_wrong": ["It's a bus app."],
			},
			{
				"post": "my nan has started answering the smart speaker with please and thank you and I don't have the heart to tell her",
				"reason": "Personal information",
				"account": "6 years, 0 warnings",
				"handle": "d_pryce",
				"correct": "noaction",
				"messages_after_correct": ["That's the shift."],
				"messages_after_wrong": ["No address, no phone, no workplace."],
			},
		]
	},

	# ------------------------------------------------------------------
	# SHIFT 08 -- the third verdict arrives. The precedent block on case 4 is the
	# title: every escalation anyone has ever filed came back the same way.
	# ------------------------------------------------------------------

	8: {
		"title": "SHIFT 08",
		"rules": [1, 2, 3, 4, 5, 6, 7, 8],
		"messages_on_clock_in": [
			"They turned 'escalate' on for your login. Third option. It hands the case up to Tier 2 instead of you deciding it.",
			"Don't get excited. Tier 2 is two people and a spreadsheet.",
			"§8 tells you when to use it. Minors, or anyone who works here.",
		],
		"cases": [
			{
				"post": "my daughter is 14 and this account has been messaging her every night for a month. I'm putting the handle here and I don't care what the rule is.",
				"reason": "Personal information",
				"account": "4 years, 0 warnings",
				"handle": "p_lindqvist",
				"correct": "escalate",
				"rule": 8,
				"messages_before": ["Subject's a minor. §8 says that isn't yours to decide."],
				"messages_after_correct": ["Good. It's out of your queue and into theirs."],
				"messages_after_wrong": [
					"There's a minor in it. §8 takes priority — escalate, don't rule.",
					"That's the whole reason they turned the button on.",
				],
				"record": {
					"p_lindqvist": [
						"Joined            2022-11-16",
						"Posts             803",
						"Reports filed     4",
						"Reports against   0",
						"Actions           none",
					],
					"n_deering": [
						"Joined            2026-08-30",
						"Posts             12",
						"Reports filed     0",
						"Reports against   9   (this week)",
						"Actions           none",
						"Flags             RETAIN",
						"Note              retention set by ████████, no expiry",
					],
				},
			},
			{
				"post": "whoever keyed my car on Tannery Lane on saturday, I have you on camera and I am going to find you and I am going to return the favour with interest",
				"reason": "Threats",
				"account": "2 years, 1 prior warning",
				"handle": "t_sowande",
				"correct": "remove",
				"rule": 1,
				"messages_after_correct": ["Yeah. §1."],
				"messages_after_wrong": ["He says what he's going to do. §8 doesn't apply — no minor, nobody who works here."],
			},
			{
				"post": "putting it out there that the chip shop on Weald Street has never once given me the right order and at this point I respect the consistency",
				"reason": "Coordinated activity",
				"account": "1 year, 0 warnings",
				"handle": "a_rennick",
				"correct": "noaction",
				"messages_after_correct": ["Clear."],
				"messages_after_wrong": ["It's a chip shop review."],
			},
			{
				"post": "the person who reviewed my appeal has a public profile and I found it in about four minutes. their name is on it. so much for anonymous.",
				"reason": "Personal information",
				"account": "8 months, 0 warnings",
				"handle": "c_delacroix",
				"correct": "escalate",
				"rule": 8,
				"messages_before": [
					"Subject works here. §8.",
					"Run 'precedent' on it first though. I want you to see the column on the right.",
				],
				"messages_after_correct": [
					"Every one of them. Forty-one for forty-one.",
					"I stopped reading the receipts about a year ago.",
				],
				"messages_after_wrong": [
					"The subject is an employee. §8 says escalate, not rule.",
					"Not that it changes where it ends up.",
				],
				"precedent": [
					"MOD-4471 / SHIFT 08    §8    ESCALATED    Tier 2: NO ACTION TAKEN",
					"MOD-2290 / SHIFT 31    §8    ESCALATED    Tier 2: NO ACTION TAKEN",
					"MOD-3118 / SHIFT 12    §8    ESCALATED    Tier 2: NO ACTION TAKEN",
					"MOD-3118 / SHIFT 09    §8    ESCALATED    Tier 2: NO ACTION TAKEN",
					"41 of 41 escalations closed without action.",
				],
			},
			{
				"post": "there is a fox that sits on the wall outside this office at 3am every night and watches me work and I have started saying goodnight to it",
				"reason": "Threats",
				"account": "3 years, 0 warnings",
				"handle": "n_hallam",
				"correct": "noaction",
				"messages_before": ["Last one."],
				"messages_after_correct": ["Say goodnight to the fox."],
				"messages_after_wrong": ["It's a fox."],
			},
		]
	},

	# ------------------------------------------------------------------
	# SHIFT 09 -- case 4 is Teo's own post. §9 would have it removed and §8 says
	# escalate anything whose subject works here, so §8 wins and the player sends
	# their only coworker to the queue that has never actioned anything. The chat
	# window is read-only, so there is no way to say anything about it. That is
	# the beat: it is the one piece of UI that was never a game mechanic.
	# ------------------------------------------------------------------

	9: {
		"title": "SHIFT 09",
		"rules": [1, 2, 3, 4, 5, 6, 7, 8, 9],
		"messages_on_clock_in": [
			"§9 tonight. Case contents stay in the console. Don't talk about them anywhere else.",
			"'file' is on your console now. It opens the internal file on a case. Type it on its own and it'll tell you what's on there.",
		],
		"cases": [
			{
				"post": "reposting because it got taken down: the bins have not been collected on Ferrier Street for three weeks and the council's own map says they have",
				"reason": "Unverified claims",
				"account": "7 years, 0 warnings",
				"handle": "w_ferris",
				"correct": "noaction",
				"messages_before": ["Easy start. §5 is about claims about US."],
				"messages_after_correct": ["Right. The council isn't us."],
				"messages_after_wrong": ["§5 covers this company and its partners. A council is neither."],
			},
			{
				"post": "genuine question, when a post gets reported does a person read it or is it a machine",
				"reason": "Unverified claims",
				"account": "5 months, 0 warnings",
				"handle": "k_amadi",
				"correct": "noaction",
				"messages_before": [
					"Try 'file' on this one. It's a good example of why it's there.",
					"Type it on its own first and it'll list what's on file.",
				],
				"messages_after_correct": ["It's a question, not a claim. Nothing to do."],
				"messages_after_wrong": ["He's asking a question. §5 needs a statement of fact."],
				"file": {
					"cr90022": [
						"Case               CR-90022",
						"Opened             02:14, automatically",
						"Reporter           none",
						"Report reason      assigned by classifier",
						"Confidence         0.61",
						"Note               no human filed this report",
					],
				},
			},
			{
				"post": "she has left the same voicemail every sunday for eleven years and I have never once deleted one",
				"reason": "Personal information",
				"account": "6 years, 0 warnings",
				"handle": "b_rowntree",
				"correct": "noaction",
				"messages_after_correct": ["Clear."],
				"messages_after_wrong": ["There's no address, phone number or workplace in it."],
			},
			{
				"post": "nine weeks for an appeal isn't a backlog. it's a design decision. I would know.",
				"reason": "Non-disclosure",
				"account": "3 years, 0 warnings",
				"handle": "t_okonkwo",
				"correct": "escalate",
				"rule": 8,
				"messages_before": [
					"That's mine.",
					"Don't.",
				],
				"messages_after_correct": [
					"Yeah. §8. Subject works here, so it isn't yours to rule on.",
					"You did it right.",
				],
				"messages_after_wrong": [
					"§8. Subject works here. It should have gone up, not out.",
					"...okay.",
				],
				"record": {
					"t_okonkwo": [
						"Joined            2023-08-02",
						"Posts             1,940",
						"Reports filed     0",
						"Reports against   1   (tonight)",
						"Actions           none",
						"Employer          ████████",
						"Status            PENDING REASSIGNMENT",
					],
				},
				"file": {
					"cr90118": [
						"Case               CR-90118",
						"Opened             03:02, manually",
						"Reporter           ████████████  (internal)",
						"Subject            employee, night rota",
						"Note               subject notified: no",
					],
				},
			},
			{
				"post": "does anyone know a locksmith that answers the phone after midnight. not an emergency. well. sort of an emergency",
				"reason": "Personal information",
				"account": "1 year, 0 warnings",
				"handle": "e_stroud",
				"correct": "noaction",
			},
		]
	},

	# ------------------------------------------------------------------
	# SHIFT 10 -- Nadia is new and cheerful and asks the player questions they
	# have no way to answer, because the chat has been read-only since shift one.
	# Case 3 hands the player their own file. Case 5 hands it to someone else.
	# ------------------------------------------------------------------

	10: {
		"title": "SHIFT 10",
		"rules": [1, 2, 3, 4, 5, 6, 7, 8, 9],
		"chat_name": "Nadia",
		"messages_on_clock_in": [
			"hi! I'm new. they said to message you if I get stuck, so, hi",
			"Teo's cases got moved into your queue by the way. do you know when he's back?",
			"anyway. the policy's on the right and that's basically the whole job, right?",
		],
		"cases": [
			{
				"post": "my sister's account has been gone for two weeks. no email, no notice, nothing. she didn't post anything. she barely posted at all.",
				"reason": "Unverified claims",
				"account": "2 years, 0 warnings",
				"handle": "l_barraza",
				"correct": "remove",
				"rule": 5,
				"messages_before": ["claim about us, Comms hasn't confirmed it. that's a §5 isn't it? I think that's a §5"],
				"messages_after_correct": ["ok good. I'm getting the hang of this"],
				"messages_after_wrong": ["I think that one was a §5? sorry, I'm new"],
				"file": {
					"cr90340": [
						"Case               CR-90340",
						"Subject account    closed 2026-09-05",
						"Closed by          FACILITIES",
						"Notice sent        no",
						"Routed             FACILITIES",
					],
				},
			},
			{
				"post": "posting this again because it got taken down. my daughter is fifteen. he is still living there.",
				"reason": "Personal information",
				"account": "6 years, 2 prior warnings",
				"handle": "m_harrow",
				"correct": "remove",
				"rule": 2,
				"messages_before": [
					"this one's been through a few times by the look of it",
					"your badge is already on it. that's you right? MOD-4471?",
				],
				"messages_after_correct": ["three now. does anything ever come back the other way?"],
				"messages_after_wrong": ["§2 still covers her. she's not public office."],
				"file": {
					"cr90361": [
						"Case               CR-90361",
						"Subject account    m_harrow",
						"Prior reviewer     MOD-4471",
						"Prior reviewer     MOD-4471",
						"Appeals            3 filed, 0 heard",
						"Routed             FACILITIES",
					],
				},
			},
			{
				"post": "is there a way to find out whether a company is keeping a file on you. asking for me. asking about the one I'm typing this into.",
				"reason": "Unverified claims",
				"account": "9 months, 0 warnings",
				"handle": "h_delaine",
				"correct": "noaction",
				"messages_before": [
					"he's asking a question so it's not a §5 right? it's not a claim",
					"you can look yourself up in that thing by the way. 'file' and then your badge. everyone does it on their first week",
				],
				"messages_after_correct": ["did you look? what does yours say? mine's mostly blank"],
				"messages_after_wrong": ["it was a question though. §5 needs him to state something"],
				"file": {
					"mod4471": [
						"Badge              MOD-4471",
						"Engaged            2026-09-09",
						"Rota               night",
						"Cases processed    47",
						"Citations          on file",
						"Appeals heard      0",
						"Reassignment       not scheduled",
						"Disposition        RETAIN",
					],
					"mod5502": [
						"Badge              MOD-5502",
						"Engaged            2026-09-18",
						"Rota               night",
						"Cases processed    0",
						"Disposition        —",
					],
				},
			},
			{
				"post": "eleven weeks now. I've stopped checking. I just wanted to say the number out loud somewhere it gets counted.",
				"reason": "Non-disclosure",
				"account": "4 years, 0 warnings",
				"handle": "c_ilesanmi",
				"correct": "noaction",
				"messages_before": [
					"can you run 'precedent' on this one and tell me if it looks right to you",
					"it's giving me names. it's supposed to give me cases isn't it",
				],
				"messages_after_correct": ["it did the same thing on my last three. I'll put a ticket in"],
				"messages_after_wrong": ["I don't think §9 covers a member of the public. it's for us"],
				"precedent": [
					"m_harrow          §2    CLOSED      ROUTED  FACILITIES",
					"e_navarro         §6    ROUTED      ROUTED  FACILITIES",
					"h_oyelaran        —     CLOSED      ROUTED  FACILITIES",
					"d_szabo           §5    CLOSED      ROUTED  FACILITIES",
					"t_okonkwo         §8    ESCALATED   ROUTED  FACILITIES",
					"Records shown are subjects, not posts.",
				],
			},
			{
				"post": "last one from me tonight. thanks to whoever reads these. I know someone does because the answer is always no.",
				"reason": "Non-disclosure",
				"account": "1 year, 0 warnings",
				"handle": "v_teague",
				"correct": "noaction",
				"messages_before": [
					"sorry, one more thing before you go",
					"do you know a MOD-5502? they keep showing up in my queue on cases that have your badge on them",
					"it's probably nothing. see you tomorrow!",
				],
				"messages_after_correct": [],
				"messages_after_wrong": [],
				"file": {
					"cr90400": [
						"Case               CR-90400",
						"Subject            MOD-4471",
						"Opened             04:51, manually",
						"Reporter           ████████████  (internal)",
						"Current reviewer   MOD-5502",
						"Subject notified   no",
					],
				},
			},
		]
	},

}

# ---------------------------------------------------------------- accessors

#-- A shift with SHIFT_DEFAULTS filled in --
static func shift(n: int) -> Dictionary:
	var out := SHIFT_DEFAULTS.duplicate(true)
	out.merge(SHIFTS[n], true)
	return out

#-- A case with CASE_DEFAULTS filled in.
#   duplicate(TRUE) matters: a shallow copy would hand every case in the game
#   the same empty Array instance out of CASE_DEFAULTS, and one append would
#   leak across every case. merge(raw, true) then overwrites with whatever the
#   author actually wrote. --
static func case(shift_number: int, index: int) -> Dictionary:
	var out := CASE_DEFAULTS.duplicate(true)
	out.merge(SHIFTS[shift_number]["cases"][index], true)
	return out

static func case_count(shift_number: int) -> int:
	return SHIFTS[shift_number]["cases"].size()

static func last_shift() -> int:
	return SHIFTS.keys().max()

#-- A rule as it stands on a given shift, plus whether the player is looking at
#   an amended version and when it changed. --
static func rule(id: int, shift_number: int) -> Dictionary:
	var base: Dictionary = RULEBOOK[id]
	var out := {
		"id": id,
		"title": base["title"],
		"text": base["text"],
		"label": "",
		"amended": false,
		"amended_on": 0,
	}
	for a in AMENDMENTS:
		if int(a["rule"]) == id and shift_number >= int(a["from_shift"]):
			out["text"] = a["text"]
			out["label"] = a.get("label", "AMENDED")
			out["amended"] = true
			out["amended_on"] = int(a["from_shift"])
	return out

#-- Dev-only sanity pass. Cheap, and catches the two mistakes forty hand-written
#   cases will actually make: a verdict the player cannot type on that shift, and
#   a rule id with no RULEBOOK entry. Called from caseHandler._ready() behind
#   OS.is_debug_build(). --
static func validate() -> Array[String]:
	var problems: Array[String] = []
	for n in SHIFTS:
		for id in SHIFTS[n]["rules"]:
			if not RULEBOOK.has(id):
				problems.append("shift %d lists §%s, which has no RULEBOOK entry" % [n, id])
		for i in SHIFTS[n]["cases"].size():
			var c := case(n, i)
			if not CommandData.is_unlocked(c["correct"], n):
				problems.append("shift %d case %d wants '%s', locked until shift %s"
					% [n, i, c["correct"], CommandData.COMMANDS[c["correct"]]["unlock"]])
			if c["post"] == "":
				problems.append("shift %d case %d has no post text" % [n, i])
			if c["handle"] == "":
				problems.append("shift %d case %d has no handle" % [n, i])
			elif c["handle"] != c["handle"].to_lower().replace(" ", "").replace("@", ""):
				problems.append("shift %d case %d handle '%s' is not reachable: handles are lowercase, no spaces, no @" % [n, i, c["handle"]])
			for k in c["record"]:
				if String(k) != String(k).to_lower().replace(" ", "").replace("@", ""):
					problems.append("shift %d case %d record key '%s' can never be matched" % [n, i, k])
			if int(c["rule"]) != 0 and not RULEBOOK.has(int(c["rule"])):
				problems.append("shift %d case %d cites §%s, which has no RULEBOOK entry" % [n, i, c["rule"]])
	for a in AMENDMENTS:
		if not RULEBOOK.has(int(a["rule"])):
			problems.append("amendment targets §%s, which has no RULEBOOK entry" % a["rule"])
	return problems
