shader_type canvas_item;

uniform bool is_hurt = false;
uniform bool custom_colors = false;

uniform vec4 skin : hint_color = vec4(0.969, 0.71, 0.545, 1.0);
uniform vec4 outline : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 accent : hint_color = vec4(0.094, 0.522, 0.969, 1.0);

uniform vec4 hurt_skin : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 hurt_outline : hint_color = vec4(0.973, 0.69, 0.188, 1.0);
uniform vec4 hurt_accent : hint_color = vec4(1.0, 0.0, 0.0, 1.0);

vec4 hurt(vec4 base) {
	float sum = base.r + base.g + base.b;
	vec4 output;
	
	if(sum > 0.0){
		if(sum > 2.0) {
			output = hurt_skin;
		} else {
			output = hurt_accent;
		}
	} else {
		output = hurt_outline;
	}
	
	return output;
}

vec4 swap(vec4 base) {
	vec4 output;
	if(base.rgb == vec3(0.0)) {
		output = outline;
	} else {
		if(base.rgb == vec3(1.0)) {
			output = skin;
		} else {
			output = accent;
		}
	}
	output.a = base.a;
	return output;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	if(is_hurt) {
		COLOR = vec4(mix(base, hurt(base), (sin(TIME * 25.0) + 1.0) / 2.0).rgb, base.a);
	} else {
		if(custom_colors) {
			COLOR = swap(base);
		} else {
			COLOR = base;
		}
	}
}