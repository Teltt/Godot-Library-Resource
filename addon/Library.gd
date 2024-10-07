@tool
extends Resource
class_name LibraryManifest
@export_tool_button("Copy Library From Source to External Paths") var export = export_library_source
@export_tool_button("Ask if Library is External") var ask_external = print_external
func print_external():
	external = external_code_path != source_code_path
	if external:
		print("True, paths mismatch from source to current")
	else:
		print("False, paths match from source to current")
@export var delete_overwrite_external = false
@export_dir() var library_path:String ="":
	set(val):
		library_path = val
@export_storage var library_relative_path:String:
	get:
		return library_path.replace("res://","./")
@export_storage var library_name:String:
	get:
		var base_name = library_relative_path.get_basename()
		var path_to = library_relative_path.get_base_dir()
		return base_name.replace(path_to+"/","")
@export_global_dir var external_roots:Array[String]:
	set(val):
		if not external:
			for v in val.size():
				if val[v].is_absolute_path():
					val[v] =(ProjectSettings.localize_path(val[v]))
		else:
			for v in val.size():
				if val[v].is_relative_path():
					val[v] = source_code_path.path_join(val[v])
					if DirAccess.dir_exists_absolute(val[v]):
						var dir = DirAccess.open(val[v])
						val[v] = dir.get_current_dir(true)
					else:
						val.remove_at(v)
		external_roots = val
@export_storage var source_code_path:String = "."
@export_storage var external_code_path:String = "."
@export var external = false
const CLASS_LIST_NAME = "INTERNAL_CLASS_LIST.gd"
const MANIFEST_PATH = "MANIFEST.tres"
func get_root():
	return "res://"
func make_library():
	external_roots = external_roots
	if external and not source_code_path == "." and not external_code_path == ".":
		return
	var dir = DirAccess.open(".")
	var lib_path = ".".path_join(library_relative_path)
	if not dir.dir_exists(lib_path):
		dir.make_dir_recursive(lib_path)
	dir.change_dir(lib_path)
	self.source_code_path= ProjectSettings.globalize_path(dir.get_current_dir(true))
	source_code_path =source_code_path.replace("/./","/")
	self.external_code_path = source_code_path
func export_library_source():
	if library_name.is_empty() or not library_name.is_valid_ascii_identifier():
		print("Invalid library name!")
		return
	if library_relative_path.count("/") > 4:
		print("Library is too deep!")
	make_library()
	copy_library_from_source(source_code_path,false)
	for ext_path in external_roots:
		ext_path = ext_path.path_join(library_relative_path)
		if ext_path == source_code_path:
			continue
		copy_library_from_source(ext_path)
func copy_library_from_source(ext_path,delete_it=delete_overwrite_external):
	ext_path =ext_path.replace("/./","/")
	export_manifest(ext_path)
	export_class_list(get_class_list(source_code_path),ext_path)
	if delete_it:
		delete(ext_path)
	if ext_path != source_code_path:
		copy(source_code_path,ext_path)
func get_class_list(path) -> Array:
	var script_info = []
	var dir = DirAccess.open(path)
	if not dir:
		print("Error opening directory: ", path)
		return script_info
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = path.path_join(file_name)
		if dir.current_is_dir():
			script_info += get_class_list(full_path)
		elif file_name.ends_with(".gd") and not CLASS_LIST_NAME in file_name:
			var _class_name = get_class_name(full_path)
			if _class_name:
				script_info.append([_class_name, full_path])
		file_name = dir.get_next()
	dir.list_dir_end()
	return script_info
func get_class_name(file_path: String) -> String:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Error opening file: ", file_path)
		return ""
	var content = file.get_as_text()
	var regex = RegEx.new()
	regex.compile("class_name\\s+(\\w+)")
	var result = regex.search(content)
	if result:
		return result.get_string(1)
	return ""
func export_manifest(path):
	var source_path =path.path_join(MANIFEST_PATH)
	var save_this = self.duplicate(true)
	
	save_this.external = path != source_code_path
	if save_this.external:
		save_this.external_roots = save_this.external_roots
		save_this.external_code_path = path
	var err= await ResourceSaver.save(save_this,source_path)
	if err != OK:
		print("Error creating manifest file")
		return
func export_class_list(script_info: Array,path) -> void:
	var file = FileAccess.open(source_code_path.path_join(CLASS_LIST_NAME), FileAccess.WRITE)
	if not file:
		print("Error creating class list file")
		return
	file.store_line("class_name " +library_name)
	var lib_path = ProjectSettings.localize_path(library_relative_path.replace("./",get_root()))
	file.store_line("const LIB_ROOT = '" +lib_path+"'")
	for info in script_info:
		var _class_name = info[0]
		var file_path = info[1]
		file_path = file_path.replace("./",get_root())
		file_path = ProjectSettings.localize_path(file_path)
		file.store_line("const " + _class_name + " = \"" + file_path + "\"")
	file.close()

func delete(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		var error = OS.move_to_trash(path)
		if error != OK:
			print("Error deleting: ", path)
func copy(src_path,dst_path):
	var dir = DirAccess.open(src_path)
	if not dir:
		print("Error opening directory: " +src_path)
		return
	if not DirAccess.dir_exists_absolute(dst_path):
		DirAccess.make_dir_recursive_absolute(dst_path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			copy(src_path.path_join(file_name), dst_path.path_join(file_name))
		else:
			var src_file = src_path.path_join(file_name)
			var dst_file = dst_path.path_join(file_name)
			var error = DirAccess.copy_absolute(src_file, dst_file)
			if error != OK:
				print("Error copying file: ", file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
