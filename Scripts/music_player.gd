extends Node

# -- Soundtrack playback --
# An autoload for the same reason GameState is one: change_scene_to_file()
# frees the whole scene, so a player that lived on the desktop would stop dead
# on 'exit' and on every clock-out. The music window is a VIEW ONLY -- it reads
# state from here and sends commands back, so minimising it or walking out to
# the main menu changes nothing about what is playing.
#
# Registered in project.godot BELOW Settings: _ready() here needs the Music bus
# to already exist.
#
# No class_name -- see the note in game_state.gd.

# Ships with the game.
const BUNDLED_DIR := "res://Assets/Music"

# Dropped in by the player. Checked in order, first folder with audio in it
# wins, and every path tried is recorded in scan_report so an empty window can
# say where it looked instead of just reading 'no tracks'.
const USER_DIRS := ["Soundtracks"]

const EXTENSIONS := ["mp3", "wav"]

enum Repeat { OFF, ALL, ONE }

const REPEAT_NAMES := ["REPEAT OFF", "REPEAT ALL", "REPEAT ONE"]

signal playlist_changed
signal track_changed
signal playback_changed

# { "title": String, "path": String, "bundled": bool }
var playlist: Array[Dictionary] = []

# Where the player looked, globalised for display. Shown when nothing was found.
var scan_report: Array[String] = []

var shuffle := false
var repeat: int = Repeat.ALL

# Indices into playlist, in the order they will be played. Shuffle permutes
# THIS rather than picking at random per track, so 'previous' is meaningful and
# nothing repeats until the list is exhausted.
var _order: Array[int] = []
var _pos := -1

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = Settings.BUS_MUSIC
	_player.finished.connect(_on_finished)
	add_child(_player)

	rescan()
	if not playlist.is_empty():
		play_index(_order[0])

# ---------------------------------------------------------------- scanning

func rescan() -> void:
	var found: Array[Dictionary] = []
	scan_report.clear()

	found.append_array(_scan_bundled())

	for dir_path in _user_dirs():
		scan_report.append(_display_path(dir_path))
		var tracks := _scan_loose(dir_path)
		if not tracks.is_empty():
			found.append_array(tracks)
			break

	playlist = found
	_rebuild_order(-1)
	playlist_changed.emit()

#-- Candidate drop folders, in priority order. The exported game is a single
#   self-contained exe, so a folder beside it is the natural place to look --
#   except that in the editor get_executable_path() is the Godot binary's own
#   directory, which is why user:// is checked too and gets created. --
func _user_dirs() -> Array[String]:
	var dirs: Array[String] = []
	var exe_dir := OS.get_executable_path().get_base_dir()
	for name in USER_DIRS:
		if exe_dir != "":
			dirs.append(exe_dir.path_join(name))
		var here := "user://".path_join(name)
		DirAccess.make_dir_recursive_absolute(here)
		dirs.append(here)
	return dirs

#-- res:// tracks are imported resources, so load() is right and load_from_file
#   is wrong. The listing differs between editor and export -- the editor shows
#   'foo.mp3' plus 'foo.mp3.import', an exported pack shows 'foo.mp3.remap' --
#   so strip either suffix, dedupe, and let ResourceLoader confirm. --
func _scan_bundled() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := DirAccess.open(BUNDLED_DIR)
	if dir == null:
		return out
	scan_report.append(BUNDLED_DIR)
	var seen := {}
	for entry in dir.get_files():
		var file_name := entry
		for suffix in [".remap", ".import"]:
			if file_name.ends_with(suffix):
				file_name = file_name.substr(0, file_name.length() - suffix.length())
		if not _is_audio(file_name) or seen.has(file_name):
			continue
		seen[file_name] = true
		var path := BUNDLED_DIR.path_join(file_name)
		if ResourceLoader.exists(path):
			out.append({"title": _title_of(file_name), "path": path, "bundled": true})
	_sort_by_title(out)
	return out

