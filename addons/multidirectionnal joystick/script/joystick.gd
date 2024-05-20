#====================================================================================
# Under licence CC0
# Credits are not required, but if they did it would be welcome
# by : jstnjrg
#====================================================================================

## A multidirectionnal joystick that can be configured for games with limited steering.
@tool
class_name MultidirectionnalJoystick extends Node2D

#Joystick textures
@export_group("Joystick textures")
@export var bigger_texture: CompressedTexture2D:
	set(img_t):
		bigger_texture = img_t
		if img_t: bigger_p = -img_t.get_size()*0.5
		queue_redraw()

	get: return bigger_texture
@export var small_texture: CompressedTexture2D:
	set(img_t): 
		
		small_texture = img_t
		
		if img_t: 
			smaller_offset = -img_t.get_size()*0.5
			draw_sensitivity_area = draw_sensitivity_area #update
		
		queue_redraw()
	
	get: return small_texture

@export_group("Joystick property")
@export var emulate_touch := false :## Enables touch emulation
	set(bool_t): 
		ProjectSettings.set("input_devices/pointing/emulate_touch_from_mouse",bool_t)
		emulate_touch = bool_t
#Joystick settings, such as degree of freedom and sensivity areas and error margin

## determines the degree of freedom of the joystick.
## For example, a value of 4 means 4 directions
@export_range(1,360,1,"suffix:direction") var amount_of_directions := 8:
	set(value_t): 
		
		#ensures that the array is ampty and determines the corresponding regular angle
		direction_arr.clear()
		amount_of_directions = value_t
		regular_angle = (TAU/amount_of_directions)
		
		#fill with the correct directions
		var sum := 0.0#-0.5*PI
		
		for i in amount_of_directions:
			direction_arr.append(Vector2.from_angle(sum))
			sum += regular_angle
		
		
		queue_redraw()
## touch validation area, a high number implies greater coverage.
## the opposite is valid. Also affects the range level of the minor texture.
@export_range(40.0,150.0,0.001,"or_greater","or_less") var sensitivity_area := 88.0: 
	set(value_t): 
		sensitivity_area = value_t
		draw_sensitivity_area = draw_sensitivity_area #update
		queue_redraw()
## how quickly the joystick responds when the screen is released.
@export_range(0.1,1.0,0.001) var softness_off := 0.6
## how quickly the joystick responds when the screen is pressed.
@export_range(0.1,1.0,0.001) var softness_on := 0.5
## interpolation security interval.
@export_range(4.0,20.0,0.001) var dead_margin := 4.0

#Drawing options
@export_subgroup("Drawing options")
## draw direction lines for debugging purposes.
@export var _draw_line := false:
	set(value_t): _draw_line = value_t; queue_redraw()
## draw direction circle for debugging purposes.
@export var _draw_circle := true:
	set(value_t): _draw_circle = value_t; queue_redraw()
## draw the touch sensitivity area, that is, the joystick reaction area. for debugging purposes.
@export var draw_sensitivity_area := true:
	set(value_t):
		
		draw_sensitivity_area = value_t 
		if not bigger_texture: return
		
		var delta := -Vector2.ONE*sensitivity_area-bigger_p
		touch_rect.position = bigger_p-delta.abs() if sign(delta.x) < 0 else bigger_p
		touch_rect.size = bigger_texture.get_size()+2*delta.abs() if sign(delta.x) < 0 else bigger_texture.get_size()
		
		queue_redraw()
@export var draw_sensitivity_rect := false:
	set(value_t): draw_sensitivity_rect = value_t; queue_redraw()

#Color options
@export_subgroup("Joystick colors")
@export var sensitivity_color := Color("#00e4ff26"):
	set(value_t): sensitivity_color = value_t; queue_redraw()
@export var circle_color := Color("#ff260077"):
	set(value_t): circle_color = value_t; queue_redraw()
@export var line_color := Color("#ff260077"):
	set(value_t): line_color = value_t; queue_redraw()


var regular_angle := 0.0 #proportional to the amount of freedom
var direction_arr : Array[Vector2]  #store amount of directions

#position on drawing
var bigger_p: Vector2
var smaller_p: Vector2

#Adjusts the position of the smaller texture
var smaller_offset: Vector2 

#utils
var touch_rect := Rect2(Vector2.ZERO,Vector2.ONE*100)
var indx_touch : Dictionary

#joystick signal
## sign that issued when joystick changes its state
signal joystick_change(new_pos: Vector2)
## joystick drag velocity
signal joystick_velocity(velocity: Vector2)
## the joystick drag position relative to the last frame
signal joystick_relactive(relactive: Vector2)
##
signal joystick_pressure(pressure: float)
##
signal  joystick_pressed(pressed: bool)


func _ready() -> void:
	initial()

func _unhandled_input(event: InputEvent) -> void:
	
	#returns if the event is not screentouch
	if !(event is InputEventScreenDrag) and !(event is InputEventScreenTouch): return
	
	#set touch screen
	event = event.xformed_by(transform.affine_inverse())
	
	if touch_rect.has_point(event.position):
		indx_touch[event.index] = event.position
		joystick_update(event)
	#
	elif indx_touch.has(event.index):
		joystick_update(event)
		indx_touch.clear()

func _draw() -> void:
	
	#draw the textures 
	if not bigger_texture or not small_texture: 
		return
	
	if draw_sensitivity_rect: draw_rect(touch_rect,sensitivity_color,false,2.0)
	
	draw_texture(bigger_texture,bigger_p,Color.WHITE)
	draw_texture(small_texture,smaller_p+smaller_offset,Color.WHITE)
	
	if draw_sensitivity_area: draw_circle(Vector2.ZERO,sensitivity_area,sensitivity_color)
	
	#draw line and circle
	if draw_line or draw_circle:
		var length_t := bigger_p.length()*0.7
		for p: Vector2 in direction_arr:
			if _draw_line: draw_line(Vector2.ZERO,p*length_t,line_color,3.0,true)
			if _draw_circle: draw_circle(p*length_t,4.0,circle_color)

func initial () -> void:
	amount_of_directions = amount_of_directions
	set_process_unhandled_input(true)

# Function that is responsible for updating the joystick stattus
func joystick_update (event: InputEvent) -> void:
	
	#set touch screen
	if not bigger_texture or not small_texture: 
		printerr("please set any texture")
		return
	
	var touch_position : Vector2 = event.position
	if event is InputEventScreenDrag and touch_position.length_squared() <= sensitivity_area*sensitivity_area:
		
		#snaps float value local_position to the regular_angle
		var local_position = touch_position
		var angle := snappedf(local_position.angle(),regular_angle)
		
		#shall be rotated according to the correct angle of the correct position
		local_position = Vector2.from_angle(angle)*(sensitivity_area-10.0)
		smaller_p = smaller_p.slerp(local_position,softness_on)
		
		#emit signal to update the position
		joystick_change.emit(local_position.normalized())
		joystick_velocity.emit(event.velocity)
		joystick_relactive.emit(event.relative)
		joystick_pressure.emit(event.pressure)
		
	
	#if is not pressed or is greater than sensitivity_area stop update
	elif event is InputEventScreenTouch and not event.is_pressed() or touch_position.length_squared() >= sensitivity_area*sensitivity_area:
		joystick_change.emit(Vector2.ZERO)
		
		while true:
			smaller_p = smaller_p.slerp(Vector2.ZERO,softness_off)
			if smaller_p.length_squared() <= dead_margin*dead_margin:
				smaller_p = Vector2.ZERO
				break
	
	queue_redraw()

