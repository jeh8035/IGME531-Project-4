extends Camera3D

## Camera with flying script attached to it.
class_name Freecam3D

##
## Camera with toggleable freecam mode for prototyping when creating levels, shaders, lighting, etc.
##
## Usage: Run your game, press <TAB> and fly around freely. Uses Minecraft-like controls.
##

## Customize your own toggle key to avoid collisions with your current mappings.
@export var toggle_key: Key = KEY_TAB
## Speed up / down by scrolling the mouse whell down / up
@export var invert_speed_controls: bool = false

@export var overlay_text: bool = true

## Pivot node for camera looking around
@onready var pivot := Node3D.new()
## Main parent for camera overlay.
@onready var screen_overlay := VBoxContainer.new()
## Container for the chat-like event log.
@onready var event_log := VBoxContainer.new()

var audio_stream_meta : AudioStreamSynchronized
var audio_stream_calm : AudioStreamInteractive
var audio_stream_action : AudioStreamRandomizer
var audio_player_bright : AudioStreamPlayer

const MAX_SPEED := 20
const MAX_SPEED_HYPERSPACE := 40
const MIN_SPEED := 0.1
const ACCELERATION := 0.5
const MOUSE_SENSITIVITY := 0.002

## Whether or not the camera can move.
var movement_active := false:
	set(val):
		movement_active = val
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if movement_active else Input.MOUSE_MODE_VISIBLE)
		display_message("[Movement ON]" if movement_active else "[Movement OFF]")

## The current maximum speed. Lower or higher it by scrolling the mouse wheel.
@export var target_speed := 20.0
## Movement velocity.
var velocity := Vector3.ZERO

var _is_ready : bool = false

## Sets up pivot and UI overlay elements.
func _setup_nodes() -> void:
	self.add_sibling(pivot)
	pivot.position = position
	pivot.rotation = rotation
	pivot.name = "FreecamPivot"
	self.reparent(pivot)
	self.position = Vector3.ZERO
	self.rotation = Vector3.ZERO
	# UI stuff
	screen_overlay.add_theme_constant_override("Separation", 8)
	self.add_child(screen_overlay)
	screen_overlay.add_child(_make_label("Debug Camera"))
	screen_overlay.add_spacer(false)
	
	screen_overlay.add_child(event_log)
	screen_overlay.visible = overlay_text
	_is_ready = true


func _ready() -> void:
	$"../AudioStreamPlayer".play()
	audio_stream_meta = $"../AudioStreamPlayer".stream
	audio_stream_calm = audio_stream_meta.get_sync_stream(0) 
	audio_stream_action = audio_stream_meta.get_sync_stream(1)
	audio_player_bright = $"../AudioStreamPlayer2"
	_setup_nodes.call_deferred()
	movement_active = false


var rand_timer : float = 15

func _process(delta: float) -> void:
	
	if Input.is_action_just_released("toggle"):
		movement_active = not movement_active
	
	if movement_active:
		var dir = Vector3.ZERO
		if Input.is_action_pressed("forward"):	dir.z -= 1
		if Input.is_action_pressed("backward"):		dir.z += 1
		if Input.is_action_pressed("left"):		dir.x -= 1
		if Input.is_action_pressed("right"):	dir.x += 1
		if Input.is_action_pressed("up"):		dir.y += 1
		if Input.is_action_pressed("down"):		dir.y -= 1
		
		dir = dir.normalized()
		dir = dir.x * pivot.global_basis.x + dir.y * pivot.global_basis.y + dir.z * pivot.global_basis.z  
		
		velocity = lerp(velocity, dir * target_speed, 1 - exp(-ACCELERATION * delta))
		pivot.position += velocity
		
		# Randomize next audio clip (Workaround for https://github.com/godotengine/godot/issues/105929)
		audio_stream_calm.set_clip_auto_advance_next_clip(0, [1, 2, 3, 4, 5].pick_random())
		audio_stream_calm.set_clip_auto_advance_next_clip(1, [0, 2, 3, 4, 5].pick_random())
		audio_stream_calm.set_clip_auto_advance_next_clip(2, [0, 1, 3, 4, 5].pick_random())
		audio_stream_calm.set_clip_auto_advance_next_clip(3, [0, 1, 2, 4, 5].pick_random())
		audio_stream_calm.set_clip_auto_advance_next_clip(4, [0, 1, 2, 3, 5].pick_random())
		audio_stream_calm.set_clip_auto_advance_next_clip(5, [0, 1, 2, 3, 4].pick_random())
		
		var target_volume : float
		if velocity.length() == 0:
			target_volume = 0
		else:
			target_volume = min(velocity.length() / target_speed, 1) * (target_speed/20)
		#audio_stream.set_sync_stream_volume(0, lerp(max(audio_stream.get_sync_stream_volume(0), -60.0), linear_to_db(target_volume), 1 - exp(-0.75 * delta)))
		#
		
		rand_timer -= delta
		if target_volume > 0.5 and !audio_player_bright.playing:
			rand_timer -= delta
			if rand_timer <= 0.0:
				audio_player_bright.play()
				rand_timer = randf_range(5.0, 30.0)
		
		target_volume = max(remap(target_volume, 0.5, 1.0, 0.0, 1.0), 0.0)
		audio_stream_meta.set_sync_stream_volume(1, lerp(max(audio_stream_meta.get_sync_stream_volume(1), -60.0), max(linear_to_db(target_volume), -60.0), 1 - exp(-0.50 * delta)))
		#audio_stream.set_sync_stream_volume(2, linear_to_db(1.0 - target_volume))


func _input(event: InputEvent) -> void:
	if movement_active:
		# Turn around
		if event is InputEventMouseMotion:
			if _is_ready:
				pivot.rotate(pivot.global_basis.x, -event.relative.y * MOUSE_SENSITIVITY)
				pivot.rotate(pivot.global_basis.y, -event.relative.x * MOUSE_SENSITIVITY)
			#pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			#rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			#rotation.x = fmod(rotation.x + PI/2, PI) - PI/2 # clamp(rotation.x, -PI/2, PI/2)
		
		var speed_up = func():
			target_speed = clamp(target_speed + 0.15, MIN_SPEED, MAX_SPEED)
			display_message("[Speed up] " + str(target_speed))
			
		var slow_down = func():
			target_speed = clamp(target_speed - 0.15, MIN_SPEED, MAX_SPEED)
			display_message("[Slow down] " + str(target_speed))
		
		# Speed up and down with the mouse wheel
		#if event is InputEventMouseButton:
			#if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				#slow_down.call() if invert_speed_controls else speed_up.call()
				#
			#if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				#speed_up.call() if invert_speed_controls else slow_down.call()


## Pushes new message label into "chat" and removes the old ones if necessary
func display_message(text: String) -> void:
	while event_log.get_child_count() >= 3:
		event_log.remove_child(event_log.get_child(0))
	
	event_log.add_child(_make_label(text))


func _make_label(text: String) -> Label:
	var l = Label.new()
	l.text = text
	return l


func _add_key_input_action(name: String, key: Key) -> void:
	var ev = InputEventKey.new()
	ev.physical_keycode = key
	
	InputMap.add_action(name)
	InputMap.action_add_event(name, ev)
