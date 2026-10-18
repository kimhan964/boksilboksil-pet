export const SOFT_BEHAVIORS=[
 ['run','통통 달리기',4.5,'move'],['jump','제자리 폴짝',1.6,'move'],['stumble','앗, 넘어졌다 일어나기',2.8,'flower'],
 ['happy','기분 좋은 춤',3.2,'pet'],['sad','잠깐 토라지기',3.5,'pet'],['peek','궁금해서 빼꼼',3.2,'flower'],
 ['drink','차 한 모금',4.8,'feed'],['sing','흥얼흥얼 노래',6.4,'sound-on'],['study','책 읽기',9.6,'journal'],
 ['work','새싹 돌보기',7.6,'flower'],['pajama','잠옷 입고 꾸벅',9.6,'sleep'],['fight','나뭇잎 방패 놀이',6.4,'play'],
 ['roll','데굴데굴 굴러가기',4,'play'],['fly','대나무 프로펠러 비행',6,'move']
].map(([id,title,duration,icon])=>({id,title,duration,icon}));
export const SOFT_NAMES=Object.fromEntries(SOFT_BEHAVIORS.map(a=>[a.id,a.title]));
export function behaviorRequirement(state,id){
 const needed=id==='roll'?8:id==='fly'?20:0,points=state.desktop.activityGroups?.bond||0;
 return {needed,points,open:points>=needed,text:needed?`쓰다듬기·토닥이기 ${Math.min(points,needed)}/${needed}회`:'처음부터 함께해요'};
}
export const smooth=(a,b,t)=>{const x=Math.max(0,Math.min(1,(t-a)/(b-a)));return x*x*(3-2*x);};
export function softMotion(spec,pose,unit=1){
 const elapsed=pose.elapsed||0,duration=pose.duration||spec.duration||1,p=Math.max(0,Math.min(1,pose.progress??elapsed/duration));
 let lift=0,angle=0;
 if(pose.bank==='fly')lift=(65+Math.sin(elapsed*Math.PI*2/2.2)*3)*smooth(0,.18,p)*smooth(0,.18,1-p);
 if(pose.bank==='roll')angle=(pose.travelPixels!=null?pose.travelPixels/(Math.max(.01,unit)*(spec.roll_radius||85.5)):Math.PI*2*smooth(.1,.88,p))*(pose.direction||1);
 if(['run','jump'].includes(pose.bank)){
  let phase=pose.bank==='run'?(elapsed/(spec.duration||1))%1:p;if(spec.hop_twice)phase=phase*2%1;
  const t=Math.max(0,Math.min(1,(phase-(spec.launch??.12))/((spec.land??.84)-(spec.launch??.12))));lift=Math.sin(Math.PI*t)*(spec.lift||0);
 }
 if(pose.bank==='stumble')angle=1.3*smooth(.12,.64,elapsed)*(1-smooth(1.55,2.65,elapsed));
 return {lift:lift*unit,angle};
}
export function tripPose(elapsed){
 const t=Math.max(0,Math.min(2.8,elapsed));
 return t<.55?{bank:'landing',progress:t/.55}:t<1.55?{bank:'dizzy',progress:(t-.55)}:{bank:'recover',progress:(t-1.55)/1.25};
}
export function lifeBank(item,activity){
 const id=item?.kind||item?.id;
 if(id==='bathtub')return 'bath';
 if(id==='toy_plush'||id==='basket')return 'play';
 if(id==='bed'||item?.kind==='bed')return 'nap';
 if(id==='wall_shelf')return 'climb';
 if(activity==='nature')return 'work';
 if(activity==='groom')return 'groom';
 if(activity==='read')return 'read';
 if(activity==='music')return 'music';
 if(activity==='drink'||activity==='tea')return 'tea';
 return ['sofa','chair','window_seat'].includes(id)?'rest':'idle';
}
