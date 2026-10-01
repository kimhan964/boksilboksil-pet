// Package VARCO complete-character action sheets as animation cels.
// Anatomical parts are never detected, separated, or recomposed.
const fs=require('fs'),path=require('path'),sharp=require('sharp');
const root=path.resolve(__dirname,'..');
const allSpecies=['otter','squirrel','hedgehog','raccoon','fox','bear','owl','cat','puppy','hamster','panda','red_panda','lamb','koala','penguin'];
const speciesArg=process.argv.find(value=>value.startsWith('--species='));
const species=speciesArg?speciesArg.slice(10).split(','):allSpecies;
const actions=['idle','walk','pet','eat','drink','sleep','carry','jump','look','sniff','wave','groom','stretch','rub','toy','rest'];
const pilot=process.argv.includes('--pilot');
const v3=process.argv.includes('--v3');
const frameCount=v3?16:8,gridColumns=4,gridRows=v3?4:2;
const selectedActions=pilot?['idle','walk','pet']:actions;
const durations={idle:4.8,walk:1.0,pet:2.4,eat:3.2,drink:3.2,sleep:3.6,carry:1.4,jump:.8,look:2.8,sniff:2.4,wave:2.4,groom:2.8,stretch:2.8,rub:2.8,toy:3.2,rest:3.6};
const versionRoot=path.join(root,'design',v3?'all-species-v3':'all-species-v2');
const output=pilot?path.join(versionRoot,'pilot-runtime'):path.join(root,'assets',v3?'species-v3':'species-v2');
const clamp=(v,a,b)=>Math.min(b,Math.max(a,v));

function components(mask,w,h){
 const seen=new Uint8Array(w*h),list=[];
 for(let seed=0;seed<mask.length;seed++){
  if(!mask[seed]||seen[seed])continue;
  const queue=[seed];seen[seed]=1;let n=0,x0=w,y0=h,x1=0,y1=0;
  for(let q=0;q<queue.length;q++){
   const p=queue[q],x=p%w,y=Math.floor(p/w);n++;x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);
   for(const next of [x>0?p-1:-1,x+1<w?p+1:-1,y>0?p-w:-1,y+1<h?p+w:-1])
    if(next>=0&&mask[next]&&!seen[next]){seen[next]=1;queue.push(next)}
  }
  list.push({seed,n,x0,y0,x1,y1});
 }
 return list;
}

function inspect(raw,w,h){
 let x0=w,y0=h,x1=-1,y1=-1;
 for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(raw[(y*w+x)*4+3]>24){x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y)}
 if(x1<0)throw Error('Empty generated frame');
 let fx0=w,fx1=-1;
 for(let y=Math.max(y0,Math.floor(y1-(y1-y0+1)*.13));y<=y1;y++)for(let x=x0;x<=x1;x++)if(raw[(y*w+x)*4+3]>90){fx0=Math.min(fx0,x);fx1=Math.max(fx1,x)}
 if(fx1<0){fx0=x0;fx1=x1}
 return {bound:{left:x0,top:y0,width:x1-x0+1,height:y1-y0+1},root:[(fx0+fx1)/2,y1+1]};
}

