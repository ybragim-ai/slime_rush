extends Node2D

# Game over screen. A rewarded video can grant one extra life and continue the
# current level - the player must confirm it explicitly (checklist 4.5).

const UI := preload("res://ui.gd")
const AdBoxScript := preload("res://adbox.gd")

var toast: Label
var ad_box

func _ready() -> void:
	Ya.gameplay_stop()
	Ya.show_ad()
	UI.make_background(self, "background_solid_dirt")
	var root := UI.make_ui_layer(self, 10)
	UI.make_label(root, L.t("game_over"), Vector2(0, 60), 640.0, 34)
	UI.make_label(root, "%s: %d    %s: %d" % [L.t("coins"), Globals.coins, L.t("trophies"), Globals.trophies], Vector2(0, 108), 640.0, 14)
	toast = UI.make_label(root, "", Vector2(0, 132), 640.0, 13)

	var ad_btn := UI.make_button(root, L.t("ad_life"), Vector2(170, 156), Vector2(300, 38), 15)
	ad_btn.pressed.connect(func(): ad_box.ask("life"))
	var retry := UI.make_button(root, L.t("restart"), Vector2(170, 202), Vector2(300, 36), 15)
	retry.pressed.connect(_on_retry)
	var shop_btn := UI.make_button(root, L.t("shop"), Vector2(170, 244), Vector2(300, 36), 15)
	shop_btn.pressed.connect(_on_shop)
	var menu_btn := UI.make_button(root, L.t("to_menu"), Vector2(170, 286), Vector2(300, 36), 15)
	menu_btn.pressed.connect(_on_menu)

	ad_box = AdBoxScript.new()
	add_child(ad_box)
	Ya.rewarded.connect(_on_rewarded)

func _on_rewarded(tag: String) -> void:
	Globals.grant_reward(tag)
	Sfx.play("sfx_gem")
	toast.text = L.t("reward_done")
	Globals.lives = maxi(1, Globals.lives)
	get_tree().change_scene_to_file("res://game.tscn")

func _on_retry() -> void:
	Sfx.play("sfx_select")
	Globals.restart_level()

func _on_shop() -> void:
	Sfx.play("sfx_select")
	get_tree().change_scene_to_file("res://shop.tscn")

func _on_menu() -> void:
	Sfx.play("sfx_select")
	Globals.to_menu()
