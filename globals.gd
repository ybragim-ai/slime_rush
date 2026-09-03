extends Node

# Global state: progress, currencies, boosters, shop, achievements, settings.
# Saved locally (user://progress.cfg) and to the Yandex player cloud (1.9).

signal achievement_unlocked(id: String)
signal hud_changed

const SAVE_PATH := "user://progress.cfg"
const MAX_LEVEL := 12
const BASE_LIVES := 3

# --- shop catalog -----------------------------------------------------------
# kind: booster | life | skin | upgrade ; currency: coins | trophies
const SHOP := [
	{
		"id": "life",
		"kind": "life",
		"price": 60,
		"currency": "coins",
		"icon": "hud_heart",
		"name": {"ru": "+1 жизнь", "en": "+1 life"},
		"desc": {"ru": "Запасная жизнь в текущий забег", "en": "Extra life for the next run"},
	},
	{
		"id": "star",
		"kind": "booster",
		"price": 8,
		"currency": "trophies",
		"icon": "star",
		"name": {"ru": "Звезда: бессмертие 8 сек", "en": "Star: 8s invincibility"},
		"desc": {"ru": "Враги гибнут от касания", "en": "Enemies die on contact"},
	},
	{
		"id": "jump",
		"kind": "booster",
		"price": 5,
		"currency": "trophies",
		"icon": "spring",
		"name": {"ru": "Пружина: прыжок +40%", "en": "Spring: +40% jump"},
		"desc": {"ru": "Действует 20 секунд", "en": "Lasts 20 seconds"},
	},
	{
		"id": "grow",
		"kind": "booster",
		"price": 6,
		"currency": "trophies",
		"icon": "mushroom_red",
		"name": {"ru": "Гриб: рост", "en": "Mushroom: grow"},
		"desc": {"ru": "Первый удар только уменьшает, жизнь не теряется", "en": "First hit only shrinks you"},
	},
	{
		"id": "gun",
		"kind": "booster",
		"price": 10,
		"currency": "trophies",
		"icon": "fireball",
		"name": {"ru": "Огнемет: 12 выстрелов", "en": "Blaster: 12 shots"},
		"desc": {"ru": "Клавиша J или кнопка на экране", "en": "Key J or the on-screen button"},
	},
	{
		"id": "skin_beige",
		"kind": "skin",
		"price": 150,
		"currency": "coins",
		"icon": "hud_player_beige",
		"skin": "beige",
		"name": {"ru": "Герой: песочный", "en": "Hero: beige"},
		"desc": {"ru": "Внешний вид", "en": "Cosmetic skin"},
	},
	{
		"id": "skin_pink",
		"kind": "skin",
		"price": 250,
		"currency": "coins",
		"icon": "hud_player_pink",
		"skin": "pink",
		"name": {"ru": "Герой: розовый", "en": "Hero: pink"},
		"desc": {"ru": "Внешний вид", "en": "Cosmetic skin"},
	},
	{
		"id": "skin_purple",
		"kind": "skin",
		"price": 400,
		"currency": "coins",
		"icon": "hud_player_purple",
		"skin": "purple",
		"name": {"ru": "Герой: фиолетовый", "en": "Hero: purple"},
		"desc": {"ru": "Внешний вид", "en": "Cosmetic skin"},
	},
	{
		"id": "up_lives",
		"kind": "upgrade",
		"price": 300,
		"currency": "coins",
		"icon": "hud_heart_half",
		"name": {"ru": "Навсегда: 4 жизни на старте", "en": "Permanent: start with 4 lives"},
		"desc": {"ru": "Действует в каждом забеге", "en": "Applies to every run"},
	},
	{
		"id": "up_magnet",
		"kind": "upgrade",
		"price": 220,
		"currency": "coins",
		"icon": "gem_blue",
		"name": {"ru": "Магнит монет", "en": "Coin magnet"},
		"desc": {"ru": "Монеты притягиваются с расстояния", "en": "Coins are pulled toward you"},
	},
	{
		"id": "up_start_grow",
		"kind": "upgrade",
		"price": 18,
		"currency": "trophies",
		"icon": "mushroom_brown",
		"name": {"ru": "Старт в большой форме", "en": "Start big"},
		"desc": {"ru": "Каждый уровень начинается с ростом", "en": "Every level starts grown"},
	},
]

