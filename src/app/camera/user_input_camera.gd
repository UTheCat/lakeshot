## Subclass of BaseCamera that allows the camera to respond to user input
extends BaseCamera
class_name UserInputCamera

const INPUT_ROTATE = "camera_rotate";
const INPUT_ZOOM_IN = "camera_zoom_in"
const INPUT_ZOOM_OUT = "camera_zoom_out"

const _BASE_ROTATION_SPEED = 0.4
const _ROTATION_SPEED_MULTIPLIER_MOUSE = 0.02

var _is_turning_camera = false

## Whether or not the camera is currently being turned
var is_turning_camera: bool:
	get: return _is_turning_camera

func _set_is_turning_camera(value):
	var value_changed = value != _is_turning_camera
	_is_turning_camera = value
	if (value_changed): is_turning_camera_toggled.emit()

## Scale for how quickly the camera rotates for the same user input.
## A value of 0 means the camera won't rotate on user input.
## Negative values mean for the same user input, the camera will turn in the reverse direction.
var rotation_sensitivty: float = 1 # This variable is not visible in the Godot editor because this should be adjusted in user settings UI.

## On keyboard and mouse, this is how much the camera will zoom in or out
## for every keyboard press or scroll increment that triggers a camera zoom change
@export
var zoom_adjustment: float = 1

## Reference to a Control that's intended to absorb mouse input as a means of preventing
## unwanted hover and click behavior
var rotation_invisible_overlay: Control = null

var _original_cursor_pos: Vector2i = Vector2i.ZERO
var _can_rotate_in_underscore_input = false

func stop_camera_turn():
	if (_is_turning_camera):
		_set_is_turning_camera(false)
		_can_rotate_in_underscore_input = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		DisplayServer.warp_mouse(_original_cursor_pos)

func _input(event: InputEvent) -> void:
	# This is checked before anything else as a failsafe
	if not _free_rotation_input_pressed(): stop_camera_turn()
	
	if _is_turning_camera and _can_rotate_in_underscore_input and event is InputEventMouseMotion:
		var rotation_overlay = rotation_invisible_overlay
		if rotation_overlay != null and rotation_overlay.visible:
			_mouse_turn_camera(event as InputEventMouseMotion)

func _unhandled_input(event: InputEvent) -> void:
	var rotation_overlay = rotation_invisible_overlay
	if _free_rotation_input_pressed():
		if (not _is_turning_camera):
			_set_is_turning_camera(true)
			_original_cursor_pos = DisplayServer.mouse_get_position()
			
			if (rotation_overlay != null): rotation_overlay.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		stop_camera_turn()
	
	# Turn camera based on mouse input
	if (_is_turning_camera and event is InputEventMouseMotion):
		# To prevent race conditions, we must null-check rotation_overlay
		# before setting _can_rotate_in_underscore_input
		if (rotation_overlay == null):
			_can_rotate_in_underscore_input = true
			_mouse_turn_camera(event as InputEventMouseMotion)
		elif not _can_rotate_in_underscore_input:
			_can_rotate_in_underscore_input = true
			_mouse_turn_camera(event as InputEventMouseMotion)
	
	# Handle input for adjusting the camera's zoom
	if Input.is_action_pressed(INPUT_ZOOM_IN):
		zoom_out_distance -= zoom_adjustment
	elif Input.is_action_pressed(INPUT_ZOOM_OUT):
		zoom_out_distance += zoom_adjustment

func _free_rotation_input_pressed():
	return Input.is_action_pressed(INPUT_ROTATE)

func _mouse_turn_camera(mouse_event):
	var mouse_movement = mouse_event.relative
	var rotation_factor = rotation_sensitivty * _BASE_ROTATION_SPEED * _ROTATION_SPEED_MULTIPLIER_MOUSE
	
	var old_global_rot = global_rotation
	set_rotation_clamped(Vector3(old_global_rot.x - mouse_movement.y * rotation_factor, old_global_rot.y - mouse_movement.x * rotation_factor, old_global_rot.z))

## Emitted when the value of is_turning_camera changes
signal is_turning_camera_toggled
