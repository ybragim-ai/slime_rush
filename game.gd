extends Node2D

# Slime Rush - gameplay scene.
# Physics values are the ones that already felt good and are not changed.

const TILE := 32
const PLAYER_W := 16.0
const PLAYER_H := 24.0
const GRAVITY := 1300.0
const WALK_SPEED := 170.0
const ACCEL := 1200.0
const FRICTION := 1600.0
const JUMP_FORCE := -400.0
const JUMP_FORCE_BIG := -520.0
const MAX_FALL := 900.0
const SPRING_FORCE := -640.0
const STOMP_BOUNCE := -300.0
const COYOTE_MAX := 0.1
const BUFFER_MAX := 0.1
const INVULN_TIME := 1.5
const STAR_TIME := 8.0
const JUMP_TIME := 20.0
const GUN_AMMO := 12
const SHOOT_COOLDOWN := 0.28

const TILES := "res://assets/Sprites/Tiles/Default/"
const CHARS := "res://assets/Sprites/Characters/Default/"

const EnemyScript := preload("res://enemy.gd")
const BossScript := preload("res://boss.gd")
const BulletScript := preload("res://bullet.gd")
const LevelGen := preload("res://level_gen.gd")
const PauseScript := preload("res://pause.gd")
const UI := preload("res://ui.gd")

var data: Dictionary = {}
var level_width := 2560.0
var theme := "grass"

var player: CharacterBody2D
var player_sprite: Sprite2D
var camera: Camera2D
var pause_layer: CanvasLayer

var start_pos := Vector2(112, 288)
var checkpoint := Vector2(112, 288)
var finish_pos := Vector2.ZERO
var finish_sprite: Sprite2D

var coins: Array = []
var pickups: Array = []
var enemies: Array = []
var bullets: Array = []
var springs: Array = []
var spikes: Array = []
var boss = null
var boss_alive := false

var coins_taken := 0
var kills := 0
var invuln := 0.0
var star_t := 0.0
var jump_t := 0.0
var ammo := 0
var big := false
var shoot_cd := 0.0
var took_damage := false
var finished := false
var dead := false

var coyote := 0.0
var buffer := 0.0
var jump_held := false
var prev_jump_held := false
var hold_left := false
var hold_right := false
var hold_shoot := false
var anim_t := 0.0
var anim_frame := 0
var facing := 1.0

var hud_top: Label
var hud_lives: Label
var hud_level: Label
var hud_msg: Label
var hud_boss: Label
var booster_buttons: Dictionary = {}
var ui_root: Control

func _ready() -> void:
	data = LevelGen.generate(Globals.level)
	theme = String(data["theme"])
	level_width = float(int(data["cols"]) * TILE)
	if Globals.lives <= 0:
		Globals.lives = Globals.start_lives()
	big = bool(Globals.owned.get("up_start_grow", false))

	_build_background()
	_build_tiles()
	_build_coins()
	_build_pickups()
	_build_hazards()
	_build_enemies()
	_build_player()
	_build_finish()
	if bool(data["boss"]):
		_build_boss()
	_build_hud()

	pause_layer = PauseScript.new()
	add_child(pause_layer)

	Globals.achievement_unlocked.connect(_on_achievement)
	Globals.hud_changed.connect(_refresh_hud)
	Ya.game_ready()
	Ya.gameplay_start()
	print("LEVEL START: ", Globals.level, " COLS: ", data["cols"])

# --- world building ---------------------------------------------------------

func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -20
	add_child(layer)
	var rect := TextureRect.new()
	rect.texture = load("res://assets/Sprites/Backgrounds/Default/" + String(data["background"]) + ".png")
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.position = Vector2.ZERO
	rect.size = Vector2(640, 360)
	layer.add_child(rect)

func _tile_texture(cell: Vector2i, kind: String) -> String:
	var solid: Dictionary = data["solid"]
	if kind == "ground":
		return "terrain_%s_block_top" % theme
	var left := solid.has(Vector2i(cell.x - 1, cell.y))
	var right := solid.has(Vector2i(cell.x + 1, cell.y))
	if left and right:
		return "terrain_%s_horizontal_middle" % theme
	if right:
		return "terrain_%s_horizontal_left" % theme
	if left:
		return "terrain_%s_horizontal_right" % theme
	return "terrain_%s_block" % theme

