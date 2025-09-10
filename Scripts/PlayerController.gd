class_name PlayerController

extends CharacterBody3D

# This is an incredibly long script that needs a lot of decoupling.
# Movement system can be swapped out for a proper state machine to avoid tons of conditional checks each frame
# Camera shake / bobbing can easily be done with an animation controller, as opposed to hard coding the bobbing via tons of math


# WALK_SPEED & SPRINT_SPEED used to change speed var for when sprint button input is handled.
# speed var used in physics function for movement.
const ACCELERATION = 0.1
const DECCELERATION = 0.25
const SLOW_WALK_SPEED = 2.5
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const MAX_HP = 100
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003
const CROUCH_HEIGHT_SCALE = 0.5
const CROUCH_SPEED = 2.0 
const CROUCH_CAMERA_OFFSET_Y = -0.5

# CAMERA BOB variables for sine wave in _headbob()
const BOB_FREQ_X = 1.5
const BOB_FREQ_Y = 2.6
const BOB_FREQ_Z = 2.0
const BOB_AMP_X = 0.03
const BOB_AMP_Y = 0.025
const BOB_AMP_Z = 0.015
var tBOB = 0.0

#----------------------------------------------------------------------------------------------------------------------------------------------

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") 

# A bunch of ready variables, I need to clean this up at some point.
@export_category("Nodes and Cameras")
@export var player_neck: Node3D
@export var weapon_manager: WeaponManager
@export var player_camera: Camera3D
@export var weapon_camera: Camera3D
@export var head_clearance_shape: ShapeCast3D
@export var interact_ray: RayCast3D
@export var state_machine: StateMachine
@export_category("Misc")
@export var animPlayer: AnimationPlayer
@export var plyFlashlight: SpotLight3D
@export var run_sound: AudioStreamPlayer3D
@onready var sound_has_played = false
@onready var collider_shape = $CollisionShape3D.shape as CapsuleShape3D

#----------------------------------------------------------------------------------------------------------------------------------------------

var onGround = true
var is_dead: bool = false
var speed
var health
var direction: Vector3 = Vector3.ZERO
var is_sprinting: bool = false
var is_walking: bool = false
var speed_modifier: float = 1.0
var touching_floor: bool = false
var is_firing: bool = false
var is_crouching: bool = false
var original_collider_height: float
var original_neck_y: float

func _ready():
	# Initialising various variables on start
	original_collider_height = collider_shape.height
	original_neck_y = player_neck.transform.origin.y
	speed = WALK_SPEED
	health = MAX_HP
	weapon_manager.set_camera(player_camera)
	state_machine.player = self
	#state_machine._ready()
	

# Mouse controls
func _input(event: InputEvent):
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#if esc pressed
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			player_neck.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			player_camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			player_camera.rotation.x = clamp(player_camera.rotation.x, deg_to_rad(-110.0), deg_to_rad(90.0))

func _process(_delta):
	weapon_camera.global_transform = player_camera.global_transform
	Global.debug_panel.add_property("WeaponList", weapon_manager.get_debug_weapon_slots(),2)
	Global.debug_panel.add_property("EquippedWep",weapon_manager.current_weapon.weapon_name if weapon_manager.current_weapon else "empty",3)
	Global.debug_panel.add_property("Velocity", self.velocity.length(),4)

func _physics_process(delta):
	if is_dead:
		return
		
	# CACHING if the player is on the floor to reduce the fifty thousand is_on_floor() calls throughout the script, the engine will thank me
	touching_floor = is_on_floor()
	
	# Delegate I/O to functions (switch to state machine later)
	_handle_input()
	_handle_movement(delta)
	#state_machine._physics_process(delta)
	_update_crouch_state(delta)
	_handle_weapons()
	_handle_misc_actions()
	
	#if is_on_ceiling() and velocity.y > 0:
		#velocity.y = 0

