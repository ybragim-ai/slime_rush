extends Node2D

# Main menu: play, level select, shop, achievements, sound, fullscreen,
# rewarded-ad bonus, reset progress.

const UI := preload("res://ui.gd")
const AdBoxScript := preload("res://adbox.gd")

var root: Control
var sound_btn: Button
var info: Label
var toast: Label
var ad_box

func _ready() -> void:
	Ya.game_ready()
	Ya.gameplay_stop()
	Sfx.refresh()
	UI.make_background(self, "background_color_hills")
	root = UI.make_ui_layer(self, 10)

	UI.make_label(root, L.t("title"), Vector2(0, 14), 640.0, 32)
	UI.make_label(root, L.t("subtitle"), Vector2(0, 52), 640.0, 12)
	info = UI.make_label(root, "", Vector2(0, 70), 640.0, 12)

	var play := UI.make_button(root, L.t("play") % Globals.unlocked, Vector2(180, 92), Vector2(280, 38), 17)
	play.pressed.connect(_on_play)

	UI.make_label(root, L.t("levels"), Vector2(0, 136), 640.0, 12)
	_build_level_buttons()

	var shop_btn := UI.make_button(root, L.t("shop"), Vector2(24, 240), Vector2(170, 36), 15)
	shop_btn.pressed.connect(_on_shop)
	var ach_btn := UI.make_button(root, L.t("achievements"), Vector2(204, 240), Vector2(212, 36), 15)
	ach_btn.pressed.connect(_on_achievements)
	var ad_btn := UI.make_button(root, L.t("ad_coins"), Vector2(426, 240), Vector2(190, 36), 14)
	ad_btn.pressed.connect(_on_ad)

	sound_btn = UI.make_button(root, _sound_text(), Vector2(24, 284), Vector2(170, 34), 14)
	sound_btn.pressed.connect(_on_sound)
	var full_btn := UI.make_button(root, L.t("fullscreen"), Vector2(204, 284), Vector2(212, 34), 14)
	full_btn.pressed.connect(Globals.toggle_fullscreen)
	var reset_btn := UI.make_button(root, L.t("reset"), Vector2(426, 284), Vector2(190, 34), 13)
	reset_btn.pressed.connect(_on_reset)

	UI.make_label(root, L.t("controls"), Vector2(0, 326), 640.0, 11)
	toast = UI.make_label(root, "", Vector2(0, 200), 640.0, 14)

	ad_box = AdBoxScript.new()
	add_child(ad_box)
	Ya.rewarded.connect(_on_rewarded)
	Globals.hud_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	info.text = L.t("progress") % [Globals.unlocked, Globals.MAX_LEVEL, Globals.coins, Globals.trophies]

func _build_level_buttons() -> void:
	var per_row := 6
	var size := Vector2(46, 32)
	var gap := 10.0
	var total_w := float(per_row) * size.x + float(per_row - 1) * gap
	var x0 := (640.0 - total_w) * 0.5
	for i in range(Globals.MAX_LEVEL):
		var level := i + 1
		var row := int(i / per_row)
		var col := i % per_row
		var pos := Vector2(x0 + float(col) * (size.x + gap), 158.0 + float(row) * (size.y + gap))
		var text := str(level)
		if level % 3 == 0:
			text = str(level) + "B"
		var b := UI.make_button(root, text, pos, size, 14)
		if level > Globals.unlocked:
			b.disabled = true
			b.tooltip_text = L.t("locked")
		else:
			b.pressed.connect(_on_level.bind(level))

func _sound_text() -> String:
	return L.t("sound_on") if Globals.sound_on else L.t("sound_off")

func _on_play() -> void:
	Sfx.play("sfx_select")
	Globals.start_level(Globals.unlocked)

func _on_level(level: int) -> void:
	Sfx.play("sfx_select")
	Globals.start_level(level)

func _on_shop() -> void:
	Sfx.play("sfx_select")
	get_tree().change_scene_to_file("res://shop.tscn")

func _on_achievements() -> void:
	Sfx.play("sfx_select")
	get_tree().change_scene_to_file("res://achievements.tscn")

func _on_ad() -> void:
	ad_box.ask("coins")

func _on_rewarded(tag: String) -> void:
	Globals.grant_reward(tag)
	Sfx.play("sfx_gem")
	toast.text = L.t("reward_done")
	_refresh()

func _on_sound() -> void:
	Globals.toggle_sound()
	sound_btn.text = _sound_text()
	Sfx.play("sfx_select")

func _on_reset() -> void:
	Globals.reset_progress()
	Sfx.play("sfx_bump")
	get_tree().reload_current_scene()
