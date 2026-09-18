extends Node

# -- Player preferences --
# Deliberately a SEPARATE file from progress.cfg. GameState.reset() rewrites
# that one wholesale, and its SAVE_VERSION guard throws the whole file away on
# a mismatch -- neither should ever cost somebody their volume settings.
#
# Registered in project.godot ABOVE GameState and MusicPlayer: autoloads
# initialise top to bottom and MusicPlayer reads the music volume in _ready().
#
# Like GameState, no class_name: the autoload name already owns 'Settings' in
# the global namespace and declaring both is a hard parse error.

const SAVE_PATH := "user://settings.cfg"

const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"

# Below this the bus is muted outright -- linear_to_db(0.0) is -inf.
const SILENCE := 0.0005

enum WindowMode { WINDOWED, MAXIMIZED, FULLSCREEN }

const WINDOW_MODE_NAMES := ["WINDOWED", "MAXIMIZED", "FULLSCREEN"]

# 1920 is the floor, not a preference. windowsHandler tiles three windows at
# MIN_SIZE.x = 560 with 24px gutters, so the desktop needs 3*560 + 4*24 = 1776
# horizontal pixels before the columns start overlapping each other. 1600x900
# would render, and look broken.
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3200, 1800),
	Vector2i(3840, 2160),
]

# Short enough that four of them fit across the settings window at its minimum
# width; the exact pixels go in the line underneath the row.
const RESOLUTION_NAMES := ["1080P", "1440P", "1800P", "4K"]

# Seconds per character. caseHandler's three typing functions used to hardcode
# 0.02, which is NORMAL here; every other delay in them is a multiple of it, so
# this one scalar still controls the whole effect. 0.0 means "no wait at all",
# which the typing functions special-case into an immediate reveal.
const TEXT_SPEED_NAMES := ["SLOW", "NORMAL", "FAST", "INSTANT"]
const TEXT_SPEEDS := [0.045, 0.02, 0.008, 0.0]

# Pause between consecutive chat messages. Typing faster but still waiting a
# full 1.2s between lines would feel broken, so this tracks the speed setting.
const MESSAGE_GAPS := [1.6, 1.2, 0.6, 0.1]

#-- Emitted after any setting changes, so every open view can re-read state
#   instead of each caller having to know who is listening. --
signal changed

# A volume slider fires value_changed on every step of a drag. Rewriting the
# file each time would be dozens of disk writes per gesture, so writes are
# coalesced; the signal still goes out immediately.
const SAVE_DEBOUNCE := 0.4
var _save_queued := false

var master_volume := 0.8
var music_volume := 0.6
var sfx_volume := 0.7

var window_mode: int = WindowMode.MAXIMIZED
var resolution_index := 0
var text_speed_index := 1


func _ready() -> void:
	_ensure_buses()
	load_settings()
	apply_audio()
	apply_display()

# ---------------------------------------------------------------- audio

#-- No default_bus_layout.tres ships with the project and project.godot has no
#   [audio] section, so Master is the only bus that exists at boot. Build the
#   other two here rather than adding a resource file just to hold two rows. --
func _ensure_buses() -> void:
	for bus in [BUS_MUSIC, BUS_SFX]:
		if AudioServer.get_bus_index(bus) != -1:
			continue
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus)
		AudioServer.set_bus_send(idx, BUS_MASTER)

func apply_audio() -> void:
	_apply_bus(BUS_MASTER, master_volume)
	_apply_bus(BUS_MUSIC, music_volume)
	_apply_bus(BUS_SFX, sfx_volume)

#-- Volumes are stored 0.0-1.0 linear and converted on the way out. Storing dB
#   would make a slider non-linear and 'off' unrepresentable. --
func _apply_bus(bus: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	var v := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(idx, v <= SILENCE)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, SILENCE)))