# --- achievements -----------------------------------------------------------
const ACHIEVEMENTS := [
	{"id": "first_level", "stat": "levels_done", "goal": 1, "name": {"ru": "Первый шаг", "en": "First step"}},
	{"id": "kills_10", "stat": "kills", "goal": 10, "name": {"ru": "Дезинсектор", "en": "Exterminator"}},
	{"id": "kills_50", "stat": "kills", "goal": 50, "name": {"ru": "Гроза слизней", "en": "Slime bane"}},
	{"id": "kills_200", "stat": "kills", "goal": 200, "name": {"ru": "Легенда охоты", "en": "Hunting legend"}},
	{"id": "coins_100", "stat": "coins_total", "goal": 100, "name": {"ru": "Копилка", "en": "Piggy bank"}},
	{"id": "coins_500", "stat": "coins_total", "goal": 500, "name": {"ru": "Золотой запас", "en": "Gold reserve"}},
	{"id": "boss_1", "stat": "bosses", "goal": 1, "name": {"ru": "Босс повержен", "en": "Boss down"}},
	{"id": "boss_all", "stat": "bosses", "goal": 4, "name": {"ru": "Все боссы", "en": "All bosses"}},
	{"id": "clean_level", "stat": "clean_levels", "goal": 1, "name": {"ru": "Без царапины", "en": "Flawless"}},
	{"id": "boosters_5", "stat": "boosters_used", "goal": 5, "name": {"ru": "Алхимик", "en": "Alchemist"}},
	{"id": "shopper", "stat": "purchases", "goal": 1, "name": {"ru": "Первая покупка", "en": "First purchase"}},
	{"id": "finish_game", "stat": "levels_done", "goal": 12, "name": {"ru": "Герой Slime Rush", "en": "Slime Rush hero"}},
]

var level := 1
var unlocked := 1
var lives := BASE_LIVES
var coins := 0
var trophies := 0
var sound_on := true
var skin := "green"
var owned: Dictionary = {}
var inventory: Dictionary = {"star": 0, "jump": 0, "grow": 0, "gun": 0}
var stats: Dictionary = {
	"kills": 0,
	"coins_total": 0,
	"levels_done": 0,
	"bosses": 0,
	"clean_levels": 0,
	"boosters_used": 0,
	"purchases": 0,
	"deaths": 0,
}
var achievements: Dictionary = {}
var bonus_lives := 0

func _ready() -> void:
	load_progress()

func start_lives() -> int:
	var base := BASE_LIVES
	if owned.get("up_lives", false):
		base += 1
	return base + bonus_lives

# --- save / load ------------------------------------------------------------

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		_apply(cfg.get_value("save", "data", {}))
	var cloud := Ya.load_cloud()
	if cloud.has("unlocked") and int(cloud.get("unlocked", 0)) >= unlocked:
		_apply(cloud)
	unlocked = clampi(unlocked, 1, MAX_LEVEL)
	level = unlocked

func _apply(raw) -> void:
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var d: Dictionary = raw
	unlocked = int(d.get("unlocked", unlocked))
	coins = int(d.get("coins", coins))
	trophies = int(d.get("trophies", trophies))
	sound_on = bool(d.get("sound", sound_on))
	skin = String(d.get("skin", skin))
	bonus_lives = int(d.get("bonus_lives", bonus_lives))
	if typeof(d.get("owned")) == TYPE_DICTIONARY:
		owned = d["owned"]
	if typeof(d.get("inventory")) == TYPE_DICTIONARY:
		for key in inventory.keys():
			inventory[key] = int(d["inventory"].get(key, inventory[key]))
	if typeof(d.get("stats")) == TYPE_DICTIONARY:
		for key in stats.keys():
			stats[key] = int(d["stats"].get(key, stats[key]))
	if typeof(d.get("achievements")) == TYPE_DICTIONARY:
		achievements = d["achievements"]

func _payload() -> Dictionary:
	return {
		"unlocked": unlocked,
		"coins": coins,
		"trophies": trophies,
		"sound": sound_on,
		"skin": skin,
		"bonus_lives": bonus_lives,
		"owned": owned,
		"inventory": inventory,
		"stats": stats,
		"achievements": achievements,
	}

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "data", _payload())
	cfg.save(SAVE_PATH)
	Ya.save_cloud(_payload())

# --- settings ---------------------------------------------------------------

func toggle_sound() -> void:
	sound_on = not sound_on
	Sfx.refresh()
	save_progress()

func reset_progress() -> void:
	unlocked = 1
	level = 1
	coins = 0
	trophies = 0
	skin = "green"
	bonus_lives = 0
	owned = {}
	achievements = {}
	for key in inventory.keys():
		inventory[key] = 0
	for key in stats.keys():
		stats[key] = 0
	save_progress()

