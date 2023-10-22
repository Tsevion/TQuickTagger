class_name TagButton extends PanelContainer

signal add_tag(String)
signal remove_tag(String)
signal filter_tag(String)

@export var base_style : StyleBox
@export var special_style : StyleBox
@export var focused_style : StyleBox
@export var special_focused_style : StyleBox

@export var special : bool
@export var tag_name : String

# Called when the node enters the scene tree for the first time.
func _ready():
	set_style()

func set_style():
	if has_focus():
		add_theme_stylebox_override(&"panel", special_focused_style if special else focused_style)
	else:
		add_theme_stylebox_override(&"panel", special_style if special else base_style)

func set_tag_name(tn : String):
	tag_name = tn
	$HBoxContainer/TagName.text = tag_name

func set_tag_ct(count : int):
	$HBoxContainer/TagCount.text = "(%d)" % count
	$HBoxContainer/TagCount.visible = count > 0

func set_add(enable_add : bool):
	$HBoxContainer/AddTag.disabled = !enable_add

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.is_pressed() and (event.double_click or event.ctrl_pressed):
				filter_tag.emit(tag_name)

		if event.button_index == 2 and event.is_pressed():
			DisplayServer.clipboard_set(tag_name)

	if event is InputEventKey:
		if event.is_action(&"ui_copy"):
			DisplayServer.clipboard_set(tag_name)

func _on_focus_entered():
	set_style()

func _on_focus_exited():
	set_style()

func _on_remove_tag_pressed():
	remove_tag.emit(tag_name)

func _on_add_tag_pressed():
	add_tag.emit(tag_name)