func _handle_input():
	# Inputs from the Project Input Action settings.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	direction = (player_neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var crouch_pressed = Input.is_action_pressed("Crouch")
	# Variable for determining if the player can stand up
	var crouch_blocked = head_clearance_shape.is_colliding()
	
	
	# Logical nightmare to make the crouching function properly. Can probably clean up the nesting and vagueness
	if crouch_pressed:
		if not is_crouching:
			is_crouching = true
	else:
		if is_crouching and not crouch_blocked:
			is_crouching = false
	
	if is_crouching:
		speed = CROUCH_SPEED
		is_sprinting = false
		is_walking = false
	else:
		is_sprinting = Input.is_action_pressed("Sprint")
		is_walking = Input.is_action_pressed("Walk")
		
		if is_sprinting:
			speed = SPRINT_SPEED
		elif is_walking:
			speed = SLOW_WALK_SPEED
		else:
			speed = WALK_SPEED
		
	# @Robin, this is some hacky pitch shifting to have the walking/running/sprinting sound different, I don't know if we want separate sounds later or what
	run_sound.pitch_scale = 1.1 if is_sprinting else (0.9 if is_walking else 1.0)
	speed_modifier = 0.9 if is_sprinting else (0.6 if is_walking else 0.75)
	
func _handle_movement(delta):
	# Apply gravity on player
	if not touching_floor:
		velocity.y -= gravity * delta
		
	# Stop vertical velocity when colliding with ceiling (stops clipping)
	if head_clearance_shape.is_colliding() and velocity.y > 0:
		velocity.y = 0
	
	_handle_jump()
	_handle_landing()
	_handle_headbob(delta)
	
	# Logic for handling movement (If on the floor and holding a movement key -> move, else deccelerate, if not touching floor, handle air movement)
	if touching_floor:
		if direction != Vector3.ZERO:
			_handle_ground_movement()
		else:
			_handle_ground_inertia(delta)
	else:
		_handle_air_movement(delta)
	#Moving the player
	move_and_slide()

func _handle_weapons():
	# Shooting logic, oh no
	
	# Some hacky logic for automatic weapons (LMG) with a separate, repeating function to repeatedly fire while the button is held down
	if weapon_manager.current_weapon:
		if weapon_manager.current_weapon.is_automatic:
			if Input.is_action_pressed("Fire"):
				if not weapon_manager.is_firing:
					is_firing = true
					_start_auto_fire()
				else:
					is_firing = false
		else:
			# If weapon isn't automatic, just fir the weapon normally. The second parameter is for determining if to call fire() or altfire()
			if Input.is_action_just_pressed("Fire"):
				weapon_manager.fire_weapon(self, 1)

	if Input.is_action_just_pressed("AltFire"):
		weapon_manager.fire_weapon(self, 2)	
		
	# Reload equipped weapon
	if Input.is_action_just_pressed("Reload"):
		weapon_manager.reload_weapon()
		
	# Switch weapon - I don't like this and need to change this at some point
	if weapon_manager.can_switch():
		if Input.is_action_just_pressed("Weapon1") and weapon_manager.current_key != "revolver":
			weapon_manager.equip_weapon_from_slot("revolver")
		if Input.is_action_just_pressed("Weapon2") and weapon_manager.current_key != "shotgun":
			weapon_manager.equip_weapon_from_slot("shotgun")
		if Input.is_action_just_pressed("Weapon3") and weapon_manager.current_key != "rifle":
			weapon_manager.equip_weapon_from_slot("rifle")
		if Input.is_action_just_pressed("Weapon4") and weapon_manager.current_key != "lmg":
			weapon_manager.equip_weapon_from_slot("lmg")

func _handle_misc_actions():
	
	#Flashlight logic - invert flashlight state on press
	if Input.is_action_just_pressed("Light"):
		plyFlashlight.visible = not plyFlashlight.visible
		$flashLight.play()
		
	#Interact action, calls pickup method from ray.
	if Input.is_action_just_pressed("Interact"):
		interact_ray.interact(self)	
		
		
# Sine wave function for determining the camera position while moving.
func _headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ_Y) * BOB_AMP_Y
	pos.x = cos(time * BOB_FREQ_X) * BOB_AMP_X
	pos.z = sin(time * BOB_FREQ_Z + 0.5) * BOB_AMP_Z #Z axis amp adds a lil bit of a phase shift, makes it cleaner
	return pos
	
# Best function - reduce health by damage amount. If you have no health, die.
func take_damage(damage_amount: int):
	health -= damage_amount
	if health <= 0:
		die()
	
