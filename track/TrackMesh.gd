extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var quads_per_row: int = get_meta("quads_per_row")
	var track_texture: CompressedTexture2D = $TrackMap.texture
	var track_image: Image = track_texture.get_image()
	var square_image_width: int = 500
	# Adding one makes the numbers line up easier for overlapping triangles
	track_image.resize(square_image_width+1,square_image_width+1)
	
	var marching_quads = generate_quads(quads_per_row, square_image_width)
	var mesh_verts = generate_mesh(track_image, marching_quads, 500.0, quads_per_row)
	# print(mesh_verts)
	
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = mesh_verts
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = arr_mesh
	var road_mat = StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.9, 0.0, 0.3)
	
	material_override = road_mat

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func generate_mesh(track_image: Image, quads: Array, scale: float, row_count: int):
	var threshold = 0.5
	var mesh = Array()
	for row in row_count:
		for col in row_count:
			var idx = 4*col*row_count + 4*row
			# generate chunk at quad
			var mesh_chunk: Array = quad_lookup(track_image, threshold, quads[idx + 0], quads[idx + 1], quads[idx + 2], quads[idx + 3])
			# slide chunk into position
			mesh_chunk = mesh_chunk.map(func (vertex):
				var offset = Vector3(1.0*row, 0.0, 1.0*col)
				return vertex+offset
			)
			# add the chunk to the mesh
			mesh.append_array(mesh_chunk)
			
	# Normalize and rescale the mesh
	mesh = mesh.map(func (vertex):
		var norm_scale = Vector3(scale/row_count, 0.0, scale/row_count)
		return vertex * norm_scale
	)
	var packed_mesh = PackedVector3Array()
	packed_mesh.append_array(mesh)
	return packed_mesh
	
func generate_quads(quads_per_row: int, square_image_width: int):
	# Pixel width/height of quads
	var width: int = square_image_width / quads_per_row
	
	var quad_verts = Array()
	
	# Template for quad vertices
	quad_verts.push_back(Vector2(0, 0))
	quad_verts.push_back(Vector2(width, 0))
	quad_verts.push_back(Vector2(0, width))
	quad_verts.push_back(Vector2(width, width))

	# Tile up many instances of the above quad together to be used as a quilt over the image
	var vertices = PackedVector2Array()
	for row in range(quads_per_row):
		for col in range(quads_per_row):
				for i in range(quad_verts.size()):
					vertices.push_back(quad_verts[i] + Vector2(width*col, width*row))
	return vertices

