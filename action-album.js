// Adapted from the installed 16-species v1 action album (2026-10-14).
// Preview state is local: never awards care, changes outfits, or changes growth.
import {resolveAnimation} from './animation-player.js';
import {growthInfo} from './desktop-features.js';

export const ALBUM_ACTIONS=[
 ['idle','�ϻ�','������ ���','�ƹ��͵� ���� �ʰ� ��� ���� ���� ������.','', 'sleep'],
 ['walk','�ϻ�','��å �� ���Ѱ���','�� �ٴ��� �� �����ų� ģ���� ������ ��å�� �� �� �� �־��.','', 'move'],
 ['look','�ϻ�','�ֺ� �ѷ�����','��Ȱ �޴��� ���� �������� ���ݿ� ���� �ֺ��� �������. ���������� ������ �� �� �־��.','', 'flower'],
 ['stretch','�ϻ�','������','��ü ���� ���� �������� ������. �ٸ� ģ���� �������� �������� �̸� �� �� �־��.','', 'sun'],
 ['pet','����','��� ���� ����','ģ���� ª�� �����ų� ���㾲���� ���� �ּ���.','', 'pet'],
 ['carry','����','��¦ ���','ģ���� ��� ���� ä ���� �Ⱦ� �÷���. ���� ���� �������ƿ�.','', 'pet'],
 ['struggle','����','���� �ּ���','�Ⱦ� �ø� ä �� 2�ʰ� ������ ���հŷ���.','', 'pet'],
 ['eat','�Ļ硤�޽�','�ȳ� �Ļ�','���Ŀ��� �丮�� �غ��� �� �Ļ� ���̺��� ������ ���� �ּ���.','table', 'feed'],
 ['drink','�Ļ硤�޽�','�� �� ���','�������� ������ ������ ���� ������ �� ���� �ּ���.','water', 'clean'],
 ['sleep','�Ļ硤�޽�','�ٹ��ٹ�','���⸦ ������ �����. ħ�뿡���� �� �� �־��.','', 'sleep'],
 ['sofa','����������','���Ŀ��� ����','���ĸ� ���� ģ���� �ٰ��� ������ �� �ּ���.','sofa', 'decorate'],
 ['read','����������','å �д� �ð�','å���� ��ġ�ϰ� �� ���� �Բ� å�� �о��.','shelf', 'journal'],
 ['music','����������','���ǿ� �� ����̱�','���� ������ ��ġ�ϰ� ������ ������ ��ܿ�.','record', 'sound-on'],
 ['play','����������','���׿��� ���','���׸� ��ġ�� �� �Բ� ����� ���� ���̸� ����.','rug', 'play'],
 ['stumble','��¦ �ൿ','��, �ʴ�!','��å �� ���� ���� ������. �Ļ糪 ���� �̿� �߿��� �������� �ʾƿ�.','', 'flower'],
 ['sneeze','��¦ �ൿ','����!','���� ���� ���� ��ä���ؿ�. ���޾� �ݺ����� �ʾƿ�.','', 'flower']
].map(([id,category,title,trigger,furniture,icon])=>({id,category,title,trigger,furniture,icon}));
export const ALBUM_CATEGORIES=['��ü',...new Set(ALBUM_ACTIONS.map(a=>a.category))];
const BANKS={carry:'hold-pickup',sofa:'home-rest',read:'home-read',music:'home-music',play:'home-play'};
export function albumPose(action,elapsed=0){
 const bank=BANKS[action.id]||action.id;
 return {bank,elapsed,...(action.id==='carry'?{progress:Math.min(1,elapsed/.28)}:{})};
}
export function albumPreview(catalog,species,age,look,action){
 const previewLook={...(age==='baby'?{style:'none',color:0}:look),previewAge:age};
 const resolved=resolveAnimation(catalog,species,age,previewLook,albumPose(action));
 return {look:previewLook,resolved,supported:Boolean(resolved?.supported)};
}
export function albumRequirement(state,action,catalog,isOpen,condition){
 if(!action.furniture)return {text:'ó������ �Բ��ؿ�',label:'',item:null,open:true};
 const item=catalog.find(i=>i.id===action.furniture);
 if(!item)return {text:'�� ������ ���� �غ� ���̿���.',label:'',item:null,open:false};
 const open=isOpen(item),placed=state.furniture.some(f=>f.id===item.id),owned=state.owned.includes(item.id);
 return {item,open,placed,text:item.name+' �� '+(placed?'�濡 ���� �־��':owned?'�����Կ� �־��':open?'���ԡ���ġ ����':condition(item)),label:placed?'���� ��ġ ����':owned?'�����Կ��� ������':open?'���� �غ��ϱ�':'�ر� ���� ����'};
}

