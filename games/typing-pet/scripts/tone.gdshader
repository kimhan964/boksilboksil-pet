shader_type canvas_item;
uniform vec3 shift=vec3(0.0);
void fragment() {
 vec4 c=texture(TEXTURE,UV);
 float l=dot(c.rgb,vec3(.299,.587,.114));
 // Keep eyes, outlines and keyboard intact, preserve all original alpha and shading.
 float mask=smoothstep(.20,.42,l)*(1.0-smoothstep(.92,1.0,l));
 mask*=1.0-smoothstep(.70,.75,UV.y);
 c.rgb=clamp(c.rgb+shift*mask,vec3(0.0),vec3(1.0));
 COLOR=c;
}
