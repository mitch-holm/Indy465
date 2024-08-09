extends CharacterBody3D

const ACCEL = 5
const BRAKE = 3
var speed = 0
const TURN_SPEED = .2
const MAX_SPEED = 30

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Get the input direction and handle the movement/deceleration.
	if Input.is_action_pressed("steer_left"):
		rotation += Vector3(0,1,0) * delta * TURN_SPEED
		
	if Input.is_action_pressed("steer_right"):
		rotation -= Vector3(0,1,0) * delta * TURN_SPEED
	
	if Input.is_action_pressed("accelerate") && is_on_floor():
		if speed < MAX_SPEED:
			speed += ACCEL * delta
	
	if Input.is_action_pressed("brake") && is_on_floor():
		speed -= BRAKE * delta
		
	if speed != 0:
		global_transform.origin -= transform.basis.z.normalized() * speed * delta		

	move_and_slide()
