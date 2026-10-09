export const MOTION_OUTFITS=[
 {id:'motion-vest',name:'산책 조끼',price:60,level:2,minutes:5},
 {id:'motion-knit',name:'포근한 니트',price:90,level:3,minutes:15},
 {id:'motion-apron',name:'카페 앞치마',price:100,level:3,minutes:15}
];
export const EMOTIONS=['surprised','happy','angry','sleepy'];
export const HOME_KINDS={read:'read',music:'music',groom:'groom',tea:'tea',rest:'rest',drink:'tea',explore:'play',nature:'rest',fish:'rest',clock:'rest',watch:'rest'};
export function motionStyle(id){return MOTION_OUTFITS.some(i=>i.id===id)?id.slice(7):null;}
export function lifeKind(id,activity){return activity==='rest'&&(id==='bed'||id==='lamp'||id.endsWith('_daybed')||id.endsWith('_lamp'))?'nap':HOME_KINDS[activity]||'rest';}
export function resolveAnimation(catalog,species,age,look,pose){
 const style=motionStyle(look?.style);
 if(style&&age==='adult'){
  const banks=catalog.costumes[species]?.[style];if(!banks)return null;
  // Keep the authored outfit visible when its action has no dedicated cels.
  // Never swap to a bare character or a different outfit in an action.
  const requested=banks[pose.bank]?pose.bank:banks['silly-'+pose.bank]?'silly-'+pose.bank:pose.bank;
  const bank=banks[requested]?requested:'idle',spec=banks[bank];
  return spec?{spec,bank,dressed:true,supported:bank===requested}:null;
 }
 const banks=catalog.base[species]?.[age];
 const bank=banks?.[pose.bank]?pose.bank:'idle',spec=banks?.[bank];
 return spec?{spec,bank,dressed:false,supported:bank===pose.bank}:null;
}
export function animationFrame(spec,pose={}){
 const count=spec.count,elapsed=Math.max(0,pose.elapsed||0);
 if(pose.bank==='emotions')return Math.max(0,EMOTIONS.indexOf(pose.emotion||'happy'));
 if(pose.bank==='dizzy'){const p=Math.max(0,Math.min(1,pose.progress??elapsed/2));return p<.15?0:p>.9?3:1+Math.floor(elapsed/.4)%2;}
 if(pose.bank?.startsWith('hold-release')&&spec.source_path?.startsWith('wardrobe-motion-v3/'))return (pose.progress??elapsed/.64)<.5?0:16;
 if(['stumble','silly-stumble'].includes(pose.bank)){const time=pose.progress!=null?Math.max(0,Math.min(1,pose.progress))*4.8:elapsed%4.8;return Math.min(count-1,time<1.4?Math.floor(time/1.4*30):time<3?30:30+Math.floor((time-3)/1.8*30));}
 const p=Math.max(0,Math.min(.999999,pose.progress??(elapsed/(pose.duration||spec.duration||2.2))%1));
 if(spec.track)return spec.track[Math.min(spec.track.length-1,Math.floor(p*spec.track.length))];
 return Math.min(count-1,Math.floor(p*count));
}
export function holdPose(elapsed,moved=true){
 if(!moved&&elapsed<2.2)return {bank:'idle',elapsed};
 if(elapsed<.28)return {bank:'hold-pickup',elapsed,progress:elapsed/.28};
 if(elapsed<2.2)return {bank:'hold-pickup',elapsed,progress:1};
 if(elapsed<2.48)return {bank:moved?'hold-carry_entry':'hold-idle_entry',elapsed,progress:(elapsed-2.2)/.28};
 return {bank:'struggle',elapsed:elapsed-2.48};
}
