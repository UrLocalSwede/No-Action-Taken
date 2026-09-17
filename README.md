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

You are graded on accuracy against the rulebook as written. Whether the rulebook is
*right* is not a question the console accepts input on.

---

## Playing

The whole game is a fake desktop. Three windows:

| Window | What it's for |
|---|---|
| **Review Queue** | The current case, and the command line you answer it with |
| **Rule Book** | The rules in force this shift |
| **Work — Chat** | Your coworker, Teo |

Windows can be dragged by their titlebar, resized from any edge or corner, and
minimised — either from the titlebar button or by clicking the taskbar tile.

### Commands

Type into the Review Queue and press <kbd>Enter</kbd>:

| Command | Effect |
|---|---|
| `remove` | Take the post down |
| `noaction` | Leave the post up |
| `exit` | Back to the main menu |

<kbd>Tab</kbd> accepts the greyed-out autocomplete suggestion.
<kbd>Enter</kbd> skips the typewriter effect while text is still printing.

Getting a case wrong earns a citation. At the end of the shift you get a count and an
accuracy score.

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
  PNGs/          taskbar + titlebar icons (colour originals and mono variants)
  Themes/        DefaultTheme.tres — the entire UI style lives here
Scenes/
  MainMenu.tscn      boot screen
  case_review.tscn   the desktop
Scripts/
  caseHandler.gd     game loop: cases, verdicts, typing effect, autocomplete
  case_data.gd       all shift/rule/case content
  windowsHandler.gd  window manager: drag, resize, minimise animations, taskbar
  main_menu.gd
shift-one.md       design doc for shift one
```

Two things worth knowing before you change anything:

- **All UI styling lives in `Assets/Themes/DefaultTheme.tres`**, as theme type
  variations. Style new UI by adding a variation and setting `theme_type_variation` on
  the node — please don't add per-node `theme_override_*`.
- **All writing lives in `Scripts/case_data.gd`.** Adding a shift or a case means
  editing that file only.

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