func _build_tiles() -> void:
	var solid: Dictionary = data["solid"]
	for cell in solid.keys():
		var c: Vector2i = cell
		var kind := String(solid[cell])
		var body := StaticBody2D.new()
		body.position = Vector2(float(c.x * TILE) + 16.0, float(c.y * TILE) + 16.0)
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(32, 32)
		col.shape = shape
		body.add_child(col)
		var spr := Sprite2D.new()
		spr.centered = true
		spr.texture = load(TILES + _tile_texture(c, kind) + ".png")
		if spr.texture != null:
			spr.scale = Vector2.ONE * (32.0 / float(spr.texture.get_height()))
		body.add_child(spr)
		add_child(body)
		if kind == "ground":
			var filler := Sprite2D.new()
			filler.centered = true
			filler.texture = load(TILES + "terrain_%s_block_center.png" % theme)
			if filler.texture != null:
				filler.scale = Vector2.ONE * (32.0 / float(filler.texture.get_height()))
			filler.position = Vector2(float(c.x * TILE) + 16.0, float((c.y + 1) * TILE) + 16.0)
			add_child(filler)

func _build_coins() -> void:
	for cell in data["coins"]:
		var c: Vector2i = cell
		var spr := Sprite2D.new()
		spr.centered = true
		spr.texture = load(TILES + "coin_gold.png")
		if spr.texture != null:
			spr.scale = Vector2.ONE * (20.0 / float(spr.texture.get_height()))
		spr.position = Vector2(float(c.x * TILE) + 16.0, float(c.y * TILE) + 16.0)
		add_child(spr)
		coins.append(spr)

func _pickup_icon(kind: String) -> String:
	match kind:
		"star":
			return "star"
		"jump":
			return "spring"
		"gun":
			return "fireball"
		_:
			return "mushroom_red"

func _build_pickups() -> void:
	for entry in data["pickups"]:
		var c: Vector2i = entry["cell"]
		var kind := String(entry["kind"])
		var spr := Sprite2D.new()
		spr.centered = true
		spr.texture = load(TILES + _pickup_icon(kind) + ".png")
		if spr.texture != null:
			spr.scale = Vector2.ONE * (24.0 / float(spr.texture.get_height()))
		spr.position = Vector2(float(c.x * TILE) + 16.0, float(c.y * TILE) + 18.0)
		add_child(spr)
		pickups.append({"node": spr, "kind": kind})

func _build_hazards() -> void:
	for cell in data["spikes"]:
		var c: Vector2i = cell
		var spr := Sprite2D.new()
		spr.centered = true
		spr.texture = load(TILES + "spikes.png")
		if spr.texture != null:
			spr.scale = Vector2.ONE * (32.0 / float(spr.texture.get_height()))
		spr.position = Vector2(float(c.x * TILE) + 16.0, float(c.y * TILE) + 16.0)
		add_child(spr)
		spikes.append(spr)
	for cell in data["springs"]:
		var c2: Vector2i = cell
		var spr2 := Sprite2D.new()
		spr2.centered = true
		spr2.texture = load(TILES + "spring.png")
		if spr2.texture != null:
			spr2.scale = Vector2.ONE * (32.0 / float(spr2.texture.get_height()))
		spr2.position = Vector2(float(c2.x * TILE) + 16.0, float(c2.y * TILE) + 16.0)
		add_child(spr2)
		springs.append(spr2)

func _build_enemies() -> void:
	for cfg in data["enemies"]:
		var e = EnemyScript.new()
		add_child(e)
		e.setup(cfg, TILE, Globals.level)
		enemies.append(e)

func _build_player() -> void:
	var cell: Vector2i = data["start"]
	start_pos = Vector2(float(cell.x * TILE) + 16.0, float(cell.y * TILE) - 4.0)
	checkpoint = start_pos
	player = CharacterBody2D.new()
	player.position = start_pos
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(PLAYER_W, PLAYER_H)
	col.shape = shape
	player.add_child(col)
	player_sprite = Sprite2D.new()
	player_sprite.centered = true
	player_sprite.texture = load(CHARS + "character_%s_idle.png" % Globals.skin)
	player.add_child(player_sprite)
	add_child(player)
	_apply_player_scale()

	camera = Camera2D.new()
	camera.position = Vector2(320, 180)
	add_child(camera)
	camera.make_current()

