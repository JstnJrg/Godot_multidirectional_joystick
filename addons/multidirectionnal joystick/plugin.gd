@tool
extends EditorPlugin

const joystick_script := preload("res://addons/multidirectionnal joystick/script/joystick.gd")
const joystick_icon := preload("res://addons/multidirectionnal joystick/icons/icon.svg")

func _enter_tree():
	add_custom_type("MultidirectionnalJoystick","Node2D",joystick_script,joystick_icon)

func _exit_tree():
	remove_custom_type("MultidirectionnalJoystick")
