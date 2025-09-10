extends Weapon
class_name Revolver

func _ready():
	blocking_animations = ["draw", "reload", "triggerPull", "triggerRelease"]


# Unique firing function because Boz's cool animations include a separate trigger pull and release, logic vaguely maps to only firing once the mouse press is released
# I guess half button presses are real B-)
func fire(shooter: Node3D):
	if not can_fire:
		return

	if current_ammo > 0:
		anim.play("triggerPull")
		can_fire = false
		await anim.animation_finished
		fire_sound.play()
		current_ammo -= 1
		anim.play("triggerRelease")
		_spawn_bullet(shooter, camera)
		await get_tree().create_timer(1.0 / fire_rate).timeout
		can_fire = true
	else:
		if not sound_cooldown:
			sound_cooldown = true
			if dry_fire_sound:
				dry_fire_sound.play()
			await get_tree().create_timer(1.0).timeout
			sound_cooldown = false
