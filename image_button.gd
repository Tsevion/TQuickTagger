class_name ImageBlock extends PanelContainer

@export var base_style : StyleBox
@export var selected_style : StyleBox
@export var focused_style : StyleBox
@export var focused_selected_style : StyleBox

@export var selected : bool :
	set(sel):
		if selected != sel:
			selected = sel
			$VBoxContainer/TextureRect/Selected.button_pressed = sel
			set_style()
			if selection_parent:
				if selection_parent.show_only_selected:
					visible = selected
				if selected:
					selection_parent.add_to_selection(self)
				else:
					selection_parent.remove_from_selection(self)

var selection_parent : TagEditor
var texture : Texture2D
var tag_file_name : String
var tags : Array[String]

func load_image(file_name : String):
	$VBoxContainer/FileName.text = file_name.split("/")[-1]
	var img = Image.load_from_file(file_name)
	img.generate_mipmaps()
	texture = ImageTexture.create_from_image(img)
	$VBoxContainer/TextureRect.texture = texture
	
	var suffix_start = file_name.rfind(".")
	tag_file_name = file_name.substr(0, suffix_start) + ".txt"

func load_tags(special_tags : Array[String]):
	if FileAccess.file_exists(tag_file_name):
		tags = Tags.load_tags_from(tag_file_name, special_tags)

func set_image_size(sz : float):
	custom_minimum_size = Vector2(sz, sz)
	size = Vector2(sz, sz)
	
func set_style():
	if has_focus():
		add_theme_stylebox_override(&"panel", focused_selected_style if selected else focused_style)
	else:
		add_theme_stylebox_override(&"panel", selected_style if selected else base_style)

func _on_selected_toggled(button_pressed):
	selected = button_pressed

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if not event.ctrl_pressed and not event.shift_pressed:
					if event.is_pressed() and event.double_click:
						selection_parent.preview_image(self)
					elif not event.is_pressed():
						selection_parent.set_selection(self)
			elif event.ctrl_pressed and not event.shift_pressed:
				if not event.is_pressed():
					selected = !selected

func _on_focus_entered():
	set_style()

func _on_focus_exited():
	set_style()
