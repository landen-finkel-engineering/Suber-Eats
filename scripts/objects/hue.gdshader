shader_type canvas_item;

uniform float hue = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec3 k = vec3(0.57735);
	float a = radians(hue);
	c.rgb = c.rgb * cos(a) + cross(k, c.rgb) * sin(a) + k * dot(k, c.rgb) * (1.0 - cos(a));
	COLOR = c;
}
