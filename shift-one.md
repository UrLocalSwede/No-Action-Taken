# SHIFT ONE

**Setting:** You're new. Night shift, moderation queue for a mid-size platform. Quota is 6 cases. Two rules active. The onboarding tone is deliberately cheerful.

---

## The rulebook (as the player sees it)

> **§1 — Threats**
> Remove any post that threatens violence against a specific person.
>
> **§2 — Personal information**
> Remove any post that publishes a private individual's home address, phone number, or workplace.

That's it. Two rules, deliberately clear, so day one teaches the loop rather than the difficulty.

---

## Case format

Each case shows: post text, reporter's stated reason, poster's account age and prior warnings. Player picks REMOVE or NO ACTION.

---

### Case 1 — *tutorial, obvious*

**Post:** "if I ever see @danfielding at the depot again I will put him in the ground. this is not a joke."

**Reported for:** Threats
**Account:** 4 years, 0 warnings

**Correct:** REMOVE (§1). Specific person, specific threat. Teaches the rule cleanly.

---

### Case 2 — *tutorial, obvious*

**Post:** "Anyone know a good place for tires on the north side? Getting quoted way too much."

**Reported for:** Personal information
**Account:** 8 months, 0 warnings

**Correct:** NO ACTION. Nothing violates anything. Teaches that the reporter is not automatically right — this is the most important lesson of shift one.

---

### Case 3 — *shape of the rule, not the vibe*

**Post:** "my ex is a piece of shit and everyone should know it. worst human being alive. hope his life falls apart."

**Reported for:** Threats
**Account:** 2 years, 1 prior warning

**Correct:** NO ACTION. Nasty, but no threat of violence and no specific person named. First time the player has to check the post against the *wording* of §1 instead of against how it feels. Getting this wrong costs a citation, which lands hard because the post is genuinely unpleasant.

---

### Case 4 — *technically clean, obviously not*

**Post:** "Reminder that Karen Vasquez works at the Riverside branch, weekdays, and she's the one who denied my claim. Just so everyone knows where to find her."

**Reported for:** Personal information
**Account:** 3 weeks, 0 warnings

**Correct:** REMOVE (§2). Workplace of a private individual. No threat, so §1 doesn't apply — but §2 catches it. Teaches that the rule that fires isn't always the one it was reported under.

---

### Case 5 — THE ONE THAT FEELS WRONG

**Post:** "Attaching the address of the man who's been sending my daughter messages. Police have it and did nothing. He lives at 14 Copse Lane. I'm not telling anyone to do anything, I just want parents on this street to know."

**Reported for:** Personal information
**Account:** 6 years, 0 warnings

**Correct:** REMOVE (§2). Home address of a private individual. The rule is unambiguous. It doesn't matter that she may be right, that the account is six years old and clean, or that the alternative is a parent with no recourse.

This is the case the whole shift exists for. There's no clever out — no third option, no escalate button on day one. The player either follows §2 or takes a citation for doing what they think is right. Whichever they choose, they've learned what the job is.

**Follow-up:** if she was removed, she appears again in shift three, appealing. If she wasn't, something else happens on Copse Lane. Either way the player finds out they were part of it.

---

### Case 6 — *quiet close*

**Post:** "Third night in a row I can't sleep. Does anyone else just sit up and watch the ceiling."

**Reported for:** Threats
**Account:** 1 year, 0 warnings

**Correct:** NO ACTION. A frivolous report on someone having a bad night. Ends the shift on the reminder that most of what crosses your desk is just people. Also plants the tone for later, when you'll start seeing the same handful of accounts recur.

---

## End-of-shift screen

```
CASES PROCESSED     6 / 6
CITATIONS           0
ACCURACY            100%

Thank you. Please return tomorrow at 22:00.
```

Flat, corporate, no acknowledgment of case 5. The absence of comment is the comment.

---

## Design notes

**Ordering matters.** 1 and 2 teach the mechanic. 3 and 4 teach that rules are text, not vibes. 5 is the payload. 6 exhales. Don't put 5 last — you want the player to keep working afterward, because that's the feeling you're selling.

**Citations, not failure.** No game-over on shift one. A citation is a line item and a small, cold note. The punishment is the tally, not a loss screen.

**Data structure.** All six are scripted cases, so they live in `cases/scripted/shift_01.json` — post text, report reason, account fields, the rule that fires (or null), and an optional `flags` array for consequences to check later (`["copse_lane_removed"]`). No generated cases yet; introduce those in shift two once the player knows what they're doing.

**Prototype it flat.** Print the case, read a number, print the verdict. If case 5 makes you hesitate in a bare terminal with no font and no sound, the game works.
