extends Node2D

# Achievements screen: 12 goals tracked by lifetime stats.
# Designed for the game's fixed 640x360 UI.

const UI := preload("res://ui.gd")


func _ready() -> void:
	Ya.game_ready()
	UI.make_background(self, "background_solid_grass")

	var root := UI.make_ui_layer(self, 10)

	# Заголовок
	UI.make_label(
		root,
		L.t("achievements"),
		Vector2(0, 8),
		640.0,
		24
	)

	# Прогресс достижений
	UI.make_label(
		root,
		L.t("ach_progress") % [
			Globals.achievements_done(),
			Globals.ACHIEVEMENTS.size()
		],
		Vector2(0, 38),
		640.0,
		13
	)

	# 4 достижения в каждой колонке.
	# При 12 достижениях получается 3 колонки × 4 строки.
	var per_col := 4

	for i in range(Globals.ACHIEVEMENTS.size()):
		var a: Dictionary = Globals.ACHIEVEMENTS[i]
		var id := String(a["id"])
		var done := bool(Globals.achievements.get(id, false))

		var col := int(i / per_col)
		var row := i % per_col

		# Позиция трёх колонок.
		var x := 40.0 + float(col) * 210.0

		# Более компактный вертикальный интервал.
		var y := 65.0 + float(row) * 55.0

		# Иконка достижения
		UI.make_icon(
			root,
			"star" if done else "hud_heart_empty",
			Vector2(x - 30.0, y + 2.0),
			26.0
		)

		# Название достижения
		var name_label := Label.new()
		name_label.position = Vector2(x + 40.0, y)
		name_label.size = Vector2(160.0, 22.0)
		name_label.text = L.pick(a["name"])

		UI.style_label(name_label, 14, 4)

		if not done:
			name_label.add_theme_color_override(
				"font_color",
				Color(0.75, 0.75, 0.75)
			)

		root.add_child(name_label)

		# Прогресс достижения
		var progress := Label.new()
		progress.position = Vector2(x + 40.0, y + 24.0)
		progress.size = Vector2(160.0, 18.0)

		var have := int(
			Globals.stats.get(
				String(a["stat"]),
				0
			)
		)

		progress.text = "%d / %d" % [
			mini(have, int(a["goal"])),
			int(a["goal"])
		]

		UI.style_label(progress, 12, 3)

		root.add_child(progress)

	# Кнопка "Назад"
	# UI имеет высоту 360 px, поэтому Y=420 был за пределами экрана.
	var back := UI.make_button(
		root,
		L.t("back"),
		Vector2(250.0, 305.0),
		Vector2(140.0, 38.0),
		15
	)

	back.pressed.connect(_on_back)


func _on_back() -> void:
	Sfx.play("sfx_select")
	Globals.to_menu()