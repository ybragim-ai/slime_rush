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

func _ready() -> void:
	Ya.game_ready()
	UI.make_background(self, "background_solid_sky")
	root = UI.make_ui_layer(self, 10)
	UI.make_label(root, L.t("shop"), Vector2(0, 8), 640.0, 24)
	balance = UI.make_label(root, "", Vector2(0, 40), 640.0, 13)
	toast = UI.make_label(root, "", Vector2(0, 300), 640.0, 14)

	var back := UI.make_button(root, L.t("back"), Vector2(14, 320), Vector2(130, 32), 14)
	back.pressed.connect(_on_back)
	var prev := UI.make_button(root, "<", Vector2(400, 320), Vector2(48, 32), 16)
	prev.pressed.connect(_on_prev)
	var next := UI.make_button(root, ">", Vector2(456, 320), Vector2(48, 32), 16)
	next.pressed.connect(_on_next)
	var ad_btn := UI.make_button(root, L.t("ad_coins"), Vector2(440, 40), Vector2(186, 30), 12)
	ad_btn.pressed.connect(func(): ad_box.ask("coins"))

	_build_rows()
	ad_box = AdBoxScript.new()
	add_child(ad_box)
	Ya.rewarded.connect(_on_rewarded)
	Globals.hud_changed.connect(_refresh)
	_refresh()

func _build_rows() -> void:
	for i in range(PER_PAGE):
		var y := 72.0 + float(i) * 44.0
		var icon := UI.make_icon(root, "hud_coin", Vector2(18, y + 4), 32.0)
		var name_label := Label.new()
		name_label.position = Vector2(60, y)
		name_label.size = Vector2(340, 20)
		UI.style_label(name_label, 14, 4)
		root.add_child(name_label)
		var desc_label := Label.new()
		desc_label.position = Vector2(60, y + 20)
		desc_label.size = Vector2(360, 16)
		UI.style_label(desc_label, 11, 3)
		root.add_child(desc_label)
		var btn := UI.make_button(root, L.t("buy"), Vector2(452, y + 2), Vector2(170, 34), 14)
		rows.append({"icon": icon, "name": name_label, "desc": desc_label, "button": btn})

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
	balance.text = "%s: %d    %s: %d    %d/%d" % [L.t("coins"), Globals.coins, L.t("trophies"), Globals.trophies, page + 1, _pages()]
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
		icon.visible = true
		icon.texture = load(UI.TILES + String(item["icon"]) + ".png")
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
