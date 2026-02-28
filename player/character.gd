extends CharacterBody3D

class_name Character

## Travel speed of the character in meters per second
@export
var speed: float = 20

## The character's jump velocity. This velocity is applied if the character is on the floor.
@export
var jump_velocity: float = 50

## Amount of air the player currently has. This can exceed max_air (e.g. after the character has picked up an air tank).
@export
var air: float = 1

## Amount of air in which the character is considered to have a full breath
@export
var max_air: float = 1

## "Scale" in which to move forward in the XZ plane.
## A value of 1 means full speed, and negative values mean move backward.
var forward_scale: float = 0

## "Scale" in which to move right in the XZ plane.
## A value of 1 means full speed, and negative values mean move left.
var right_scale: float = 0

## Whether or not the character wants to jump
var try_jump: bool = false

## Whether or not the character wants to climb something
var try_climb: bool = false

# Private for now since we plan to add acceleration that changes based on
# the surface material that the character is walking on.
const _ACCELERATION = 150
const _AIR_ACCELERATION = 100

## Get the character's desired move direction in the XZ plane for the given angle
func get_move_direction(angle: float) -> Vector3:
	return Vector3(right_scale, 0, forward_scale).rotated(Vector3.UP, angle)

## Returns the character's real velocity or "target" real velocity, whichever is closest to zero.
func closest_to_zero_velocity() -> Vector3:
	var target_real_velocity = velocity
	var real_velocity = get_real_velocity()
	
	return target_real_velocity if target_real_velocity.length() < real_velocity.length() else real_velocity

## Returns whether or not the character can currently climb something based on the character's current collision state.
func can_climb() -> bool:
	return false

func _physics_process(delta: float) -> void:
	var is_on_floor = is_on_floor()
	var last_velocity = velocity
	var gravity = get_gravity()
	var gravity_direction = gravity.normalized()
	
	# How much the character's velocity will change this physics frame
	var velocity_delta = Vector3.ZERO
	
	if try_jump:
		if is_on_floor or (try_climb and can_climb()):
			# Jump velocity is specified this way to support different gravity directions
			velocity_delta -= gravity_direction * jump_velocity * delta
		else:
			velocity_delta += gravity_direction * delta
	elif can_climb():
		pass
	elif not is_on_floor:
		velocity_delta += gravity_direction * delta
		
	velocity = last_velocity + velocity_delta
