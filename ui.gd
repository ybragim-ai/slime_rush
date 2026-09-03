extends RefCounted

# Small shared UI helpers so every screen looks the same and stays
# touch friendly (big hit areas, no tiny text) - checklist 1.10.

const TILES := "res://assets/Sprites/Tiles/Default/"
const BGS := "res://assets/Sprites/Backgrounds/Default/"

static func style_label(l: Label, size: int, outline := 5) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", outline)

static func make_label(parent: Node, text: String, pos: Vector2, width: float, size: int, center := true) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(width, float(size) + 8.0)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_label(l, size)
	parent.add_child(l)
	return l

static func make_button(parent: Node, text: String, pos: Vector2, size: Vector2, font_size := 15) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_theme_font_size_override("font_size", font_size)
	parent.add_child(b)
	return b

static func make_icon(parent: Node, file: String, pos: Vector2, target: float) -> TextureRect:
	var tex := TextureRect.new()
	tex.texture = load(TILES + file + ".png")
	tex.position = pos
	tex.size = Vector2(target, target)
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tex)
	return tex

static func make_background(node: Node, file: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	node.add_child(layer)
	var rect := TextureRect.new()
	rect.texture = load(BGS + file + ".png")
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.position = Vector2.ZERO
	rect.size = Vector2(640, 360)
	layer.add_child(rect)

static func make_ui_layer(node: Node, layer_index := 10) -> Control:
	var layer := CanvasLayer.new()
	layer.layer = layer_index
	node.add_child(layer)
	var root := Control.new()
	root.position = Vector2.ZERO
	root.size = Vector2(640, 360)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	return root
