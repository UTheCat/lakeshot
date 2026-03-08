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

## If set to true, the character will instantly face the direction of the camera's yaw
## every frame.
## Otherwise, the character's yaw will try to gradually turn to the character's desired move direction
var fast_turn_enabled: bool = false

## If non-null, this Camera3D's current view direction will be used
## as the character's desired move direction
var direction_camera: Camera3D = null

var _climb_hitbox: Area3D = null
var _climb_direction_cast: ShapeCast3D = null
var _step_climb_cast: ShapeCast3D = null

var _last_xz_velocity: Vector2 = Vector2.ZERO

# The "vertical" velocity based on the gravity vector
# Needs to be stored separately from other velocities because
# gravity vector is not necessarily (0, -1, 0)
var _last_vertical_velocity: Vector3 = Vector3.ZERO

# Private for now to support future implementation of different acceleration values based on
# surface material
const _ACCELERATION = 600
const _AIR_ACCELERATION = 400

const _VELOCITY_DIFF_SNAP_THRESHOLD = 0.1
	
func _on_ready():
	_climb_hitbox = get_node("ClimbHitbox")
	_climb_direction_cast = get_node("ClimbDirectionCast")
	_step_climb_cast = get_node("StepClimbCast")

func _physics_process(delta: float) -> void:
	var last_xz_velocity = _last_xz_velocity
	var last_vertical_velocity = _last_vertical_velocity
	
	var c_is_on_floor = is_on_floor() # Are we currently on the floor?
	var gravity = get_gravity()
	var gravity_direction = gravity.normalized()
	
	# How much the character's velocity will change this physics frame
	#var velocity_delta = Vector3.ZERO
	
	var is_trying_to_move = is_trying_to_move()
	var move_direction = get_move_direction(direction_camera.yaw if direction_camera != null else 0)
	var accel = _ACCELERATION if c_is_on_floor else _AIR_ACCELERATION
	var next_xz_velocity = _approach_xz_velocity(last_xz_velocity, Vector2(move_direction.x, move_direction.z), accel, delta)
	var next_vertical_velocity = last_vertical_velocity
	
	if try_jump:
		if c_is_on_floor or (try_climb and can_climb()):
			# Jump velocity is specified this way to support different gravity directions
			next_vertical_velocity = -gravity_direction * jump_velocity * delta
		else:
			next_vertical_velocity += gravity_direction * delta
	elif can_climb():
		var climb_velocity = 0
		var can_apply_climb_velocity = false
		
		if is_trying_to_move:
			pass
		else:
			climb_velocity = 0
	elif not c_is_on_floor:
		next_vertical_velocity += gravity_direction * delta
	
	_last_xz_velocity = next_xz_velocity
	_last_vertical_velocity = next_vertical_velocity
	
	velocity = Vector3(next_xz_velocity.x, 0, next_xz_velocity.y) + next_vertical_velocity
	move_and_slide()
	
func _approach_xz_velocity(current_vel: Vector2, goal_vel: Vector2, accel: float, physics_delta_time: float):
	var direction = (goal_vel - current_vel).normalized()
	var xz_velocity_delta = direction * accel * physics_delta_time
	var final_vel = current_vel + xz_velocity_delta
	
	# To prevent unwanted movement due to floating-point precision errors
	var new_xz_vel_diff = goal_vel - final_vel
	if new_xz_vel_diff.length() <= _VELOCITY_DIFF_SNAP_THRESHOLD or not is_zero_approx(new_xz_vel_diff.normalized().angle() - direction.angle()):
		final_vel = goal_vel
		
	return final_vel

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

## Returns whether or not the character is currently trying to move
func is_trying_to_move() -> bool: return forward_scale != 0 && right_scale != 0