func _apply_player_scale() -> void:
	if player_sprite == null or player_sprite.texture == null:
		return
	var target := PLAYER_H * (1.45 if big else 1.0)
	player_sprite.scale = Vector2.ONE * (target / float(player_sprite.texture.get_height()))
	player_sprite.position = Vector2(0, (PLAYER_H - target) * 0.5)

func _build_finish() -> void:
	var cell: Vector2i = data["finish"]
	finish_pos = Vector2(float(cell.x * TILE) + 16.0, float(cell.y * TILE))
	finish_sprite = Sprite2D.new()
	finish_sprite.centered = true
	var file := "flag_green_a"
	if bool(data["boss"]):
		file = "flag_off"
	finish_sprite.texture = load(TILES + file + ".png")
	if finish_sprite.texture != null:
		finish_sprite.scale = Vector2.ONE * (32.0 / float(finish_sprite.texture.get_height()))
	finish_sprite.position = finish_pos
	add_child(finish_sprite)

func _build_boss() -> void:
	boss = BossScript.new()
	add_child(boss)
	var cell: Vector2i = data["boss_cell"]
	boss.setup(Vector2(float(cell.x * TILE) + 16.0, float(cell.y * TILE)), Globals.level)
	boss_alive = true

# --- HUD --------------------------------------------------------------------

func _build_hud() -> void:
	ui_root = UI.make_ui_layer(self, 100)

	hud_top = Label.new()
	hud_top.position = Vector2(12, 4)
	hud_top.size = Vector2(300, 18)
	UI.style_label(hud_top, 13, 4)
	ui_root.add_child(hud_top)

	hud_lives = Label.new()
	hud_lives.position = Vector2(12, 22)
	hud_lives.size = Vector2(300, 18)
	UI.style_label(hud_lives, 13, 4)
	ui_root.add_child(hud_lives)

	hud_level = UI.make_label(ui_root, "", Vector2(170, 4), 300.0, 13)
	hud_boss = UI.make_label(ui_root, "", Vector2(170, 22), 300.0, 13)
	hud_msg = UI.make_label(ui_root, "", Vector2(0, 150), 640.0, 24)

	var pause_btn := UI.make_button(ui_root, "II", Vector2(596, 4), Vector2(34, 28), 14)
	pause_btn.pressed.connect(_on_pause_pressed)
	var full_btn := UI.make_button(ui_root, "[ ]", Vector2(556, 4), Vector2(34, 28), 14)
	full_btn.pressed.connect(Globals.toggle_fullscreen)

	var order := ["star", "jump", "grow", "gun"]
	for i in range(order.size()):
		var id := String(order[i])
		var b := UI.make_button(ui_root, "", Vector2(12.0 + float(i) * 40.0, 44.0), Vector2(36, 32), 12)
		b.icon = load(TILES + _pickup_icon(id) + ".png")
		b.expand_icon = true
		b.pressed.connect(_use_booster.bind(id))
		booster_buttons[id] = b

	if DisplayServer.is_touchscreen_available():
		_build_touch_controls()
	_refresh_hud()

func _build_touch_controls() -> void:
	var left := UI.make_button(ui_root, "<", Vector2(14, 282), Vector2(64, 64), 24)
	left.button_down.connect(func(): hold_left = true)
	left.button_up.connect(func(): hold_left = false)
	var right := UI.make_button(ui_root, ">", Vector2(88, 282), Vector2(64, 64), 24)
	right.button_down.connect(func(): hold_right = true)
	right.button_up.connect(func(): hold_right = false)
	var jump := UI.make_button(ui_root, "^", Vector2(562, 282), Vector2(64, 64), 24)
	jump.button_down.connect(func(): jump_held = true)
	jump.button_up.connect(func(): jump_held = false)
	var shoot := UI.make_button(ui_root, "*", Vector2(488, 282), Vector2(64, 64), 24)
	shoot.button_down.connect(func(): hold_shoot = true)
	shoot.button_up.connect(func(): hold_shoot = false)