func quad_lookup(track_image: Image, threshold: float, top_left: Vector2, top_right: Vector2, bottom_left: Vector2, bottom_right: Vector2):
	var inside_test = func (point):
		var tmp_vec3_point = Vector3(point.x, 0.0, point.y)
		return !point_outside_track(tmp_vec3_point, track_image)
	
	var interp = func (p1, p2):
		var p1_value = track_image.get_pixel(snappedi(p1[0], 1), snappedi(p1[1], 1))
		var p2_value = track_image.get_pixel(snappedi(p2[0], 1), snappedi(p2[1], 1))
		# Don't try to interpolate if points have equal value. Just give the midpoint
		if (min(p2_value.r, p1_value.r) > threshold) || (max(p2_value.r, p1_value.r) < threshold) :
			return 0.5
		print([p1_value.r, p2_value.r])
		print((threshold - p1_value.r) / (p2_value.r - p1_value.r))
		return (threshold - p1_value.r) / (p2_value.r - p1_value.r)
	
	var marching_squares_case: int = 0
	if inside_test.call(top_left):
		marching_squares_case |= 1
	if inside_test.call(top_right):
		marching_squares_case |= 1 << 1
	if inside_test.call(bottom_left):
		marching_squares_case |= 1 << 2
	if inside_test.call(bottom_right):
		marching_squares_case |= 1 << 3
	
	var generated_mesh_segment = Array()
	# template mesh pieces in a semi-normalized range
	var half_width = 0.5
	var width = 2 * half_width

	var top_midpoint = 1.0 - interp.call(top_right, top_left)
	var right_midpoint = 1.0 - interp.call(bottom_right, top_right)
	var bottom_midpoint = 1.0 - interp.call(bottom_right, bottom_left)
	var left_midpoint = 1.0 - interp.call(bottom_left, top_left)
	var top_left_tri = [Vector3(0.0, 0.0, 0.0), Vector3(top_midpoint, 0.0, 0.0), Vector3(0.0, 0.0, left_midpoint)]
	var top_right_tri = [Vector3(width, 0.0, 0.0), Vector3(width, 0.0, right_midpoint), Vector3(top_midpoint, 0.0, 0.0)]
	var top_center_tri = [Vector3(top_midpoint, 0.0, 0.0), Vector3(width, 0.0, right_midpoint), Vector3(0.0, 0.0, left_midpoint)]
	var bottom_left_tri = [Vector3(0.0, 0.0, width), Vector3(0.0, 0.0, left_midpoint), Vector3(bottom_midpoint, 0.0, width)]
	var bottom_right_tri = [Vector3(width, 0.0, width), Vector3(bottom_midpoint, 0.0, width), Vector3(width, 0.0, right_midpoint)]
	var bottom_center_tri = [Vector3(0.0, 0.0, left_midpoint), Vector3(width, 0.0, right_midpoint), Vector3(bottom_midpoint, 0.0, width)]
	var left_center_tri = [Vector3(0.0, 0.0, half_width), Vector3(top_midpoint, 0.0, 0.0), Vector3(bottom_midpoint, 0.0, width)]
	var right_center_tri = [Vector3(width, 0.0, half_width), Vector3(bottom_midpoint, 0.0, width), Vector3(top_midpoint, 0.0, 0.0)]
	
	match marching_squares_case:
		1:
			generated_mesh_segment.append_array(top_left_tri)
		2:
			generated_mesh_segment.append_array(top_right_tri)
		3:
			generated_mesh_segment.append_array(top_left_tri)
			generated_mesh_segment.append_array(top_right_tri)
			generated_mesh_segment.append_array(top_center_tri)
		4:
			generated_mesh_segment.append_array(bottom_left_tri)
		5:
			generated_mesh_segment.append_array(top_left_tri)
			generated_mesh_segment.append_array(bottom_left_tri)
			generated_mesh_segment.append_array(left_center_tri)
		6:
			generated_mesh_segment.append_array(top_center_tri)
			generated_mesh_segment.append_array(top_right_tri)
			generated_mesh_segment.append_array(bottom_center_tri)
			generated_mesh_segment.append_array(bottom_left_tri)
		7:
			generated_mesh_segment.append_array(top_left_tri)
			generated_mesh_segment.append_array(top_right_tri)
			generated_mesh_segment.append_array(top_center_tri)
			generated_mesh_segment.append_array(bottom_left_tri)
			generated_mesh_segment.append_array(bottom_center_tri)
		8:
			generated_mesh_segment.append_array(bottom_right_tri)
		9:
			generated_mesh_segment.append_array(top_left_tri)
			generated_mesh_segment.append_array(bottom_right_tri)
		10:
			generated_mesh_segment.append_array(top_right_tri)
			generated_mesh_segment.append_array(bottom_right_tri)
			generated_mesh_segment.append_array(right_center_tri)
		11:
			generated_mesh_segment.append_array(top_left_tri)
			generated_mesh_segment.append_array(top_right_tri)
			generated_mesh_segment.append_array(top_center_tri)
			generated_mesh_segment.append_array(bottom_right_tri)
			generated_mesh_segment.append_array(bottom_center_tri)
		12:
			generated_mesh_segment.append_array(bottom_left_tri)
			generated_mesh_segment.append_array(bottom_right_tri)
			generated_mesh_segment.append_array(bottom_center_tri)
		13:
			generated_mesh_segment.append_array(top_left_tri)
			generated_mesh_segment.append_array(top_center_tri)
			generated_mesh_segment.append_array(bottom_left_tri)
			generated_mesh_segment.append_array(bottom_right_tri)
			generated_mesh_segment.append_array(bottom_center_tri)
		14:
			generated_mesh_segment.append_array(top_right_tri)
			generated_mesh_segment.append_array(top_center_tri)
			generated_mesh_segment.append_array(bottom_left_tri)
			generated_mesh_segment.append_array(bottom_right_tri)
			generated_mesh_segment.append_array(bottom_center_tri)
		15:
			generated_mesh_segment.append_array(top_left_tri)
			generated_mesh_segment.append_array(top_right_tri)
			generated_mesh_segment.append_array(top_center_tri)
			generated_mesh_segment.append_array(bottom_left_tri)
			generated_mesh_segment.append_array(bottom_right_tri)
			generated_mesh_segment.append_array(bottom_center_tri)
	return generated_mesh_segment

func point_outside_track(point: Vector3, track_image: Image):
	var outside_color: Color = Color(0.5, 0.5, 0.5)
	var pixel = track_image.get_pixel(snappedi(point[0], 1), snappedi(point[2], 1))
	return pixel.r < outside_color.r
