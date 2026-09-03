extends Node2D

# Shop: lives, boosters (paid with trophies earned for kills), hero skins and
# permanent upgrades (paid with coins). Also a rewarded-ad coin bonus.

const UI := preload("res://ui.gd")
const AdBoxScript := preload("res://adbox.gd")
const PER_PAGE := 5

var root: Control
var balance: Label
var toast: Label
var page := 0
var rows: Array = []
var ad_box
var items_container: VBoxContainer
var pagination_label: Label
var prev_btn: Button
var next_btn: Button

const ICON_COLORS := {
	"heart": Color(0.906, 0.298, 0.235),
	"star": Color(0.945, 0.769, 0.0),
	"spring": Color(0.204, 0.584, 0.839),
	"mushroom": Color(0.753, 0.224, 0.169),
	"flamethrower": Color(0.902, 0.494, 0.133)
}


func _ready() -> void:
	Ya.game_ready()
	UI.make_background(self, "background_solid_sky")
	root = UI.make_ui_layer(self, 10)
	
	# Настройка root для правильного позиционирования
	var viewport_size := get_viewport().get_visible_rect().size
	root.position = Vector2.ZERO
	root.size = viewport_size
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Основной вертикальный контейнер
	var main_container := VBoxContainer.new()
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.offset_left = 25
	main_container.offset_top = 10
	main_container.offset_right = -25
	main_container.offset_bottom = -10
	main_container.add_theme_constant_override("separation", 6)
	root.add_child(main_container)

	# Верхняя панель с заголовком и балансом
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 20)
	header.custom_minimum_size = Vector2(0, 45)
	main_container.add_child(header)

	var title := Label.new()
	title.text = L.t("shop")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 26)
	UI.style_label(title, 26, 5)
	header.add_child(title)

	balance = Label.new()
	balance.text = ""
	balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	balance.custom_minimum_size = Vector2(180, 30)
	balance.add_theme_font_size_override("font_size", 13)
	UI.style_label(balance, 13, 4)
	header.add_child(balance)

	# Кнопка рекламы
	var ad_container := HBoxContainer.new()
	ad_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ad_container.alignment = BoxContainer.ALIGNMENT_END
	ad_container.custom_minimum_size = Vector2(0, 30)
	main_container.add_child(ad_container)

	var ad_btn := Button.new()
	ad_btn.text = L.t("ad_coins")
	ad_btn.custom_minimum_size = Vector2(140, 28)
	ad_btn.add_theme_font_size_override("font_size", 12)
	ad_container.add_child(ad_btn)
	ad_btn.pressed.connect(func(): ad_box.ask("coins"))

	# КОНТЕЙНЕР С ПРОКРУТКОЙ
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_container.add_child(scroll)

	# Контейнер для списка товаров (внутри скролла)
	items_container = VBoxContainer.new()
	items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_container.add_theme_constant_override("separation", 8)
	scroll.add_child(items_container)

	# Toast сообщение
	toast = Label.new()
	toast.text = ""
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.custom_minimum_size = Vector2(0, 25)
	toast.add_theme_font_size_override("font_size", 14)
	UI.style_label(toast, 14, 4)
	main_container.add_child(toast)

	# Нижняя панель с кнопками навигации
	var bottom_panel := HBoxContainer.new()
	bottom_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_panel.add_theme_constant_override("separation", 10)
	bottom_panel.custom_minimum_size = Vector2(0, 45)
	main_container.add_child(bottom_panel)

	var back := Button.new()
	back.text = L.t("back")
	back.custom_minimum_size = Vector2(100, 32)
	back.add_theme_font_size_override("font_size", 14)
	bottom_panel.add_child(back)
	back.pressed.connect(_on_back)

	prev_btn = Button.new()
	prev_btn.text = "<"
	prev_btn.custom_minimum_size = Vector2(32, 32)
	prev_btn.add_theme_font_size_override("font_size", 16)
	prev_btn.pressed.connect(_on_prev)
	bottom_panel.add_child(prev_btn)

	pagination_label = Label.new()
	pagination_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pagination_label.custom_minimum_size = Vector2(50, 32)
	pagination_label.add_theme_font_size_override("font_size", 14)
	UI.style_label(pagination_label, 14, 4)
	bottom_panel.add_child(pagination_label)

	next_btn = Button.new()
	next_btn.text = ">"
	next_btn.custom_minimum_size = Vector2(32, 32)
	next_btn.add_theme_font_size_override("font_size", 16)
	next_btn.pressed.connect(_on_next)
	bottom_panel.add_child(next_btn)

	_build_rows()

	ad_box = AdBoxScript.new()
	add_child(ad_box)
	Ya.rewarded.connect(_on_rewarded)
	Globals.hud_changed.connect(_refresh)
	_refresh()