function rgbToLab(r,g,b){
 let R=r/255,G=g/255,B=b/255;
 R=R<=.04045?R/12.92:Math.pow((R+.055)/1.055,2.4);G=G<=.04045?G/12.92:Math.pow((G+.055)/1.055,2.4);B=B<=.04045?B/12.92:Math.pow((B+.055)/1.055,2.4);
 let x=(R*.4124+G*.3576+B*.1805)/.95047,y=(R*.2126+G*.7152+B*.0722),z=(R*.0193+G*.1192+B*.9505)/1.08883;
 const f=v=>v>.008856?Math.cbrt(v):7.787*v+16/116;x=f(x);y=f(y);z=f(z);
 return [116*y-16,500*(x-y),200*(y-z)];
}
function labToRgb(L,a,b){
 let y=(L+16)/116,x=a/500+y,z=y-b/200;
 const f=v=>Math.pow(v,3)>.008856?Math.pow(v,3):(v-16/116)/7.787;x=.95047*f(x);y=f(y);z=1.08883*f(z);
 let R=x*3.2406-y*1.5372-z*.4986,G=-x*.9689+y*1.8758+z*.0415,B=x*.0557-y*.204+z*1.057;
 const g=v=>255*(v<=.0031308?12.92*v:1.055*Math.pow(Math.max(0,v),1/2.4)-.055);
 return [clamp(Math.round(g(R)),0,255),clamp(Math.round(g(G)),0,255),clamp(Math.round(g(B)),0,255)];
}
const labDistance=(a,b)=>(a[0]-b[0])**2+(a[1]-b[1])**2+(a[2]-b[2])**2;
function palette(frame,count=12){
 const pixels=[];
 for(let p=0;p<frame.w*frame.h;p+=3)if(frame.raw[p*4+3]>180)pixels.push(rgbToLab(frame.raw[p*4],frame.raw[p*4+1],frame.raw[p*4+2]));
 if(!pixels.length)throw Error('Cannot build palette from empty frame');
 const centers=[pixels[Math.floor(pixels.length/2)].slice()];
 while(centers.length<count){
  let farthest=pixels[0],best=-1;
  for(const pixel of pixels){const distance=Math.min(...centers.map(center=>labDistance(pixel,center)));if(distance>best){best=distance;farthest=pixel}}
  centers.push(farthest.slice());
 }
 let weights=[];
 for(let iteration=0;iteration<12;iteration++){
  const sums=centers.map(()=>[0,0,0,0]);
  for(const pixel of pixels){
   let nearest=0,best=Infinity;for(let i=0;i<centers.length;i++){const distance=labDistance(pixel,centers[i]);if(distance<best){best=distance;nearest=i}}
   sums[nearest][0]+=pixel[0];sums[nearest][1]+=pixel[1];sums[nearest][2]+=pixel[2];sums[nearest][3]++;
  }
  weights=sums.map(sum=>sum[3]/pixels.length);
  for(let i=0;i<centers.length;i++)if(sums[i][3])centers[i]=[sums[i][0]/sums[i][3],sums[i][1]/sums[i][3],sums[i][2]/sums[i][3]];
 }
 return centers.map((lab,i)=>({lab,weight:weights[i]}));
}
function paletteTransfer(frame,target){
 const source=palette(frame);
 const pairs=source.map(entry=>{
  let choice=target[0],best=Infinity;
  for(const candidate of target){
   const weightPenalty=Math.abs(Math.log((entry.weight+.01)/(candidate.weight+.01)))*45;
   const distance=labDistance(entry.lab,candidate.lab)+weightPenalty;
   if(distance<best){best=distance;choice=candidate}
  }
  return {source:entry.lab,target:choice.lab};
 });
 return pairs;
}
function recolor(raw,transfer){
 const result=Buffer.from(raw);
 for(let p=0;p<result.length/4;p++){
  const at=p*4;if(result[at+3]<20)continue;
  const lab=rgbToLab(result[at],result[at+1],result[at+2]);
  if(lab[0]<16)continue;
  let pair=transfer[0],best=Infinity;for(const candidate of transfer){const distance=labDistance(lab,candidate.source);if(distance<best){best=distance;pair=candidate}}
  const mapped=[lab[0]+(pair.target[0]-pair.source[0])*.92,lab[1]+pair.target[1]-pair.source[1],lab[2]+pair.target[2]-pair.source[2]];
  const rgb=labToRgb(mapped[0],mapped[1],mapped[2]);result[at]=rgb[0];result[at+1]=rgb[1];result[at+2]=rgb[2];
 }
 return result;
}

