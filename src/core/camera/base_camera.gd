## Base class for a game camera whose main use is to focus on a particular point in space
extends Camera3D
class_name BaseCamera

## The smallest allowed pitch angle in radians
@export
var min_pitch: float = -0.5 * PI

## The largest allowed pitch angle in radians
@export
var max_pitch: float = 0.5 * PI

## The smallest allowable distance (in meters) from the point that the camera is focusing on
@export
var min_zoom_out_distance: float = 0;

## The largest allowable distance (in meters) from the point that the camera is focusing on
@export
var max_zoom_out_distance: float = 15;

@export
## The point that the camera should focus on. It's recommended to set this to a Node3D.
var focus_point: Node3D = null

## The offset of the camera's position to the right relative to the point that the camera is focusing on
var right_offset: float = 0

var _zoom_out_distance: float = min_zoom_out_distance

## How far zoomed out (in meters) that the camera is from the point that the camera is focusing on
var zoom_out_distance: float:
	get: return _zoom_out_distance
	set(value):
		_zoom_out_distance = value
		zoom_out_distance_set.emit(value)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_rotation.x = clamp(global_rotation.x, min_pitch, max_pitch)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = get_desired_position()
	
func _get_focus_point_position(): return Vector3.ZERO if focus_point == null else focus_point.global_position

## Returns the "target" position of the camera that's used when there are no obstructions between
## the camera's focus point and the target position of the camera
func get_desired_position():
	var cam_pos = _get_focus_point_position()
	var c_zoom_out_dist = zoom_out_distance
	if c_zoom_out_dist == 0: return cam_pos
	
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
