class_name TS extends OptionButton

@export_dir var textures_dir : String
@export  var bigger := true


func _ready():
	search()


func search():
	
	var dir := DirAccess.open(textures_dir)
	
	if dir:
		
		dir.list_dir_begin()
		var file_n := dir.get_next()
		
		while  file_n !="":
			
			if dir.current_is_dir(): pass
			else : 
				if file_n.get_extension() != "svg" : pass
				elif file_n.begins_with("b" if bigger else "s"): 
					add_item(file_n.get_basename())
					set_meta(file_n.get_basename(),textures_dir+"/"+file_n)
			
			file_n = dir.get_next()
		
		dir.list_dir_end()
	
