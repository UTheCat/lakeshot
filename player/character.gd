extends CharacterBody3D

## Travel speed of the character in meters per second
@export
var speed: float = 20

## Amount of air the player currently has. This can exceed max_air (e.g. after the character has picked up an air tank).
@export
var air: float = 1

## Amount of air in which the character is considered to have a full breath
@export
var max_air: float = 1

func _physics_process(delta: float) -> void:
	pass
