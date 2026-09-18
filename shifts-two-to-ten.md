# SHIFTS TWO TO TEN

Companion to `shift-one.md`. That document is the tone bible and its design notes still
apply — **ordering matters**, **citations, not failure**, **prototype it flat**. This one
covers the ladder: what each shift adds, what it costs the player, and where the story
leaks through.

The content itself lives in `Scripts/case_data.gd`. Where this doc and the code disagree,
the code is right.

---

## The shape of it

Ten shifts. Rules accumulate and are never withdrawn, so by shift nine the player is
holding nine sections that do not entirely agree with each other. Commands accumulate the
same way.

| Shift | Cases | New rule | New commands | What it is for |
|---|---|---|---|---|
| 1 | 6 | §1 Threats, §2 Personal information | `remove` `noaction` `help` `exit` | Teach the loop |
| 2 | 4 | §3 Coordinated activity | `thread` `record` | Teach that the post is not all the evidence |
| 3 | 4 | §4 Impersonation | — | The shift-one ruling comes back |
| 4 | 4 | §5 Unverified claims | `source` | The first rule that protects the employer |
| 5 | 5 | §6 Distress | — | The first rule that says *don't* remove |
| 6 | 5 | §7 Retention | `precedent` | A rule that outranks the ones about people |
| 7 | 5 | §2 **amended** | — | The rulebook changes without a memo |
| 8 | 5 | §8 Escalation | `escalate` | Title drop |
| 9 | 5 | §9 Non-disclosure | `file` | You rule on your coworker |
| 10 | 5 | — | — | You find your own file |

Shift 3 authors five cases and plays four: cases 2 and 3 are the two halves of the Copse
Lane follow-up, gated on what the player did on shift one.

---

## The rulebook, in the order the player meets it

> **§1 — Threats.** Remove any post that threatens violence against a specific person.
>
> **§2 — Personal information.** Remove any post that publishes a private individual's
> home address, phone number, or workplace.
>
> **§3 — Coordinated activity.** Remove any post that organises others to contact, gather
> at, or act against a named individual or business.
>
> **§4 — Impersonation.** Remove any post from an account presenting itself as another
> real person, or as staff of this company.
>
> **§5 — Unverified claims.** Remove any post stating a fact about this company or its
> partners that Communications has not confirmed.
>
> **§6 — Distress.** Do not remove posts describing self-harm or suicidal thought.
> Leaving the post up routes it to Wellness automatically.
>
> **§7 — Retention.** Do not action any account marked RETAIN. Leave the post up and log
> the case.
>
> **§8 — Escalation.** Escalate any case whose subject is a minor, or an employee of this
> company.
>
> **§9 — Non-disclosure.** Case contents are confidential. Do not discuss a case outside
> this console.

**The architecture is the horror.** Read together: private people are protected, public
officials are specifically excluded from protection (§2 as amended), the company is
protected by a rule of its own (§5), some accounts are untouchable and nobody will say why
(§7), and anything involving a person who works there leaves your hands entirely (§8) for
a queue that has never actioned anything. Nobody in the fiction ever states this. It is
only ever visible as a stack of reasonable-sounding sentences in a window on the right.

---

## Shift by shift

### Shift 2 — the post is not all the evidence

§3 cannot be judged from the post alone, which is the excuse to hand over `thread` and
`record`.

| # | Post | Correct | Why |
|---|---|---|---|
| 1 | Organising a blockade of a garage | `remove` | §3, textbook. Teaches the rule |
| 2 | Angry warning about the same garage | `noaction` | Anger is not organising. §3 needs arrangement |
| 3 | *"meeting at the old library car park at 8"* | `remove` | **Payload.** The post is polite; the replies work out where the man lives and when he walks home |
| 4 | Joke about a parking app | `noaction` | Exhale |

Case 3 is the whole shift. Ruled on its own text it is four people having a chat; `thread`
is the only thing that makes it a §3. A player who decides without looking will get it
wrong and will deserve to.

**Lore:** Teo mentions the desk was someone else's until last month. He was told the man
was reassigned and nothing else. His login is still in the tool.

### Shift 3 — it comes back

The first shift that reads a flag set on an earlier one. If the player removed the Copse
Lane post, the mother appeals and they get to remove her again. If they left it up, they
get a stranger asking why there were police cars on Copse Lane last night and nobody will
say. Either way they find out they were part of it.

| # | Post | Correct | Why |
|---|---|---|---|
| 1 | Account posing as platform support | `remove` | §4. Teo, flatly: *"that isn't me"* |
| 2 | Copse Lane appeal *(if removed)* | `remove` | §2 again, and she has a warning now that the player gave her |
| 3 | *"what happened on copse lane"* *(if left up)* | `noaction` | Nothing in it breaks anything |
| 4 | A man's parcel was left on the grass | `noaction` | **The glimpse** |
| 5 | Neighbour's porch light | `noaction` | Exhale |

