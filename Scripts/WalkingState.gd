class_name WalkingState

extends State

func update(delta):
	if player.velocity.length() == 0.0:
		transition.emit("IdleState")
