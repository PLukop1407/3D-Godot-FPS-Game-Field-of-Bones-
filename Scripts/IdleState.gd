class_name IdleState

extends State

func update(delta):
	if player.velocity.length() > 0.0 and player.is_on_floor():
		transition.emit("WalkingState")


