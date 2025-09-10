## Old skeleton script, not in use anymore

extends Node3D

@onready var skelAnim = $AnimationPlayer
@export var player_path : NodePath
const SPEED = 2.0
var player = null

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node(player_path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	velocity = Vector3.ZERO
	
	if !skelAnim.is_playing():
		skelAnim.play()
		