# --- currencies and events --------------------------------------------------

func add_coins(amount: int) -> void:
	coins += amount
	stats["coins_total"] = int(stats["coins_total"]) + amount
	check_achievements()
	hud_changed.emit()

func add_kill(is_boss := false) -> void:
	var gain := 5 if is_boss else 1
	trophies += gain
	stats["kills"] = int(stats["kills"]) + 1
	if is_boss:
		stats["bosses"] = int(stats["bosses"]) + 1
	check_achievements()
	hud_changed.emit()

func add_booster(id: String, amount := 1) -> void:
	if inventory.has(id):
		inventory[id] = int(inventory[id]) + amount
		hud_changed.emit()

func use_booster(id: String) -> bool:
	if int(inventory.get(id, 0)) <= 0:
		return false
	inventory[id] = int(inventory[id]) - 1
	stats["boosters_used"] = int(stats["boosters_used"]) + 1
	check_achievements()
	hud_changed.emit()
	return true

func currency(kind: String) -> int:
	return trophies if kind == "trophies" else coins

func spend(kind: String, amount: int) -> bool:
	if currency(kind) < amount:
		return false
	if kind == "trophies":
		trophies -= amount
	else:
		coins -= amount
	return true

func shop_item(id: String) -> Dictionary:
	for item in SHOP:
		if String(item["id"]) == id:
			return item
	return {}

func buy(id: String) -> String:
	var item := shop_item(id)
	if item.is_empty():
		return "error"
	var kind := String(item["kind"])
	if (kind == "skin" or kind == "upgrade") and owned.get(id, false):
		return "owned"
	if not spend(String(item["currency"]), int(item["price"])):
		return "no_money"
	match kind:
		"life":
			bonus_lives += 1
		"booster":
			add_booster(id, 1)
		"skin":
			owned[id] = true
			skin = String(item.get("skin", "green"))
		"upgrade":
			owned[id] = true
	stats["purchases"] = int(stats["purchases"]) + 1
	check_achievements()
	save_progress()
	hud_changed.emit()
	return "ok"

func equip_skin(id: String) -> void:
	var item := shop_item(id)
	if item.is_empty():
		return
	if not owned.get(id, false):
		return
	skin = String(item.get("skin", "green"))
	save_progress()

func check_achievements() -> void:
	for a in ACHIEVEMENTS:
		var id := String(a["id"])
		if achievements.get(id, false):
			continue
		if int(stats.get(String(a["stat"]), 0)) >= int(a["goal"]):
			achievements[id] = true
			achievement_unlocked.emit(id)

func achievement_name(id: String) -> String:
	for a in ACHIEVEMENTS:
		if String(a["id"]) == id:
			return L.pick(a["name"])
	return id

func achievements_done() -> int:
	var count := 0
	for a in ACHIEVEMENTS:
		if achievements.get(String(a["id"]), false):
			count += 1
	return count

# --- flow -------------------------------------------------------------------

func start_level(n: int) -> void:
	level = clampi(n, 1, MAX_LEVEL)
	lives = start_lives()
	bonus_lives = 0
	unlocked = maxi(unlocked, level)
	save_progress()
	get_tree().change_scene_to_file("res://game.tscn")

func restart_level() -> void:
	lives = start_lives()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://game.tscn")

func level_done(no_damage: bool) -> void:
	stats["levels_done"] = int(stats["levels_done"]) + 1
	if no_damage:
		stats["clean_levels"] = int(stats["clean_levels"]) + 1
	check_achievements()

func next_level() -> void:
	get_tree().paused = false
	if level >= MAX_LEVEL:
		save_progress()
		get_tree().change_scene_to_file("res://win.tscn")
		return
	level += 1
	unlocked = maxi(unlocked, level)
	save_progress()
	Ya.show_ad()
	get_tree().change_scene_to_file("res://game.tscn")

func game_over() -> void:
	get_tree().paused = false
	stats["deaths"] = int(stats["deaths"]) + 1
	save_progress()
	get_tree().change_scene_to_file("res://gameover.tscn")

func to_menu() -> void:
	get_tree().paused = false
	save_progress()
	get_tree().change_scene_to_file("res://menu.tscn")

func toggle_fullscreen() -> void:
	Sfx.play("sfx_select")
	if Ya.is_web():
		Ya.fullscreen()
		return
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func grant_reward(tag: String) -> void:
	match tag:
		"coins":
			add_coins(75)
		"life":
			bonus_lives += 1
			lives += 1
		"booster":
			add_booster("star", 1)
	save_progress()
	hud_changed.emit()