async function readFrames(id,stage,action){
 const file=pilot?path.join(versionRoot,'pilot-sources',id,stage,action+'.png'):path.join(versionRoot,'production-sources',id,stage,action+'.png');
 const {data,info}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const w=info.width/gridColumns,h=info.height/gridRows;
 if(!Number.isInteger(w)||!Number.isInteger(h))throw Error('Uneven '+gridColumns+'x'+gridRows+' grid: '+file);
 const result=[];
 for(let f=0;f<frameCount;f++){
  const raw=Buffer.alloc(w*h*4);
  for(let y=0;y<h;y++)for(let x=0;x<w;x++){
   const s=((Math.floor(f/gridColumns)*h+y)*info.width+(f%gridColumns)*w+x)*4,d=(y*w+x)*4;
   const r=data[s],g=data[s+1],b=data[s+2],spill=Math.min(g-r,b-r);
   let a=spill<=10?1:Math.max(0,1-(spill-10)/210);if(a<.025)a=0;
   raw[d]=a?clamp(Math.round(r/a),0,255):0;
   raw[d+1]=a?clamp(Math.round((g-(1-a)*245)/a),0,255):0;
   raw[d+2]=a?clamp(Math.round((b-(1-a)*245)/a),0,255):0;
   raw[d+3]=Math.round(a*255);
  }
  // Keep the largest connected complete character and discard detached motion marks.
  const mask=new Uint8Array(w*h);for(let p=0;p<mask.length;p++)mask[p]=raw[p*4+3]>0?1:0;
  const islands=components(mask,w,h).sort((a,b)=>b.n-a.n);
  if(!islands.length){result.push(null);continue}
  const keep=new Uint8Array(w*h),queue=[islands[0].seed];keep[queue[0]]=1;
  for(let q=0;q<queue.length;q++){
   const p=queue[q],x=p%w,y=Math.floor(p/w);
   for(const next of [x>0?p-1:-1,x+1<w?p+1:-1,y>0?p-w:-1,y+1<h?p+w:-1])if(next>=0&&mask[next]&&!keep[next]){keep[next]=1;queue.push(next)}
  }
  for(let p=0;p<keep.length;p++)if(!keep[p])raw.fill(0,p*4,p*4+4);
  result.push({raw,w,h,...inspect(raw,w,h)});
 }
 for(let f=0;f<frameCount;f++)if(result[f]===null){
  if(!pilot)throw Error('Missing complete character: '+id+'/'+stage+'/'+action+' frame '+f);
  let replacement=-1;
  for(let distance=1;distance<frameCount&&replacement<0;distance++)for(const candidate of [f-distance,f+distance])if(candidate>=0&&candidate<frameCount&&result[candidate]!==null){replacement=candidate;break}
  if(replacement<0)throw Error('No subject in any frame: '+file);
  result[f]=result[replacement];
  console.log('REUSED '+id+'/'+stage+'/'+action+' frame '+f+' <- '+replacement);
 }
 return result;
}

async function readMaster(id,stage){
 const file=path.join(versionRoot,'masters',id,stage+'.png');
 const loaded=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true}),data=loaded.data,w=loaded.info.width,h=loaded.info.height,raw=Buffer.alloc(w*h*4);
 for(let p=0;p<w*h;p++){const at=p*4,r=data[at],g=data[at+1],b=data[at+2],spill=Math.min(g-r,b-r);let a=spill<=10?1:Math.max(0,1-(spill-10)/210);if(a<.025)a=0;raw[at]=a?r:0;raw[at+1]=a?g:0;raw[at+2]=a?b:0;raw[at+3]=Math.round(a*255)}
 return {raw,w,h,...inspect(raw,w,h)};
}

function safeFactor(frames,desired){
 let factor=desired;
 for(const frame of frames){
  const b=frame.bound,r=frame.root;
  const left=r[0]-b.left,right=b.left+b.width-r[0],above=r[1]-b.top,below=b.top+b.height-r[1];
  // Use the available 256px cell while retaining a small alpha margin. A
  // conservative 6px side margin made wide walk contacts visibly shrink.
  factor=Math.min(factor,126/Math.max(1,left),126/Math.max(1,right),230/Math.max(1,above),22/Math.max(1,below));
 }
 return factor;
}

async function renderFrame(src,factor,lift,transfer){
 const b=src.bound,sw=Math.max(1,Math.round(b.width*factor)),sh=Math.max(1,Math.round(b.height*factor));
 const left=Math.round(128+(b.left-src.root[0])*factor),top=Math.round(232+(b.top-src.root[1])*factor-lift);
 if(left<0||top<0||left+sw>256||top+sh>256)throw Error('Clipped frame '+[left,top,sw,sh]);
 const colored=transfer?recolor(src.raw,transfer):src.raw;
 const cut=await sharp(colored,{raw:{width:src.w,height:src.h,channels:4}}).extract(b).resize(sw,sh,{kernel:'lanczos3'}).png().toBuffer();
 return sharp({create:{width:256,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:cut,left,top}]).png().toBuffer();
}

