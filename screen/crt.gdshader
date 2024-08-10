shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform vec3 brightness = vec3(0.0, 0.0, 0.0);
// If you intend to read from mipmaps with `textureLod()` LOD values greater than `0.0`,
// use `filter_nearest_mipmap` instead. This shader doesn't require it.
uniform sampler2D base_texture : repeat_disable, filter_nearest;
uniform sampler2D bloom_texture : repeat_disable, filter_linear_mipmap;
uniform sampler2D shadow_mask : repeat_enable, filter_nearest;
uniform vec2 bloom_size;

vec4 blur(vec2 uv) {
	vec2 pixel_size = 1.0 / bloom_size;
	vec3 col = texture(bloom_texture, uv).xyz * 0.16;
	col += texture(bloom_texture, uv + vec2(pixel_size.x, 0.0)).xyz * 0.075;
	col += texture(bloom_texture, uv + vec2(-pixel_size.x, 0.0)).xyz * 0.075;
	col += texture(bloom_texture, uv + vec2(2.0 * pixel_size.x, 0.0)).xyz * 0.06;
	col += texture(bloom_texture, uv + vec2(2.0 * -pixel_size.x, 0.0)).xyz * 0.06;
	col += texture(bloom_texture, uv + vec2(3.0 * pixel_size.x, 0.0)).xyz * 0.045;
	col += texture(bloom_texture, uv + vec2(3.0 * -pixel_size.x, 0.0)).xyz * 0.045;
	col += texture(bloom_texture, uv + vec2(4.0 * pixel_size.x, 0.0)).xyz * 0.025;
	col += texture(bloom_texture, uv + vec2(4.0 * -pixel_size.x, 0.0)).xyz * 0.025;
	col += texture(bloom_texture, uv + vec2(0.0, pixel_size.y)).xyz * 0.075;
	col += texture(bloom_texture, uv + vec2(0.0, -pixel_size.y)).xyz * 0.075;
	col += texture(bloom_texture, uv + vec2(0.0, 2.0 * pixel_size.y)).xyz * 0.06;
	col += texture(bloom_texture, uv + vec2(0.0, 2.0 * -pixel_size.y)).xyz * 0.06;
	col += texture(bloom_texture, uv + vec2(0.0, 3.0 * pixel_size.y)).xyz * 0.045;
	col += texture(bloom_texture, uv + vec2(0.0, 3.0 * -pixel_size.y)).xyz * 0.045;
	col += texture(bloom_texture, uv + vec2(0.0, 4.0 * pixel_size.y)).xyz * 0.025;
	col += texture(bloom_texture, uv + vec2(0.0, 4.0 * -pixel_size.y)).xyz * 0.025;
	return vec4(col, 0.0);
}

void fragment() {
	vec4 brightness_color = vec4(brightness, 0.0);
	vec2 mask_uv = SCREEN_UV * (vec2(1.0, 1.0))/(SCREEN_PIXEL_SIZE * vec2(8, 7));
	vec4 mask_sample = textureLod(shadow_mask, mask_uv, 0.0);
	vec4 base_color = (brightness_color + textureLod(base_texture, SCREEN_UV, 0.0));
	vec4 blurred_bloom_color = vec4(blur(SCREEN_UV).xyz, 1.0);
	vec4 fried_color = texture(bloom_texture, SCREEN_UV);
	COLOR.xyz = base_color.xyz + blurred_bloom_color.xyz;
	COLOR = COLOR * mask_sample;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
