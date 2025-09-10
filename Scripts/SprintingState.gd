extends State
class_name SprintingState

func enter():
	player.speed = player.SPRINT_SPEED

func update(_delta):
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	player.direction = (player.player_neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if player.direction.length() == 0.0:
		transition.emit("IdleState")
	elif not Input.is_action_pressed("Sprint"):
		transition.emit("WalkingState")

	if Input.is_action_just_pressed("Jump") and player.touching_floor:
		transition.emit("JumpingState")

func physics_update(delta):
	player._handle_ground_movement()
	player._handle_headbob(delta)
