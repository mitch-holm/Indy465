extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var quads_per_row: int = get_meta("quads_per_row")
	var track_texture: CompressedTexture2D = $TrackMap.texture
	var track_image: Image = track_texture.get_image()
	print(track_image)
	var square_image_width: int = 500
	# Adding one makes the numbers line up easier for overlapping triangles
	track_image.resize(square_image_width+1,square_image_width+1)
	
	# Generate an unculled plane mesh
	#var mesh_verts = entriangle(quads_per_row, square_image_width)
	
	# Basic test: Completely cull out the tris that aren't inside the borders
	#mesh_verts = remove_outside_triangles(mesh_verts, track_image)
	
	# Refinement: Remove the jaggy edges and refit closer to the image
	#mesh_verts = cleanup_edges(mesh_verts, track_image)
	
	var marching_quads = generate_quads(quads_per_row, square_image_width)
	var mesh_verts = generate_mesh(track_image, marching_quads, 500.0, quads_per_row)
	print(mesh_verts)
	
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

# Generate a bunch of quads and shove em in an array
# For good results, quads per row should be divisible evenly by the image resolution
func entriangle(quads_per_row: int, square_image_width: int):
	# Pixel width/height of triangles composing each quad
	var width: int = square_image_width / quads_per_row
	
	var quad_verts = Array()
	
	# top-left triangle
	quad_verts.push_back(Vector3(0, 0, 0))
	quad_verts.push_back(Vector3(width, 0, 0))
	quad_verts.push_back(Vector3(0, 0, width))
	# top-right triangle
	quad_verts.push_back(Vector3(0, 0, width))
	quad_verts.push_back(Vector3(width, 0, 0))
	quad_verts.push_back(Vector3(width, 0, width))
	
	# Tile up many instances of the above quad together to be used as a quilt over the image
	var vertices = PackedVector3Array()
	for row in range(quads_per_row):
		for col in range(quads_per_row):
				for i in range(quad_verts.size()):
					vertices.push_back(quad_verts[i] + Vector3(width*col, 0, width*row))
	
	return vertices

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

	var top_left_tri = [Vector3(0.0, 0.0, 0.0), Vector3(half_width, 0.0, 0.0), Vector3(0.0, 0.0, half_width)]
	var top_right_tri = [Vector3(width, 0.0, 0.0), Vector3(width, 0.0, half_width), Vector3(half_width, 0.0, 0.0)]
	var top_center_tri = [Vector3(half_width, 0.0, 0.0), Vector3(width, 0.0, half_width), Vector3(0.0, 0.0, half_width)]
	var bottom_left_tri = [Vector3(0.0, 0.0, width), Vector3(0.0, 0.0, half_width), Vector3(half_width, 0.0, width)]
	var bottom_right_tri = [Vector3(width, 0.0, width), Vector3(half_width, 0.0, width), Vector3(width, 0.0, half_width)]
	var bottom_center_tri = [Vector3(0.0, 0.0, half_width), Vector3(width, 0.0, half_width), Vector3(half_width, 0.0, width)]
	var left_center_tri = [Vector3(0.0, 0.0, half_width), Vector3(half_width, 0.0, 0.0), Vector3(half_width, 0.0, width)]
	var right_center_tri = [Vector3(width, 0.0, half_width), Vector3(half_width, 0.0, width), Vector3(half_width, 0.0, 0.0)]
	
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

func remove_outside_triangles(pre_removal_verts: PackedVector3Array, track_image: Image):
	var mesh_verts = PackedVector3Array()
	for tri_index in range(pre_removal_verts.size() / 3):
		var vert_a = pre_removal_verts[tri_index*3 + 0]
		var vert_b = pre_removal_verts[tri_index*3 + 1]
		var vert_c = pre_removal_verts[tri_index*3 + 2]

		# Check if all vertices are outside the track
		var a_is_outside = point_outside_track(vert_a, track_image)
		var b_is_outside = point_outside_track(vert_b, track_image)
		var c_is_outside = point_outside_track(vert_c, track_image)
		
		if !(a_is_outside && b_is_outside && c_is_outside):
			mesh_verts.push_back(vert_a)
			mesh_verts.push_back(vert_b)
			mesh_verts.push_back(vert_c)
	return mesh_verts

