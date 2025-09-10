## Subclass of Item
## Holds the weapon scene that needs to be added to the weapon manager

extends Item
class_name WeaponPickup

@export var weapon: PackedScene

func interact(player):
	if player:
		if player.weapon_manager:
			player.weapon_manager.add_weapon(weapon, item_name)
			if interact_sound:
				print("Playing sound")
				interact_sound.play()
	hide_label()
	get_parent().queue_free()	
