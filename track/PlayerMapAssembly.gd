extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var startingPosition = $TrackMesh.get_meta("starting_position")
	var startingRotation = $TrackMesh.get_meta("starting_rotation_rad")
	
	var playerTransform: Transform3D = $CharacterBody3D.transform
	playerTransform = playerTransform.rotated_local(Vector3(0.0, 1.0, 0.0), startingRotation)
	playerTransform.origin = Vector3(startingPosition.x, playerTransform.origin.y, startingPosition.y)

	$CharacterBody3D.transform = playerTransform

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