func _refresh_hud() -> void:
	if hud_top == null:
		return
	hud_top.text = "%s: %d   %s: %d" % [L.t("coins"), Globals.coins, L.t("trophies"), Globals.trophies]
	hud_lives.text = "%s: %d" % [L.t("lives"), Globals.lives]
	hud_level.text = L.t("level_of") % [Globals.level, Globals.MAX_LEVEL]
	for id in booster_buttons.keys():
		var b: Button = booster_buttons[id]
		var count := int(Globals.inventory.get(id, 0))
		if id == "gun":
			b.text = str(count) if ammo <= 0 else "%d|%d" % [count, ammo]
		else:
			b.text = str(count)
		b.disabled = count <= 0
	if boss != null and boss_alive:
		hud_boss.text = L.t("boss_hp") % [maxi(0, boss.hp), boss.max_hp]
	else:
		hud_boss.text = ""

func _message(text: String, seconds := 1.6) -> void:
	hud_msg.text = text
	var timer := get_tree().create_timer(seconds)
	timer.timeout.connect(_clear_message.bind(text))

func _clear_message(text: String) -> void:
	if hud_msg != null and hud_msg.text == text:
		hud_msg.text = ""

func _on_achievement(id: String) -> void:
	Sfx.play("sfx_gem")
	_message(L.t("ach_done") % Globals.achievement_name(id), 2.2)

func _on_pause_pressed() -> void:
	if pause_layer != null:
		pause_layer.open_menu()

# --- boosters ---------------------------------------------------------------

func _use_booster(id: String) -> void:
	if not Globals.use_booster(id):
		return
	_activate(id)

func _activate(id: String) -> void:
	match id:
		"star":
			star_t = STAR_TIME
			Sfx.play("sfx_magic")
		"jump":
			jump_t = JUMP_TIME
			Sfx.play("sfx_jump-high")
		"grow":
			big = true
			_apply_player_scale()
			Sfx.play("sfx_magic")
		"gun":
			ammo += GUN_AMMO
			Sfx.play("sfx_throw")
	_refresh_hud()

func _shoot() -> void:
	if ammo <= 0 or shoot_cd > 0.0:
		return
	ammo -= 1
	shoot_cd = SHOOT_COOLDOWN
	var b = BulletScript.new()
	add_child(b)
	b.setup(player.position + Vector2(facing * 12.0, -2.0), facing)
	bullets.append(b)
	Sfx.play("sfx_throw", -4.0)
	_refresh_hud()

# --- input and physics ------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1:
			_use_booster("star")
		KEY_2:
			_use_booster("jump")
		KEY_3:
			_use_booster("grow")
		KEY_4:
			_use_booster("gun")

func _physics_process(delta: float) -> void:
	if player == null or finished or dead:
		return

	var left := hold_left or Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A)
	var right := hold_right or Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D)
	var dir := (1.0 if right else 0.0) - (1.0 if left else 0.0)
	if dir != 0.0:
		facing = dir

	jump_held = jump_held or Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_SPACE)
	var jump_edge := jump_held and not prev_jump_held
	prev_jump_held = jump_held
	jump_held = false

	if hold_shoot or Input.is_physical_key_pressed(KEY_J):
		_shoot()
	shoot_cd = maxf(0.0, shoot_cd - delta)

	var v := player.velocity
	if dir != 0.0:
		v.x = move_toward(v.x, dir * WALK_SPEED, ACCEL * delta)
	else:
		v.x = move_toward(v.x, 0.0, FRICTION * delta)
	v.y = minf(v.y + GRAVITY * delta, MAX_FALL)

	if player.is_on_floor():
		coyote = COYOTE_MAX
	else:
		coyote = maxf(0.0, coyote - delta)
	if jump_edge:
		buffer = BUFFER_MAX
	else:
		buffer = maxf(0.0, buffer - delta)
	if buffer > 0.0 and coyote > 0.0:
		v.y = JUMP_FORCE_BIG if jump_t > 0.0 else JUMP_FORCE
		buffer = 0.0
		coyote = 0.0
		Sfx.play("sfx_jump" if jump_t <= 0.0 else "sfx_jump-high")

	player.velocity = v
	player.move_and_slide()
	player.position.x = clampf(player.position.x, 12.0, level_width - 12.0)

	_update_timers(delta)
	_update_camera()
	_update_animation(delta)
	_check_coins()
	_check_pickups()
	_check_hazards()
	_check_enemies()
	_check_bullets()
	_check_boss()
	_check_checkpoint()
	_check_finish()

	if player.position.y > float(int(data["rows"]) * TILE) + 80.0:
		_hurt(true)

