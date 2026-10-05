// Whole-cel packing. Preserve authored body movement; never register the head.
const fs=require('fs'),path=require('path'),sharp=require('sharp');
const B=require('./build_all_species_frames.cjs');
const root=path.resolve(__dirname,'..');
async function main(){
 const source=process.argv[2];
 if(!source)throw Error('Provide a source sprite sheet');
 const columns=Number(process.argv[3]||4),rows=Number(process.argv[4]||2);
 const output=path.resolve(process.argv[5]||path.join(root,'design/rabbit-frame-pilot-v4/packed-keys'));
 const meta=await sharp(source).metadata(),w=meta.width/columns,h=meta.height/rows;
 if(!Number.isInteger(w)||!Number.isInteger(h))throw Error('Nonintegral cells');
 const cells=[];
 for(let i=0;i<columns*rows;i++){
  const raw=await sharp(source).extract({left:i%columns*w,top:Math.floor(i/columns)*h,width:w,height:h}).ensureAlpha().raw().toBuffer();
  for(let p=0;p<raw.length;p+=4){
   const r=raw[p],g=raw[p+1],b=raw[p+2],spill=Math.min(g-r,b-r);
   const alpha=r<80&&g>150&&b>150?0:Math.max(0,Math.min(1,1-(spill-10)/220));
   raw[p+3]=alpha<.025?0:Math.round(alpha*255);
   if(alpha>.025){raw[p]=Math.min(255,Math.round(r/alpha));raw[p+1]=Math.min(255,Math.max(0,Math.round((g-(1-alpha)*255)/alpha)));raw[p+2]=Math.min(255,Math.max(0,Math.round((b-(1-alpha)*255)/alpha)));}
  }
  const box=B.inspect(raw,w,h).bound;
  if(box.width<40||box.height<80||box.left<3||box.top<3||box.left+box.width>w-3||box.top+box.height>h-3)throw Error('Empty or clipped source '+i);
  cells.push({raw,box});
 }
 const heights=cells.map(c=>c.box.height).sort((a,b)=>a-b);
 // Fit the complete pose envelope once. Median height clips an extended pose.
 const extent=Math.max(...cells.flatMap(c=>[Math.abs(c.box.left-w/2),Math.abs(c.box.left+c.box.width-w/2)]));
 const fixedScale=process.argv[6]===undefined?null:Number(process.argv[6]);
 if(fixedScale!==null&&(!Number.isFinite(fixedScale)||fixedScale<=0))throw Error('Invalid fixed whole-sequence scale');
 const scale=fixedScale===null?Math.min(216/heights[heights.length-1],124/extent):fixedScale;
 const frames=[],records=[];
 fs.mkdirSync(output,{recursive:true});
 for(let i=0;i<cells.length;i++){
  const {raw,box:b}=cells[i],width=Math.round(b.width*scale),height=Math.round(b.height*scale);
  // Camera center is the cell center. Only the contact floor is registered.
  // Body compression/rise and head/ear follow-through stay in the illustration.
  const left=Math.round(128+(b.left-w/2)*scale),top=232-height;
  if(left<3||top<3||left+width>253)throw Error('Fixed scale cannot fit '+i);
  const cel=await sharp(raw,{raw:{width:w,height:h,channels:4}}).extract(b).resize(width,height).png().toBuffer();
  const frame=await sharp({create:{width:256,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:cel,left,top}]).png().toBuffer();
  fs.writeFileSync(path.join(output,String(i).padStart(2,'0')+'.png'),frame);
  frames.push(frame);records.push({index:i,sourceBounds:b,scale,left,top,ground:232});
 }
 const layers=frames.map((input,i)=>({input,left:i%8*256,top:Math.floor(i/8)*256}));
 for(const review of [false,true])await sharp({create:{width:2048,height:Math.ceil(frames.length/8)*256,channels:4,background:review?'#fff8ed':{r:0,g:0,b:0,alpha:0}}}).composite(layers).png().toFile(path.join(output,review?'contact.png':'atlas.png'));
 fs.writeFileSync(path.join(output,'registration.json'),JSON.stringify({method:'shared scale, fixed camera center, contact floor registration; no head/body registration',source,records},null,2));
 console.log(JSON.stringify({frames:frames.length,scale,output}));
}
main().catch(e=>{console.error(e);process.exitCode=1});