func cleanup_edges(jaggy_mesh_verts: PackedVector3Array, track_image: Image):
	var mesh_verts = PackedVector3Array()
	for tri_index in range(jaggy_mesh_verts.size() / 3):
		var vert_a = jaggy_mesh_verts[tri_index*3 + 0]
		var vert_b = jaggy_mesh_verts[tri_index*3 + 1]
		var vert_c = jaggy_mesh_verts[tri_index*3 + 2]

		# Check which vertices are outside the track
		var a_is_outside = point_outside_track(vert_a, track_image)
		var b_is_outside = point_outside_track(vert_b, track_image)
		var c_is_outside = point_outside_track(vert_c, track_image)
		
		if (a_is_outside || b_is_outside || c_is_outside):
			var new_triangle_verts = retriangulate(vert_a, vert_b, vert_c, track_image)
			for new_vert in new_triangle_verts:
				mesh_verts.push_back(new_vert)
		else:
			mesh_verts.push_back(vert_a)
			mesh_verts.push_back(vert_b)
			mesh_verts.push_back(vert_c)
	return mesh_verts

# Function that provides the approximate location of where along the edge the inside/outside boundary lies
func find_approx_cutoff_binary_search(outside_vert: Vector3, inside_vert: Vector3, test, depth: int):
	var midpoint = (outside_vert + inside_vert) / 2
	if depth == 0:
		return midpoint
	if test.call(midpoint):
		return find_approx_cutoff_binary_search(midpoint, inside_vert, test, depth-1)
	else:
		return find_approx_cutoff_binary_search(outside_vert, midpoint, test, depth-1)

func point_outside_track(point: Vector3, track_image: Image):
	var outside_color: Color = Color(0.5, 0.5, 0.5)
	var pixel = track_image.get_pixel(snappedi(point[0], 1), snappedi(point[2], 1))
	return pixel.r < outside_color.r

func make_clockwise(triangle_list: PackedVector3Array):
	var corrected_list = PackedVector3Array()
	for i in range(triangle_list.size() / 3):
		var p1 = triangle_list[3*i + 0]
		var p2 = triangle_list[3*i + 1]
		var p3 = triangle_list[3*i + 2]
		var v1 = p1 - p2
		var v2 = p3 - p2
		
		var orientation = v1.cross(v2).y
		if orientation < 0:
			corrected_list.push_back(p3)
			corrected_list.push_back(p2)
			corrected_list.push_back(p1)
		else:
			corrected_list.push_back(p1)
			corrected_list.push_back(p2)
			corrected_list.push_back(p3)
	return corrected_list

# Takes the vertices of a triangle and spits out new triangles that are better aligned with the track_image
# Assumes that at least one vertex is inside the track
func retriangulate(vert_a: Vector3, vert_b: Vector3, vert_c: Vector3, track_image: Image):
	# Check which vertices are outside the track
	var a_is_outside = point_outside_track(vert_a, track_image)
	var b_is_outside = point_outside_track(vert_b, track_image)
	var c_is_outside = point_outside_track(vert_c, track_image)
	
	var final_vertices = Array()
	# Put the vertices into buckets based on whether they're inside or outside
	var outside_vertices = Array()
	var inside_vertices = Array()
	if a_is_outside:
		outside_vertices.push_back(vert_a)
	else:
		inside_vertices.push_back(vert_a)
		final_vertices.push_back(vert_a)
	if b_is_outside:
		outside_vertices.push_back(vert_b)
	else:
		inside_vertices.push_back(vert_b)
		final_vertices.push_back(vert_b)
	if c_is_outside:
		outside_vertices.push_back(vert_c)
	else:
		inside_vertices.push_back(vert_c)
		final_vertices.push_back(vert_c)
	
	# Find new vertices along the edges between old vertices
	var test = func (point):
		return point_outside_track(point, track_image)
	var iterations = 7
	for outside in outside_vertices:
		for inside in inside_vertices:
			var edge_vertex: Vector3 = find_approx_cutoff_binary_search(outside, inside, test, iterations)
			final_vertices.push_back(edge_vertex)
	
	# Mix up the representation of the final vertices so they can be retriangulated
	var verts_2d = PackedVector2Array()
	for vert in final_vertices:
		var vert_2d = Vector2(vert.x, vert.z)
		verts_2d.push_back(vert_2d)
	
	var triangulated_indices = Geometry2D.triangulate_delaunay(verts_2d)
	
	# Iterate over the triangle indices to pack the final vertices in the correct order
	var output_triangles = PackedVector3Array()
	for index in triangulated_indices:
		output_triangles.push_back(final_vertices[index])
	output_triangles = make_clockwise(output_triangles)
	return output_triangles
