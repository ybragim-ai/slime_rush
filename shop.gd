extends Node2D

# Shop: lives, boosters (paid with trophies earned for kills), hero skins and
# permanent upgrades (paid with coins). Also a rewarded-ad coin bonus.

const UI := preload("res://ui.gd")
const AdBoxScript := preload("res://adbox.gd")
const PER_PAGE := 5

var root: Control
var balance: Label
var toast: Label
var pagination_label: Label
var prev_btn: Button
var next_btn: Button
var page := 0
var rows: Array = []
var ad_box

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
	
	# ЗАГОЛОВОК
	UI.make_label(root, L.t("shop"), Vector2(0, 4), 640.0, 20)
	
	# БАЛАНС
	balance = UI.make_label(root, "", Vector2(0, 28), 640.0, 11)
	
	# КНОПКА РЕКЛАМЫ - выровнена по колонке кнопок "КУПИТЬ" (x=420, w=120)
	var ad_btn := UI.make_button(root, L.t("ad_coins"), Vector2(420, 26), Vector2(120, 24), 10)
	ad_btn.pressed.connect(func(): ad_box.ask("coins"))
	
	# TOAST
	toast = UI.make_label(root, "", Vector2(0, 310), 640.0, 12)

	# КНОПКА НАЗАД
	var back := UI.make_button(root, L.t("back"), Vector2(14, 310), Vector2(76, 26), 12)
	back.pressed.connect(_on_back)
	
	# СТРЕЛКИ И ПАГИНАЦИЯ
	prev_btn = UI.make_button(root, "<", Vector2(370, 310), Vector2(34, 26), 14)
	prev_btn.pressed.connect(_on_prev)
	
	pagination_label = UI.make_label(root, "", Vector2(406, 312), 46.0, 12)
	pagination_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	next_btn = UI.make_button(root, ">", Vector2(454, 310), Vector2(34, 26), 14)
	next_btn.pressed.connect(_on_next)

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
		var y := 58.0 + float(i) * 44.0
		
		var container := Node2D.new()
		root.add_child(container)
		
		# ИКОНКА - фиксированный бокс 24x24, текстура масштабируется внутрь
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(24, 24)
		icon.position = Vector2(28, y + 4)
		icon.size = Vector2(24, 24)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.visible = false
		container.add_child(icon)
		
		# ЗАГЛУШКА ИКОНКИ - создаётся один раз, а не каждый _refresh()
		var fallback := ColorRect.new()
		fallback.position = Vector2(28, y + 4)
		fallback.size = Vector2(24, 24)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fallback.visible = false
		container.add_child(fallback)
		
		# НАЗВАНИЕ - увеличен отступ
		var name_label := Label.new()
		name_label.position = Vector2(62, y)
		name_label.size = Vector2(340, 18)
		name_label.clip_text = true
		name_label.add_theme_font_size_override("font_size", 11)
		UI.style_label(name_label, 11, 4)
		container.add_child(name_label)
		
		# ОПИСАНИЕ - увеличен отступ
		var desc_label := Label.new()
		desc_label.position = Vector2(62, y + 19)
		desc_label.size = Vector2(340, 13)
		desc_label.clip_text = true
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.modulate = Color(0.7, 0.7, 0.7)
		UI.style_label(desc_label, 9, 3)
		container.add_child(desc_label)
		
		# КНОПКА КУПИТЬ
		var btn := UI.make_button(container, L.t("buy"), Vector2(420, y + 1), Vector2(120, 24), 10)
		
		rows.append({
			"icon": icon, 
			"fallback": fallback, 
			"name": name_label, 
			"desc": desc_label, 
			"button": btn,
			"container": container
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
	balance.text = "МОНЕТ: %d    ТРОФЕЙ: %d" % [Globals.coins, Globals.trophies]
	pagination_label.text = "%d/%d" % [page + 1, _pages()]
	
	prev_btn.disabled = (page == 0)
	next_btn.disabled = (page >= _pages() - 1)
	
	var items := _page_items()
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var icon: TextureRect = row["icon"]
		var fallback: ColorRect = row["fallback"]
		var name_label: Label = row["name"]
		var desc_label: Label = row["desc"]
		var btn: Button = row["button"]
		var container: Node2D = row["container"]
		
		if i >= items.size():
			container.visible = false
			continue
		
		container.visible = true
		var item: Dictionary = items[i]
		var id := String(item["id"])
		
		var icon_name := String(item.get("icon", "heart"))
		var icon_path := UI.TILES + icon_name + ".png"
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
			icon.visible = true
			fallback.visible = false
		else:
			icon.texture = null
			icon.visible = false
			fallback.color = ICON_COLORS.get(icon_name, Color(0.5, 0.5, 0.5))
			fallback.visible = true
		
		var currency := String(item["currency"])
		var unit := "ТР" if currency == "trophies" else "МН"
		var suffix := ""
		if String(item["kind"]) == "booster":
			suffix = " x%d" % int(Globals.inventory.get(id, 0))
		
		name_label.text = "%s - %d%s%s" % [L.pick(item["name"]), int(item["price"]), unit, suffix]
		desc_label.text = L.pick(item["desc"])
		
		btn.visible = true
		btn.disabled = false
		
		var kind := String(item["kind"])
		if (kind == "skin" or kind == "upgrade") and Globals.owned.get(id, false):
			if kind == "skin":
				var equipped := Globals.skin == String(item.get("skin", ""))
				btn.text = "НАДЕТО" if equipped else "НАДЕТЬ"
				btn.disabled = equipped
			else:
				btn.text = "КУПЛЕНО"
				btn.disabled = true
		else:
			btn.text = "КУПИТЬ"
		
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
			toast.text = "КУПЛЕНО!"
		"no_money":
			Sfx.play("sfx_bump")
			toast.text = "НЕТ СРЕДСТВ"
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
	toast.text = "РЕКЛАМА ПОСМОТРЕНА!"
	_refresh()

func _on_back() -> void:
	Sfx.play("sfx_select")
	Globals.to_menu()