# Some multimesh nonsense

extends MultiMeshInstance3D

func _ready():
	multimesh.set_instance_transform(0,Transform3D(Basis(),Vector3(0,0,0)))
