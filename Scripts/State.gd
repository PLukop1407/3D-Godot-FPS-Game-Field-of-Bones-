class_name State

extends Node

signal transition(new_state_name: StringName)

@onready var player : PlayerController = get_parent().player

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	pass
