extends Node3D

@onready var blood = $BloodSplatter
@onready var terrain = $TerrainSplatter


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_timer_timout():
	queue_free()
	
	
func trigger_particles(pos, player_pos, on_enemy):
	if on_enemy:
		blood.global_position = pos
		blood.look_at(player_pos)
		blood.emitting = true
	else:
		terrain.global_position = pos
		terrain.look_at(player_pos)
		terrain.emitting = true
