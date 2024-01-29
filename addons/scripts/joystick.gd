#====================================================================================
# Under licence CC0
# Credits are not required, but if they did it would be welcome
# A multidirectionnal joystick that can be configured for games with limited steering.
# by : jstnjrg
#====================================================================================
tool
extends Node2D
class_name joystick ,"res://addons/icon.svg"

#Joystick textures
export(Texture) var bigger_texture setget js_set_bigger
export(Texture) var small_texture setget js_set_smaller

#Enables touch emulation
export var emulate_touc := true setget js_set_emulate_touch

#Joystick settings, such as degree of freedom and sensivity areas and error margin
export(int,"linear interpolation","curve interpolation") var interpolation_mode : int = 0
export(float,1.0,5.0) var interpolation_time := 1.0
export var interpolation_curve : Curve

export(int,1,360) var amount_of_directions := 8 setget js_set_amount
export var sensitivity_area := 88.0
export(float,0.1,1.0) var softness_off := 0.6

export(float,0.1,1.0) var softness_on := 0.5
export var circles_offset := 64.0
export(float,4.0,20.0) var dead_margin := 4.0

#Drawing options
export var draw_line := false setget js_draw_line
export var draw_circle := true setget js_draw_circle
export var draw_sensitivity_area := false setget js_draw_area

#Color options
export(Color) var sensitivity_color := Color("#6a00c3ff")
export(Color) var circle_color := Color.white
export(Color) var line_color := Color("#73ffffff")


var regular_angle := 0.0 #proportional to the amount of freedom
var direction_array : Array  #store amount of directions

#position on drawing
var bigger_texture_pos: Vector2
var smaller_texture_pos: Vector2

#Adjusts the position of the smaller texture
var smaller_offset: Vector2 

#joystick signal
signal update_pos(pos)
signal stop_update_pos (pos)
signal update_interpolation (dt,pos)


func _init():
	connect("update_interpolation",self,"js_interpolation_curve")

func _ready() -> void:
	initial()
	set_process_input(true)


func _input(event: InputEvent) -> void:
	
	#returns if the event is not screentouch
	if !(event is InputEventScreenDrag) and !(event is InputEventScreenTouch):
		return
	
	#set touch screen
	var touch_position : Vector2 = to_local(event.position)
	
	
	if event is InputEventScreenDrag and touch_position.length() <= sensitivity_area:
		
		var local_position = touch_position
		#snaps float value local_position to the regular_angle
		var angle := stepify(local_position.angle(),regular_angle)
		
		#shall be rotated according to the correct angle of the correct position
		local_position = Vector2.RIGHT.rotated(angle)*(sensitivity_area-10.0)
		smaller_texture_pos = smaller_texture_pos.linear_interpolate(local_position,softness_on)
		
		#emit signal to update the position
		emit_signal("update_pos",local_position.normalized())
	
	#if is not pressed or is greater than sensitivity_area stop update
	
	elif event is InputEventScreenTouch and not event.is_pressed() or touch_position.length() >= sensitivity_area:
		
		emit_signal("stop_update_pos",Vector2.ZERO)
		
		#Interpolation the return of the texture
		match interpolation_mode:
			0: 
				
				while true:
					smaller_texture_pos = smaller_texture_pos.linear_interpolate(Vector2.ZERO,softness_off)
					if smaller_texture_pos.length() <= dead_margin:
						smaller_texture_pos = Vector2.ZERO
						break
			1:
				#Interpolation of position according to curve
				var t_pos = smaller_texture_pos
				var temp := 0
				
				while true:
					# smoothstep(0.0,100*interpolation_time,temp)
					var dt := range_lerp(temp,0.0,5*interpolation_time,0.0,5.0)
					emit_signal("update_interpolation",dt,t_pos)
					temp += 1
					
					if temp > 5*interpolation_time:
						break
	
	get_tree().set_input_as_handled()
	update()

func _draw() -> void:
	
	#stop execution if there is no reference for some texture
	if not bigger_texture or not small_texture:
		printerr("bigger texture or smaller texture is null, please set any texture")
		if not Engine.editor_hint: get_tree().quit(-1)
	
	#draw the textures 
	draw_texture(bigger_texture,bigger_texture_pos,Color.white)
	draw_texture(small_texture,smaller_texture_pos+smaller_offset,Color.white)
	
	# drawings are perfomed down in order to debug
	# please at run time disables these options
	
	if draw_sensitivity_area: 
		draw_circle(Vector2.ZERO,sensitivity_area,sensitivity_color)
	
	#draw line and circle
	if draw_line or draw_circle:
#		if not Engine.editor_hint: push_warning("in order to improve perfomance, consider in disabling the debug drawings")
		for p in direction_array:
			if draw_line: draw_line(Vector2.ZERO,p*78,line_color,5.0)
			if draw_circle: draw_circle(p*(bigger_texture_pos.length()-circles_offset),6.0,circle_color)

#joystick required conditions
func initial():
	if direction_array.empty():
		js_set_angle(amount_of_directions)

# Joystick setters and getters

func js_interpolation_curve(value: float, t_pos: Vector2) -> void:
	var dt := interpolation_curve.interpolate_baked(value)
	smaller_texture_pos = t_pos*dt


func js_draw_line(value: bool) -> void:
	draw_line = value
	update()

func js_draw_circle(value: bool) -> void:
	draw_circle = value
	update()

func js_draw_area(value: bool) -> void:
	draw_sensitivity_area = value
	update()

func js_set_angle(value: int) -> void:
	
	#ensures that the array is ampty and determines the corresponding regular angle
	direction_array.clear()
	amount_of_directions = value
	regular_angle = TAU/amount_of_directions
	
	#fill with the correct directions
	var sum := 0.0
	
	for i in amount_of_directions:
		direction_array.append(Vector2.UP.rotated(sum))
		sum += regular_angle

func js_set_amount(value: int):
	js_set_angle(value)
	update()

#Receive the textures assigned to the drawing
func js_set_bigger(texture: Texture)->void:
	
	if texture :
		bigger_texture = texture
		bigger_texture_pos = -texture.get_size()*0.5
	
	else: bigger_texture = null
	update()

func js_set_smaller(texture: Texture)->void:
	
	if texture :
		small_texture = texture
		smaller_offset = -texture.get_size()*0.5
	
	else : small_texture = null
	update()

func _get_configuration_warning() -> String:
	if not get_parent() is CanvasLayer:
		return "For it to be fixed on the screen, this scene must be son of a CanvasLayer"
	return ""

func js_set_emulate_touch(value: bool) -> void:
	emulate_touc = value
	ProjectSettings.set("input_devices/pointing/emulate_touch_from_mouse",emulate_touc)


