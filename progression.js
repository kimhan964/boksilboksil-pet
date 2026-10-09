// Progress belongs to the home, while needs belong to each animal.
export const FRIEND_LEVELS = {rabbit:1,otter:2,squirrel:2,hedgehog:3,raccoon:3,fox:4,bear:4,owl:5,cat:5,puppy:6,hamster:6,panda:7,red_panda:7,lamb:8,koala:8,penguin:9};
export const SKIN_LEVELS = {forest:1,korea:2,japan:3,france:4,finland:6,morocco:8};
export const FURNITURE_LEVELS = {sofa:1,table:1,rug:1,plant:1,lamp:2,clock:2,chair:3,shelf:3,bed:4,record:5,tv:6,aquarium:7};
export const PERIODS = [
  {id:'morning',name:'아침',hours:'06:00~11:59',icon:'sun'},
  {id:'day',name:'낮',hours:'12:00~17:59',icon:'flower'},
  {id:'evening',name:'저녁',hours:'18:00~21:59',icon:'decorate'},
  {id:'night',name:'밤',hours:'22:00~05:59',icon:'sleep'}
];
// Time is an alternative route to the existing level route. Period visits stack
// across sessions, and an unlocked entry remains open after the clock changes.
export const TIME_UNLOCKS = {
  furniture:{lamp:{minutes:5,period:'night'},clock:{minutes:10,period:'morning'},chair:{minutes:15,period:'day'},shelf:{minutes:25},bed:{minutes:20,period:'night'},record:{minutes:30,period:'evening'},tv:{minutes:45,period:'evening'},aquarium:{minutes:60,period:'day'}},
  friend:{otter:{minutes:5},squirrel:{minutes:8,period:'morning'},hedgehog:{minutes:12,period:'evening'},raccoon:{minutes:15,period:'night'},fox:{minutes:20,period:'evening'},bear:{minutes:25,period:'day'},owl:{minutes:20,period:'night'},cat:{minutes:30},puppy:{minutes:35,period:'morning'},hamster:{minutes:40},panda:{minutes:50,period:'day'},red_panda:{minutes:55,period:'evening'},lamb:{minutes:60,period:'morning'},koala:{minutes:70,period:'day'},penguin:{minutes:80,period:'night'}},
  skin:{korea:{minutes:20,period:'morning'},japan:{minutes:30,period:'evening'},france:{minutes:45,period:'day'},finland:{minutes:60,period:'night'},morocco:{minutes:90,period:'evening'}}
};
const LEVELS={friend:FRIEND_LEVELS,skin:SKIN_LEVELS,furniture:FURNITURE_LEVELS};
const seoulHour=new Intl.DateTimeFormat('en-GB',{timeZone:'Asia/Seoul',hour:'2-digit',hourCycle:'h23'});
export function timePeriod(now=Date.now()){const hour=Number(seoulHour.format(new Date(now)));return PERIODS.find(p=>p.id===(hour>=6&&hour<12?'morning':hour>=12&&hour<18?'day':hour>=18&&hour<22?'evening':'night'));}
export function formatPlayTime(seconds){const minutes=Math.floor(seconds/60);return minutes<1?Math.floor(seconds)+'초':minutes<60?minutes+'분 '+Math.floor(seconds%60)+'초':Math.floor(minutes/60)+'시간 '+minutes%60+'분';}
function ownedIds(state,kind){return kind==='friend'?state.progress.friends:kind==='skin'?state.progress.skins:state.owned;}
function timeReady(state,rule){return rule&&state.progress.playSeconds>=rule.minutes*60&&(!rule.period||(state.progress.periodSeconds[rule.period]||0)>=60);}
export function unlockCondition(state,kind,id){
  const rule=TIME_UNLOCKS[kind]?.[id];if(!rule)return 'Lv. '+LEVELS[kind][id]+' 해금';
  const remaining=Math.max(0,Math.ceil((rule.minutes*60-state.progress.playSeconds)/60));
  const period=PERIODS.find(p=>p.id===rule.period),visit=rule.period?Math.max(0,Math.ceil(60-(state.progress.periodSeconds[rule.period]||0))):0;
  return 'Lv. '+LEVELS[kind][id]+' 또는 '+(remaining?'플레이 '+remaining+'분 더':'플레이 시간 달성')+(period?' · '+period.name+(visit?' '+visit+'초 더':' 방문 완료'):'');
}
export function refreshUnlocks(state){
  const opened=[];for(const [kind,ids] of Object.entries(LEVELS))for(const [id,required] of Object.entries(ids)){
    if(state.progress.unlocked[kind].includes(id))continue;
    if(ownedIds(state,kind).includes(id)||level(state)>=required||timeReady(state,TIME_UNLOCKS[kind]?.[id])){state.progress.unlocked[kind].push(id);opened.push({kind,id});}
  }return opened;
}
export function addPlayTime(state,seconds,now=Date.now()){
  // A long scheduler gap or a suspended mobile tab must never count as play.
  if(!Number.isFinite(seconds)||seconds<=0||seconds>5)return [];
  state.progress.playSeconds+=seconds;
  // Split an interval crossing an hour, including a Korean period boundary.
  let cursor=now-seconds*1000;while(cursor<now){const end=Math.min(now,(Math.floor(cursor/3600000)+1)*3600000),period=timePeriod(cursor).id;state.progress.periodSeconds[period]=(state.progress.periodSeconds[period]||0)+(end-cursor)/1000;cursor=end;}
  return refreshUnlocks(state);
}
export const GOALS = [
  {id:'first-order',title:'숲속 식당 첫 주문',description:'식당에서 요리를 한 접시 주문하세요',event:'foodbuy',target:1,coins:20,xp:15,icon:'feed'},
  {id:'taste-five',title:'작은 숲의 미식가',description:'서로 다른 식당 요리를 5종 먹여 주세요',event:'taste',target:5,coins:60,xp:40,icon:'feed'},
  {id:'first-feed',title:'냠냠, 첫 간식',description:'친구에게 먹이를 한 번 주세요',event:'feed',target:1,coins:30,xp:20,icon:'feed'},
  {id:'first-pet',title:'마음을 나누는 쓰담',description:'친구를 한 번 쓰다듬어 주세요',event:'pet',target:1,coins:25,xp:20,icon:'pet'},
  {id:'first-clean',title:'보송보송 목욕 시간',description:'친구를 한 번 씻겨 주세요',event:'clean',target:1,coins:30,xp:20,icon:'clean'},
  {id:'first-play',title:'실뭉치와 데굴데굴',description:'친구와 한 번 놀아 주세요',event:'play',target:1,coins:30,xp:20,icon:'play'},
  {id:'first-rest',title:'달콤한 낮잠',description:'친구를 한 번 쉬게 해 주세요',event:'sleep',target:1,coins:25,xp:20,icon:'sleep'},
  {id:'first-arrange',title:'내 손으로 꾸민 집',description:'가구를 옮기고 꾸미기를 완료하세요',event:'arrange',target:1,coins:40,xp:25,icon:'decorate'},
  {id:'first-buy',title:'작은 집에 새 가구',description:'새 가구를 한 개 구입하세요',event:'buy',target:1,coins:45,xp:25,icon:'decorate'},
  {id:'first-friend',title:'반가워, 새 친구',description:'다른 친구와 함께 살아 보세요',event:'friend',target:1,coins:50,xp:30,icon:'friends'},
  {id:'first-skin',title:'우리 집 세계 여행',description:'집 스킨을 한 번 바꿔 보세요',event:'skin',target:1,coins:50,xp:30,icon:'skins'},
  {id:'care-20',title:'다정한 집사',description:'돌봄을 총 20번 완료하세요',event:'care',target:20,coins:100,xp:60,icon:'pet'},
  {id:'care-60',title:'함께 자라는 우리',description:'돌봄을 총 60번 완료하세요',event:'care',target:60,coins:180,xp:100,icon:'flower'}
];
export const DAILY_GOALS = [
  {id:'daily-feed',title:'오늘의 든든한 한 끼',description:'먹이를 2번 주세요',event:'feed',target:2,coins:25,xp:15,icon:'feed'},
  {id:'daily-care',title:'오늘도 다정하게',description:'돌봄을 5번 완료하세요',event:'care',target:5,coins:40,xp:25,icon:'pet'},
  {id:'daily-clean',title:'뽀송한 하루',description:'목욕을 한 번 완료하세요',event:'clean',target:1,coins:20,xp:15,icon:'clean'}
];
export function dayKey(now=Date.now()){return new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Seoul',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date(now));}
export function levelInfo(xp){let level=1,start=0,next=60;while(xp>=next&&level<9){start=next;level++;next+=60+(level-1)*25;}return {level,start,next,earned:xp-start,needed:next-start,max:level===9};}
export function initProgress(state,now=Date.now()){
  if(!state.progress)state.progress={xp:Math.max(0,Math.floor((state.bond||0)*2)),counts:{},claimed:[],friends:[state.species,...Object.keys(state.petStats||{})],skins:[state.skin||'forest'],daily:{day:dayKey(now),counts:{},claimed:[]}};
  const p=state.progress;p.playSeconds=Number.isFinite(p.playSeconds)&&p.playSeconds>=0?p.playSeconds:0;p.periodSeconds||={};p.unlocked||={friend:[],skin:[],furniture:[]};
  refreshUnlocks(state);refreshDay(state,now);return p;
}
export function refreshDay(state,now=Date.now()){const key=dayKey(now);if(state.progress.daily.day!==key)state.progress.daily={day:key,counts:{},claimed:[]};}
export function level(state){return levelInfo(state.progress.xp).level;}
export function isUnlocked(state,kind,id){return state.progress.unlocked[kind]?.includes(id)||ownedIds(state,kind).includes(id)||level(state)>=(LEVELS[kind]?.[id]??Infinity)||Boolean(timeReady(state,TIME_UNLOCKS[kind]?.[id]));}
export function recordEvent(state,event,now=Date.now()){
  refreshDay(state,now);const p=state.progress;for(const counts of [p.counts,p.daily.counts]){counts[event]=(counts[event]||0)+1;if(['feed','pet','play','clean','sleep'].includes(event))counts.care=(counts.care||0)+1;}
  if(['feed','pet','play','clean','sleep'].includes(event))p.xp+=p.daily.counts[event]<=5?8:1;
  refreshUnlocks(state);
}
export function goalStatus(state,goal,daily=false){const p=daily?state.progress.daily:state.progress,value=Math.min(goal.target,p.counts[goal.event]||0);return {value,ready:value>=goal.target,claimed:p.claimed.includes(goal.id)};}
export function claimGoal(state,id,daily=false,now=Date.now()){
  refreshDay(state,now);const goal=(daily?DAILY_GOALS:GOALS).find(g=>g.id===id);if(!goal)return false;const status=goalStatus(state,goal,daily);if(!status.ready||status.claimed)return false;
  (daily?state.progress.daily:state.progress).claimed.push(id);state.coins+=goal.coins;state.progress.xp+=goal.xp;refreshUnlocks(state);return goal;
}
