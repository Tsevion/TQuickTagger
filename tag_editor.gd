class_name TagEditor extends Control

const ALLOWED_EXT = [".png", ".jpeg", ".jpg", ".gif"]
const IMAGE_BUTTON = preload("res://image_button.tscn")
const TAG_BUTTON = preload("res://tag_button.tscn")

var current_dir : String = ""
var thumbs : HFlowContainer
var p_size : HSlider
var image_buttons := []
var selected := []
var tags_need_recalc := false
var previewing = null
var special_tags : Array[String] = Array([], TYPE_STRING, &"", null)
var special_file : String
var needs_save : bool :
	set(ns):
		if ns != needs_save:
			needs_save = ns
			$VBoxContainer/HBoxContainer/SaveButton.disabled = !needs_save
var show_only_selected: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().gui_embed_subwindows = false
	thumbs = $VBoxContainer/HSplitContainer/TabContainer/FileList/MarginContainer/ImageThumbs
	p_size = $VBoxContainer/HBoxContainer/PreviewSize

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if tags_need_recalc:
		recalculate_current_tags()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if check_save(func(): get_tree().quit()):
			get_tree().quit()

func _on_select_dir(dir_name : String):
	needs_save = true
	
	current_dir = dir_name
	$VBoxContainer/HBoxContainer/CurDir.text = dir_name
	for c in thumbs.get_children():
		c.queue_free()
	
	selected = []
	image_buttons = []
	
	special_tags = Array([], TYPE_STRING, &"", null)
	special_file = dir_name + "/.tags.txt"
	if FileAccess.file_exists(special_file):
		special_tags = Tags.load_tags_from(special_file, [])
	
	var files = DirAccess.get_files_at(dir_name)
	for f in files:
		for e in ALLOWED_EXT:
			if f.ends_with(e):
				var imb = IMAGE_BUTTON.instantiate()
				imb.selection_parent = self
				imb.set_image_size(p_size.value)
				imb.load_image(dir_name + "/" + f)
				imb.load_tags(special_tags)
				thumbs.add_child(imb)
				image_buttons.append(imb)
				break
	
	make_special_tag_buttons()

func make_special_tag_buttons():
	var tl = $VBoxContainer/HSplitContainer/ScrollContainer2/MarginContainer/VBoxContainer/PriorityTagContainer/PriorityTagList
	for c in tl.get_children():
		c.queue_free()
	
	for st in special_tags:
		var ntb : TagButton = TAG_BUTTON.instantiate()
		ntb.special = true
		ntb.set_tag_name(st)
		ntb.set_tag_ct(0)
		ntb.set_add(false)
		ntb.add_tag.connect(add_tag)
		ntb.remove_tag.connect(remove_special_tag)
		ntb.filter_tag.connect(filter_tag)
		tl.add_child(ntb)

	tags_need_recalc = true

func recalculate_current_tags():
	tags_need_recalc = false
	
	$VBoxContainer/HBoxContainer/SelectedCounter.text = "%d/%d" % [len(selected), len(image_buttons)]
	
	var stl = $VBoxContainer/HSplitContainer/ScrollContainer2/MarginContainer/VBoxContainer/PriorityTagContainer/PriorityTagList
	var tl = $VBoxContainer/HSplitContainer/ScrollContainer2/MarginContainer/VBoxContainer/FileTagContainer/FileTagList
	for c in tl.get_children():
		c.queue_free()
	
	var tag_set = {}
	var sel_ct = len(selected)
	for imb in selected:
		for tag in imb.tags:
			tag_set[tag] = tag_set.get(tag, 0) + 1

	for c in stl.get_children():
		var ct = tag_set.get(c.tag_name, 0)
		c.set_tag_ct(ct)
		c.set_add(ct < sel_ct)

	var tags = Array(tag_set.keys(), TYPE_STRING, &"", null)
	Tags.sort_tag_list(tags, special_tags)
	for t in tags:
		var ntb : TagButton = TAG_BUTTON.instantiate()
		ntb.special = t in special_tags
		ntb.set_tag_name(t)
		ntb.set_tag_ct(tag_set[t])
		ntb.set_add(tag_set[t] < sel_ct)
		ntb.add_tag.connect(add_tag)
		ntb.remove_tag.connect(remove_tag)
		ntb.filter_tag.connect(filter_tag)
		tl.add_child(ntb)

func add_tag(tag : String):
	for imb in selected:
		if tag not in imb.tags:
			imb.tags.append(tag)
			Tags.sort_tag_list(imb.tags, special_tags)
	tags_need_recalc = true
	needs_save = true

func remove_special_tag(tag : String):
	special_tags.erase(tag)
	make_special_tag_buttons()
	needs_save = true

func remove_tag(tag : String):
	for imb in selected:
		if tag in imb.tags:
			imb.tags.erase(tag)
	tags_need_recalc = true
	needs_save = true

func filter_tag(tag : String):
	for s in selected.duplicate():
		if tag not in s.tags:
			s.selected = false

