extends CharacterBody3D
## Lakeshot character.
##
## Designed to support the playback of Flood Escape 2 maps.

class_name Character

## Amount of air that's considered "full-breath".
## [br][br]
## Keep in mind that the actual amount of air that the character
## has at any given moment can exceed this amount
## (which is what happens when the player picks up an air tank)
@export
var max_air: float = 100.0

## Character's walk speed in meters per second
@export
var speed: float = 20
