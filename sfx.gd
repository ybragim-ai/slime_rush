extends Node

# Sound bank. Mutes on window focus loss and while an ad is playing
# (checklist 1.3 and 4.7).

const DIR := "res://assets/Sounds/"
const KEYS := [
	"sfx_jump",
	"sfx_jump-high",
	"sfx_coin",
	"sfx_hurt",
	"sfx_bump",
	"sfx_disappear",
	"sfx_magic",
	"sfx_select",
	"sfx_gem",
	"sfx_throw",
]

var players: Dictionary = {}
var focus_lost := false
var ad_active := false

func _ready() -> void:
	for key in KEYS:
		var stream = load(DIR + str(key) + ".ogg")
		if stream == null:
			continue
		var p := AudioStreamPlayer.new()
		p.stream = stream
		add_child(p)
		players[key] = p
	Ya.external_pause.connect(_on_external_pause)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		focus_lost = true
		_apply_mute()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		focus_lost = false
		_apply_mute()

func _on_external_pause(active: bool) -> void:
	ad_active = active
	_apply_mute()

func _apply_mute() -> void:
	var mute := focus_lost or ad_active or not Globals.sound_on
	AudioServer.set_bus_mute(0, mute)

func refresh() -> void:
	_apply_mute()

func play(key: String, volume_db := 0.0) -> void:
	if not Globals.sound_on:
		return
	if not players.has(key):
		return
	var p: AudioStreamPlayer = players[key]
	p.volume_db = volume_db
	p.play()