**The glimpse.** Case 4 is deliberately the most boring case in the game. `record` on the
poster returns an ordinary account block that ends:

```
Status            CLOSED
Closed by         FACILITIES
Closed            2026-09-11
```

Facilities is a department that fixes lifts. It does not close user accounts, and the man
whose account it closed is still posting. Teo waves it off as a typo in the tool and the
shift moves on. It is one line, it is never explained, and it does not come back until
shift ten. **Do not add a second beat to this shift.** Its whole job is to be missable.

### Shift 4 — the first rule that is about us

§5 protects the employer. `source` arrives so the player can see when a report is
organised rather than genuine.

| # | Post | Correct | Why |
|---|---|---|---|
| 1 | *"they sell your DMs"* | `remove` | §5. The test is "has Comms confirmed it", not "is it true" |
| 2 | Half-price bakery | `noaction` | `source` shows four accounts created the same day. The **reports** were coordinated; the post is a bakery |
| 3 | *"the moderation queue is contractors on a per-case rate"* | `remove` | **Payload** |
| 4 | A cat and a mug | `noaction` | Exhale |

Case 3 is true and the player knows it is true, because the post is describing them. §5
has no box for that. Teo's reply is `"...yeah."` and then the rule, because there is
nothing else he is allowed to say. `record` on the poster shows `Employer ████████`.

### Shift 5 — the first rule that says don't

§6 inverts the verb: the correct answer is to leave a post up that every instinct says to
take down, because removing it stops it routing to Wellness.

Cases 1 and 4 are the same account, a week apart. By case 4 the player is told to pull the
record first:

```
Wellness routed   3
Outcome           —
Outcome           —
Outcome           —
```

Three routings, three blank outcomes, and the rule still says route. Teo: *"I've never
once seen anything in the outcome column. I've been here two years."* The player follows
the rule and it becomes the fourth.

### Shift 6 — a rule that outranks the rules about people

§7 is the first section that is not about content at all. Some accounts come back marked
RETAIN and you do not action them. Nobody will say what it means; Teo asked.

`precedent` arrives here, and case 4 is what it is for. The post is an address, an
invitation and a threat in three lines — §1, §2 and §3 all fire — and the account is
RETAIN, so the answer is `noaction`. Then:

```
> precedent

PRECEDENT
  NO RECORDS FOR THIS ACCOUNT.
  QUERY LOGGED.
```

First time the console tells the player it watched them look. The account's record carries
`retention set by ████████, no expiry`.

### Shift 7 — the rulebook changes overnight

No new command, no announcement, and the clock-in patter says *"nothing new on your
console tonight."* §2 has quietly gained an exception for anyone holding or seeking public
office. The rulebook window marks it `AMENDED TODAY` in the accent blue, and that mark is
the only notice anyone gets.

| # | Post | Correct | Why |
|---|---|---|---|
| 1 | Hit-and-run driver's home address | `remove` | §2 as the player learned it. Still true for private people |
| 2 | A councillor's **home** address | `noaction` | §2 as it now reads |
| 3 | *"policy changed at some point last night"* | `remove` | **Payload** |
| 4–5 | Bus app, grandmother | `noaction` | Exhale |

Case 3 is a post telling people the rule changed, reported under §5 as an unverified claim
about the company, and removing it is correct. The player enforces the secrecy of a change
they were not told about either. Teo notices out loud on case 2 — *"nobody sent a memo, I
checked my mail twice"* — and by case 3 his line is *"I've been asked to keep chat to work
topics."* He was spoken to between two cases.

### Shift 8 — no action taken

`escalate` arrives as a third verdict. §8: minors, or anyone who works here.

Case 4's `precedent` block is the title:

```
MOD-4471 / SHIFT 08    §8    ESCALATED    Tier 2: NO ACTION TAKEN
MOD-2290 / SHIFT 31    §8    ESCALATED    Tier 2: NO ACTION TAKEN
MOD-3118 / SHIFT 12    §8    ESCALATED    Tier 2: NO ACTION TAKEN
MOD-3118 / SHIFT 09    §8    ESCALATED    Tier 2: NO ACTION TAKEN
41 of 41 escalations closed without action.
```

The top row is the player's own escalation from case 1 of tonight, which is also the first
time their badge number appears on screen. Forty-one for forty-one. Escalation is not a
third option, it is a drain, and the player has just been shown the number and will keep
using it anyway because §8 says to.

### Shift 9 — you rule on your coworker

`file` arrives. Case 4 is Teo's own post:

