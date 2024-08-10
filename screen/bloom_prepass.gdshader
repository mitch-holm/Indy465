shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform sampler2D prebloom: repeat_disable, filter_nearest;

float deep_fry(float in_val) {
	float k = -0.8;
	float x = in_val*2.0 - 1.0;
	// Sigmoid shenanigans to crank the contrast
	float fried = ((x - k*x) / (k - 2.0*k*abs(x) + 1.0) + 1.0) / 2.0;
	return fried;
	// return in_val;
	// return in_val*in_val;
}

void fragment() {

	COLOR = texture(prebloom, UV);
	COLOR = vec4(deep_fry(COLOR.r), deep_fry(COLOR.g), deep_fry(COLOR.b), 1.0);
	//COLOR = texture(prebloom, UV);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
