extends Sprite

export var speed := 300.0
export var max_length := 30
export var color := Color.yellow

var motion : Vector2

var pos_array := []

func _process(delta: float) -> void:
	
	rotation = motion.angle() if motion.length() > 0 else rotation
	
	translate(delta*motion*speed)
	
	pos_array.append(global_position)
	
	if pos_array.size() > max_length:
		pos_array.pop_front()
	update()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	for i in pos_array.size():
		color.a = smoothstep(0,pos_array.size(),i)
		draw_circle(-Vector2.RIGHT*30+transform.xform_inv(pos_array[i]),6.0,color)



func _on_joystick_multidirectionnal_stop_update_pos(pos) -> void:
	motion = pos

func _on_joystick_multidirectionnal_update_pos(pos) -> void:
	motion = pos