export function createActionAlbum(api){return function openAlbum(){
 const {state,openSheet,drawPet,iconHTML,animationCatalog}=api;
 openSheet('ģ���� �ൿ ����','���� ������ �߰��ϴ� �ð�');
 const content=document.querySelector('#sheet-content');content.className='action-album-sheet';
 content.innerHTML=`<div class="album-navigation"></div><div class="album-filters" aria-label="�ൿ �з�"></div><div class="action-book"><section class="action-preview"><div class="album-ages" aria-label="�̸����� ����"></div><canvas width="320" height="280" aria-label="ģ�� �ൿ �̸�����"></canvas><div class="album-controls"><button class="pill album-pause">�Ͻ� ����</button><button class="pill album-flip">���� �ٲٱ�</button></div><p class="album-preview-note"></p></section><section class="action-pages"><div class="album-actions" aria-label="�ൿ ����"></div><article class="album-detail" aria-live="polite"><h3></h3><p class="album-trigger"></p><p class="album-requirement"></p><button class="pill album-furniture"></button></article></section></div><p class="album-footnote">���̿� �������� �̸����⿹��. ���� ģ���� ���塤���������رݰ� ������ �ٲ��� �ʾƿ�.</p><button class="pill album-extras">�� ���� ���� ����</button>`;
 content.querySelector('.album-navigation').append(api.tabs('���� ����'));
 const root=content.querySelector('.action-book'),canvas=root.querySelector('canvas'),ctx=canvas.getContext('2d');
 const look={...(state.desktop.outfits[state.species]||{style:'none',color:0})};
 let selected=ALBUM_ACTIONS[0],category='��ü',age=growthInfo(state).stage==='baby'?'baby':'adult',paused=false,direction=1,elapsed=0,last=null;
 const ageRail=root.querySelector('.album-ages'),filter=content.querySelector('.album-filters'),list=root.querySelector('.album-actions');
 function button(text,fn){const b=document.createElement('button');b.type='button';b.textContent=text;b.onclick=fn;return b;}
 function detail(){
  const preview=albumPreview(animationCatalog,state.species,age,look,selected),req=albumRequirement(state,selected,api.catalog,api.isFurnitureOpen,api.furnitureCondition);
  root.querySelector('h3').textContent=selected.title;root.querySelector('.album-trigger').textContent=selected.trigger;
  root.querySelector('.album-requirement').textContent=req.text;
  const link=root.querySelector('.album-furniture');link.hidden=!req.item;link.textContent=req.label;link.onclick=()=>api.openFurniture(req.item.id);
  root.querySelector('.album-preview-note').textContent=age==='baby'?'�Ʊ� �� ���� ���':look.style&&look.style!=='none'?'��ü �� ���� ������':'��ü �� ���� ���';
  if(!preview.supported)root.querySelector('.album-preview-note').textContent+=' �� �� ����� ���� ������ �غ� ���̶� ��� ������� ������.';
  for(const b of ageRail.children)b.setAttribute('aria-pressed',String(b.dataset.age===age));
 }
 function renderList(){
  list.replaceChildren();for(const a of ALBUM_ACTIONS.filter(a=>category==='��ü'||a.category===category)){
   const b=button('',()=>{selected=a;elapsed=0;last=null;renderList();detail();});
   b.innerHTML=(a.id==='drink'?'<img class="ui-art" src="assets/desktop/water.webp" alt="">':iconHTML(a.icon))+`<span>${a.title}</span>`;b.setAttribute('aria-pressed',String(selected.id===a.id));list.append(b);
  }
  for(const b of filter.children)b.setAttribute('aria-pressed',String(b.textContent===category));
 }
 for(const c of ALBUM_CATEGORIES)filter.append(button(c,()=>{category=c;if(c!=='��ü'&&selected.category!==c)selected=ALBUM_ACTIONS.find(a=>a.category===c);elapsed=0;last=null;renderList();detail();}));
 for(const [id,label] of [['baby','�Ʊ�'],['adult','��ü']]){const b=button(label,()=>{age=id;elapsed=0;last=null;detail();});b.dataset.age=id;ageRail.append(b);}
 const pause=root.querySelector('.album-pause');pause.setAttribute('aria-pressed','false');pause.onclick=()=>{paused=!paused;last=null;pause.textContent=paused?'�ٽ� ���':'�Ͻ� ����';pause.setAttribute('aria-pressed',String(paused));};
 root.querySelector('.album-flip').onclick=()=>{direction*=-1;};
 content.querySelector('.album-extras').onclick=api.extras;
 renderList();detail();
 function animate(ms){
  if(!root.isConnected)return;
  if(!paused&&!document.hidden&&last!==null)elapsed+=Math.min(.1,(ms-last)/1000);last=ms;
  const p=albumPreview(animationCatalog,state.species,age,look,selected),pose=albumPose(selected,elapsed);
  pose.duration=p.resolved?.spec.duration||4.8;
  ctx.clearRect(0,0,320,280);drawPet(ctx,160,245,246,state.species,elapsed,false,direction,null,p.look,pose);
  requestAnimationFrame(animate);
 }
 requestAnimationFrame(animate);
};}
