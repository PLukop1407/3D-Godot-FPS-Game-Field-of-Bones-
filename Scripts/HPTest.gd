## Temporary script for displaying skeleton's HP for debugging

extends Label3D

@onready var skeleton = $".."

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if skeleton:
		#If player exists, format string to display current health, i.e., 100HP
		var format_string = "SKELETON HEALTH: {health}"
		var actual_string = format_string.format({"health":skeleton.health})
		text = actual_string
		
	pass
