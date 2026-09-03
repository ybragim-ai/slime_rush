extends Node2D

# Enemy types:
#   slime - basic walker, 1 hp
#   snail - slow, 2 hp
#   fly   - flying bee, appears from level 3, sine movement, cannot be stomped safely from the side
#   spike - spiky slime, cannot be stomped at all, only the blaster or a star kills it

const ENEMY_DIR := "res://assets/Sprites/Enemies/Default/"
const FRAME_TIME := 0.18

var kind := "slime"
var hp := 1
var speed := 40.0
var dir := -1.0
var min_x := 0.0
var max_x := 0.0
var base_y := 0.0
var size := Vector2(24.0, 22.0)
var dead := false
var anim_t := 0.0
var frame := 0
var phase := 0.0
var sprite: Sprite2D
var frames: Array = []

func setup(cfg: Dictionary, tile: int, level: int) -> void:
	kind = String(cfg.get("kind", "slime"))
	var col := int(cfg.get("col", 0))
	var row := int(cfg.get("row", 9))
	min_x = float(int(cfg.get("min_col", col)) * tile) + 8.0
	max_x = float(int(cfg.get("max_col", col)) * tile) + float(tile) - 8.0
	var target_height := 22.0

	match kind:
		"snail":
			hp = 2
			speed = 26.0 + 2.0 * float(level)
			frames = ["snail_walk_a", "snail_walk_b"]
			target_height = 22.0
		"fly":
			hp = 1
			speed = 55.0 + 5.0 * float(level)
			frames = ["bee_a", "bee_b"]
			target_height = 22.0
		"spike":
			hp = 1
			speed = 34.0 + 3.0 * float(level)
			frames = ["slime_spike_walk_a", "slime_spike_walk_b"]
			target_height = 24.0
		_:
			kind = "slime"
			hp = 1
			speed = 40.0 + 4.0 * float(level)
			frames = ["slime_normal_walk_a", "slime_normal_walk_b"]
			target_height = 22.0

	sprite = Sprite2D.new()
	sprite.centered = true
	sprite.texture = load(ENEMY_DIR + String(frames[0]) + ".png")
	var scale_factor := 1.0
	if sprite.texture != null:
		var h := float(sprite.texture.get_height())
		if h > 0.0:
			scale_factor = target_height / h
		sprite.scale = Vector2.ONE * scale_factor
		size = Vector2(float(sprite.texture.get_width()) * scale_factor, target_height)
	add_child(sprite)

	base_y = float(row * tile) + float(tile) - target_height * 0.5
	position = Vector2(float(col * tile) + float(tile) * 0.5, base_y)
	phase = float(col) * 0.7

func can_be_stomped() -> bool:
	return kind != "spike"

# Returns true when the enemy dies from this hit.
func hit(damage := 1) -> bool:
	if dead:
		return false
	hp -= damage
	if hp <= 0:
		dead = true
		queue_free()
		return true
	if sprite != null:
		sprite.modulate = Color(1.0, 0.6, 0.6)
	return false

func kill() -> void:
	dead = true
	queue_free()

func _process(delta: float) -> void:
	if dead or frames.is_empty() or sprite == null:
		return
	position.x += dir * speed * delta
	if position.x <= min_x:
		position.x = min_x
		dir = 1.0
	elif position.x >= max_x:
		position.x = max_x
		dir = -1.0
	if kind == "fly":
		phase += delta * 3.0
		position.y = base_y + sin(phase) * 18.0
	anim_t += delta
	if anim_t >= FRAME_TIME:
		anim_t = 0.0
		frame = (frame + 1) % frames.size()
		if sprite != null:
			sprite.texture = load(ENEMY_DIR + String(frames[frame]) + ".png")
	if sprite != null:
		sprite.flip_h = dir > 0.0
