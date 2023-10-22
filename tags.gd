class_name Tags extends Object

static func load_tags_from(file_name : String, special_tags : Array[String]) -> Array[String]:
	var tf := FileAccess.open(file_name, FileAccess.READ)
	var lines = []
	var tags = Array([], TYPE_STRING, &"", null)

	while not tf.eof_reached():
		var line = tf.get_line().strip_edges()
		if len(line) > 0:
			lines.append(line)
	tf.close()
	
	# Special case, if there are exactly 2 lines, first line is added to special tags
	if len(lines) == 2:
		var new_specials =  Array(lines[0].split(',')).map(func(a): return a.strip_edges())
		for ns in new_specials:
			if ns not in special_tags:
				special_tags.append(ns)
		special_tags.sort()

	for ln in lines:
		var line_tags = Array(ln.split(',')).map(func(a): return a.strip_edges())
		for lt in line_tags:
			if lt not in tags:
				tags.append(lt)
	
	sort_tag_list(tags, special_tags)
	return tags

static func compare_w_priority(special_tags : Array[String], a : String, b : String):
	if a in special_tags and b not in special_tags:
		return true
	if b in special_tags and a not in special_tags:
		return false
	return a < b

static func sort_tag_list(tag_list : Array[String], special_tags : Array[String]):
	tag_list.sort_custom(func(a, b) : return compare_w_priority(special_tags, a, b))

static func save_tags(file_name : String, tags : Array[String], special_tags : Array[String]):
	var spec = PackedStringArray([])
	var rest = PackedStringArray([])
	
	for t in tags:
		if t in special_tags:
			spec.append(t)
		else:
			rest.append(t)
	
	var tf := FileAccess.open(file_name, FileAccess.WRITE)
	if len(spec) > 0:
		tf.store_csv_line(spec)
	if len(rest) > 0:
		tf.store_csv_line(rest)

