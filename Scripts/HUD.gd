extends Label

#References to player and weapon manager on the player, need to change this probably
@onready var player = get_node("/root/Main/Character")
#@onready var weapon_manager = player.get_node("/Neck/SubViewportContainer/WeaponViewport/WeaponCamera/Hand")
@export var weapon_manager: Node3D

func _ready():
	self.position = self.position.snapped(Vector2(1,1))
	


func _process(_delta):
	#If weapon manager is initialised, and a weapon is equipped, display ammo via string formatting.
	if weapon_manager and weapon_manager.current_weapon:	
		var format_string = "{loaded} / {reserve}"
		var actual_string = format_string.format({"loaded":weapon_manager.current_weapon.current_ammo, "reserve":weapon_manager.current_weapon.reserve_ammo})
		text = actual_string
	else:
		text = " / "



	

	
	
