extends Weapon
class_name LMG

# LMG doesn't have any special functions, so all this does is just set up animations that block functions for safety
func _ready():
	blocking_animations = ["draw", "fire", "reload", "startFiring", "endFiring"]
