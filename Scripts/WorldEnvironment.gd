extends WorldEnvironment
@onready var enviroNoise = $Enviro
@onready var BGM = $BGM

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !enviroNoise.playing:
		BGM.play()
		enviroNoise.play()
	pass
