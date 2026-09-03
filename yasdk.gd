extends Node

# Yandex.Games SDK bridge.
# On desktop every call is a safe no-op, so the same build runs locally and in
# the browser. JS helpers (window.nl*) are injected into index.html by
# _bin/patch_yandex.ps1 from web/yandex_snippet.html.

signal external_pause(active: bool)
signal rewarded(tag: String)

var js = null
var ready_sent := false
var poll_t := 0.0
var paused_externally := false
var pending_reward := ""

func _ready() -> void:
	if Engine.has_singleton("JavaScriptBridge"):
		js = Engine.get_singleton("JavaScriptBridge")

func is_web() -> bool:
	return js != null and OS.has_feature("web")

func _eval(code: String):
	if not is_web():
		return null
	return js.call("eval", code, true)

func _process(delta: float) -> void:
	if pending_reward != "":
		var tag := pending_reward
		pending_reward = ""
		rewarded.emit(tag)
	if not is_web():
		return
	poll_t += delta
	if poll_t < 0.25:
		return
	poll_t = 0.0
	# Ad shown or the page lost focus -> pause the game and mute audio (1.3, 4.7).
	var flag = _eval("window.nlPaused ? 1 : 0")
	var active := int(flag) == 1 if typeof(flag) != TYPE_NIL else false
	if active != paused_externally:
		paused_externally = active
		external_pause.emit(active)
	var reward = _eval("window.nlTakeReward ? window.nlTakeReward() : ''")
	if typeof(reward) == TYPE_STRING and String(reward) != "":
		rewarded.emit(String(reward))

# Requirement 1.19.2 (Game Ready API): called once the game is ready to play.
func game_ready() -> void:
	if ready_sent:
		return
	ready_sent = true
	_eval("window.nlReady && window.nlReady();")

func get_lang() -> String:
	var raw = _eval("window.nlLang ? window.nlLang() : ''")
	if typeof(raw) == TYPE_STRING:
		return String(raw)
	return ""

# Interstitial ad. Only between levels and on game over, never during gameplay (4.4).
func show_ad() -> void:
	_eval("window.nlAd && window.nlAd();")

# Rewarded video. Always called after an explicit user confirmation (4.5).
func show_rewarded(tag: String) -> void:
	if not is_web():
		pending_reward = tag
		return
	_eval("window.nlRewarded && window.nlRewarded('%s');" % tag)

func gameplay_start() -> void:
	_eval("window.nlGameplayStart && window.nlGameplayStart();")

func gameplay_stop() -> void:
	_eval("window.nlGameplayStop && window.nlGameplayStop();")

func fullscreen() -> void:
	_eval("window.nlFullscreen && window.nlFullscreen();")

func save_cloud(payload: Dictionary) -> void:
	var text := JSON.stringify(payload)
	text = text.replace("\\", "\\\\").replace("'", "\\'")
	_eval("window.nlSave && window.nlSave('%s');" % text)

func load_cloud() -> Dictionary:
	var raw = _eval("window.nlLoad ? window.nlLoad() : ''")
	if typeof(raw) != TYPE_STRING:
		return {}
	var text := String(raw)
	if text.is_empty() or text == "null":
		return {}
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