func _scan_loose(dir_path: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for file_name in dir.get_files():
		if _is_audio(file_name):
			out.append({
				"title": _title_of(file_name),
				"path": dir_path.path_join(file_name),
				"bundled": false,
			})
	_sort_by_title(out)
	return out

func _is_audio(file_name: String) -> bool:
	return file_name.get_extension().to_lower() in EXTENSIONS

#-- The filename stem IS the track title. No ID3 parsing, and renaming a file
#   is how the player retitles a track. --
func _title_of(file_name: String) -> String:
	return file_name.get_basename().replace("_", " ").strip_edges()

func _sort_by_title(tracks: Array[Dictionary]) -> void:
	tracks.sort_custom(func(a, b): return String(a["title"]).nocasecmp_to(String(b["title"])) < 0)

func _display_path(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.begins_with("user://") else path

# ---------------------------------------------------------------- play order

#-- Rebuilds the play order, optionally pinning one playlist index to the front
#   so the track that is already playing keeps playing when shuffle flips. --
func _rebuild_order(keep: int) -> void:
	_order.clear()
	for i in playlist.size():
		_order.append(i)
	if shuffle:
		_order.shuffle()
	if keep >= 0:
		var at := _order.find(keep)
		if at > 0:
			_order.remove_at(at)
			_order.insert(0, keep)
		_pos = 0
	else:
		_pos = -1 if _order.is_empty() else 0

func set_shuffle(on: bool) -> void:
	if shuffle == on:
		return
	shuffle = on
	_rebuild_order(current_index())
	playlist_changed.emit()

func cycle_repeat() -> void:
	repeat = (repeat + 1) % REPEAT_NAMES.size()
	playback_changed.emit()

# ---------------------------------------------------------------- transport

func current_index() -> int:
	if _pos < 0 or _pos >= _order.size():
		return -1
	return _order[_pos]

func current_track() -> Dictionary:
	var i := current_index()
	return playlist[i] if i >= 0 else {}

func current_title() -> String:
	var t := current_track()
	return String(t.get("title", ""))

func is_playing() -> bool:
	return _player != null and _player.playing and not _player.stream_paused

func has_track() -> bool:
	return current_index() >= 0 and _player != null and _player.stream != null

func play_index(playlist_index: int) -> void:
	if playlist_index < 0 or playlist_index >= playlist.size():
		return
	var at := _order.find(playlist_index)
	if at < 0:
		return
	_pos = at

	var stream := _load_stream(playlist[playlist_index])
	if stream == null:
		# A file that will not decode should not wedge the whole playlist:
		# drop it and move on to the next one.
		push_warning("MusicPlayer: could not load %s" % playlist[playlist_index]["path"])
		playlist.remove_at(playlist_index)
		_rebuild_order(-1)
		playlist_changed.emit()
		if not playlist.is_empty():
			play_index(_order[mini(at, _order.size() - 1)])
		return

	_player.stream = stream
	_player.stream_paused = false
	_player.play()
	track_changed.emit()
	playback_changed.emit()

func toggle_play() -> void:
	if not has_track():
		if not playlist.is_empty():
			play_index(_order[maxi(_pos, 0)])
		return
	if _player.playing:
		_player.stream_paused = not _player.stream_paused
	else:
		_player.play()
	playback_changed.emit()

func next_track() -> void:
	_step(1)

func previous_track() -> void:
	# Standard transport behaviour: more than a moment in, 'previous' restarts
	# the current track rather than skipping back.
	if elapsed() > 3.0:
		seek(0.0)
		return
	_step(-1)

func _step(delta: int) -> void:
	if _order.is_empty():
		return
	var next := _pos + delta
	if next >= _order.size():
		if shuffle:
			_rebuild_order(-1)   # fresh permutation once the list is exhausted
		next = 0
	elif next < 0:
		next = _order.size() - 1
	play_index(_order[next])

func stop() -> void:
	if _player:
		_player.stop()
	playback_changed.emit()

# ---------------------------------------------------------------- position

func duration() -> float:
	if _player == null or _player.stream == null:
		return 0.0
	return _player.stream.get_length()

func elapsed() -> float:
	if _player == null or _player.stream == null:
		return 0.0
	return _player.get_playback_position()

func seek(to: float) -> void:
	if _player == null or _player.stream == null:
		return
	if not _player.playing:
		_player.play()
	_player.seek(clampf(to, 0.0, maxf(duration() - 0.05, 0.0)))

# ---------------------------------------------------------------- internals

func _load_stream(track: Dictionary) -> AudioStream:
	var path := String(track["path"])
	if bool(track.get("bundled", false)):
		return load(path) as AudioStream
	# res:// is sealed inside the exe (binary_format/embed_pck), so loose files
	# beside it are unreachable through ResourceLoader. These two static helpers
	# read an absolute path off disk instead.
	match path.get_extension().to_lower():
		"mp3": return AudioStreamMP3.load_from_file(path)
		"wav": return AudioStreamWAV.load_from_file(path)
	return null

func _on_finished() -> void:
	match repeat:
		Repeat.ONE:
			play_index(current_index())
		Repeat.OFF:
			if _pos + 1 >= _order.size():
				playback_changed.emit()
			else:
				_step(1)
		_:
			_step(1)
