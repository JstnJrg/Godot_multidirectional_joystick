tool
extends EditorPlugin

var joyustick := preload("res://addons/scene/joystick.tscn")


func _enter_tree() -> void:
	add_custom_type("joystick multidirectionnal","Node2D",preload("res://addons/scripts/joystick.gd"),preload("res://addons/icons/icon.svg"))

func _exit_tree() -> void:
	remove_custom_type("joystick multidirectionnal")

