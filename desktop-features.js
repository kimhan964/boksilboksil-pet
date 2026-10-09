import {PERSONAL_PROPS} from './personal-data.js';
import {SIGNATURE_FURNITURE} from './signature-data.js';
import {initSettings,sourceUnlocked,rewardCurrentActivity,growthScale} from './current-settings.js';
import {MOTION_OUTFITS,motionStyle} from './animation-player.js';
import {level,dayKey} from './progression.js';
export const OUTFITS=[{id:'none',name:'기본 복장',price:0},...MOTION_OUTFITS];
export const CLOTH_COLORS=[['세이지','#88a879'],['살구','#dc9078'],['하늘','#79a9c5'],['라벤더','#a790c2'],['딸기','#c96f7b'],['크림','#d8bd88']];
export const TOYS=[
 {id:'acorn',name:'도토리 오뚝이',image:'desktop/acorn.webp',price:0,plays:0,minutes:0,description:'톡 건드리면 흔들흔들. 친구가 다가와 살펴봐요.'},
 {id:'follow',name:'손가락 따라 산책',image:'ui-icons/move.png',price:0,plays:0,minutes:0,description:'방 바닥을 누른 채 손가락을 움직여 함께 걸어요.'},
 {id:'rug',name:'포근한 러그 놀이',image:'rug.webp',price:0,plays:0,minutes:0,description:'방에 놓은 러그에서 실뭉치와 놀아요.'},
 {id:'basket',name:'숨은 간식 찾기',image:'desktop/basket.webp',price:25,plays:1,minutes:2,description:'세 바구니 중 간식이 숨은 곳을 찾아요.'},
 {id:'toy_ball',name:'실뜨개 공 굴리기',image:'desktop/toy_ball.webp',price:40,plays:3,minutes:5,description:'공을 톡 굴리거나 손가락으로 밀어요. 친구가 뒤따라가요.'},
 {id:'toy_mouse',name:'생쥐 따라잡기',image:'desktop/toy_mouse.webp',price:65,plays:8,minutes:15,description:'작은 생쥐를 움직여 보세요. 친구가 따라가 킁킁 살펴봐요.'}
];
export const DESKTOP_FURNITURE=[
 {id:'vanity',name:'고양이 거울 화장대',price:130,cat:'가구',w:.16,group:'pet',count:20,minutes:30,activity:'groom'},
 {id:'window_seat',name:'잎새 창가 벤치',price:135,cat:'가구',w:.25,group:'feed',count:15,minutes:25,activity:'rest'},
 {id:'turntable',name:'곰 LP 리스닝 테이블',price:150,cat:'가구',w:.19,group:'music',count:12,minutes:40,activity:'music'},
 {id:'wall_shelf',name:'토끼 책꽂이 벽 선반',price:90,cat:'벽 장식',w:.20,wall:true,group:'read',count:4,minutes:15,activity:'read'},
 {id:'dresser',name:'발바닥 원목 서랍장',price:110,cat:'가구',w:.18,group:'pet',count:15,minutes:20,activity:'groom'},
 {id:'fireplace',name:'포근한 전기 벽난로',price:160,cat:'가구',w:.19,group:'sleep',count:20,minutes:40,activity:'rest'},
 {id:'alarm_clock',name:'동물 귀 작은 자명종',price:65,cat:'소품',w:.08,group:'sleep',count:8,minutes:12,activity:'clock'},
 {id:'toy_ball',name:'실뜨개 공 놀이감',price:40,cat:'놀이감',w:.07,group:'play',count:3,minutes:5,activity:'toy'},
 {id:'toy_mouse',name:'리넨 생쥐 놀이감',price:65,cat:'놀이감',w:.09,group:'play',count:8,minutes:15,activity:'toy'},
 {id:'acorn',name:'도토리 오뚝이',price:0,cat:'놀이감',w:.08,group:'play',count:0,minutes:0,activity:'toy'},
 {id:'water',name:'작은 세라믹 물컵',price:0,cat:'소품',w:.08,group:'feed',count:0,minutes:0,activity:'drink'}
].map(i=>({...i,file:'desktop/'+i.id+'.webp'})).concat(PERSONAL_PROPS.filter(i=>i.id.endsWith('-plant')),SIGNATURE_FURNITURE);
export const LIFE={
 explore:{name:'취향 놀이감 살펴보기',icon:'play',happy:10,group:'play'},tea:{name:'식탁에서 티타임',icon:'feed',happy:6,energy:5,group:'feed'},
 fish:{name:'물고기 구경',icon:'play',happy:8,group:'play'},nature:{name:'잎새 구경',icon:'flower',happy:6,group:'play'},clock:{name:'시계 살펴보기',icon:'sun',happy:4,group:'read'},
 read:{name:'책 읽기',icon:'journal',happy:8,energy:2,group:'read'},music:{name:'음악 듣기',icon:'sound-on',happy:12,energy:3,group:'music'},
 rest:{name:'가구에서 휴식',icon:'sleep',happy:4,energy:15,group:'sleep'},groom:{name:'거울 보고 단장',icon:'clean',happy:6,clean:12,group:'pet'},
 drink:{name:'물 마시기',icon:'feed',happy:4,energy:8,group:'feed'},watch:{name:'TV 보기',icon:'play',happy:10,energy:3,group:'play'}
};
export function initDesktop(state,legacy=false){
 if(!state.desktop){state.desktop={version:1,outfits:{},wardrobeOwned:['none'],growth:{},counts:legacy?{...state.progress.counts}:{},unlocked:[],daily:{day:dayKey(),counts:{}}};if(legacy)for(const id of [state.species,...Object.keys(state.petStats||{})])state.desktop.growth[id]=36;}
 const d=state.desktop;d.outfits||={};d.wardrobeOwned||=['none'];d.growth||={};d.counts||={};d.unlocked||=[];d.daily||={day:dayKey(),counts:{}};
 if(!d.motionWardrobeVersion){for(const [old,next] of [['vest','motion-vest'],['sweater','motion-knit']])if(d.wardrobeOwned.includes(old)&&!d.wardrobeOwned.includes(next))d.wardrobeOwned.push(next);d.motionWardrobeVersion=1;}
 if(!d.currentSourceVersion){
  d.retiredOutfits=JSON.parse(JSON.stringify(d.outfits));
  for(const [old,next] of [['vest','motion-vest'],['sweater','motion-knit']])if(d.wardrobeOwned.includes(old)&&!d.wardrobeOwned.includes(next))d.wardrobeOwned.push(next);
  for(const [animal,look] of Object.entries(d.outfits))if(!['none',...MOTION_OUTFITS.map(i=>i.id)].includes(look.style))d.outfits[animal]={style:(d.growth[animal]||0)>=12?({vest:'motion-vest',sweater:'motion-knit'}[look.style]||'none'):'none',color:0};
  d.currentSourceVersion=1;
 }
 // Older furniture ownership always wins; new unlocks stay permanent.
 for(const id of state.owned||[])if(DESKTOP_FURNITURE.some(i=>i.id===id)&&!d.unlocked.includes(id))d.unlocked.push(id);
 initSettings(state);refreshDesktop(state);return d;
}
export function growthInfo(state,species=state.species){const points=state.desktop.growth[species]||0;return {points,scale:growthScale(points),stage:points<12?'baby':points<36?'young':'adult',name:points<12?'아기':points<36?'자라는 중':'성체',next:points<12?12:points<36?36:null};}
export function desktopUnlocked(state,item){if(item.signature)return item.species===state.species;return sourceUnlocked(state,item)||state.desktop.unlocked.includes(item.id)||(state.desktop.counts[item.group]||0)>=item.count||state.progress.playSeconds>=item.minutes*60;}
export function refreshDesktop(state){const opened=[];for(const item of DESKTOP_FURNITURE)if(!state.desktop.unlocked.includes(item.id)&&desktopUnlocked(state,item)){state.desktop.unlocked.push(item.id);opened.push(item);}return opened;}
export function desktopCondition(state,item){return `${item.group==='read'?'독서':item.group==='music'?'음악':item.group==='play'?'놀이':item.group==='pet'?'교감':item.group==='feed'?'식사·물':'휴식'} ${Math.min(state.desktop.counts[item.group]||0,item.count)}/${item.count}회 또는 플레이 ${item.minutes}분`;}
export function toyUnlocked(state,toy){return (state.desktop.counts.play||0)>=toy.plays||state.progress.playSeconds>=toy.minutes*60||state.owned.includes(toy.id);}
export function buyToy(state,id){const toy=TOYS.find(t=>t.id===id);if(!toy||['acorn','follow','rug'].includes(id)||!toyUnlocked(state,toy)||state.owned.includes(id)||state.coins<toy.price)return false;state.coins-=toy.price;state.owned.push(id);refreshDesktop(state);return true;}
export function outfitName(species,style){return OUTFITS.find(i=>i.id===style)?.name||'기본 복장';}
export function outfitUnlocked(state,item){if(motionStyle(item.id)&&growthInfo(state).stage==='baby')return false;return state.desktop.wardrobeOwned.includes(item.id)||item.id==='none'||level(state)>=(item.level||1)||state.progress.playSeconds>=(item.minutes||0)*60;}
export function buyOutfit(state,id){const item=OUTFITS.find(i=>i.id===id);if(!item||!outfitUnlocked(state,item)||state.desktop.wardrobeOwned.includes(id)||state.coins<item.price)return false;state.coins-=item.price;state.desktop.wardrobeOwned.push(id);return true;}
export function wearOutfit(state,id,color=0){if(!state.desktop.wardrobeOwned.includes(id)||!OUTFITS.some(i=>i.id===id)||!Number.isInteger(color)||color<0||color>=6||(motionStyle(id)&&growthInfo(state).stage==='baby'))return false;state.desktop.outfits[state.species]={style:id,color:motionStyle(id)?0:color};return true;}
export function completeDesktopActivity(state,action,now=Date.now()){
 const d=state.desktop,day=dayKey(now);if(d.daily.day!==day)d.daily={day,counts:{}};
 if(!rewardCurrentActivity(state,action,now))return [];
 const group=LIFE[action]?.group||action;d.counts[group]=(d.counts[group]||0)+1;
 const key=state.species+':'+action,count=d.daily.counts[key]||0;d.daily.counts[key]=count+1;
 return refreshDesktop(state);
}
