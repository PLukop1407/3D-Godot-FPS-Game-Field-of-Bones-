extends Node3D
class_name Item

# ------------ BASE ITEM CLASS ------------ # 
# Some important exports for the item template
@export var item_name: String = "BASE ITEM"
@export var interact_text: String = "Press [E] to pick up {item_name}"
@export var interact_sound: AudioStreamPlayer3D
@export var auto_pickup: bool = false
@export var label: Label3D
var player_camera: Camera3D = null


# Setup item label and player camera reference on ready
func _ready():
	if label == null:
		print("Error, Label3D reference not found in Item: %s" % self.name)
	else:
		update_text()
	player_camera = get_tree().get_current_scene().get_node("Character/Neck/Camera3D")
	#print("Label nodel class: ", label.get_class())
	#print("Label node type info: ", label)
	
# 
func _process(delta):
	# Constantly rotate to face the player while visible
	if label and label.visible and player_camera:
		var label_pos = label.global_transform.origin
		var cam_pos = player_camera.global_transform.origin
		
		cam_pos.y = label_pos.y
		
		label.look_at(cam_pos, Vector3.UP)
		label.rotate_y(deg_to_rad(180))

func interact(player):
	#No generic interact function, just destroys item on interaction.
	get_parent().queue_free()

# Function for showing the item label if item is interactible
func show_label():
	label.show()

# Hide player label once not interactible
func hide_label():
	label.hide()

func update_text():
	label.text = interact_text.format({"item_name": item_name})
