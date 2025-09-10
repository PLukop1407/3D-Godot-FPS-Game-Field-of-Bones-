extends RayCast3D

@onready var camera = $".."

const INTERACT_LENGTH := 5.0

#Storing a reference to the previously picked up item because Label3D sucks and doesn't nuke itself even if its parent is gone.
var last_item: Item = null

func _process(_delta):
	
	#global_transform.origin = camera.global_transform.origin
	#target_position = camera.global_transform.basis.z * -INTERACT_LENGTH
	#var start = global_transform.origin
	#var end = start + target_position
	
	#Check if interaction raycast is colliding with an item
	if is_colliding():
		var collider = get_collider()
		#print("Colliding with: %s" % collider)
		var item = _find_item_root(collider)

		#???? idk man, Label3D is just bizarre
		if item:
			if item != last_item:
				if last_item:
					last_item.hide_label()
				last_item = item

			item.show_label()
		else:
			_clear_label() # I hate that this is somehow necessary
	else:
		_clear_label()

func _clear_label():
	if last_item:
		last_item.hide_label()
		last_item = null

func _find_item_root(collider: Node) -> Item:
	while collider and not (collider is Item):
		collider = collider.get_parent()
	return collider if collider is Item else null

#Important part - collision checks if the node's root has a collider with a script that can call interact()
func interact(player):
	if is_colliding():
		var item = _find_item_root(get_collider())
		if item:
			item.hide_label()
			item.interact(player)
			last_item = null