func set_volume(bus: StringName, linear: float) -> void:
	var v := clampf(linear, 0.0, 1.0)
	match bus:
		BUS_MASTER: master_volume = v
		BUS_MUSIC: music_volume = v
		BUS_SFX: sfx_volume = v
		_: return
	_apply_bus(bus, v)
	_commit()

func get_volume(bus: StringName) -> float:
	match bus:
		BUS_MASTER: return master_volume
		BUS_MUSIC: return music_volume
		BUS_SFX: return sfx_volume
	return 1.0

# ---------------------------------------------------------------- display

func resolution() -> Vector2i:
	return RESOLUTIONS[clampi(resolution_index, 0, RESOLUTIONS.size() - 1)]

#-- Whether a resolution can actually be shown on this machine. Offering one
#   larger than the monitor would put the window's own edges off-screen, so the
#   settings row greys those out. Index 0 always stays available -- something
#   has to be selectable, and it is what project.godot already asks for. --
func fits_screen(index: int) -> bool:
	if index <= 0 or _is_headless():
		return true
	var want := RESOLUTIONS[clampi(index, 0, RESOLUTIONS.size() - 1)]
	var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()).size
	return want.x <= usable.x and want.y <= usable.y

#-- True while nothing can be shown: --headless has a DisplayServer, but every
#   window call on it is a no-op and screen_get_usable_rect() is meaningless. --
func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless"

func apply_display() -> void:
	if _is_headless():
		return
	match window_mode:
		WindowMode.FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		WindowMode.MAXIMIZED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(resolution())
			_centre_window()

func _centre_window() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var win := DisplayServer.window_get_size()
	DisplayServer.window_set_position(usable.position + (usable.size - win) / 2)

func set_window_mode(mode: int) -> void:
	window_mode = clampi(mode, 0, WINDOW_MODE_NAMES.size() - 1)
	apply_display()
	_commit()

func set_resolution_index(i: int) -> void:
	resolution_index = clampi(i, 0, RESOLUTIONS.size() - 1)
	# Only the windowed mode has a size of its own to set; the other two take
	# whatever the screen is. Store the choice anyway so it is there on the way
	# back to windowed.
	if window_mode == WindowMode.WINDOWED:
		apply_display()
	_commit()

# ---------------------------------------------------------------- text speed

func type_speed() -> float:
	return TEXT_SPEEDS[clampi(text_speed_index, 0, TEXT_SPEEDS.size() - 1)]

func message_gap() -> float:
	return MESSAGE_GAPS[clampi(text_speed_index, 0, MESSAGE_GAPS.size() - 1)]

func set_text_speed_index(i: int) -> void:
	text_speed_index = clampi(i, 0, TEXT_SPEEDS.size() - 1)
	_commit()

# ---------------------------------------------------------------- persistence

#-- Announce now, write shortly. --
func _commit() -> void:
	changed.emit()
	if _save_queued:
		return
	_save_queued = true
	await get_tree().create_timer(SAVE_DEBOUNCE).timeout
	if _save_queued:
		save()

#-- Quitting inside the debounce window must not cost the player the change. --
func _exit_tree() -> void:
	if _save_queued:
		save()

#-- No version field on purpose. Every read below has a default, so a file
#   written by an older build loses nothing but the keys it never had. --
func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("display", "window_mode", window_mode)
	cfg.set_value("display", "resolution_index", resolution_index)
	cfg.set_value("text", "speed_index", text_speed_index)
	cfg.save(SAVE_PATH)
	_save_queued = false

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	master_volume = clampf(float(cfg.get_value("audio", "master", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value("audio", "music", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx", sfx_volume)), 0.0, 1.0)
	window_mode = clampi(int(cfg.get_value("display", "window_mode", window_mode)), 0, WINDOW_MODE_NAMES.size() - 1)
	resolution_index = clampi(int(cfg.get_value("display", "resolution_index", resolution_index)), 0, RESOLUTIONS.size() - 1)
	text_speed_index = clampi(int(cfg.get_value("text", "speed_index", text_speed_index)), 0, TEXT_SPEEDS.size() - 1)
