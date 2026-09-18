extends VBoxContainer

# -- The music window's contents --
# A view and nothing else: it reads MusicPlayer and sends commands back, never
# holds playback state of its own. That is what lets the window be minimised,
# or the whole scene be thrown away on 'exit', without the music stopping.
#
# The track list is a column of flat Buttons rather than an ItemList, and the
# transport uses the TitlebarButton variation, so the only control here that
# needed new theme work is HSlider.

@onready var title_label: Label = %MusTitle
@onready var status_label: Label = %MusStatus

@onready var seek_slider: HSlider = %MusSeek
@onready var elapsed_label: Label = %MusElapsed
@onready var duration_label: Label = %MusDuration

@onready var shuffle_button: Button = %MusShuffle
@onready var prev_button: Button = %MusPrev
@onready var play_button: Button = %MusPlay
@onready var next_button: Button = %MusNext
@onready var repeat_button: Button = %MusRepeat

@onready var volume_slider: HSlider = %MusVolume
@onready var volume_value: Label = %MusVolumeValue

@onready var list_header: Label = %MusListHeader
@onready var list_box: VBoxContainer = %MusList
@onready var empty_label: Label = %MusEmpty

# True between drag_started and drag_ended on the seek bar. The _process poll
# would otherwise write the playback position straight back over the position
# the player is dragging to.
var _seeking := false

var _list_group := ButtonGroup.new()


func _ready() -> void:
	prev_button.pressed.connect(MusicPlayer.previous_track)
	play_button.pressed.connect(MusicPlayer.toggle_play)
	next_button.pressed.connect(MusicPlayer.next_track)
	repeat_button.pressed.connect(MusicPlayer.cycle_repeat)
	shuffle_button.toggled.connect(MusicPlayer.set_shuffle)

	seek_slider.min_value = 0.0
	seek_slider.max_value = 1.0
	seek_slider.step = 0.001
	seek_slider.drag_started.connect(func() -> void: _seeking = true)
	seek_slider.drag_ended.connect(_on_seek_drag_ended)
	seek_slider.value_changed.connect(_on_seek_value_changed)

	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.value_changed.connect(
		func(v: float) -> void: Settings.set_volume(Settings.BUS_MUSIC, v))

	MusicPlayer.playlist_changed.connect(_rebuild_list)
	MusicPlayer.track_changed.connect(_refresh)
	MusicPlayer.playback_changed.connect(_refresh)
	Settings.changed.connect(_refresh_volume)

	_rebuild_list()
	_refresh_volume()

func _process(_delta: float) -> void:
	if _seeking or not is_visible_in_tree():
		return
	var total := MusicPlayer.duration()
	if total <= 0.0:
		return
	var at := MusicPlayer.elapsed()
	seek_slider.set_value_no_signal(clampf(at / total, 0.0, 1.0))
	_show_times(at, total)

# ---------------------------------------------------------------- list

func _rebuild_list() -> void:
	for child in list_box.get_children():
		list_box.remove_child(child)
		child.queue_free()

	var tracks := MusicPlayer.playlist
	var empty := tracks.is_empty()
	empty_label.visible = empty
	list_header.text = "PLAYLIST — %d TRACK%s" % [tracks.size(), "" if tracks.size() == 1 else "S"]

	if empty:
		# Say where the search happened. Somebody who dropped files in the
		# wrong folder can see why nothing showed up.
		var lines := "NO AUDIO FOUND. DROP .MP3 OR .WAV FILES INTO:"
		for path in MusicPlayer.scan_report:
			# res:// is sealed inside the executable -- telling somebody to
			# put a file there is not an instruction they can act on.
			if not path.begins_with("res://"):
				lines += "\n  " + path
		empty_label.text = lines

	for i in tracks.size():
		var b := Button.new()
		b.text = "%02d  %s" % [i + 1, tracks[i]["title"]]
		b.theme_type_variation = &"TitlebarButton"
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.custom_minimum_size = Vector2(0, 30)
		b.focus_mode = Control.FOCUS_NONE
		b.toggle_mode = true
		b.button_group = _list_group   # the lit row IS the playing track
		b.pressed.connect(MusicPlayer.play_index.bind(i))
		list_box.add_child(b)

	_refresh()

# ---------------------------------------------------------------- state

func _refresh() -> void:
	var index := MusicPlayer.current_index()
	var playing := MusicPlayer.is_playing()

	title_label.text = MusicPlayer.current_title() if index >= 0 else "NOTHING QUEUED"
	status_label.text = _status_line(index, playing)

	play_button.text = "PAUSE" if playing else "PLAY"
	play_button.disabled = MusicPlayer.playlist.is_empty()
	prev_button.disabled = play_button.disabled
	next_button.disabled = play_button.disabled
	seek_slider.editable = MusicPlayer.duration() > 0.0

	shuffle_button.set_pressed_no_signal(MusicPlayer.shuffle)
	repeat_button.text = MusicPlayer.REPEAT_NAMES[MusicPlayer.repeat]

	for i in list_box.get_child_count():
		var b := list_box.get_child(i) as Button
		if b:
			b.set_pressed_no_signal(i == index)

	var total := MusicPlayer.duration()
	_show_times(MusicPlayer.elapsed() if total > 0.0 else 0.0, total)

func _status_line(index: int, playing: bool) -> String:
	if index < 0:
		return "—"
	return "%s · TRACK %d OF %d" % [
		"PLAYING" if playing else "PAUSED", index + 1, MusicPlayer.playlist.size()]

func _refresh_volume() -> void:
	volume_slider.set_value_no_signal(Settings.music_volume)
	volume_value.text = "OFF" if Settings.music_volume <= Settings.SILENCE \
		else "%d%%" % roundi(Settings.music_volume * 100.0)

func _show_times(at: float, total: float) -> void:
	elapsed_label.text = _clock(at)
	duration_label.text = _clock(total)

func _clock(seconds: float) -> String:
	var whole := maxi(int(seconds), 0)
	return "%d:%02d" % [whole / 60, whole % 60]

# ---------------------------------------------------------------- seeking

func _on_seek_drag_ended(changed: bool) -> void:
	_seeking = false
	if changed:
		MusicPlayer.seek(seek_slider.value * MusicPlayer.duration())

func _on_seek_value_changed(v: float) -> void:
	var total := MusicPlayer.duration()
	if _seeking:
		_show_times(v * total, total)   # live readout under the thumb
	else:
		MusicPlayer.seek(v * total)
