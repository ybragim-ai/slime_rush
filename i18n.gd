extends Node

# Interface language. In the browser it comes from ysdk.environment.i18n.lang
# (checklist 2.14), on desktop from the OS locale. Fallback is Russian.

var lang := "ru"

var strings := {
	"ru": {
		"title": "SLIME RUSH",
		"subtitle": "Прыгай, топчи слизней, собирай монеты",
		"play": "ИГРАТЬ — УРОВЕНЬ %d",
		"levels": "ВЫБОР УРОВНЯ",
		"shop": "МАГАЗИН",
		"achievements": "ДОСТИЖЕНИЯ",
		"sound_on": "ЗВУК: ВКЛ",
		"sound_off": "ЗВУК: ВЫКЛ",
		"fullscreen": "НА ВЕСЬ ЭКРАН",
		"reset": "СБРОСИТЬ ПРОГРЕСС",
		"controls": "A/D или ←/→ — бег, W/Space — прыжок, J — выстрел, Esc — пауза",
		"progress": "Открыто: %d/%d    Монеты: %d    Трофеи: %d",
		"coins": "МОНЕТЫ",
		"trophies": "ТРОФЕИ",
		"lives": "ЖИЗНИ",
		"level_of": "УРОВЕНЬ %d/%d",
		"boss": "БОСС",
		"boss_hp": "БОСС: %d/%d",
		"boss_defeated": "БОСС ПОБЕЖДЁН!",
		"level_complete": "УРОВЕНЬ ПРОЙДЕН!",
		"game_over": "ИГРА ОКОНЧЕНА",
		"pause": "ПАУЗА",
		"resume": "ПРОДОЛЖИТЬ",
		"restart": "ЗАНОВО",
		"to_menu": "В МЕНЮ",
		"back": "НАЗАД",
		"victory": "ПОБЕДА!",
		"victory_sub": "Все %d уровней пройдены. Монет: %d, трофеев: %d",
		"buy": "КУПИТЬ",
		"owned": "КУПЛЕНО",
		"equipped": "ВЫБРАН",
		"equip": "НАДЕТЬ",
		"no_money": "Не хватает средств",
		"bought": "Куплено!",
		"locked": "Закрыто",
		"ad_coins": "РЕКЛАМА: +75 МОНЕТ",
		"ad_life": "РЕКЛАМА: +1 ЖИЗНЬ",
		"ad_confirm": "Посмотреть рекламный ролик и получить награду?",
		"yes": "СМОТРЕТЬ",
		"no": "ОТМЕНА",
		"reward_done": "Награда получена!",
		"ach_done": "Достижение: %s",
		"ach_progress": "Получено %d из %d",
		"boosters": "БУСТЕРЫ",
		"skins": "ГЕРОИ",
		"upgrades": "УЛУЧШЕНИЯ",
		"use_hint": "1-4 или тап по иконке — применить бустер",
	},
	"en": {
		"title": "SLIME RUSH",
		"subtitle": "Jump, stomp slimes, collect coins",
		"play": "PLAY - LEVEL %d",
		"levels": "LEVEL SELECT",
		"shop": "SHOP",
		"achievements": "ACHIEVEMENTS",
		"sound_on": "SOUND: ON",
		"sound_off": "SOUND: OFF",
		"fullscreen": "FULLSCREEN",
		"reset": "RESET PROGRESS",
		"controls": "A/D or arrows - run, W/Space - jump, J - shoot, Esc - pause",
		"progress": "Unlocked: %d/%d    Coins: %d    Trophies: %d",
		"coins": "COINS",
		"trophies": "TROPHIES",
		"lives": "LIVES",
		"level_of": "LEVEL %d/%d",
		"boss": "BOSS",
		"boss_hp": "BOSS: %d/%d",
		"boss_defeated": "BOSS DEFEATED!",
		"level_complete": "LEVEL COMPLETE!",
		"game_over": "GAME OVER",
		"pause": "PAUSE",
		"resume": "RESUME",
		"restart": "RESTART",
		"to_menu": "MENU",
		"back": "BACK",
		"victory": "VICTORY!",
		"victory_sub": "All %d levels done. Coins: %d, trophies: %d",
		"buy": "BUY",
		"owned": "OWNED",
		"equipped": "EQUIPPED",
		"equip": "EQUIP",
		"no_money": "Not enough currency",
		"bought": "Purchased!",
		"locked": "Locked",
		"ad_coins": "AD: +75 COINS",
		"ad_life": "AD: +1 LIFE",
		"ad_confirm": "Watch a rewarded video to get the prize?",
		"yes": "WATCH",
		"no": "CANCEL",
		"reward_done": "Reward received!",
		"ach_done": "Achievement: %s",
		"ach_progress": "Unlocked %d of %d",
		"boosters": "BOOSTERS",
		"skins": "HEROES",
		"upgrades": "UPGRADES",
		"use_hint": "1-4 or tap an icon to use a booster",
	},
}

func _ready() -> void:
	var detected := Ya.get_lang()
	if detected.is_empty():
		detected = OS.get_locale_language()
	detected = detected.to_lower()
	if detected.begins_with("ru") or detected.begins_with("be") or detected.begins_with("uk") or detected.begins_with("kk"):
		lang = "ru"
	else:
		lang = "en"

func t(key: String) -> String:
	var table: Dictionary = strings.get(lang, strings["ru"])
	if table.has(key):
		return String(table[key])
	if strings["ru"].has(key):
		return String(strings["ru"][key])
	return key

# Picks a localized value out of {"ru": ..., "en": ...} dictionaries.
func pick(values: Dictionary) -> String:
	if values.has(lang):
		return String(values[lang])
	if values.has("ru"):
		return String(values["ru"])
	return ""
