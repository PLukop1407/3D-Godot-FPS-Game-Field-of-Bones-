extends Node3D
class_name Weapon

## WEAPON SUPER CLASS
## Contains all of the primary logic for weapons to be inherited (firing, reloading, altfire, debug drawing, function/animation locking)


# ------------ References to Scene Components (Audio, Anim, Barrel) ------------ #
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var fire_sound: AudioStreamPlayer3D = $shoot
@onready var dry_fire_sound: AudioStreamPlayer3D = $dryfire
@onready var reload_sound: AudioStreamPlayer3D = $reload
@onready var barrel: RayCast3D = $barrel

# ------------ Weapon Parameters ------------ #
@export var bullet_impact: PackedScene
@export var weapon_name: String
@export var fire_rate: float = 1.0
@export var loaded_ammo: int = 0
@export var reserve_ammo: int = 20
@export var max_ammo: int = 10
@export var damage: int = 1
@export var is_automatic: bool = false
@export var weapon_range: float = 1.0
@export var blocking_animations: Array[String] = []

var current_ammo: int
var can_fire: bool = true
var sound_cooldown: bool = false
var is_firing: bool = false
var is_reloading: bool = false
var camera: Camera3D


# Firing function. Checks if ammo is available, spawns a bullet raycast, plays sounds and animations, or plays dry fire sound if no ammo.
func fire(shooter: Node3D):
	if not can_fire:
		return

	if current_ammo > 0:
		current_ammo -= 1
		if anim:
			anim.play("fire")
		if fire_sound:
			fire_sound.play()
		_spawn_bullet(shooter, camera)
		can_fire = false
		await get_tree().create_timer(1.0 / fire_rate).timeout
		can_fire = true
	else:
		if not sound_cooldown:
			sound_cooldown = true
			if dry_fire_sound:
				dry_fire_sound.play()
			await get_tree().create_timer(1.0).timeout
			sound_cooldown = false

# Empty function for alt firing - not every weapon will have it. Shotgun, Revolver, Rifle should use it for firing both barrels, fanning the hammer, or scoping.
func alt_fire(shooter: Node3D):
	pass

# Raycasting from gun barrel based on range - finally replaced node raycast with dynamic instantiated raycast
func _spawn_bullet(shooter: Node3D, camera: Camera3D):
	# There has to be a cleaner way to do this - variables for raycast (origin, direction, distance, etc.)
	var from = camera.global_position
	var aim_direction = -camera.global_transform.basis.z.normalized()
	var target_position = camera.global_transform.origin + aim_direction * weapon_range
	var direction = (target_position - from).normalized()
	var to = from + direction * weapon_range
	
	## DEBUG FOR DRAWING RAYCASTS - MAKE THIS AN OPTION IN DEBUG LATER ##
	draw_debug_line(from,to,Color.RED,0.5)
	
	# Raycast instantiation and querying for intersection - excludes shooter (self) so that the weapons don't collide with the player or their children nodes
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [shooter]
	
	var result = space_state.intersect_ray(query)
	
	# If collision is present, hurt enemy (if it's an enemy), spawn hit particles based on surface (skeleton, terrain)
	if result:
		var target = result.collider
		var collision_point = result.position
		var collision_normal = result.normal
		var impact = bullet_impact.instantiate()
		get_tree().current_scene.add_child(impact)
		if target and target.has_method("hit"):
			target.hit(damage)
			impact.trigger_particles(collision_point, self.global_position, true)
		else:
			impact.trigger_particles(collision_point, self.global_position, false)

# Reloading logic - reloads the maximum amount of ammo the gun can hold + the player has in reserve, determines if reloading possible, and so on
func reload():
	# If there's no ammo or already firing or already reloading or already full on ammo, do nothing
	if reserve_ammo <= 0 or current_ammo == max_ammo or not can_fire or is_reloading:
		return
	
	# Storing how much ammo current weapon is missing
	var missing_ammo = max_ammo - current_ammo
	# Storing how much ammo *can* be reloaded
	var ammo_to_reload = min(missing_ammo, reserve_ammo)
	
	# If there's any ammo to reload, block firing and reloading and play the reload anim
	if ammo_to_reload > 0:
		can_fire = false
		is_reloading = true
		anim.play("reload")
		reload_sound.play()
		await anim.animation_finished
		
		# Doublechecking how much ammo is availble and how much to reload (I don't remember if this is redundant)
		missing_ammo = max_ammo - current_ammo
		ammo_to_reload = min(missing_ammo, reserve_ammo)
		
		# Add ammo
		current_ammo += ammo_to_reload
		reserve_ammo -= ammo_to_reload
		can_fire = true
		is_reloading = false
	else:
		dry_fire_sound.play()

# Busy function to block gun functions to avoid firing while reloading or multiple simultaneous reloads, etc. Safety lock
func is_busy() -> bool:
	return is_firing or is_reloading or (anim and anim.is_playing() and anim.current_animation in blocking_animations)


#DEBUG FUNCTION FOR RAYCASTS
func draw_debug_line(from: Vector3, to: Vector3, color: Color = Color.RED, duration: float = 0.5):
	var mesh := ImmediateMesh.new()
	mesh.clear_surfaces()
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)
	mesh.surface_end()
	
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.visible = true
	
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.5
	
	
	mesh_instance.material_override = material
	
	get_tree().current_scene.add_child(mesh_instance)
	
	await get_tree().create_timer(duration).timeout
	if mesh_instance:
		mesh_instance.queue_free()

func set_camera(cam: Camera3D):
	camera = cam