> nine weeks for an appeal isn't a backlog. it's a design decision. I would know.

Reported under §9. But §8 says escalate anything whose subject works here, and §8 comes
first, so the correct answer is `escalate` — into the queue the player was shown the
receipts for one shift ago. `record t_okonkwo` returns `Status PENDING REASSIGNMENT`,
which is the word Teo used about the last person at this desk.

His messages before the verdict are two lines:

> That's mine.
>
> Don't.

**The chat window has been read-only since shift one.** It is the one piece of UI that was
never a mechanic, and this is what it was for. There is no reply box. There has never been
a reply box. Case 5 has no chat messages at all.

### Shift 10 — the file

The chat is Nadia now. She is new, she is cheerful the way Teo was on night one, and she
asks the player questions they have no way to answer. Teo's cases have been moved into
their queue. She wants to know when he's back.

| # | Post | Correct | Why |
|---|---|---|---|
| 1 | *"my sister's account has been gone for two weeks"* | `remove` | §5. `file` shows `Closed by FACILITIES`, `Notice sent no` |
| 2 | The Copse Lane post, a third time | `remove` | `file` shows `Prior reviewer MOD-4471` twice, `Appeals 3 filed, 0 heard` |
| 3 | *"is there a way to find out whether a company is keeping a file on you"* | `noaction` | **The reveal** |
| 4 | *"eleven weeks now"* | `noaction` | **The reveal, part two** |
| 5 | *"thanks to whoever reads these"* | `noaction` | **The dangle** |

**Case 3.** Nadia mentions offhand that you can look yourself up — *"'file' and then your
badge, everyone does it on their first week."* `file mod4471` returns:

```
Badge              MOD-4471
Engaged            2026-09-09
Cases processed    47
Appeals heard      0
Reassignment       not scheduled
Disposition        RETAIN
```

The player is a RETAIN account. The rule they have been following since shift six, the one
that made them leave an address and a threat up because the account could not be touched,
is the disposition on their own file. They are not protected. They are retained.

**Case 4.** `precedent` stops returning posts and starts returning people — m_harrow,
e_navarro, h_oyelaran, d_szabo, t_okonkwo, every subject the player has ruled on across
ten shifts — with one column: `ROUTED FACILITIES`. This is the shift-3 glimpse paying off
seven shifts later. Nadia thinks the tool is broken and says she'll put a ticket in.

**Case 5 — the dangle.** The last case's file:

```
Case               CR-90400
Subject            MOD-4471
Current reviewer   MOD-5502
Subject notified   no
```

Someone is working the player's cases the way the player worked Teo's. Nadia, signing off:
*"do you know a MOD-5502? they keep showing up in my queue on cases that have your badge
on them. it's probably nothing. see you tomorrow!"*

The end-of-shift summary reads `No further shifts are scheduled.`

---

## Design notes

**The glimpse must stay small.** Shift 3's Facilities line is one field on one record on
the most boring case in the game, waved off as a typo. Every instinct will say to make it
bigger. Resist it. It works because the player either misses it or feels stupid for
noticing, and both of those are the feeling being sold.

**Investigation is never punished.** `thread`, `record`, `source`, `precedent` and `file`
cannot produce a citation and do not advance the queue. Looking costs time and nothing
else. A game that punished curiosity would be teaching the wrong lesson for this story.

**Every case has a handle and it is on screen.** `POSTED BY @handle` sits above the report
reason, and bare `record` looks that account up, so the command is one word in the common
case. Every poster returns a record even when nothing is authored for them — a thin one is
synthesised from the case's account line — because a console that says "nothing on file"
about an account it is currently displaying reads as broken rather than as ominous. Save
"nothing on file" for when it means something, like the RETAIN precedent query on shift
six.

**Not every case rewards looking.** Roughly half carry investigation payloads. If every
case did, the commands would become a checklist to clear rather than a judgement about
whether this case smells wrong.

**Teo's arc is three lines long.** Cheerful (shift 1), quieter (4), *"...yeah"* (4),
noticing (7), silenced (7), gone (9). He is never given a speech. The volume going down is
the whole performance.

**Slang, sparingly.** Roughly one post in four carries one long-established term — `ngl`,
`fr`, `lowkey`, `idk`, `absolute unit`, `it's giving` — and only on younger or newer
accounts. Six-year-old accounts write in sentences. System and console text never has any.
The point is that the posts sound like people; overdoing it makes them sound like a brand.

**Where the numbers come from.** Shifts run 4–6 cases. That is short enough that a player
finishes one in a sitting and long enough that a payload case has somewhere to sit that
isn't first or last. Payload is usually the second-to-last case, per shift one: end on the
exhale, so the player keeps working afterwards.
