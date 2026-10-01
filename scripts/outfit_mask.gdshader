shader_type canvas_item;
uniform sampler2D body_texture : filter_linear;
uniform vec2 fit_origin;
uniform vec2 fit_scale=vec2(1.0);
uniform vec2 garment_size;
uniform float head_boundary=0.0;
uniform bool lying=false;
void fragment(){
	vec4 cloth=texture(TEXTURE,UV)*COLOR;
	vec2 body_pixel=fit_origin+UV*garment_size*fit_scale;
	float body_alpha=texture(body_texture,body_pixel/vec2(256.0)).a;
	float face_mask=lying?1.0-smoothstep(head_boundary-3.0,head_boundary+3.0,body_pixel.x):smoothstep(head_boundary-2.0,head_boundary+2.0,body_pixel.y);
	cloth.a*=body_alpha*face_mask;
	COLOR=cloth;
}
