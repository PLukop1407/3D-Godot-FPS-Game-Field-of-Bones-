extends Node3D
class_name WeaponManager

# ------- WEAPON INVENTORY --------- #
# Dictionary Key:Value pairs, strings correspond to weapon instances. "shotgun" = Shotgun Object
var weapon_slots: Dictionary = {
	"melee": null,
	"revolver": null,
	"shotgun": null,
	"rifle": null,
	"lmg": null
}

# Dictionary for holding weapon ammo - can hold ammo even if the player doesn't have the corresponding gun
var ammo_queue: Dictionary = {
	"revolver": 0,
	"shotgun": 0,
	"rifle": 0,
	"lmg": 0
}

@export var crosshair_raycast: RayCast3D
var camera: Camera3D

#Currently equipped weapon and key
var current_key: String = ""
var current_weapon: Weapon = null
var is_firing: bool = false

# Testing function, not used in the game.
func equip_weapon(weapon_scene: PackedScene):
	if current_weapon:
		current_weapon.queue_free()
		
	current_weapon = weapon_scene.instantiate() as Weapon
	add_child(current_weapon)
	
# Equip via dictionary key, rewritten instead of WeaponSlots crap
func equip_weapon_from_slot(weapon_key: String) -> void:
	if not weapon_slots.has(weapon_key):
		print("Invalid weapon: %s" % weapon_key)
		return
	
	var weapon_instance: Weapon = weapon_slots[weapon_key]
	if weapon_instance == null:
		print("Weapon slot '%s' is empty" % weapon_key)
		return
	
	if current_weapon != null:
		#current_weapon.anim.play("stow") ## Stow animation disabled for better flow
		#await current_weapon.anim.animation_finished
		current_weapon.hide()
		current_weapon.set_process(false)
		
	current_weapon = weapon_instance
	current_key = weapon_key
	current_weapon.set_camera(camera)
	current_weapon.anim.play("draw")
	current_weapon.show()
	current_weapon.set_process(true)
	
	
func add_weapon(weapon_scene: PackedScene, weapon_key: String):
	if not weapon_slots.has(weapon_key):
		push_error("Invalid weapon slot key! %s", weapon_key)
		return
	
	var weapon_instance := weapon_scene.instantiate() as Weapon
	weapon_instance.hide()
	weapon_instance.set_process(false)
	weapon_instance.current_ammo = weapon_instance.loaded_ammo
	add_child(weapon_instance)

	weapon_slots[weapon_key] = weapon_instance

	if ammo_queue.get(weapon_key, 0) > 0:
		weapon_instance.reserve_ammo += ammo_queue[weapon_key]
		ammo_queue[weapon_key] = 0

	# Auto-equip first weapon
	if current_weapon == null:
		equip_weapon_from_slot(weapon_key)		
	
func fire_weapon(shooter: Node3D, firemode: int):
	if current_weapon:
		if firemode == 1:
			current_weapon.fire(shooter)
		else:
			current_weapon.alt_fire(shooter)

func reload_weapon():
	if current_weapon:
		current_weapon.reload()
		
func get_weapon_by_key(weapon_key: String) -> Weapon:
	return weapon_slots.get(weapon_key, null)
	

func add_ammo(weapon_key: String, ammo_amount: int):
	if not weapon_slots.has(weapon_key):
		print("No key '%s' found in weapon dictionary" % weapon_key)
		return
	
	if weapon_slots[weapon_key]:
		weapon_slots[weapon_key].reserve_ammo += ammo_amount
	else:
		ammo_queue[weapon_key] += ammo_amount
		
func can_switch() -> bool:
	return current_weapon != null and not current_weapon.is_busy()

func set_camera(cam: Camera3D):
	camera = cam
	
	
func get_debug_weapon_slots() -> Array:
	var readable_slots := []
	for key in weapon_slots.keys():
		var weapon = weapon_slots[key]
		if weapon:
			readable_slots.append(weapon.weapon_name)
		else:
			readable_slots.append("empty")
	return readable_slots
