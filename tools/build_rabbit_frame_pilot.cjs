// Whole character extraction and fixed-camera atlas packing only.
// No anatomical segmentation, recomposition, mesh warping or frame duplication.
const fs=require('fs'),path=require('path'),sharp=require('sharp');
const B=require('./build_all_species_frames.cjs');
const root=path.resolve(__dirname,'..');
const source=path.join(root,'design/rabbit-frame-pilot-v2/frames-walk-v2');
const output=path.join(root,'assets/rabbit-frame-pilot-v2');
const preview=path.join(root,'design/rabbit-frame-pilot-v2');
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
async function isolate(file){
 const {data,info}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const raw=Buffer.alloc(data.length),mask=new Uint8Array(info.width*info.height);
 for(let p=0;p<mask.length;p++){
  const at=p*4,r=data[at],g=data[at+1],b=data[at+2],spill=Math.min(g-r,b-r);
  let a=spill<=10?1:Math.max(0,1-(spill-10)/210);a*=data[at+3]/255;if(a<.025)a=0;
  raw[at]=a?clamp(Math.round(r/a),0,255):0;
  raw[at+1]=a?clamp(Math.round((g-(1-a)*245)/a),0,255):0;
  raw[at+2]=a?clamp(Math.round((b-(1-a)*245)/a),0,255):0;
  raw[at+3]=Math.round(a*255);mask[p]=raw[at+3]>30?1:0;
 }
 const islands=B.components(mask,info.width,info.height).sort((a,b)=>b.n-a.n);
 if(!islands.length||islands[0].n<10000)throw Error('Missing whole character '+file);
 if(islands[1]&&islands[1].n>islands[0].n*.15)throw Error('Extra character/component '+file);
 const biggest=islands[0],keep=new Uint8Array(mask.length),queue=[biggest.seed];keep[biggest.seed]=1;
 for(let q=0;q<queue.length;q++){
  const p=queue[q],x=p%info.width,y=Math.floor(p/info.width);
  for(const n of [x?p-1:-1,x+1<info.width?p+1:-1,y?p-info.width:-1,y+1<info.height?p+info.width:-1])
   if(n>=0&&mask[n]&&!keep[n]){keep[n]=1;queue.push(n);}
 }
 // Include anti-alias edge neighbors while discarding remote generation noise.
 for(let p=0;p<keep.length;p++)if(!keep[p]){
  const x=p%info.width,y=Math.floor(p/info.width);
  if(![x?p-1:-1,x+1<info.width?p+1:-1,y?p-info.width:-1,y+1<info.height?p+info.width:-1].some(n=>n>=0&&keep[n]))raw[p*4+3]=0;
 }
 const inspected=B.inspect(raw,info.width,info.height);
 if(inspected.bound.left<3||inspected.bound.top<3||inspected.bound.left+inspected.bound.width>info.width-3||inspected.bound.top+inspected.bound.height>info.height-3)throw Error('Clipped complete cel '+file);
 return {raw,w:info.width,h:info.height,...inspected};
}
async function main(){
 fs.mkdirSync(output,{recursive:true});
 const manifest={version:2,method:'complete illustrated whole-character cels',canvas:[256,256],root:[128,232],stages:{}};
 const report=[];
 for(const stage of ['adult','baby']){
  const master=await isolate(path.join(root,`design/all-species-v3/masters/rabbit/${stage}.png`));
  let images=[],calibration=[];
  const factor=216/master.bound.height;
  const referenceRoot=master.root;
  for(let i=0;i<32;i++){
   const filename=path.join(source,stage,String(i).padStart(2,'0')+'.png');
   const frame=await isolate(filename);
   const sourceRatio=master.w/frame.w;
   const b=frame.bound;
   const scaledWidth=Math.round(b.width*factor*sourceRatio),scaledHeight=Math.round(b.height*factor*sourceRatio);
   const left=Math.round(128+(b.left*sourceRatio-referenceRoot[0])*factor),top=Math.round(232+(b.top*sourceRatio-referenceRoot[1])*factor);
   if(left<0||top<0||left+scaledWidth>256||top+scaledHeight>256)throw Error('Fixed camera cannot fit original canvas');
   const cut=await sharp(frame.raw,{raw:{width:frame.w,height:frame.h,channels:4}}).extract(b).resize(scaledWidth,scaledHeight).png().toBuffer();
   const cel=await sharp({create:{width:256,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:cut,left,top}]).png().toBuffer();
   images.push(cel);calibration.push({index:i,sourceIndex:i,sourceWidth:frame.w,sourceHeight:frame.h,sourceBounds:frame.bound,sourceRoot:referenceRoot,fixedScale:factor*sourceRatio});
  }
  // Correct camera drift by translating the WHOLE cel to its reference head.
  // The art is never divided into body parts or deformed.
  const unaligned=await Promise.all(images.map(im=>sharp(im).ensureAlpha().raw().toBuffer()));
  const reference=unaligned[0];
  for(let i=0;i<images.length;i++){
   let best={cost:Infinity,dx:0,dy:0};
   for(let dy=-3;dy<=3;dy++)for(let dx=-3;dx<=3;dx++){
    let cost=0;
    for(let y=14;y<155;y+=2)for(let x=48;x<207;x+=2){
     const a=(y*256+x)*4,b=((y-dy)*256+x-dx)*4;
     const aa=reference[a+3]/255,ba=unaligned[i][b+3]/255;
     for(let c=0;c<4;c++){const difference=c===3?reference[a+3]-unaligned[i][b+3]:reference[a+c]*aa-unaligned[i][b+c]*ba;cost+=difference*difference;}
    }
    if(cost<best.cost)best={cost,dx,dy};
   }
   calibration[i].cameraTranslation=[best.dx,best.dy];
   // Keep the existing cel dimensions and scale; only its canvas offset changes.
   const alpha=B.inspect(unaligned[i],256,256).bound;
   const cut=await sharp(images[i]).extract(alpha).png().toBuffer();
   images[i]=await sharp({create:{width:256,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:cut,left:alpha.left+best.dx,top:alpha.top+best.dy}]).png().toBuffer();
  }
  // Measure the drawn sole contour only to order COMPLETE images in time.
  // No measured region is cut, transformed or composited back into the art.
  const scores=[];
  for(const cel of images){
   const pixels=await sharp(cel).ensureAlpha().raw().toBuffer();
   const soles=[];
   for(const [x0,x1] of [[72,117],[127,182]]){
    const columns=[];
    for(let x=x0;x<x1;x++){
     let bottom=-1;
     for(let y=207;y<241;y++){const p=(y*256+x)*4;if(pixels[p+3]>180&&pixels[p]<140&&pixels[p+1]<100)bottom=y;}
     if(bottom>=0)columns.push(bottom);
    }
    soles.push(columns.reduce((a,b)=>a+b,0)/columns.length);
   }
   scores.push(soles);
  }
  const order=[];
  const aligned=await Promise.all(images.map(im=>sharp(im).ensureAlpha().raw().toBuffer()));
  const pairCosts=Array.from({length:32},()=>Array(32).fill(0));
  for(let a=0;a<32;a++)for(let b=a+1;b<32;b++){
   let cost=0;
   for(let y=14;y<240;y+=2)for(let x=48;x<207;x+=2){
    const p=(y*256+x)*4,aa=aligned[a][p+3]/255,ba=aligned[b][p+3]/255;
    for(let c=0;c<4;c++){const difference=c===3?aligned[a][p+3]-aligned[b][p+3]:aligned[a][p+c]*aa-aligned[b][p+c]*ba;cost+=difference*difference*(y<155?2:1);}
   }
   pairCosts[a][b]=pairCosts[b][a]=cost;
  }
  for(let half=0;half<2;half++){
   const first=half*16,side=half===0?1:0;
   const candidates=Array.from({length:15},(_,i)=>first+i+1).sort((a,b)=>scores[b][side]-scores[a][side]);
   const peak=candidates.pop();
   let best={cost:Infinity,path:[]};
   // Choose the smoothest complete-image route with a monotonic rise/fall.
   // This also groups forepaw poses coherently instead of sorting only a foot.
   for(let mask=0;mask<(1<<14);mask++){
    const rising=[],falling=[];
    for(let i=0;i<14;i++)(mask&(1<<i)?rising:falling).push(candidates[i]);
    if(rising.length!==7)continue;
    const route=[first,...rising,peak,...falling.reverse(),(first+16)%32];
    let cost=0;for(let i=1;i<route.length;i++)cost+=pairCosts[route[i-1]][route[i]];
    if(cost<best.cost)best={cost,path:route.slice(0,-1)};
   }
   order.push(...best.path);
  }
  images=order.map(i=>images[i]);
  calibration=order.map((i,index)=>({...calibration[i],index,measuredSoles:scores[i]}));
  const layers=images.map((input,i)=>({input,left:i%8*256,top:Math.floor(i/8)*256}));
  await sharp({create:{width:2048,height:1024,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(layers).png().toFile(path.join(output,stage+'-walk.png'));
  await sharp({create:{width:2048,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:images[0],left:0,top:0},{input:images[16],left:256,top:0}]).png().toFile(path.join(output,stage+'-idle.png'));
  await sharp({create:{width:2048,height:1024,channels:4,background:'#fff8ed'}}).composite(layers).png().toFile(path.join(preview,stage+'-frame-contact.png'));
  manifest.stages[stage]={reference_height:216,stride:180*factor,cycle_seconds:1.8,sequences:{walk:{file:stage+'-walk.png',count:32,columns:8},idle:{file:stage+'-idle.png',count:2,columns:8}}};
  report.push({stage,fixed_source_scale:factor,reference_root:referenceRoot,whole_frame_playback_order:order,calibration});
 }
 fs.writeFileSync(path.join(output,'manifest.json'),JSON.stringify(manifest,null,2));
 fs.writeFileSync(path.join(preview,'frame-calibration.json'),JSON.stringify(report,null,2));
 console.log('FULL_CHARACTER_FRAME_PILOT_READY 64 complete walk cels');
}
module.exports={isolate};
if(require.main===module)main().catch(e=>{console.error(e);process.exitCode=1;});
