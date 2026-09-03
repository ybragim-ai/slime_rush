extends Node2D

# Achievements screen: 12 goals tracked by lifetime stats.

const UI := preload("res://ui.gd")

func _ready() -> void:
	Ya.game_ready()
	UI.make_background(self, "background_solid_grass")
	var root := UI.make_ui_layer(self, 10)
	UI.make_label(root, L.t("achievements"), Vector2(0, 8), 640.0, 24)
	UI.make_label(root, L.t("ach_progress") % [Globals.achievements_done(), Globals.ACHIEVEMENTS.size()], Vector2(0, 38), 640.0, 13)

	var per_col := 6
	for i in range(Globals.ACHIEVEMENTS.size()):
		var a: Dictionary = Globals.ACHIEVEMENTS[i]
		var id := String(a["id"])
		var done := bool(Globals.achievements.get(id, false))
		var col := int(i / per_col)
		var row := i % per_col
		var x := 20.0 + float(col) * 310.0
		var y := 62.0 + float(row) * 40.0
		UI.make_icon(root, "star" if done else "hud_heart_empty", Vector2(x, y + 2), 26.0)
		var name_label := Label.new()
		name_label.position = Vector2(x + 32.0, y)
		name_label.size = Vector2(260, 18)
		name_label.text = L.pick(a["name"])
		UI.style_label(name_label, 13, 4)
		if not done:
			name_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		root.add_child(name_label)
		var progress := Label.new()
		progress.position = Vector2(x + 32.0, y + 18.0)
		progress.size = Vector2(260, 16)
		var have := int(Globals.stats.get(String(a["stat"]), 0))
		progress.text = "%d / %d" % [mini(have, int(a["goal"])), int(a["goal"])]
		UI.style_label(progress, 11, 3)
		root.add_child(progress)

	var back := UI.make_button(root, L.t("back"), Vector2(250, 316), Vector2(140, 34), 15)
	back.pressed.connect(_on_back)

func _on_back() -> void:
	Sfx.play("sfx_select")
	Globals.to_menu()
