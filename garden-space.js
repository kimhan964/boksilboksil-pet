import {GARDEN_WORK_TIMING} from './garden-work.js';
import {choreMotion,transformToolPoint,fallingParticle} from './garden-motion.js';
import {initGardenIdle} from './garden-idle.js';
import {CROPS,GARDEN_DISHES,recipesForCrop,cropUnlocked,plotStatus,plantCrop,waterCrop,harvestCrop,expandGarden} from './garden.js';
export function createGardenSpace(api){
 const {state,save,toast,recordEvent,updateUI,log,iconHTML}=api;let active=false,selected='carrot';
 const space=document.querySelector('#garden-space');
 function enter(crop){if(!api.prepare())return;if(typeof crop==='string'&&CROPS.some(c=>c.id===crop)){if(cropUnlocked(state,crop))selected=crop;else toast(CROPS.find(c=>c.id===crop).name+' 씨앗은 총 수확 '+CROPS.find(c=>c.id===crop).harvests+'회에 열려요.');}api.closeSheet();active=true;document.body.classList.add('garden-view');space.hidden=false;document.querySelector('#scene-garden').setAttribute('aria-pressed','true');document.querySelector('#scene-home').setAttribute('aria-pressed','false');render();}
 function home(){active=false;space.hidden=true;document.body.classList.remove('garden-view');document.querySelector('#scene-home').setAttribute('aria-pressed','true');document.querySelector('#scene-garden').setAttribute('aria-pressed','false');api.onHome();}
 function changed(){save();updateUI();render();}
 function act(i){if(api.worker.task?.plot===i){toast('펫이 이 밭을 돌보고 있어요. 잠깐 기다려 주세요.');return;}const status=plotStatus(state,i);
  if(status.stage==='empty'){const crop=plantCrop(state,i,selected);if(!crop)return toast('씨앗 해금 조건과 도토리를 확인해 주세요.');changed();toast(crop.name+' 씨앗을 심었어요. 물을 주세요!');}
  else if(status.stage==='thirsty'){if(!waterCrop(state,i))return;changed();toast('물을 줬어요. 햇살을 받으며 쑥쑥 자라요.');}
  else if(status.stage==='ready'){const result=harvestCrop(state,i);if(!result)return;recordEvent(state,'harvest');log(result.crop.name+' '+result.amount+'개를 수확했어요.');selected=result.crop.id;changed();toast(result.crop.name+' +'+result.amount+(result.recipes.length?' · '+result.recipes.map(r=>r.name.replace('텃밭 ','')).join(' · ')+' 해금!':''));}
  else if(status.stage==='growing')toast('조금만 기다려 주세요. 작물이 자라고 있어요.');
 }
 function render(){const g=state.garden;space.innerHTML=`<div class="yard-heading"><b>우리의 작은 텃밭</b><small>수확 ${g.harvests}회 · 요리법 ${g.recipes.length}/${GARDEN_DISHES.length}</small><button id="yard-auto" aria-pressed="${initGardenIdle(state).enabled}">자동 생활 ${g.auto.enabled?'ON':'OFF'}</button><small id="yard-auto-status"></small></div><div class="yard-beds"></div><canvas class="yard-pet" width="180" height="180" aria-label="텃밭에 함께 온 우리 펫"></canvas><div class="yard-tools"><button id="yard-expand"></button><button id="yard-care">${iconHTML('flower')} 돌봄 · 상점</button><button id="yard-recipes" class="yard-recipe-link"></button></div><div class="yard-dock"><div class="yard-seeds" aria-label="심을 씨앗 선택"></div><div class="yard-stock">${CROPS.map(c=>`<span>${c.name} <b>${g.ingredients[c.id]}</b></span>`).join('')}</div></div>`;
  for(let i=0;i<3;i++){const s=plotStatus(state,i),b=document.createElement('button');b.className='yard-bed '+s.stage;b.dataset.plot=String(i);b.disabled=s.stage==='locked';b.innerHTML=`<div class="yard-soil">${s.crop?Array.from({length:3},()=>`<img src="${s.crop.art}" alt="">`).join(''):iconHTML(s.stage==='locked'?'lock':'flower')}</div><b></b><small></small>`;b.onclick=()=>act(i);space.querySelector('.yard-beds').append(b);}
  for(const c of CROPS){const b=document.createElement('button');b.className='yard-seed';b.disabled=!cropUnlocked(state,c.id);b.setAttribute('aria-pressed',String(selected===c.id));b.setAttribute('aria-label',c.name+' 씨앗 선택');b.innerHTML=`<img src="${c.art}" alt=""><div><b>${c.name}</b><small>${b.disabled?'수확 '+c.harvests+'회':c.seed+' 도토리 · '+c.seconds/60+'분'}</small></div>`;b.onclick=()=>{selected=c.id;render();};space.querySelector('.yard-seeds').append(b);}
  space.querySelector('#yard-auto').onclick=()=>{const a=initGardenIdle(state);a.enabled=!a.enabled;a.nextAt=0;changed();toast(a.enabled?'자동 재배와 요리를 시작해요.':'자동 생활을 쉬어요. 직접 돌볼 수 있어요.');};
  const ex=space.querySelector('#yard-expand'),required=g.plotCount===1?3:8,price=g.plotCount===1?40:80;ex.innerHTML=iconHTML('move')+(g.plotCount===3?'밭 확장 완료':'밭 넓히기 · '+g.harvests+'/'+required+'회 · '+price+' 도토리');ex.disabled=g.plotCount===3||g.harvests<required||state.coins<price;ex.onclick=()=>{if(!expandGarden(state))return;changed();toast('우리 텃밭이 더 넓어졌어요!');};space.querySelector('#yard-care').onclick=api.farm;const recipeLink=space.querySelector('#yard-recipes'),crop=CROPS.find(c=>c.id===selected),recipes=recipesForCrop(selected);recipeLink.innerHTML=`<img src="${crop.art}" alt=""><span>${crop.name} 요리 ${recipes.length}종<br><small>${g.discovered.includes(selected)?'요리책 열기 →':'첫 수확으로 해금 →'}</small></span>`;recipeLink.setAttribute('aria-label',crop.name+' 요리책 열기');recipeLink.title=recipes.map(r=>r.name).join(' · ');recipeLink.onclick=()=>api.kitchen(selected);update();
 }
 function update(){if(!active)return;const a=initGardenIdle(state);space.querySelector('#yard-auto-status').textContent=(a.enabled?a.message:'직접 돌보는 중')+' · 씨앗 '+a.spent+'/100';space.querySelectorAll('.yard-stock b').forEach((b,i)=>{b.textContent=state.garden.ingredients[CROPS[i].id];});for(const b of space.querySelectorAll('.yard-bed')){const i=Number(b.dataset.plot),s=plotStatus(state,i);b.className='yard-bed '+s.stage;const action=s.stage==='empty'?CROPS.find(c=>c.id===selected).name+' 씨앗 심기':s.stage==='thirsty'?'물 주기':s.stage==='ready'?'수확하기':s.stage==='growing'?'자라는 중':'잠긴 밭';b.querySelector('b').textContent=s.stage==='empty'?CROPS.find(c=>c.id===selected).name+' 심기':s.crop?.name||'밭을 넓혀요';b.querySelector('small').textContent=s.stage==='locked'?(i===1?'수확 3회로 확장':'수확 8회로 확장'):s.stage==='empty'?'빈 밭을 톡 눌러요':s.stage==='thirsty'?'톡 눌러 물 주기':s.stage==='ready'?'수확 '+s.yield+'개':Math.floor(s.remaining/60)+'분 '+s.remaining%60+'초'+(s.fertilized?' · 비료':'' );b.setAttribute('aria-label',(i+1)+'번 밭 · '+action);}}
 const artCache=new Map();
 for(const name of ['watering-can','seed-bag','harvest-basket','cooking-pot','water-drop','seed-grain','harvest-glow','steam-puff'])art('assets/garden/'+name+'-v1.png');
 function art(src){if(!artCache.has(src)){const im=new Image();im.src=src;artCache.set(src,im);}return artCache.get(src);}
 function geometry(plan){
  const w=space.clientWidth||space.parentElement.clientWidth,h=space.clientHeight||space.parentElement.clientHeight,size=Math.min(135,Math.max(60,h*.31));
  const origin={x:w*.74,y:h*.72};let soil=null;
  if(Number.isInteger(plan?.plot)){
   const bed=space.querySelector('[data-plot="'+plan.plot+'"] .yard-soil'),r=bed?.getBoundingClientRect(),rect=space.getBoundingClientRect();
   soil=r?.width?{x:r.x-rect.x+r.width*.5,y:r.y-rect.y+r.height*.32,height:r.height}:{x:w*(.07+.72*(plan.plot+.5)/3),y:h*.43,height:h*.25};
  }
  const dest=soil?{x:soil.x+size*.82,y:Math.min(h*.70,soil.y+size*.25)}:{x:w*.74,y:h*.67};
  return {w,h,size,origin,soil,dest};
 }
 function timing(plan){const g=geometry(plan),period=api.motion()?.hop?.period||.8;
  const cycles=Math.max(1,Math.min(7,Math.ceil(Math.hypot(g.dest.x-g.origin.x,g.dest.y-g.origin.y)/(g.size*.82))));
  return {walk:cycles*period,work:4.2,return:cycles*period};
 }
 function draw(time){
  if(!active)return;const canvas=space.querySelector('.yard-pet'),ctx=canvas.getContext('2d'),t=api.worker.task,{w,h,size,origin,soil,dest}=geometry(t),dpr=Math.min(devicePixelRatio||1,2);
  if(canvas.width!==Math.round(w*dpr)||canvas.height!==Math.round(h*dpr)){canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);}
  ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,w,h);
  function sprite(name,cx,cy,width){const im=art('assets/garden/'+name+'-v1.png');if(!im.complete||!im.naturalWidth)return;const height=width*im.naturalHeight/im.naturalWidth;ctx.drawImage(im,cx-width/2,cy-height/2,width,height);}
  const m=t?choreMotion(t.elapsed,t.timing||GARDEN_WORK_TIMING,t.type,api.motion()?.hop):null;
  const x=m?origin.x+(dest.x-origin.x)*m.travel:origin.x,y=m?origin.y+(dest.y-origin.y)*m.travel:origin.y;
  const walking=m&&m.phase!=='work',working=m?.phase==='work',dir=walking?(m.phase==='walk'?(dest.x<origin.x?-1:1):(dest.x<origin.x?1:-1)):-1;
  ctx.fillStyle='#756c4830';ctx.beginPath();ctx.ellipse(x,y,size*.22,size*.045,0,0,Math.PI*2);ctx.fill();
  ctx.save();ctx.translate(x,y);ctx.rotate(m?.lean||0);
  const pose=m?{bank:walking?'walk':'look',elapsed:m.local,...(working?{progress:m.p}:{})}:null;
  const anchors=api.drawPet(ctx,0,0,size,state.species,time,walking,dir,null,null,pose);ctx.restore();
  if(!t){canvas.setAttribute('aria-label','텃밭에서 쉬고 있는 우리 펫');return;}
  const localHand=anchors?.hand||{x:-size*.08,y:-size*.20},hand=transformToolPoint({x,y},localHand,m.lean);
  const tool={water:'watering-can',plant:'seed-bag',harvest:'harvest-basket',cook:'cooking-pot'}[t.type];
  const toolWidth={water:.53,plant:.34,harvest:.46,cook:.48}[t.type]*size,im=art('assets/garden/'+tool+'-v1.png'),toolHeight=toolWidth*(im.naturalHeight/(im.naturalWidth||1));
  const grip={water:{x:.33,y:0},plant:{x:0,y:-.35},harvest:{x:0,y:-.35},cook:{x:.40,y:0}}[t.type],flip=dir===-1?1:-1;
  ctx.save();ctx.translate(hand.x,hand.y);ctx.scale(flip,1);ctx.rotate(m.tilt);
  sprite(tool,-grip.x*toolWidth,-grip.y*toolHeight,toolWidth);
  if(t.type==='harvest'&&(t.committed||working&&m.p>.55)){
   const crop=art(t.result?.crop.art||CROPS.find(c=>c.id===state.garden.plots[t.plot]?.crop)?.art||CROPS[0].art);
   if(crop.complete&&crop.naturalWidth)ctx.drawImage(crop,-size*.12,-size*.07,size*.24,size*.24);
  }
  if(t.type==='cook'&&working){for(let i=0;i<3;i++){const u=(m.local*.8+i/3)%1;ctx.globalAlpha=(1-u)*.7;sprite('steam-puff',-toolWidth*.4+(i-1)*size*.08,-size*(.13+u*.20),size*(.12+u*.10));}ctx.globalAlpha=1;}
  ctx.restore();
  if(working&&soil){
   const work=t.timing?.work||GARDEN_WORK_TIMING.work,count=t.type==='water'?32:9;
   for(let i=0;i<count;i++){
    const born=t.type==='water'?work*.25+i*.065:work*(.30+Math.floor(i/3)*.18)+(i%3)*.045,age=m.local-born,life=.55;
    if(age<0||age>life||born>work*.78)continue;
    const mouth=t.type==='water'?{x:(-.46-grip.x)*toolWidth,y:(-.05-grip.y)*toolHeight}:{x:-grip.x*toolWidth,y:(-.43-grip.y)*toolHeight};
    const start=transformToolPoint(hand,mouth,m.tilt,flip),end={x:soil.x+(i%3-1)*size*.15,y:soil.y+soil.height*.42};
    const u=age/life,point=fallingParticle(start,end,u);ctx.globalAlpha=1-Math.max(0,(u-.85)/.15);
    sprite(t.type==='water'?'water-drop':t.type==='plant'?'seed-grain':'harvest-glow',point.x,point.y,t.type==='harvest'?size*.12:size*.065);
   }ctx.globalAlpha=1;
  }
  canvas.setAttribute('aria-label','우리 펫 · '+m.label);
  ctx.font='bold 10px "Malgun Gothic",sans-serif';const textWidth=ctx.measureText(m.label).width,bx=Math.max(3,Math.min(w-textWidth-17,x-textWidth/2-7)),by=Math.max(3,y-size*.80-18);ctx.fillStyle='#fff9eae8';ctx.beginPath();ctx.roundRect(bx,by,textWidth+14,19,8);ctx.fill();ctx.fillStyle='#697958';ctx.fillText(m.label,bx+7,by+13);
 }

 document.querySelector('#scene-garden').onclick=enter;document.querySelector('#scene-home').onclick=home;
 return {enter,home,update,draw,timing,refresh:()=>{if(active)render();},get active(){return active;}};
}
