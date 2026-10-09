// Current desktop scripts/expression_behavior.gd: rigid whole-cel motion only.
const TEMPO=[1,1.05,.91,1.18,1.08,.97,1.24,1.19,1.02,.94,.90,1.28,.96,1.12,1.32,1.14];
const HOP=[9,4.5,7,2.5,4,6,3,2,4,7.5,5,2.5,6.5,5.5,1.5,3.5];
const TILT=[.06,.085,.07,.045,.055,.10,.05,.13,.11,.075,.06,.045,.09,.065,.10,.12];
export function expressionDuration(index,kind){return ({surprised:2.1,happy:2.8,angry:2.7,sleepy:3.4}[kind]||2.5)*TEMPO[index];}
function pulse(p,a,b){return p<=a||p>=b?0:Math.sin((p-a)/(b-a)*Math.PI)**2;}
function sample(index,kind,event,p){
 let x=0,y=0,angle=0,t=TILT[index],h=HOP[index];
 if(kind==='surprised'){const r=pulse(p,.08,.48);x=-5*r;y=-Math.min(5,h*.6)*r;angle=-t*.8*r+t*.3*pulse(p,.48,.83);}
 if(kind==='happy'){const a=pulse(p,.12,.42),b=pulse(p,.48,.78);y=-h*(a+b*.72);angle=t*.45*(a-b);}
 if(kind==='angry'){y=-Math.min(3,h*.45)*(pulse(p,.13,.31)+pulse(p,.38,.56));angle=t*.55*pulse(p,.12,.62)-t*.9*pulse(p,.64,.94);}
 if(kind==='sleepy'){const n=pulse(p,.1,.47)+pulse(p,.49,.93)*1.25;angle=t*n;x=-2*n;y=2*n;}
 const soft=pulse(p,.08,.94),nod=pulse(p,.15,.48)+pulse(p,.55,.86)*.55;
 if(['pet','hand_feed','hello','set_down'].includes(event)){x=3*soft;y=-1.5*soft;angle=t*.7*soft;}
 if(['meal','favorite_meal'].includes(event)){x=0;y=-2*nod;angle=t*.7*nod;}
 if(['water','tea','rest','wake'].includes(event)){x=-2*soft;y=2*soft;angle=-t*.6*soft;}
 if(['read','garden'].includes(event)){x=2*soft;y=0;angle=t*soft;}
 if(event==='groom'){x=0;y=-3*soft;angle=-t*.4*soft;}
 if(event==='music'){const sway=Math.sin(p*Math.PI*4)*soft;x=2*sway;y=0;angle=t*.6*sway;}
 return {x,y,angle};
}
export function expressionPose(index,kind,event,progress,strength=.55){
 const f=Math.max(0,Math.min(1,progress))*59,a=sample(index,kind,event,Math.floor(f)/59),b=sample(index,kind,event,Math.min(59,Math.ceil(f))/59),mix=f-Math.floor(f);
 return {x:(a.x+(b.x-a.x)*mix)*.65*strength,y:(a.y+(b.y-a.y)*mix)*.65*strength,angle:(a.angle+(b.angle-a.angle)*mix)*.7*strength};
}
