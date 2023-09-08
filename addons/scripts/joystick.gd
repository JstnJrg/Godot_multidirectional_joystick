# Under licence CC BY
# A multidirectionnal joystick that can be configured for games with limited steering.
# by : jstnjrg 2023

tool
extends Node2D
class_name joystick ,"res://addons/icons/icon.svg"

export(Texture) var bigger_texture setget _set_bigger
export(Texture) var small_texture setget _set_smaller

export var emulate_touc := true setget _set_emulate_touch
export var amount_of_directions := 8 setget _setamount
export var sensitivity_area := 88.0

export var softness_off := 0.6
export var softness_on := 0.5
export var texture_offset := 64.0

export var draw_line := false setget _draw_line
export var draw_circle := true setget _draw_circle
export var draw_sensitivity_area := false setget _draw_area


export(Color) var sensitivity_color := Color("#6a00c3ff")
export(Color) var circle_color := Color.white
export(Color) var line_color := Color("#73ffffff")

var regular_angle := 0.0 
var direction_array := []
var pos : Vector2

var bigger_pos: Vector2
var small_pos: Vector2

var const_pos: Vector2


signal update_pos(pos)
signal stop_update_pos (pos)

func _ready() -> void:
	
	if direction_array.size() == 0:
		_setangle(amount_of_directions)
	
	set_process_input(true)

func _input(event: InputEvent) -> void:

	if !(event is InputEventScreenDrag) and !(event is InputEventScreenTouch):
		return
	
	var touch_pos : Vector2 = to_local(event.position)

	if event is InputEventScreenDrag and touch_pos.length() <= sensitivity_area:
		
		pos = touch_pos
		var angle := stepify(pos.angle(),regular_angle)
		
		pos = Vector2.RIGHT.rotated(angle)*(sensitivity_area-10.0)
		small_pos = small_pos.linear_interpolate(pos,softness_on)
		
		emit_signal("update_pos",pos.normalized())

	
	elif event is InputEventScreenTouch and not event.is_pressed() or touch_pos.length() >= sensitivity_area:
		
		emit_signal("stop_update_pos",Vector2.ZERO)
		
		while true:
			small_pos = small_pos.linear_interpolate(Vector2.ZERO,softness_off)
			
			if small_pos.length() == 0:
				break
	
	update()


#Setters and getters
func _draw_line(value: bool) -> void:
	draw_line = value
	update()

func _draw_circle(value: bool) -> void:
	draw_circle = value
	update()

func _draw_area(value: bool) -> void:
	draw_sensitivity_area = value
	update()

func _setangle(value: int) -> void:
	
	var sum := 0.0
	
	direction_array.clear()
	amount_of_directions = value
	regular_angle = deg2rad(360.0/amount_of_directions)
	
	for i in amount_of_directions:
		direction_array.append(Vector2.UP.rotated(sum))
		sum += regular_angle

func _setamount(value: int):
	_setangle(value)
	update()

func _set_bigger(texture: Texture)->void:
	bigger_texture = texture
	if texture != null:
		bigger_pos = -texture.get_size()*0.5
		update()

func _set_smaller(texture: Texture)->void:
	small_texture = texture
	if texture != null:
		const_pos = -texture.get_size()*0.5
		update()

func _get_configuration_warning() -> String:
	if not get_parent() is CanvasLayer:
		return "For it to be fixed on the screen, this scene must be son of a CanvasLayer"
	return ""


func _draw() -> void:
	
	draw_texture(bigger_texture,bigger_pos,Color.white)
	draw_texture(small_texture,small_pos+const_pos,Color.white)

	if draw_sensitivity_area: draw_circle(Vector2.ZERO,sensitivity_area,sensitivity_color)
	
	if not draw_line and not draw_circle:
		return
	
	for p in direction_array:
		if draw_line: draw_line(Vector2.ZERO,p*78,line_color,5.0)
		if draw_circle: draw_circle(p*(bigger_pos.length()-texture_offset),6.0,circle_color)

func _set_emulate_touch(value: bool) -> void:
	emulate_touc = value
	ProjectSettings.set("input_devices/pointing/emulate_touch_from_mouse",emulate_touc)