# Hacky death fucntion - uses tweening to rotate and transform camera position to imitate the player 'falling and dying'
func die():
	if is_dead:
		return
	is_dead = true
	# Stop a bunch of crap from working when dead
	run_sound.stop()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Disable weapon and flashlight
	plyFlashlight.visible = false
	if weapon_manager.current_weapon:
		weapon_manager.current_weapon.hide()
	
	# I hate this tween nonsense, it barely works, and this could've been easily done with a player animation, get rid of this asap
	var tween := create_tween()
	var target_pos = player_camera.transform.origin - Vector3(0, 1.25, 0)
	tween.tween_property(player_camera, "rotation_degrees:x", 60, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(player_camera, "transform:origin", target_pos, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)



func _handle_jump():
	# nothing special, check if on the floor, stop running sound, make the player go up
	if Input.is_action_just_pressed("Jump") and touching_floor:
		velocity.y = JUMP_VELOCITY
		$JumpNoise.play()
		run_sound.stop()
		onGround = false

func _handle_landing():
	if touching_floor and not onGround and velocity.y ==0:
		$LandNoise.play()
		onGround = true

func _handle_headbob(delta):
	tBOB += delta * velocity.length() * float(touching_floor) * speed_modifier


func _handle_ground_movement():
	# Ground movement is way too convoluted, largely due to the headbobbing logic. Once headbobbing is just an anim, a lot of this becomes cleaner
	var bob_offset = _headbob(tBOB)
	var final_offset = bob_offset 
	
	var cam_transform = player_camera.transform
	#cam_transform.origin = final_offset
	player_camera.transform = cam_transform  # ??? what
	
	# apply headbobbing to weapon
	if weapon_manager.current_weapon:
		var weapon_transform = weapon_manager.current_weapon.transform
		weapon_transform.origin = bob_offset
		weapon_manager.current_weapon.transform = weapon_transform
		
	# linear interpolation for player acceleration, movetowards is probably better, need to check
	velocity.x = lerp(velocity.x, direction.x * speed, ACCELERATION)
	velocity.z = lerp(velocity.z, direction.z * speed, ACCELERATION)
	
	
	# Hacky logic for not playing footstep sounds if the player isn't "stepping" based on bobbing pattern
	var step = sin(tBOB * BOB_FREQ_Y)
	if step < -0.99 and not sound_has_played:
		run_sound.play()
		sound_has_played = true
	elif step > -0.5:
		sound_has_played = false

# Decceleration for ground movement
func _handle_ground_inertia(delta):
	run_sound.stop()

	var target_offset = Vector3.ZERO
	
	var cam_transform = player_camera.transform
	cam_transform.origin = cam_transform.origin.lerp(target_offset, delta * 2.0)
	player_camera.transform = cam_transform
	
	if weapon_manager.current_weapon:
		var weapon_transform = weapon_manager.current_weapon.transform
		weapon_transform.origin = weapon_transform.origin.lerp(target_offset, delta * 6.0)
		weapon_manager.current_weapon.transform = weapon_transform
		
	velocity.x = move_toward(velocity.x, 0, DECCELERATION)
	velocity.z = move_toward(velocity.z, 0, DECCELERATION)

# Air movement, more linear interpolation
func _handle_air_movement(delta):
	run_sound.stop()
	velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
	velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)

# Convoluted mess to change the player collider size and camera position to make them "crouch"
func _update_crouch_state(delta):
	var target_height = original_collider_height
	var target_neck_y = original_neck_y
	
	# is_crouching determined by input
	if is_crouching:
		target_height = original_collider_height * CROUCH_HEIGHT_SCALE
		target_neck_y = original_neck_y + CROUCH_CAMERA_OFFSET_Y
	
	# Some linear interpolation for collider height so that player height doesn't *instantly* snap down
	collider_shape.height = lerp(collider_shape.height, target_height, delta * 10)
	
	var shape_transform = $CollisionShape3D.transform
	shape_transform.origin.y = collider_shape.height / 2
	$CollisionShape3D.transform = shape_transform
	
	# Moving the neck since everything is attached to it (camera, interact ray, hand, weapon cam)
	var neck_transform = player_neck.transform
	neck_transform.origin.y = lerp(neck_transform.origin.y, target_neck_y, delta * 10.0)
	player_neck.transform = neck_transform

# Not a fan of this function, couldn't figure out a better way to do auto weapons for now
func _start_auto_fire():
	# While current weapon is uatomatic and firing, call the fire_weapon function based on weapon fire rate
	while is_firing and weapon_manager.current_weapon and weapon_manager.current_weapon.is_automatic:
		if not Input.is_action_pressed("Fire"):
			is_firing = false
			break

		weapon_manager.fire_weapon(self, 1)
		await get_tree().create_timer(1.0 / weapon_manager.current_weapon.fire_rate).timeout
