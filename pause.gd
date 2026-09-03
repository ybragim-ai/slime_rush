extends CanvasLayer

# In-game pause overlay: resume, restart, sound, fullscreen, menu.
# Also reacts to external pause events (ad playing, tab hidden).

var panel: ColorRect
var sound_btn: Button
var root: Control
var open := false
var buttons: Array = []

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.size = Vector2(640, 360)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	panel = ColorRect.new()
	panel.color = Color(0.05, 0.05, 0.1, 0.78)
	panel.size = Vector2(640, 360)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)

	var title := Label.new()
	title.text = L.t("pause")
	title.position = Vector2(0, 40)
	title.size = Vector2(640, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 5)
	panel.add_child(title)

	var resume_btn := _make_button(L.t("resume"), Vector2(220, 96))
	resume_btn.pressed.connect(close)
	var restart_btn := _make_button(L.t("restart"), Vector2(220, 140))
	restart_btn.pressed.connect(_on_restart)
	sound_btn = _make_button(_sound_text(), Vector2(220, 184))
	sound_btn.pressed.connect(_on_sound)
	var full_btn := _make_button(L.t("fullscreen"), Vector2(220, 228))
	full_btn.pressed.connect(_on_fullscreen)
	var menu_btn := _make_button(L.t("to_menu"), Vector2(220, 272))
	menu_btn.pressed.connect(_on_menu)

	visible = false
	Ya.external_pause.connect(_on_external_pause)

func _make_button(text: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(200, 36)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 16)
	panel.add_child(b)
	buttons.append(b)
	return b

func _sound_text() -> String:
	return L.t("sound_on") if Globals.sound_on else L.t("sound_off")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			toggle()

func toggle() -> void:
	if open:
		close()
	else:
		open_menu()

func open_menu() -> void:
	open = true
	visible = true
	get_tree().paused = true
	Ya.gameplay_stop()

func close() -> void:
	open = false
	visible = false
	get_tree().paused = false
	Ya.gameplay_start()

# Ad or hidden tab: pause silently, no user action needed (checklist 1.3, 4.7).
func _on_external_pause(active: bool) -> void:
	if active:
		get_tree().paused = true
	elif not open:
		get_tree().paused = false

func _on_sound() -> void:
	Globals.toggle_sound()
	sound_btn.text = _sound_text()
	Sfx.play("sfx_select")

func _on_fullscreen() -> void:
	Globals.toggle_fullscreen()

func _on_restart() -> void:
	Sfx.play("sfx_select")
	Globals.restart_level()

func _on_menu() -> void:
	Sfx.play("sfx_select")
	Globals.to_menu()
