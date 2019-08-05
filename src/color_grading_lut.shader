shader_type canvas_item;

uniform sampler2D lut;
uniform float lut_size = 16.0;

//
vec4 get_lut_mapping_floor_v1(vec4 old_color){
	float lut_div = lut_size;
	float pixel_center = float(0.5/(lut_div*lut_div));
	vec2 slice_pos = vec2(floor(lut_div*old_color.r)/lut_div, floor(lut_div*old_color.g)/lut_div);
	float slice_index = (floor(lut_div*old_color.b))/lut_div;
	vec2 lut_pos = vec2(pixel_center + slice_index + (slice_pos.x/lut_div), pixel_center + slice_pos.y);
	vec4 final_color = texture(lut, lut_pos);
	final_color.a = old_color.a;
	return final_color;
}

// Retrieve percentage from color diff

float get_interp_percent_float(float color_value, float floor_value, float diff_value){
	// Workaround to avoid division by zero and return zero
	float div_sign = abs(sign(diff_value));
	return (color_value-floor_value)*div_sign/(diff_value + (div_sign-1.0));
	//return (color_value-floor_value)/diff_value;
}

vec3 get_interp_percent_color(vec3 color, vec3 floor, vec3 diff){
	vec3 res = vec3(0.0);
	res.r = get_interp_percent_float(color.r, floor.r, diff.r);
	res.g = get_interp_percent_float(color.g, floor.g, diff.g);
	res.b = get_interp_percent_float(color.b, floor.b, diff.b);
	return res;
}

// Retrieve interpolated color

vec3 get_interpolated_color(vec3 floorc, vec3 diff, vec3 perc){
	return floorc.rgb + diff.rgb * perc.rgb;
}

//
vec4 get_lut_mapping_floor(vec4 old_color){
	float lut_div = lut_size - 1.0;
	vec3 old_color_b16f = lut_div * old_color.rgb;
	vec3 old_color_floor_b16f = floor(old_color_b16f);
	vec3 old_color_ceil_b16f = ceil(old_color_b16f);
	vec3 old_color_diff = (old_color_floor_b16f - old_color_ceil_b16f)/lut_div;
	vec3 old_color_percentages = get_interp_percent_color(old_color.rgb, old_color_floor_b16f/lut_div, old_color_diff);

	ivec2 lut_color_floor_pos = ivec2(int(lut_size*old_color_floor_b16f.b + old_color_floor_b16f.r),  int(old_color_floor_b16f.g));
	ivec2 lut_color_ceil_pos = ivec2(int(lut_size*old_color_ceil_b16f.b + old_color_ceil_b16f.r), int(old_color_ceil_b16f.g));
	vec3 lut_color_floor = texelFetch(lut, lut_color_floor_pos, 0).rgb;
	vec3 lut_color_ceil = texelFetch(lut, lut_color_ceil_pos, 0).rgb;
	vec3 lut_color_diff = lut_color_floor - lut_color_ceil;

	vec3 lut_color_interpolated = get_interpolated_color(lut_color_floor, lut_color_diff, old_color_percentages);
	vec4 final_color = vec4(lut_color_interpolated, old_color.a);
	return final_color;
}

void fragment(){
	vec4 color = texture(SCREEN_TEXTURE,SCREEN_UV);
	color = get_lut_mapping_floor(color);
	//color.r = texture(red,vec2(color.r,0.5)).a;
	//color.g = texture(green,vec2(color.g,0.5)).a;
	//color.b = texture(blue,vec2(color.b,0.5)).a;
	//color.b = color2.b;
	COLOR = color;
}