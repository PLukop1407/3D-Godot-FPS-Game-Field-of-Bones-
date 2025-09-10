extends Label

#Reference to player for retrieving player's health points
@onready var player = $"../../../Character"

func _ready():
	self.position = self.position.snapped(Vector2(1,1))
	

func _process(_delta):	
	if player:
		#If player exists, format string to display current health, i.e., 100HP
		var format_string = "{health}HP"
		var actual_string = format_string.format({"health":player.health})
		text = actual_string
	else:
		text = ""



	