func _build_rows() -> void:
	for row in rows:
		if row.has("container") and row["container"]:
			row["container"].queue_free()
	rows.clear()

	for i in range(PER_PAGE):
		var item_row := HBoxContainer.new()
		item_row.alignment = BoxContainer.ALIGNMENT_CENTER
		item_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_row.add_theme_constant_override("separation", 15)
		
		var row_height := 64
		item_row.custom_minimum_size = Vector2(0, row_height)
		items_container.add_child(item_row)

		# Иконка с отступом слева
		var icon_container := HBoxContainer.new()
		icon_container.custom_minimum_size = Vector2(50, 0)
		icon_container.alignment = BoxContainer.ALIGNMENT_CENTER
		item_row.add_child(icon_container)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		# В Godot 4.7 используем size вместо expand
		icon.size = Vector2(32, 32)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon_container.add_child(icon)

		# Контейнер для текста
		var text_container := VBoxContainer.new()
		text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_container.add_theme_constant_override("separation", 2)
		item_row.add_child(text_container)

		var name_label := Label.new()
		name_label.text = ""
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 14)
		UI.style_label(name_label, 14, 4)
		text_container.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = ""
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.modulate = Color(0.7, 0.7, 0.7)
		UI.style_label(desc_label, 11, 3)
		text_container.add_child(desc_label)

		# Кнопка покупки
		var btn_container := HBoxContainer.new()
		btn_container.custom_minimum_size = Vector2(140, 0)
		btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
		item_row.add_child(btn_container)

		var btn := Button.new()
		btn.text = L.t("buy")
		btn.custom_minimum_size = Vector2(120, 32)
		btn.add_theme_font_size_override("font_size", 13)
		btn_container.add_child(btn)

		rows.append({
			"icon": icon,
			"name": name_label,
			"desc": desc_label,
			"button": btn,
			"container": item_row
		})


func _page_items() -> Array:
	var items: Array = []
	var start := page * PER_PAGE
	for i in range(PER_PAGE):
		var index := start + i
		if index < Globals.SHOP.size():
			items.append(Globals.SHOP[index])
	return items


func _pages() -> int:
	return int(ceil(float(Globals.SHOP.size()) / float(PER_PAGE)))


func _refresh() -> void:
	balance.text = "%s: %d    %s: %d" % [L.t("coins"), Globals.coins, L.t("trophies"), Globals.trophies]
	pagination_label.text = "%d/%d" % [page + 1, _pages()]

	prev_btn.disabled = (page == 0)
	next_btn.disabled = (page >= _pages() - 1)

	var items := _page_items()
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var icon: TextureRect = row["icon"]
		var name_label: Label = row["name"]
		var desc_label: Label = row["desc"]
		var btn: Button = row["button"]

		if i >= items.size():
			icon.visible = false
			name_label.text = ""
			desc_label.text = ""
			btn.visible = false
			continue

		var item: Dictionary = items[i]
		var id := String(item["id"])

		# Загружаем иконку
		icon.visible = true
		var icon_path := UI.TILES + String(item.get("icon", "heart")) + ".png"
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)

		var unit := L.t("trophies") if String(item["currency"]) == "trophies" else L.t("coins")
		var suffix := ""
		if String(item["kind"]) == "booster":
			suffix = "  x%d" % int(Globals.inventory.get(id, 0))

		name_label.text = "%s  -  %d %s%s" % [L.pick(item["name"]), int(item["price"]), unit, suffix]
		desc_label.text = L.pick(item["desc"])

		btn.visible = true
		btn.disabled = false

		var kind := String(item["kind"])
		if (kind == "skin" or kind == "upgrade") and Globals.owned.get(id, false):
			if kind == "skin":
				var equipped := Globals.skin == String(item.get("skin", ""))
				btn.text = L.t("equipped") if equipped else L.t("equip")
				btn.disabled = equipped
			else:
				btn.text = L.t("owned")
				btn.disabled = true
		else:
			btn.text = L.t("buy")

		_reconnect(btn, id)


func _reconnect(btn: Button, id: String) -> void:
	for c in btn.pressed.get_connections():
		btn.pressed.disconnect(c["callable"])
	btn.pressed.connect(_on_row.bind(id))


func _on_row(id: String) -> void:
	var item := Globals.shop_item(id)
	if item.is_empty():
		return

	if String(item["kind"]) == "skin" and Globals.owned.get(id, false):
		Globals.equip_skin(id)
		Sfx.play("sfx_select")
		_refresh()
		return

	var result := Globals.buy(id)
	match result:
		"ok":
			Sfx.play("sfx_gem")
			toast.text = L.t("bought")
		"no_money":
			Sfx.play("sfx_bump")
			toast.text = L.t("no_money")
		_:
			toast.text = ""
	_refresh()


func _on_prev() -> void:
	page = (page - 1 + _pages()) % _pages()
	Sfx.play("sfx_select")
	_refresh()


func _on_next() -> void:
	page = (page + 1) % _pages()
	Sfx.play("sfx_select")
	_refresh()


func _on_rewarded(tag: String) -> void:
	Globals.grant_reward(tag)
	Sfx.play("sfx_gem")
	toast.text = L.t("reward_done")
	_refresh()


func _on_back() -> void:
	Sfx.play("sfx_select")
	Globals.to_menu()