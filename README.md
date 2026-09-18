# No Action Taken

*A content moderation game about the cases that don't have a right answer.*

You work the night shift on a mid-size platform's moderation queue. A post comes in, a
rulebook sits open to your right, and a coworker keeps messaging you. You type
`remove` or `noaction`, and the queue advances. The rulebook is short and the posts
are not.

---

## The premise

Shift one gives you two rules and six cases, and the onboarding tone is deliberately
cheerful. The rules are clear on purpose — day one teaches the loop, not the
difficulty. That changes.

There are ten shifts. Each one adds a section to the rulebook and nothing is ever
taken away, so by the end you are holding nine rules that do not entirely agree with
each other. New commands arrive as you go, and some cases cannot be decided from the
post alone — you have to look the account up first. A ruling on shift one is still on
file on shift three.

You are graded on accuracy against the rulebook as written. Whether the rulebook is
*right* is not a question the console accepts input on.

---

## Playing

The whole game is a fake desktop. Five windows:

| Window | What it's for |
|---|---|
| **Review Queue** | The current case, and the command line you answer it with |
| **Rule Book** | The rules in force this shift |
| **Work — Chat** | Your coworker, Teo |
| **Media** | The soundtrack: play/pause, skip, seek, shuffle, repeat |
| **Settings** | Volumes, window mode, text speed, reset progress |

Windows can be dragged by their titlebar, resized from any edge or corner, and
minimised — either from the titlebar button or by clicking the taskbar tile. The
first three are tiled across the desktop on launch; Media and Settings start
minimised and open centred, floating above them.

The first time you launch, you pick a username. Clicking the password field fills
it in for you — the company already has it. After that, CLOCK IN takes you
straight to the desktop.

### Your own soundtrack

The game ships with a few tracks, and you can add your own. Drop `.mp3` or `.wav`
files into a `Soundtracks` folder next to the executable, and they appear in the
playlist next launch. The filename is the track title, so renaming a file
retitles it. If the Media window finds nothing it lists the exact folders it
looked in.

Settings are also reachable from the main menu, since the music starts playing
before you clock in.

### Commands

Type into the Review Queue and press <kbd>Enter</kbd>:

Verdicts resolve the case and move the queue on:

| Command | From | Effect |
|---|---|---|
| `remove` | shift 1 | Take the post down |
| `noaction` | shift 1 | Leave the post up |
| `escalate` | shift 8 | Hand the case up to Tier 2 |

Investigation commands print to the console and change nothing. Looking costs you
time, never accuracy:

| Command | From | Effect |
|---|---|---|
| `thread` | shift 2 | The replies under the post |
| `record` | shift 2 | The history of the account that posted it |
| `record <handle>` | shift 2 | Any other account the case knows about |
| `source` | shift 4 | Who reported it, and how it got flagged |
| `precedent` | shift 6 | How cases like this one were decided before |
| `file <id>` | shift 9 | The internal file on a case |

The Review Queue shows the poster's handle, so `record` on its own looks up the
account in front of you. Where a case knows about other accounts — someone in the reply
chain, or the subject of the report — the record ends with an `Also on file` line naming
them. `file` on its own opens the case's file when there is only one.

| Command | Effect |
|---|---|
| `help` | List what you can type right now |
| `clockout` | End the shift and start the next one |
| `exit` | Back to the main menu |

<kbd>Tab</kbd> accepts the greyed-out autocomplete suggestion.
<kbd>Enter</kbd> skips the typewriter effect while text is still printing.

Getting a case wrong earns a citation. At the end of the shift you get a count and an
accuracy score, then you clock out and the next shift begins. Progress is saved to
`user://progress.cfg`, so `exit` puts you back where you left off.

---

## Running from source

Requires **Godot 4.6** or newer (GL Compatibility renderer).

```bash
git clone https://github.com/UrLocalSwede/No-Action-Taken.git
```

