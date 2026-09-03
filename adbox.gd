extends CanvasLayer

# Explicit confirmation dialog before a rewarded video (checklist 4.5).
# The ad is requested only after the player presses the confirm button.

const UI := preload("res://ui.gd")

var panel: ColorRect
var tag := "coins"

func _ready() -> void:
	layer = 250
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = ColorRect.new()
	panel.color = Color(0.05, 0.05, 0.1, 0.8)
	panel.size = Vector2(640, 360)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	UI.make_label(panel, L.t("ad_confirm"), Vector2(40, 130), 560.0, 16)
	var yes := UI.make_button(panel, L.t("yes"), Vector2(140, 180), Vector2(160, 38), 16)
	yes.pressed.connect(_on_yes)
	var no := UI.make_button(panel, L.t("no"), Vector2(340, 180), Vector2(160, 38), 16)
	no.pressed.connect(hide_box)
	visible = false

func ask(reward_tag: String) -> void:
	tag = reward_tag
	visible = true
	Sfx.play("sfx_select")

func hide_box() -> void:
	visible = false

func _on_yes() -> void:
	visible = false
	Ya.show_rewarded(tag)
