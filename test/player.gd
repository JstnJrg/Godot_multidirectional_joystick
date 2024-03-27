extends Sprite

export var speed := 300.0
export var max_length := 60
export var color := Color.yellow

var motion : Vector2

var pos_array := []

func _process(delta: float) -> void:
	
	rotation = lerp_angle(rotation,motion.angle(),0.3) if motion.length() > 0 else rotation
	translate(delta*motion*speed)
	
	if motion: pos_array.append(global_position)
	
	if pos_array.size() >= max_length:
		pos_array.pop_front()
	update()


func _draw() -> void:
	draw_set_transform_matrix(get_parent().transform)
	for i in pos_array.size():
		color.a = (float(i)/pos_array.size())*0.8
		draw_circle(transform.affine_inverse()*(pos_array[i])-Vector2(65,0)*0.5,6.0*color.a,color)


func _on_joystick_multidirectionnal_stop_update_pos(pos) -> void:
	motion = pos

func _on_joystick_multidirectionnal_update_pos(pos) -> void:
	motion = pos
	


