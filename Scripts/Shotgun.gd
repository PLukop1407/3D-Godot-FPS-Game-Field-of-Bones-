extends Weapon
class_name Shotgun

#Differs from super class by being a spread gun, so it has pellets, a spread angle, and an altfire sound
@export var MIN_pellets_per_shot: int = 1
@export var MAX_pellets_per_shot: int = 2
@export var spread_angle: float = 8.0
@onready var fire_sound_alt = $altShoot


func _ready():
	blocking_animations = ["draw", "fire", "altFire", "reload"]


#Different fire function because it's built different
func fire(shooter: Node3D):
	if not can_fire:
		return

	if current_ammo > 0:
		current_ammo -= 1
		var pellets = randf_range(MIN_pellets_per_shot, MAX_pellets_per_shot)
		anim.play("fire")
		fire_sound.play()
		
		
		#For each pellet, randomise the spread angle based on preset angle deviation in spread_angle, spawn pellet with that spread, reference to gun, and damage.
		for i in range(pellets):
			var spread = Vector3(
				randf_range(-spread_angle, spread_angle),
				randf_range(-spread_angle, spread_angle),
				0
			)
			_spawn_pellet(spread, shooter)

		can_fire = false
		await get_tree().create_timer(1.0 / fire_rate).timeout
		can_fire = true
	else:
		if not sound_cooldown:
			sound_cooldown = true
			dry_fire_sound.play()
			await get_tree().create_timer(1.0).timeout
			sound_cooldown = false
			
func alt_fire(shooter: Node3D):
	if not can_fire:
		return
	
	#Alt fire works the same way as normal fire, but it uses two rounds and doubles up the pellets + sound.
	if current_ammo == 2:
		current_ammo = 0
		var pellets = randf_range(MIN_pellets_per_shot, MAX_pellets_per_shot)
		anim.play("altFire")
		fire_sound_alt.pitch_scale = 0.5
		fire_sound_alt.play()
		fire_sound.play()

		for i in range(pellets * 2):
			var spread = Vector3(
				randf_range(-spread_angle, spread_angle),
				randf_range(-spread_angle, spread_angle),
				0
			)
			_spawn_pellet(spread, shooter)

		can_fire = false
		await get_tree().create_timer(1.0 / fire_rate).timeout
		can_fire = true
		fire_sound.pitch_scale = 1.0
	else:
		# If it doesn't have two shells loaded, it calls fire, which handles what to do if there's only 1 or 2 shells.
		fire(shooter)


func _spawn_pellet(spread: Vector3, shooter: Node3D):
	# Shotgun shoots from barrel, can change to crosshair_raycast.globaL_position to shoot from centre camera
	var from = barrel.global_position
	var aim_direction = -camera.global_transform.basis.z.normalized()
	var target_position = camera.global_transform.origin + aim_direction * weapon_range
	var direction = (target_position - from).normalized()
	
	direction = direction.rotated(Vector3.UP, deg_to_rad(spread.y))
	direction = direction.rotated(Vector3.RIGHT, deg_to_rad(spread.x))
	direction = direction.normalized()
	
	var to = from + direction * weapon_range
	
	
	## DEBUG: Drawing raycasts to see if it works.
	draw_debug_line(from,to,Color.RED,0.5)
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [shooter]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var target = result.collider
		var collision_point = result.position
		var impact = bullet_impact.instantiate()
		get_tree().current_scene.add_child(impact)
		if target and target.has_method("hit"):
			target.hit(damage)
			impact.trigger_particles(collision_point, self.global_position, true)
		else:
			impact.trigger_particles(collision_point, self.global_position, false)
			

	
func reload():
	if reserve_ammo <= 0 or current_ammo == max_ammo or not can_fire:
		return
	
	# TO DO: Add logic for reloading left/right barrel, also need to track which barrel fired if we want to be fancy
	# Still need the animations for that
	while reserve_ammo > 0 and current_ammo < max_ammo:
		can_fire = false
		anim.play("reload")
		reload_sound.play()
		await anim.animation_finished
		
		var missing_ammo = max_ammo - current_ammo
		var shells_to_reload = min(2, missing_ammo, reserve_ammo)
	
		if shells_to_reload > 0:
			current_ammo += shells_to_reload
			reserve_ammo -= shells_to_reload
		
	can_fire = true

