extends ColorRect

func update_screen_params():
	var screen_res = get_tree().get_root().size;
	get_viewport().size = screen_res;
	custom_minimum_size = screen_res;
	material.set("shader_parameter/monitor_resolution", Vector2(screen_res.x, screen_res.y))
	print(material.get("shader_parameter/monitor_resolution"))
	
# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().get_root().size_changed.connect(resize)
	update_screen_params()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func resize():
	update_screen_params()
