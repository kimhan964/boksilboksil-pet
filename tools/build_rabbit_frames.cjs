// VARCO full-character frames only: crop, remove cyan, align, and package.
// Never separates or animates anatomical parts.
const fs=require('fs'), path=require('path'), sharp=require('sharp');
const root=path.resolve(__dirname,'..');
const actions=['idle','walk','pet','eat','drink','sleep','carry','jump','look','sniff','wave','groom','stretch','rub','toy','rest'];
const duration={idle:4.8,walk:1.0,pet:2.4,eat:3.2,drink:3.2,sleep:3.6,carry:1.4,jump:.8,look:2.8,sniff:2.4,wave:2.4,groom:2.8,stretch:2.8,rub:2.8,toy:3.2,rest:3.6};
const outDir=path.join(root,'assets/rabbit-v3');
const design=path.join(root,'design/rabbit-v3');
const clamp=(v,a,b)=>Math.min(b,Math.max(a,v));
function components(mask,w,h) {
 const seen=new Uint8Array(w*h), list=[];
 for(let p=0;p<mask.length;p++) {
  if(!mask[p]||seen[p]) continue;
  const queue=[p];seen[p]=1;let n=0,sx=0,sy=0,x0=w,y0=h,x1=0,y1=0;
  for(let q=0;q<queue.length;q++) {
   const at=queue[q],x=at%w,y=Math.floor(at/w);n++;sx+=x;sy+=y;x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);
   for(const next of [x>0?at-1:-1,x+1<w?at+1:-1,y>0?at-w:-1,y+1<h?at+w:-1])
    if(next>=0&&mask[next]&&!seen[next]){seen[next]=1;queue.push(next)}
  }
  list.push({n,x:sx/n,y:sy/n,x0,y0,x1,y1,seed:p});
 }
 return list;
}
function inspect(buf,w,h) {
 let x0=w,y0=h,x1=0,y1=0;
 const noseMask=new Uint8Array(w*h);
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){
  const k=(y*w+x)*4,r=buf[k],g=buf[k+1],b=buf[k+2],a=buf[k+3];
  if(a>30){x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);}
  if(a>220&&r>150&&r-g>65&&g-b>-2&&g<165&&b<150)noseMask[y*w+x]=1;
 }
 const bound={left:x0,top:y0,width:x1-x0+1,height:y1-y0+1};
 const noses=components(noseMask,w,h).filter(c=>c.n>=6&&c.n<180&&c.y>y0+bound.height*.25&&c.y<y0+bound.height*.83&&c.x>x0+bound.width*.48);
 noses.sort((a,b)=>b.n-a.n);
 const nose=noses[0]||{x:x0+bound.width*.76,y:y0+bound.height*.48};
 let hx0=w,hx1=0;
 for(let y=Math.max(0,Math.round(nose.y)-3);y<=Math.min(h-1,Math.round(nose.y)+3);y++)
  for(let x=0;x<w;x++){
   const k=(y*w+x)*4,r=buf[k],g=buf[k+1],b=buf[k+2];
   if(buf[k+3]>200&&r>215&&g>165&&b>135&&r>=g-5&&g>=b-10){hx0=Math.min(hx0,x);hx1=Math.max(hx1,x)}
  }
 let fx0=w,fx1=0;
 for(let y=Math.max(0,Math.floor(y1-bound.height*.14));y<=y1;y++)for(let x=x0;x<=x1;x++){
  if(buf[(y*w+x)*4+3]>100){fx0=Math.min(fx0,x);fx1=Math.max(fx1,x)}
 }
 return {bound,nose:[nose.x,nose.y],noseDetected:noses.length>0,headWidth:hx1-hx0+1,root:[(fx0+fx1)/2,y1+1]};
}
async function readFrames(stage,action) {
 const {data,info}=await sharp(path.join(design,stage,action+'.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const w=info.width/4,h=info.height/2;
 if(!Number.isInteger(w)||!Number.isInteger(h))throw Error('Uneven grid '+stage+'/'+action);
 const result=[];
 for(let f=0;f<8;f++){
  const raw=Buffer.alloc(w*h*4);
  for(let y=0;y<h;y++)for(let x=0;x<w;x++){
   const s=(((f>>2)*h+y)*info.width+(f%4)*w+x)*4,d=(y*w+x)*4;
   const r=data[s],g=data[s+1],b=data[s+2],spill=Math.min(g-r,b-r);
   let a=spill<=10?1:Math.max(0,1-(spill-10)/210);if(a<.025)a=0;
   raw[d]=a?clamp(Math.round(r/a),0,255):0;
   raw[d+1]=a?clamp(Math.round((g-(1-a)*245)/a),0,255):0;
   raw[d+2]=a?clamp(Math.round((b-(1-a)*245)/a),0,255):0;
   raw[d+3]=Math.round(a*255);
  }
  // Remove disconnected generated motion ticks / specks. Keep the whole rabbit.
  const alphaMask=new Uint8Array(w*h);
  for(let p=0;p<alphaMask.length;p++)alphaMask[p]=raw[p*4+3]>0?1:0;
  const islands=components(alphaMask,w,h).sort((a,b)=>b.n-a.n);
  const keep=new Uint8Array(w*h),queue=[islands[0].seed];keep[queue[0]]=1;
  for(let q=0;q<queue.length;q++){
   const p=queue[q],x=p%w,y=Math.floor(p/w);
   for(const next of [x>0?p-1:-1,x+1<w?p+1:-1,y>0?p-w:-1,y+1<h?p+w:-1])
    if(next>=0&&alphaMask[next]&&!keep[next]){keep[next]=1;queue.push(next)}
  }
  for(let p=0;p<keep.length;p++)if(!keep[p])raw.fill(0,p*4,p*4+4);
  result.push({raw,w,h,...inspect(raw,w,h)});
 }
 return result;
}
async function main(){
 fs.mkdirSync(outDir,{recursive:true});fs.mkdirSync(path.join(design,'review'),{recursive:true});
 const manifest={version:3,method:'generated-complete-character-cels',canvas:[256,256],root:[128,232],stages:{}};
 const report={method:'One scale per action, calibrated to its neutral head width. No per-frame height normalization.',sequences:[]};
 for(const stage of ['baby','adult']){
  const idle=await readFrames(stage,'idle'),ref=idle[0];
  const baseFactor=200/ref.bound.height,targetHead=ref.headWidth*baseFactor;
  const stageData={reference_height:200,master:'design/rabbit-v3/'+stage+'/master.png',sequences:{}};
  const previewFrames=[];
  let neutralImage,neutralAnchor;
  for(const action of actions){
   const frames=action==='idle'?idle:await readFrames(stage,action);
   const neutral=frames[0];
   const factor=neutral.noseDetected&&neutral.headWidth>100?targetHead/neutral.headWidth:200/neutral.bound.height;
   const images=[],anchors=[];
   for(let f=0;f<8;f++){
    const src=frames[f],b=src.bound;
    let lift=0;
    if(action==='jump')lift=[0,0,3,13,19,10,0,0][f];
    if(action==='carry')lift=[0,2,5,5,5,5,0,0][f];
    const sw=Math.round(b.width*factor),sh=Math.round(b.height*factor);
    const left=Math.round(128+(b.left-src.root[0])*factor),top=Math.round(232+(b.top-src.root[1])*factor-lift);
    if(left<1||top<1||left+sw>255||top+sh>255)throw Error('Clipped '+stage+'/'+action+'/'+f+' '+[left,top,sw,sh]);
    const cut=await sharp(src.raw,{raw:{width:src.w,height:src.h,channels:4}}).extract(b).resize(sw,sh,{kernel:'lanczos3'}).png().toBuffer();
    const png=await sharp({create:{width:256,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:cut,left,top}]).png().toBuffer();
    images.push(png);
    const mouth=[128+(src.nose[0]-src.root[0])*factor,232+(src.nose[1]+8-src.root[1])*factor-lift];
    const handGap=([75,60,42,42,44,48,65,75][f])*factor;
    const hand=[mouth[0]-10*factor,mouth[1]+handGap];
    anchors.push({mouth,hand,source_root:src.root,source_bounds:[b.left,b.top,b.width,b.height],head_width:src.headWidth*factor,nose_detected:src.noseDetected});
   }
   // Reuse the SAME complete neutral cel at gesture boundaries. This is
   // whole-frame selection, never assembly of body parts or invented motion.
   if(action==='idle'){neutralImage=images[0];neutralAnchor=anchors[0]}
   if(action!=='walk'){
    for(const index of [0,7]){
     images[index]=neutralImage;
     anchors[index]={...neutralAnchor,source_action:'idle',source_frame:0};
    }
   }
   const file=stage+'-'+action+'.png';
   await sharp({create:{width:2048,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(images.map((input,i)=>({input,left:i*256,top:0}))).png().toFile(path.join(outDir,file));
   stageData.sequences[action]={file,count:8,duration:duration[action],anchors};
   report.sequences.push({stage,action,scale:factor,neutralHeadWidth:neutral.headWidth,normalizedHeadWidths:anchors.map(a=>Math.round(a.head_width*10)/10),noseMisses:anchors.flatMap((a,i)=>a.nose_detected?[]:[i])});
   previewFrames.push({action,images});
  }
  manifest.stages[stage]=stageData;
  for(let batch=0;batch<4;batch++){
   const layers=[];
   for(let row=0;row<4;row++){
    const item=previewFrames[batch*4+row];
    const label=Buffer.from('<svg width="1536" height="28"><rect width="1536" height="28" fill="#e8ece9"/><text x="12" y="20" font-size="16" font-family="Arial" fill="#333">'+stage+' / '+item.action+'</text></svg>');
    layers.push({input:label,left:0,top:row*220});
    for(let f=0;f<8;f++)layers.push({input:await sharp(item.images[f]).resize(192,192).png().toBuffer(),left:f*192,top:row*220+28});
   }
   await sharp({create:{width:1536,height:880,channels:4,background:'#f4f2ef'}}).composite(layers).png().toFile(path.join(design,'review',stage+'-'+batch+'.png'));
  }
 }
 fs.writeFileSync(path.join(outDir,'manifest.json'),JSON.stringify(manifest,null,2));
 fs.writeFileSync(path.join(design,'frame-calibration.json'),JSON.stringify(report,null,2));
 console.log(JSON.stringify(report));
}
main().catch(e=>{console.error(e);process.exit(1)});