async function buildSpecies(id){
 const outDir=path.join(output,id);fs.mkdirSync(outDir,{recursive:true});
 const reviewDir=pilot?path.join(versionRoot,'pilot-review',id):path.join(versionRoot,'production-review',id);fs.mkdirSync(reviewDir,{recursive:true});
 const manifest={version:v3?2:1,species:id,method:'VARCO generated complete-character cels',canvas:[256,256],root:[128,232],stages:{}};
 const calibration={species:id,rule:'One scale per '+frameCount+'-frame action; complete cels only.',sequences:[]};
 const targetPalette=palette(await readMaster(id,'baby'));
 for(const stage of ['baby','adult']){
  const byAction={};
  for(const action of selectedActions)byAction[action]=await readFrames(id,stage,action);
  const idle=byAction.idle,safeByAction={};
  // First find the largest safe neutral height each complete action can use.
  // The smallest achievable height becomes the stage target; then each
  // action gets one fixed scale that reaches that same target. This corrects
  // both generated camera-distance drift and wide tail/contact poses.
  for(const action of selectedActions){const frames=byAction[action];safeByAction[action]=safeFactor(frames,200/frames[0].bound.height)}
  const referenceHeight=Math.floor(Math.min(...selectedActions.map(action=>byAction[action][0].bound.height*safeByAction[action])));
  const stageData={reference_height:referenceHeight,master:'design/'+(v3?'all-species-v3':'all-species-v2')+'/masters/'+id+'/'+stage+'.png',sequences:{}};
  let neutralImage=null,neutralAnchor=null;
  const review=[];
  for(const action of selectedActions){
   const frames=byAction[action];
   const factor=referenceHeight/frames[0].bound.height;
   const transfer=paletteTransfer(frames[0],targetPalette);
   const images=[],anchors=[];
   for(let f=0;f<frameCount;f++){
    const src=frames[f],b=src.bound;
    const progress=f/(frameCount-1);
    // V3 poses author vertical travel inside each complete raster cell. Adding
    // another packaging lift would double the jump and can clip the ears.
    const lift=v3?0:(action==='jump'?Math.max(0,Math.sin(progress*Math.PI))*19:action==='carry'?Math.max(0,Math.sin(progress*Math.PI))*5:0);
    images.push(await renderFrame(src,factor,lift,transfer));
    const bird=id==='owl'||id==='penguin',mouthSource=[b.left+b.width*(bird?.62:.70),b.top+b.height*(bird?.40:.41)];
    const mouth=[128+(mouthSource[0]-src.root[0])*factor,232+(mouthSource[1]-src.root[1])*factor-lift];
    const handArc=72-Math.max(0,Math.sin(progress*Math.PI))*30;
    const hand=[mouth[0]-10*factor,mouth[1]+handArc*factor];
    anchors.push({mouth,hand,source_root:src.root,source_bounds:[b.left,b.top,b.width,b.height],scale:factor});
   }
   if(action==='idle'){neutralImage=images[0];neutralAnchor=anchors[0]}
   if(action!=='walk')for(const index of [0,frameCount-1]){images[index]=neutralImage;anchors[index]={...neutralAnchor,source_action:'idle',source_frame:0}}
   const filename=stage+'-'+action+'.png';
   await sharp({create:{width:frameCount*256,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(images.map((input,i)=>({input,left:i*256,top:0}))).png().toFile(path.join(outDir,filename));
   stageData.sequences[action]={file:filename,count:frameCount,columns:frameCount,duration:durations[action],anchors};
   calibration.sequences.push({stage,action,scale:factor,neutral_height:frames[0].bound.height,output_neutral_height:referenceHeight,relative_to_idle:factor/(referenceHeight/idle[0].bound.height)});
   review.push({action,images});
  }
  manifest.stages[stage]=stageData;
  for(let page=0;page<Math.ceil(review.length/4);page++){
   const layers=[];
   for(let row=0;row<4;row++){
    const item=review[page*4+row];if(!item)continue;
    const cell=v3?128:192,rowHeight=cell+28,width=frameCount*cell;
    const label=Buffer.from(`<svg width="${width}" height="28"><rect width="${width}" height="28" fill="#e8ece9"/><text x="12" y="20" font-size="16" font-family="Arial" fill="#333">${id} / ${stage} / ${item.action}</text></svg>`);
    layers.push({input:label,left:0,top:row*rowHeight});
    for(let f=0;f<frameCount;f++)layers.push({input:await sharp(item.images[f]).resize(cell,cell).png().toBuffer(),left:f*cell,top:row*rowHeight+28});
   }
   const cell=v3?128:192,rowHeight=cell+28;
   await sharp({create:{width:frameCount*cell,height:rowHeight*4,channels:4,background:'#f4f2ef'}}).composite(layers).png().toFile(path.join(reviewDir,stage+'-'+page+'.png'));
  }
 }
 fs.writeFileSync(path.join(outDir,'manifest.json'),JSON.stringify(manifest,null,2));
 fs.writeFileSync(path.join(reviewDir,'frame-calibration.json'),JSON.stringify(calibration,null,2));
 console.log('BUILT '+id);
}

async function main(){fs.mkdirSync(output,{recursive:true});for(const id of species)await buildSpecies(id);console.log('ALL_SPECIES_BUILT '+species.length)}
module.exports={components,inspect,palette,paletteTransfer,renderFrame,safeFactor,readMaster};
if(require.main===module) main().catch(error=>{console.error(error);process.exit(1)});
