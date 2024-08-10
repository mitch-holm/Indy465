extends RigidBody3D

var CRUISE_CONTROL = 14
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	set_linear_velocity(Vector3.MODEL_REAR * CRUISE_CONTROL)
	pass
