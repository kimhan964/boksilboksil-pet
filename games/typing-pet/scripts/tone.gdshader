shader_type canvas_item;
uniform vec3 shift=vec3(0.0);
// Midtone lift, saturation, cream highlight adjustment, warmth. Fox is identity.
uniform vec4 balance=vec4(0.0,1.0,0.0,0.0);
void fragment() {
 vec4 c=texture(TEXTURE,UV);
 float l=dot(c.rgb,vec3(.299,.587,.114));
 float character=1.0-smoothstep(.70,.76,UV.y);
 float pigment=smoothstep(.22,.43,l);
 float middle=1.0-smoothstep(.78,.94,l);
 vec3 graded=mix(vec3(l),c.rgb,balance.y);
 graded+=vec3(balance.x*4.0*l*(1.0-l)*middle);
 graded+=vec3(balance.z*smoothstep(.82,.95,l));
 graded+=balance.w*vec3(1.0,.2,-.65);
 c.rgb=mix(c.rgb,graded,character*pigment);
 // Keep eyes, outlines and keyboard intact, preserve all original alpha and shading.
 float mask=smoothstep(.20,.42,l)*(1.0-smoothstep(.92,1.0,l));
 mask*=1.0-smoothstep(.70,.75,UV.y);
 c.rgb=clamp(c.rgb+shift*mask,vec3(0.0),vec3(1.0));
 COLOR=c;
}
