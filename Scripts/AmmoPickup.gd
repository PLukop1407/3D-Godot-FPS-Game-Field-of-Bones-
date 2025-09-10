extends Item
class_name ItemPickup

# Attach script to ammo scenes and set amount and key, otherwise it won't work. Ammo addition is based on key.
@export var ammo_amount: int
@export var ammo_key: String
#@export var weapon_manager: Node3D

# Interaction function for the player's interact ray to hook into. Adds ammo to the weapon manager. 
func interact(player):
	var weapon_manager = player.get_node("Neck/SubViewportContainer/WeaponViewport/WeaponCamera/Hand")
	if weapon_manager:
		weapon_manager.add_ammo(ammo_key, ammo_amount)
		if interact_sound:
			interact_sound.play()
	hide_label()
	queue_free()
