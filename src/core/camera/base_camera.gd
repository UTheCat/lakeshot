## Base class for a game camera whose main use is to focus on a particular point in space
extends Camera3D
class_name BaseCamera

## The smallest allowed pitch angle in radians
@export
var min_pitch: float = -0.5 * PI

## The largest allowed pitch angle in radians
@export
var max_pitch: float = 0.5 * PI

var _min_zoom_out_distance = 0

## The smallest allowable distance (in meters) from the point that the camera is focusing on
@export
var min_zoom_out_distance: float:
	get: return _min_zoom_out_distance
	set(value):
		_min_zoom_out_distance = value
		_clamp_zoom_out_distance()

var _max_zoom_out_distance = 15

## The largest allowable distance (in meters) from the point that the camera is focusing on
@export
var max_zoom_out_distance: float:
	get: return _max_zoom_out_distance
	set(value):
		_max_zoom_out_distance = value
		_clamp_zoom_out_distance()

@export
## The point that the camera should focus on. It's recommended to set this to a Node3D.
var focus_point: Node3D = null

## The offset of the camera's position to the right relative to the point that the camera is focusing on
var right_offset: float = 0

var _zoom_out_distance: float = min_zoom_out_distance

## How far zoomed out (in meters) that the camera is from the point that the camera is focusing on
var zoom_out_distance: float:
	get: return _zoom_out_distance
	set(value): _set_zoom_out_distance(value)

func _clamp_zoom_out_distance(): _set_zoom_out_distance(_zoom_out_distance)

func _set_zoom_out_distance(value):
	_zoom_out_distance = clamp(value, min_zoom_out_distance, max_zoom_out_distance)
	zoom_out_distance_set.emit(value)

## (Forcefully) updates the camera's position
func update_position():
	global_position = get_desired_position()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_rotation.x = clamp(global_rotation.x, min_pitch, max_pitch)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void: update_position()
	
func _get_focus_point_position(): return Vector3.ZERO if focus_point == null else focus_point.global_position

## Returns the "target" position of the camera that's used when there are no obstructions between
## the camera's focus point and the target position of the camera
func get_desired_position():
	var cam_pos = _get_focus_point_position()
	var c_zoom_out_dist = zoom_out_distance
	if c_zoom_out_dist == 0: return cam_pos
	c_zoom_out_dist = clamp(c_zoom_out_dist, min_zoom_out_distance, max_zoom_out_distance)
	
	var cam_rot = global_rotation
	var pitch = -cam_rot.x
	var transform_horizontal_dist = c_zoom_out_dist * cos(pitch)
	var transform_height = c_zoom_out_dist * sin(pitch)
	cam_pos += Vector3(right_offset, transform_height, transform_horizontal_dist).rotated(Vector3.UP, cam_rot.y)
	
	return cam_pos

## Sets the global-space rotation of the camera to the Vector3 specified.
## This function respects the value restrictions on the camera's pitch, yaw, and roll that are defined in this class.
func set_rotation_clamped(rot: Vector3):
	global_rotation = Vector3(clamp(rot.x, min_pitch, max_pitch), rot.y, rot.z)

## Emitted when the value of zoom_out_distance is set
## The first and only argument of this signal is whatever zoom_out_distance was set to.
##
## Note: It is not necessary for zoom_out_distance to be set to a different value for this signal to be emitted.
signal zoom_out_distance_set