func _update_timers(delta: float) -> void:
	invuln = maxf(0.0, invuln - delta)
	if star_t > 0.0:
		star_t = maxf(0.0, star_t - delta)
	if jump_t > 0.0:
		jump_t = maxf(0.0, jump_t - delta)
	if player_sprite != null:
		if star_t > 0.0:
			player_sprite.modulate = Color(1.0, 0.9, 0.3) if int(star_t * 8.0) % 2 == 0 else Color(0.6, 1.0, 1.0)
		elif invuln > 0.0:
			player_sprite.modulate = Color(1, 1, 1, 0.45) if int(invuln * 10.0) % 2 == 0 else Color(1, 1, 1, 1)
		else:
			player_sprite.modulate = Color(1, 1, 1, 1)

func _update_camera() -> void:
	if camera == null:
		return
	camera.position.x = clampf(player.position.x, 320.0, maxf(320.0, level_width - 320.0))
	camera.position.y = 180.0

func _update_animation(delta: float) -> void:
	if player_sprite == null:
		return
	var file := "idle"
	if not player.is_on_floor():
		file = "jump"
	elif absf(player.velocity.x) > 12.0:
		anim_t += delta
		if anim_t >= 0.14:
			anim_t = 0.0
			anim_frame = (anim_frame + 1) % 2
		file = "walk_a" if anim_frame == 0 else "walk_b"
	player_sprite.texture = load(CHARS + "character_%s_%s.png" % [Globals.skin, file])
	player_sprite.flip_h = facing < 0.0
	_apply_player_scale()

func _player_rect() -> Rect2:
	var h := PLAYER_H
	return Rect2(player.position - Vector2(PLAYER_W * 0.5, h * 0.5), Vector2(PLAYER_W, h))

# --- interactions -----------------------------------------------------------

func _check_coins() -> void:
	var magnet := bool(Globals.owned.get("up_magnet", false))
	var remaining: Array = []
	for c in coins:
		if not is_instance_valid(c):
			continue
		var dist := player.position.distance_to(c.position)
		if magnet and dist < 90.0:
			c.position = c.position.move_toward(player.position, 160.0 * get_physics_process_delta_time())
			dist = player.position.distance_to(c.position)
		if dist < 22.0:
			coins_taken += 1
			Globals.add_coins(1)
			Sfx.play("sfx_coin")
			c.queue_free()
			continue
		remaining.append(c)
	coins = remaining

func _check_pickups() -> void:
	var remaining: Array = []
	for entry in pickups:
		var node = entry["node"]
		if not is_instance_valid(node):
			continue
		if player.position.distance_to(node.position) < 24.0:
			_activate(String(entry["kind"]))
			node.queue_free()
			continue
		remaining.append(entry)
	pickups = remaining

func _check_hazards() -> void:
	for s in spikes:
		if is_instance_valid(s) and player.position.distance_to(s.position) < 24.0:
			_hurt()
			return
	for s in springs:
		if not is_instance_valid(s):
			continue
		if absf(player.position.x - s.position.x) < 22.0 and player.velocity.y >= 0.0:
			if absf(player.position.y + PLAYER_H * 0.5 - (s.position.y - 8.0)) < 14.0:
				player.velocity.y = SPRING_FORCE
				Sfx.play("sfx_jump-high")

func _check_enemies() -> void:
	var rect := _player_rect()
	var remaining: Array = []
	for e in enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		var erect := Rect2(e.position - e.size * 0.5, e.size)
		if rect.intersects(erect):
			if star_t > 0.0:
				e.kill()
				_register_kill()
				continue
			var falling := player.velocity.y > 40.0
			var above := rect.position.y + rect.size.y - 10.0 < erect.position.y + erect.size.y * 0.5
			if falling and above and e.can_be_stomped():
				player.velocity.y = STOMP_BOUNCE
				if e.hit(1):
					_register_kill()
					continue
				Sfx.play("sfx_bump")
			else:
				_hurt()
		remaining.append(e)
	enemies = remaining

