# Under licence CC BY
# A multidirectionnal joystick that can be configured for games with limited steering.
# by : jstnjrg 2023

tool
extends Node2D
class_name joystick ,"res://addons/icons/icon.svg"

export(Texture) var bigger_texture  setget setbigger
export(Texture) var small_texture setget setsmaller

export var emulate_touc := true setget _setemulatetouch
export var amount_of_directions := 8 setget _setamount
export var sensitivity_area := 78.0

export var softness_off := 0.6
export var softness_on := 0.5

export var draw_line := false
export var draw_circle := true
export var draw_sensitivity_area := false


export(Color) var sensitivity_color := Color("#6a00c3ff")
export(Color) var circle_color := Color.white
export(Color) var line_color := Color("#73ffffff")

var regular_angle := 0.0 
var direction_array := []
var pos : Vector2

var bigger: Sprite 
var small: Sprite 

signal update_pos(pos)
signal stop_update_pos (pos)

func _ready() -> void:
	_free()
	if direction_array.size() == 0:
		_setangle(amount_of_directions)
	set_process_input(true)

func _input(event: InputEvent) -> void:
	
	if !(event is InputEventScreenDrag) and !(event is InputEventScreenTouch):
		return
	
	elif bigger == null or small == null:
		if get_child_count() > 0:
			bigger = get_child(0)
			if bigger.get_child_count() > 0:
				small = bigger.get_child(0)
		else : return
	
	var touch_pos : Vector2 = bigger.to_local(event.position)
	
	if event is InputEventScreenDrag and touch_pos.length() <= sensitivity_area:
		pos = touch_pos
		var angle := stepify(pos.angle(),regular_angle)
		pos = Vector2.RIGHT.rotated(angle)*(sensitivity_area-10.0)
		small.position = small.position.linear_interpolate(pos,softness_on)
		emit_signal("update_pos",pos.normalized())

	elif event is InputEventScreenTouch and not event.is_pressed() or touch_pos.length() >= sensitivity_area:
		emit_signal("stop_update_pos",Vector2.ZERO)
		while true:
			small.position = small.position.linear_interpolate(Vector2.ZERO,softness_off)
			if small.position.length() == 0:
				break
	
	update()

func setbigger(texture: Texture ) -> void:
	
	bigger_texture = texture
	
	if bigger != null :
		bigger.texture = bigger_texture
		return
	
	elif bigger == null and get_child_count() >= 1 :
		bigger= get_child(0)
		bigger.texture = bigger_texture
		return
	
	
	bigger = Sprite.new()
	bigger.name = "bigger"
	bigger.texture = texture
	add_child(bigger)
	bigger.set_owner(owner)

func setsmaller(texture: Texture ) -> void:
	
	small_texture = texture
	
	if bigger == null:
		if small != null:
			small.queue_free()
		return
	
	else:
		if bigger.get_child_count() >= 1:
			small = bigger.get_child(0)
			small.texture = small_texture
			return
	
	small = Sprite.new()
	small.name = "small"
	small.texture = texture
	bigger.add_child(small)
	small.set_owner(owner)

func _setangle(value: int) -> void:
	
	var sum := 0.0
	amount_of_directions = value
	
	direction_array.clear()
	
	regular_angle = deg2rad(360.0/amount_of_directions)
	
	for i in amount_of_directions:
		direction_array.append(Vector2.UP.rotated(sum))
		sum += regular_angle

func _setamount(value: int):
	_setangle(value)
	update()

func _get_configuration_warning() -> String:
	if not get_parent() is CanvasLayer:
		return "For it to be fixed on the screen, this scene must be son of a CanvasLayer"
	return ""

func _draw() -> void:
	
	if bigger != null:
		draw_set_transform_matrix(bigger.transform)
	
	if draw_sensitivity_area: draw_circle(Vector2.ZERO,sensitivity_area,sensitivity_color)
	
	for p in direction_array:
		if draw_line: draw_line(Vector2.ZERO,p*78,line_color,5.0)
		if draw_circle: draw_circle(p*78,6.0,circle_color)

func _setemulatetouch(value: bool) -> void:
	emulate_touc = value
	ProjectSettings.set("input_devices/pointing/emulate_touch_from_mouse",emulate_touc)

func _free():
	if get_child_count() > 1:
		get_child(1).queue_free()
		var son = get_child(0)
		if son.get_child_count() > 1:
			son.get_child(1).queue_free()