func check_save(on_done : Callable):
	if needs_save:
		var should_save = AcceptDialog.new()
		should_save.dialog_text = "You have unsaved Tag Changes, Save Now:"
		should_save.get_ok_button().text = "Yes"
		should_save.add_button("No", true, "no_save")
		should_save.add_cancel_button("Cancel")
		should_save.exclusive = true
		should_save.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_KEYBOARD_FOCUS
		should_save.confirmed.connect(func(): should_save.queue_free(); save(); on_done.call_deferred())
		should_save.custom_action.connect(func(_a): should_save.hide(); should_save.queue_free(); needs_save = false; on_done.call_deferred())
		should_save.canceled.connect(should_save.queue_free)
		add_child(should_save)
		should_save.popup()
		return false
	
	return true

func save():
	Tags.save_tags(special_file, special_tags, special_tags)
	for imb in image_buttons:
		Tags.save_tags(imb.tag_file_name, imb.tags, special_tags)
	needs_save = false

func show_only_selected_change(new_val : bool):
	if new_val == show_only_selected:
		return
	
	show_only_selected = new_val
	for imb in image_buttons:
		if show_only_selected:
			imb.visible = imb.selected
		else:
			imb.visible = true

func in_preview() -> bool:
	return $VBoxContainer/HSplitContainer/TabContainer.current_tab == 1

func _on_choose_dir_pressed():
	if not check_save(_on_choose_dir_pressed):
		return

	var fd = FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.exclusive = true
	fd.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_KEYBOARD_FOCUS
	fd.dir_selected.connect(_on_select_dir)
	fd.size = Vector2(800, 640)
	fd.add_filter("*.jpg,*.jpeg,*.gif,*.png,*.txt","Images and Tags")
	if current_dir:
		fd.current_dir = current_dir
	add_child(fd)
	fd.popup()

func _on_swap_view_pressed():
	var tc = $VBoxContainer/HSplitContainer/TabContainer
	if tc.current_tab == 0:
		if len(selected) > 0:
			preview_image(selected[0])
		elif len(image_buttons):
			preview_image(image_buttons[0])
	else:
		tc.current_tab = 0

func _on_preview_size_value_changed(value):
	print(value)
	for ib in image_buttons:
		ib.set_image_size(value)

func preview_image(imblock):
	$VBoxContainer/HSplitContainer/TabContainer.current_tab = 1
	if imblock:
		$VBoxContainer/HSplitContainer/TabContainer/ImageView.texture = imblock.texture
	else:
		$VBoxContainer/HSplitContainer/TabContainer/ImageView.texture = null
	previewing = imblock
	if not show_only_selected:
		set_selection(previewing)

func add_to_selection(imblock : ImageBlock):
	if imblock not in selected:
		selected.append(imblock)
	tags_need_recalc = true

func remove_from_selection(imblock : ImageBlock):
	if imblock in selected:
		selected.erase(imblock)
	tags_need_recalc = true

func set_selection(imblock : ImageBlock):
	clear_selection()
	imblock.selected = true

func clear_selection():
	var prev_selected = selected
	selected = []
	for imb in prev_selected:
		imb.selected = false
		
func select_all():
	for imb in image_buttons:
		imb.selected = true

func _on_fw_button_pressed():
	if show_only_selected:
		if len(selected) == 0:
			preview_image(null)
		else:
			var preview_idx = selected.find(previewing)
			preview_image(selected[(preview_idx + 1) % len(selected)])
	else:
		if len(image_buttons) == 0:
			preview_image(null)
		else:
			var preview_idx = image_buttons.find(previewing)
			preview_image(image_buttons[(preview_idx + 1) % len(image_buttons)])

func _on_back_button_pressed():
	if show_only_selected:
		if len(selected) == 0:
			preview_image(null)
		else:
			# abs here is a dumb trick, so if it finds nothing and returns -1, it just goes to element 0
			var preview_idx = abs(selected.find(previewing))
			preview_image(selected[preview_idx - 1])
	else:
		if len(image_buttons) == 0:
			preview_image(null)
		else:
			# abs here is a dumb trick, so if it finds nothing and returns -1, it just goes to element 0
			var preview_idx = abs(image_buttons.find(previewing))
			preview_image(image_buttons[preview_idx - 1])

func _on_image_view_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 2 and not event.is_pressed():
			_on_swap_view_pressed()

func _on_new_priority_tag_button_pressed():
	var nt = $VBoxContainer/HSplitContainer/ScrollContainer2/MarginContainer/VBoxContainer/HBoxNewPriorityTag/NewPriorityTagName.text.strip_edges()
	_on_new_priority_tag_name_text_submitted(nt)

func _on_new_tag_button_pressed():
	var nt = $VBoxContainer/HSplitContainer/ScrollContainer2/MarginContainer/VBoxContainer/HBoxNewTag/NewTagName.text.strip_edges()
	add_tag(nt)

func _on_new_priority_tag_name_text_submitted(new_text):
	if new_text not in special_tags:
		special_tags.append(new_text)
		special_tags.sort()
		make_special_tag_buttons()
		needs_save = true

func _on_new_tag_name_text_submitted(new_text):
	add_tag(new_text)

func _on_show_selected_toggle_toggled(button_pressed):
	show_only_selected_change(button_pressed)
