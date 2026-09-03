extends Node2D

# Victory screen after the last level.

const UI := preload("res://ui.gd")

func _ready() -> void:
	Ya.gameplay_stop()
	Ya.game_ready()
	UI.make_background(self, "background_color_mushrooms")
	var root := UI.make_ui_layer(self, 10)
	UI.make_label(root, L.t("victory"), Vector2(0, 80), 640.0, 40)
	UI.make_label(root, L.t("victory_sub") % [Globals.MAX_LEVEL, Globals.coins, Globals.trophies], Vector2(0, 140), 640.0, 14)
	UI.make_label(root, L.t("ach_progress") % [Globals.achievements_done(), Globals.ACHIEVEMENTS.size()], Vector2(0, 164), 640.0, 13)

	var shop_btn := UI.make_button(root, L.t("shop"), Vector2(170, 200), Vector2(300, 36), 15)
	shop_btn.pressed.connect(_on_shop)
	var menu_btn := UI.make_button(root, L.t("to_menu"), Vector2(170, 244), Vector2(300, 36), 15)
	menu_btn.pressed.connect(_on_menu)
	Sfx.play("sfx_magic")

func _on_shop() -> void:
	Sfx.play("sfx_select")
	get_tree().change_scene_to_file("res://shop.tscn")

func _on_menu() -> void:
	Sfx.play("sfx_select")
	Globals.to_menu()
