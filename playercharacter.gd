extends CharacterBody3D

const ACCEL = 10.0
const BRAKE = 15.0
var speed = 0.0
var turn = 0.0
const TURN_SPEED = 10.0
const MAX_TURN_SPEED = 10.0
const TURN_REDUCTION = 6.0
const MAX_SPEED = 30.0
const SPEED_REDUCTION = 3.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Get the input direction and handle the movement/deceleration.
	if Input.is_action_pressed("steer_left"):
		turn += TURN_SPEED * delta
		
	if Input.is_action_pressed("steer_right"):
		turn -= TURN_SPEED * delta
	
	if Input.is_action_pressed("accelerate") && is_on_floor():
		if speed <= MAX_SPEED:
			speed += ACCEL * delta
			speed = min(speed,MAX_SPEED)
	
	if Input.is_action_pressed("brake") && is_on_floor():
		speed -= BRAKE * delta
		speed = max(speed,-MAX_SPEED)
			
		
	if turn != 0:
		turn = fixedInterpToZero(turn, TURN_REDUCTION, delta)


	if speed != 0:
		if abs(turn) >= (MAX_TURN_SPEED * (1-(abs(speed)/(MAX_SPEED + 2.0)))): 
			turn = MAX_TURN_SPEED * (1 if turn > 0 else -1) * (1.0-(abs(speed)/(MAX_SPEED + 2.0)))
		global_transform.origin -= transform.basis.z.normalized() * speed * delta
		speed = fixedInterpToZero(speed, SPEED_REDUCTION, delta)
		rotation += Vector3(0,1,0) * delta * turn * (speed/MAX_SPEED)

	move_and_slide()

func fixedInterpToZero(val, rate, delta):
	if abs(val) < abs(rate) * delta:
		return 0
	else:
		return val - (rate * delta * (1 if val > 0 else -1))
	
