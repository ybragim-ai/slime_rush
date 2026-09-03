extends Node2D

# Blaster projectile: flies straight, dies on enemies or after a short range.

const SPEED := 320.0
const LIFETIME := 1.1

var dir := 1.0
var life := 0.0
var sprite: Sprite2D

func setup(start: Vector2, direction: float) -> void:
	position = start
	dir = 1.0 if direction >= 0.0 else -1.0
	sprite = Sprite2D.new()
	sprite.centered = true
	sprite.texture = load("res://assets/Sprites/Tiles/Default/fireball.png")
	if sprite.texture != null:
		var h := float(sprite.texture.get_height())
		if h > 0.0:
			sprite.scale = Vector2.ONE * (14.0 / h)
	sprite.flip_h = dir < 0.0
	add_child(sprite)

func _process(delta: float) -> void:
	position.x += dir * SPEED * delta
	life += delta
	if sprite != null:
		sprite.rotation += delta * 12.0 * dir
	if life > LIFETIME:
		queue_free()
