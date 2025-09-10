# Debug Panel script for displaying debug properties (FPS, Weapon Manager Status, AI status, Player State, etc.)


extends PanelContainer

@onready var property_container = %DebugInfoText
var property
var fps : String

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.debug_panel = self
	visible = false

func _input(event):
	if event.is_action_pressed("Debug"):
		visible = !visible
		
func _process(delta):
	if visible:
		fps = "%.2f" % (1.0/delta)
		add_property("FPS", fps, 1)
		
func add_property(title: String, value, order):
	var target
	target = property_container.find_child(title,true,false)
	if !target:
		target = Label.new()
		property_container.add_child(target)
		target.name = title
		target.text = target.name + ": " + str(value)
	elif visible:
		target.text = title + ": " + str(value)
		property_container.move_child(target,order)