func _register_kill() -> void:
	kills += 1
	Globals.add_kill()
	Sfx.play("sfx_disappear")
	_refresh_hud()

func _check_bullets() -> void:
	var remaining: Array = []
	for b in bullets:
		if not is_instance_valid(b):
			continue
		var brect := Rect2(b.position - Vector2(7, 7), Vector2(14, 14))
		var consumed := false
		for e in enemies:
			if not is_instance_valid(e) or e.dead:
				continue
			if brect.intersects(Rect2(e.position - e.size * 0.5, e.size)):
				if e.hit(1):
					_register_kill()
				consumed = true
				break
		if not consumed and boss != null and boss_alive:
			if brect.intersects(Rect2(boss.position - boss.size * 0.5, boss.size)):
				_damage_boss()
				consumed = true
		if consumed:
			b.queue_free()
			continue
		remaining.append(b)
	bullets = remaining

func _damage_boss() -> void:
	if boss == null or not boss_alive:
		return
	if boss.stomp():
		boss_alive = false
		Globals.add_kill(true)
		Sfx.play("sfx_magic")
		_message(L.t("boss_defeated"), 2.0)
		if finish_sprite != null:
			finish_sprite.texture = load(TILES + "flag_green_a.png")
			if finish_sprite.texture != null:
				finish_sprite.scale = Vector2.ONE * (32.0 / float(finish_sprite.texture.get_height()))
		print("BOSS DEFEATED")
	else:
		Sfx.play("sfx_bump")
	_refresh_hud()

func _check_boss() -> void:
	if boss == null or not boss_alive:
		return
	boss.track(player.position)
	var rect := _player_rect()
	var brect := Rect2(boss.position - boss.size * 0.5, boss.size)
	if not rect.intersects(brect):
		return
	if star_t > 0.0:
		_damage_boss()
		return
	if player.velocity.y > 40.0 and rect.position.y + rect.size.y - 12.0 < brect.position.y + brect.size.y * 0.5:
		player.velocity.y = STOMP_BOUNCE
		_damage_boss()
	else:
		_hurt()

func _check_checkpoint() -> void:
	if player.is_on_floor() and player.position.x > checkpoint.x + 320.0:
		checkpoint = Vector2(player.position.x, player.position.y)

func _check_finish() -> void:
	if finished:
		return
	if bool(data["boss"]) and boss_alive:
		return
	if player.position.distance_to(finish_pos) < 34.0:
		_finish_level()

func _finish_level() -> void:
	finished = true
	Globals.level_done(not took_damage)
	Globals.add_coins(10)
	Sfx.play("sfx_magic")
	_message(L.t("level_complete"), 1.4)
	print("LEVEL COMPLETE")
	Ya.gameplay_stop()
	var timer := get_tree().create_timer(1.4)
	timer.timeout.connect(Globals.next_level)

# --- damage -----------------------------------------------------------------

func _hurt(from_pit := false) -> void:
	if dead or finished:
		return
	if not from_pit and (invuln > 0.0 or star_t > 0.0):
		return
	took_damage = true
	if big and not from_pit:
		big = false
		invuln = INVULN_TIME
		_apply_player_scale()
		Sfx.play("sfx_bump")
		return
	big = false
	ammo = 0
	star_t = 0.0
	Globals.lives -= 1
	Sfx.play("sfx_hurt")
	_refresh_hud()
	print("LIVES LEFT: ", Globals.lives)
	if Globals.lives <= 0:
		dead = true
		_message(L.t("game_over"), 1.6)
		Ya.gameplay_stop()
		var timer := get_tree().create_timer(1.5)
		timer.timeout.connect(Globals.game_over)
		return
	player.position = checkpoint
	player.velocity = Vector2.ZERO
	invuln = INVULN_TIME
	_apply_player_scale()
	print("RESPAWN AT CHECKPOINT")
