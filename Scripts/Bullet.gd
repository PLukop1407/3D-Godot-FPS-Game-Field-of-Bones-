## UNUSED SCRIPT ##
## Old script for 3D Projectile bullets ##
## Guns now just use raycasts ##


extends Node3D


const SPEED = 40.0

@onready var mesh = $MeshInstance3D
@onready var particles = $GPUParticles3D
@export var damage: int = 1
var has_hit: bool = false

var shooter: Node3D
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if has_hit:
		return
	# Move bullet forward by updating global_transform.origin
	global_transform.origin += global_transform.basis.z * SPEED * delta

	var from = global_transform.origin
	var to = from + global_transform.basis.z * SPEED * delta
	
	#Painful
	#Generating raycasts dynamically instead of relying on a raycast created with the bullet.
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	# Excluding itself from the collisions list + the gun itself so that the raycasts don't nuke themselves when colliding with the gun.
	# Frankly could've been fixed by just changing collision masks actually, but fuck it.
	var exclude_list = [self]
	query.hit_from_inside = true
	if shooter != null:
		exclude_list.append(shooter)
	query.exclude = exclude_list
	
	#Query the raycast to see if it intersects with anything.
	var result = space_state.intersect_ray(query)

	#If it intersects, do shit (disable the mesh, emit particles, check if colliding with a bone, call function on beune)
	if result:
		has_hit = true
		mesh.visible = false
		particles.emitting = true
		#print("Hit something ", result.collider.get_path())
		if result.collider and result.collider.is_in_group("SkelCollision"):
			result.collider.hit(damage)
		await get_tree().create_timer(0.2).timeout
		queue_free()
#die
func _on_timer_timeout():
	queue_free()
