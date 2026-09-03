extends Node2D

# Level boss: a big slime that chases the player and jumps.
# Stomp its head or shoot it to take one hit point off.

const DIR := "res://assets/Sprites/Enemies/Default/"
const FRAME_TIME := 0.2
const GRAVITY := 900.0
const JUMP_VY := -420.0
const JUMP_EVERY := 1.8

var hp := 3
var max_hp := 3
var dead := false
var size := Vector2(56.0, 56.0)
var speed := 55.0
var dir := -1.0
var min_x := 0.0
var max_x := 0.0
var floor_y := 0.0
var vy := 0.0
var jump_timer := 0.0
var hurt_timer := 0.0
var anim_t := 0.0
var anim_flip := false

var sprite: Sprite2D
var tex_a: Texture2D
var tex_b: Texture2D
var tex_jump: Texture2D
var target_x := 0.0

func setup(pos: Vector2, level: int) -> void:
	floor_y = pos.y - 32.0
	position = Vector2(pos.x, floor_y)
	target_x = pos.x
	min_x = pos.x - 224.0
	max_x = pos.x + 192.0
	hp = 3 + int(level / 3)
	max_hp = hp
	speed = 50.0 + 4.0 * float(level)

	tex_a = load(DIR + "slime_block_walk_a.png")
	tex_b = load(DIR + "slime_block_walk_b.png")
	tex_jump = load(DIR + "slime_block_jump.png")
	sprite = Sprite2D.new()
	sprite.centered = true
	sprite.texture = tex_a
	if tex_a != null:
		var h := float(tex_a.get_height())
		if h > 0.0:
			sprite.scale = Vector2.ONE * (64.0 / h)
		size = Vector2(float(tex_a.get_width()) * (64.0 / h), 64.0)
	add_child(sprite)

# Called by game.gd every frame with the player position.
func track(player_pos: Vector2) -> void:
	target_x = player_pos.x

func _process(delta: float) -> void:
	if dead:
		return
	if hurt_timer > 0.0:
		hurt_timer -= delta
		if hurt_timer <= 0.0 and sprite != null:
			sprite.modulate = Color(1, 1, 1)

	anim_t += delta
	if anim_t >= FRAME_TIME:
		anim_t = 0.0
		anim_flip = not anim_flip

	if target_x < position.x - 6.0:
		dir = -1.0
	elif target_x > position.x + 6.0:
		dir = 1.0
	position.x = clampf(position.x + dir * speed * delta, min_x, max_x)

	jump_timer -= delta
	if position.y >= floor_y:
		position.y = floor_y
		if jump_timer <= 0.0:
			vy = JUMP_VY
			jump_timer = JUMP_EVERY
		else:
			vy = 0.0
	if vy != 0.0 or position.y < floor_y:
		vy += GRAVITY * delta
		position.y = minf(position.y + vy * delta, floor_y)

	if sprite != null:
		if position.y < floor_y - 1.0:
			sprite.texture = tex_jump
		else:
			sprite.texture = tex_b if anim_flip else tex_a
		sprite.flip_h = dir < 0.0

# Returns true when this hit kills the boss.
func stomp() -> bool:
	if dead:
		return false
	hp -= 1
	hurt_timer = 0.35
	if sprite != null:
		sprite.modulate = Color(1.0, 0.5, 0.5)
	if hp <= 0:
		dead = true
		visible = false
		set_process(false)
		return true
	return false
