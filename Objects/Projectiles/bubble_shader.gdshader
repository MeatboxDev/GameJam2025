// Shamelessly ripped of from
// https://youtu.be/sj4BeJKhe_Y?si=flSE-FbErLckZUwh
// @Pefeper on YT
// modified 2 lines due to Godot 4 lmao

shader_type spatial;

uniform sampler2D noise_texture;
uniform vec4 bubble_color:source_color;
uniform float height_multiplier = 0.1;
uniform float noise_sample_multiplier = 0.1;
uniform float animation_speed = 1.0;

varying float height;

float fresnel(vec3 normal, mat4 camera_matrix) {
	vec3 view_direction_world = (camera_matrix * vec4(0.0, 0.0, 1.0, 0.0)).xyz;
	vec3 normal_world = (camera_matrix * vec4(normal, 0.0)).xyz;

	float d = dot(view_direction_world, normal_world);
	d = abs(d);
	d = clamp(d, 0.0, 1.0);

	return 1.0 - d;
}

void vertex() {
	height = texture(noise_texture, VERTEX.xz * noise_sample_multiplier + vec2(TIME) * animation_speed).r;
	VERTEX += NORMAL * height * height_multiplier;
}

void fragment() {
	ROUGHNESS = mix(0.05, 0.1, 1.0 - height);
	SPECULAR = height;
	ALPHA = fresnel(NORMAL, VIEW_MATRIX);
	ALBEDO = bubble_color.rgb;
}