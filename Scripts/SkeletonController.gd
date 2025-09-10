# This is kind of a nightmare and I need to redo this / change a lot of it, I won't comment this yet, we don't really need to change this anyway.

extends CharacterBody3D

@export var player_path : NodePath #Needs the player object to follow - change this in the future.
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0
@export var roam_radius: float = 10.0
@onready var anim_player = $AnimationPlayer
@onready var nav_agent = $NavigationAgent3D
@onready var boneNoise = $BoneSounds
@onready var nav_region = nav_agent.get_navigation_map()

const WALK_SPEED = 1.8
const CHASE_SPEED = 6.4
# Skeleton states
enum SkelState { IDLE, CHASE, ATTACK, DAMAGED, DEAD }

# Variables, could export so that they can be changed in the editor
var player = null
var health = 200.0
var speed
var current_state: SkelState = SkelState.IDLE
var idle_timer = 0.0
var idle_wait_time = 2.0
var current_idle_target = Vector3.ZERO
var reached_idle_target := true
var time_since_last_attack: float = 0.0
var attack_anim_duration: float = 0.0
var is_attacking: bool = false


func _ready():
	player = get_node(player_path)
	speed = WALK_SPEED

# Switch case for executing corresponding state logic
func _process(delta):
	#Global.debug_panel.add_property("SkeletonState", current_state, 5)
	match current_state:
		SkelState.IDLE:
			update_idle(delta)
		SkelState.CHASE:
			update_chase(delta)
		SkelState.ATTACK:
			update_attack(delta)
		SkelState.DAMAGED:
			update_damaged(delta)
		SkelState.DEAD:
			pass

# Idle state walks around between random navigation nodes until the player gets too close (10 units of distance)

func update_idle(delta):
	speed = WALK_SPEED
	#anim_player.speed_scale = 1.0

	# Check if player is close
	if global_position.distance_to(player.global_position) < 10.0 and not player.is_dead:
		current_state = SkelState.CHASE
		return
		
	# Wait and until it can find a new node to navigate to
	if reached_idle_target:
		idle_timer -= delta
		if idle_timer <= 0.0:
			pick_new_idle_target()
		# Play idle animation while doing nothing	
		if anim_player.current_animation != "idle":
			anim_player.play("idle")
			
	# Wander to the next navigation point
	else:
		nav_agent.set_target_position(current_idle_target)
		var next_point = nav_agent.get_next_path_position()
		var direction = (next_point - global_transform.origin).normalized()
		velocity = direction * speed
		move_and_slide()
		rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
		
		if anim_player.current_animation != "walkForward":
			anim_player.play("walkForward")
		
		if global_position.distance_to(current_idle_target) < 1.0:
			reached_idle_target = true
			idle_timer = idle_wait_time

# Chase state - just runs at the player using built-in navigation to walk around terrain
func update_chase(delta):
	#NAVIGATION
	speed = CHASE_SPEED
	#anim_player.speed_scale = 4.0
	
	# Go back to idle once player is dead
	if player.is_dead:
		return_to_idle()
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Attack once within melee range
	if distance_to_player <= attack_range:
		current_state = SkelState.ATTACK
		return
	
	# Play sprinting animation while chasing
	if anim_player.current_animation != "sprint":
		anim_player.play("sprint")
		
	# Navigate towards player
	velocity = Vector3.ZERO
	nav_agent.set_target_position(player.global_transform.origin)
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_transform.origin).normalized() * speed
	rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
	
	#LOOK AT PLAYER
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	if !boneNoise.playing:
		boneNoise.play()
	move_and_slide()
	
# Attack state
func update_attack(delta):
	if player.is_dead:
		return_to_idle()
		return
	
	# Tying the attack to attack animation length
	if is_attacking:
		time_since_last_attack += delta
		if time_since_last_attack >= attack_anim_duration:
			is_attacking = false
			if global_position.distance_to(player.global_position) > attack_range:
				current_state = SkelState.CHASE
		return
	
	
	velocity = Vector3.ZERO
	move_and_slide()
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)

	# Do some damage in the range 10-30 when attacking player
	if anim_player.current_animation != "hit":
		anim_player.play("hit")
		attack_anim_duration = anim_player.current_animation_length
		time_since_last_attack = 0.0
		is_attacking = true
		player.take_damage(randf_range(10,30))

# Stop skeleton on damage
func update_damaged(delta):
	velocity = Vector3.ZERO
	move_and_slide()
		
# Register damage from player weapons and play the hurt animation
func hit(damage: int):
	health -= damage
	$BoneHit.play()
	if health <= 0:	
		queue_free()
	
	
	current_state = SkelState.DAMAGED
	anim_player.play("hit2")
	await anim_player.animation_finished
	
	current_state = SkelState.CHASE

# Helper function for picking the next nav node when idle based on roam range
func pick_new_idle_target():
	var offset = Vector3(
		randf_range(-roam_radius, roam_radius),
		0,
		randf_range(-roam_radius, roam_radius)
	)
	var raw_target = global_position + offset
	current_idle_target = NavigationServer3D.map_get_closest_point(nav_region, raw_target)
	reached_idle_target = false


func return_to_idle():
	current_state = SkelState.IDLE
	pick_new_idle_target()