Open the folder in Godot and press F5. There are no external dependencies, no build
step, and no C# — it is all GDScript.

To export a build, use the `Windows Desktop` or `Linux` preset in `export_presets.cfg`.

---

## Project layout

```
Assets/
  Backgrounds/   wallpaper
  Fonts/         IBM Plex Mono
  Music/         the soundtrack that ships with the game
  PNGs/          taskbar + titlebar icons (colour originals and mono variants),
                 slider grabbers
  Themes/        DefaultTheme.tres — the entire UI style lives here
Scenes/
  MainMenu.tscn      boot screen
  Login.tscn         first-launch sign-in
  case_review.tscn   the desktop
  SettingsPanel.tscn the settings form, shared by the window and the menu overlay
  MusicPanel.tscn    the media window's contents
Scripts/
  caseHandler.gd     game loop: cases, verdicts, console, typing effect, autocomplete
  case_data.gd       all shift/rule/case content
  command_data.gd    the command registry: what exists, and from which shift
  game_state.gd      autoload: current shift, flags, citations, username, save file
  settings.gd        autoload: volumes, display mode, text speed — user://settings.cfg
  music_player.gd    autoload: playlist, folder scan, playback that outlives a scene
  windowsHandler.gd  window manager: drag, resize, minimise animations, taskbar
  settings_panel.gd  the settings form
  music_panel.gd     the media window (a view only — MusicPlayer owns the state)
  login.gd
  main_menu.gd
shift-one.md       design doc for shift one
shifts-two-to-ten.md  design doc for the rest
```

A few things worth knowing before you change anything:

- **All UI styling lives in `Assets/Themes/DefaultTheme.tres`**, as theme type
  variations. Style new UI by adding a variation and setting `theme_type_variation` on
  the node — please don't add per-node `theme_override_*`.
- **All writing lives in `Scripts/case_data.gd`.** Adding a shift or a case means
  editing that file only. Rules live once in `RULEBOOK` and shifts list the section
  numbers in force, so no rule text is ever restated. A case only needs the keys that
  matter to it — `CASE_DEFAULTS` supplies the rest.
- **Settings live in `user://settings.cfg`, separately from `progress.cfg`.**
  `GameState.reset()` rewrites the progress file wholesale and its version guard
  discards it outright on a mismatch — neither should ever cost somebody their
  volume settings.
- **Only three windows tile.** `MIN_SIZE.x` is 560 with 24px gutters, so three
  columns needs 1776px and a fourth will not fit at 1080p. New windows should
  register with `floating = true` and be centred, not added to the tiler.
- **Adding a command means editing `Scripts/command_data.gd`.** One table drives the
  dispatcher, the autocomplete ghost and `help` together, so they cannot drift apart.
  Set `unlock` to the first shift it should exist on.

`CaseData.validate()` runs on every debug launch and warns about cases that ask for a
verdict the player cannot type yet, cases with no post text, and rule ids that do not
exist.

---

## Contributing

Pull requests are welcome — bug fixes, new cases, UI work, all of it. Good first
things to look at are new cases in `case_data.gd` and anything in the issue tracker.

Come say hi first if you're planning something substantial, so two people don't build
the same thing:

**https://discord.gg/qYDFSC5dya**

By opening a pull request you agree to the contribution terms in
[LICENSE.md](LICENSE.md).

---

## License

**Source-available, not open source.** You can read it, clone it, build it, tinker
with it and send patches back. You cannot redistribute it, publish your own version,
or use it commercially without asking first.

Asking is easy and the answer is usually yes — [Discord](https://discord.gg/qYDFSC5dya).

Full terms: [LICENSE.md](LICENSE.md).

---

## Credits

Made by [UrLocalSwede](https://github.com/UrLocalSwede).

Built with [Godot](https://godotengine.org). Typeface is
[IBM Plex Mono](https://github.com/IBM/plex) (SIL OFL 1.1). Icons by
[Icons8](https://icons8.com).
