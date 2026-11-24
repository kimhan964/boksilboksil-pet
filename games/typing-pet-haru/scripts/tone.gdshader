shader_type canvas_item;
uniform vec3 shift=vec3(0.0);
// Midtone lift, saturation, cream highlight adjustment, warmth. Fox is identity.
uniform vec4 balance=vec4(0.0,1.0,0.0,0.0);
uniform vec2 body_motion=vec2(0.0);
uniform vec4 eye_centers=vec4(.396,.527,.633,.527);
uniform vec2 eye_expression=vec2(0.0);
uniform int action_type=-1;
uniform float action_phase=0.0;
varying vec4 canvas_tint;
void vertex() {
 canvas_tint=COLOR;
}
vec2 expressive_eye(vec2 uv, vec2 center, float amount) {
 vec2 d=uv-center;
 float horizontal=1.0-smoothstep(.040,.064,abs(d.x));
 float smile=amount*.012*(1.0-pow(clamp(d.x/.055,-1.0,1.0),2.0));
 float y=d.y+smile;
 float radius=.055*(1.0-amount*.78);
 float ay=abs(y);
 float mapped=ay;
 if (ay<radius) { mapped=ay*.055/radius; }
 else if (ay<.095) { mapped=.055+(ay-radius)*(.095-.055)/(.095-radius); }
 float shaped=sign(y)*mapped;
 float edge=1.0-smoothstep(.085,.10,abs(d.y));
 uv.y+=(shaped-d.y)*horizontal*edge;
 return uv;
}
void fragment() {
 float body=1.0-smoothstep(.56,.73,UV.y);
 vec2 posed_uv=UV-body_motion*body;
 if (action_type>=0) {
  vec2 left=vec2(.34,.69);
  vec2 right=vec2(.66,.69);
  vec2 radius=vec2(.14,.09);
  if (action_type==2) { left=vec2(.28,.38); right=vec2(.72,.38); radius=vec2(.17,.22); }
  float l=1.0-smoothstep(.25,1.0,length((posed_uv-left)/radius));
  float r=1.0-smoothstep(.25,1.0,length((posed_uv-right)/radius));
  float tap=sin(action_phase*10.0)*.016;
  posed_uv.y+=tap*(r-(action_type==1 ? 0.0 : l));
 }
 posed_uv=expressive_eye(posed_uv,eye_centers.xy,eye_expression.x);
 posed_uv=expressive_eye(posed_uv,eye_centers.zw,eye_expression.y);
 vec4 c=texture(TEXTURE,posed_uv);
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
 COLOR=c*canvas_tint;
}
