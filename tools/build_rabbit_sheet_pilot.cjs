// Extract complete sequential drawings from one authored walk sheet.
// No anatomy, pose reordering, mesh deformation, or duplicated frames.
const fs=require('fs'),path=require('path'),sharp=require('sharp');
const B=require('./build_all_species_frames.cjs');
const root=path.resolve(__dirname,'..'),work=path.join(root,'design/rabbit-frame-pilot-v3'),out=path.join(root,'assets/rabbit-frame-pilot-v3');
async function readCel(file,rectangle){
 const {data,info}=await sharp(file).extract(rectangle).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const raw=Buffer.from(data),mask=new Uint8Array(info.width*info.height);
 for(let p=0;p<mask.length;p++){
  const a=p*4,spill=Math.min(data[a+1]-data[a],data[a+2]-data[a]);
  const clearCyan=data[a]<80&&data[a+1]>150&&data[a+2]>150;
  const alpha=clearCyan?0:Math.max(0,Math.min(1,1-(spill-10)/220));
  raw[a+3]=alpha<.025?0:Math.round(alpha*255);mask[p]=raw[a+3]>30;
  if(alpha>.025){raw[a]=Math.min(255,Math.round(data[a]/alpha));raw[a+1]=Math.min(255,Math.max(0,Math.round((data[a+1]-(1-alpha)*255)/alpha)));raw[a+2]=Math.min(255,Math.max(0,Math.round((data[a+2]-(1-alpha)*255)/alpha)));}
 }
 const regions=B.components(mask,info.width,info.height).sort((a,b)=>b.n-a.n);
 if(!regions.length||regions[0].n<1500)throw Error('Missing full character');
 if(regions[1]?.n>regions[0].n*.08)throw Error('Extra or disconnected character');
 const box=B.inspect(raw,info.width,info.height).bound;
 if(box.left<3||box.top<3||box.left+box.width>info.width-3||box.top+box.height>info.height-3)throw Error('Clipped frame');
 const upper=[],upperY=[];
 for(let y=box.top;y<box.top+box.height*.62;y++)for(let x=box.left;x<box.left+box.width;x++){
  const p=(Math.floor(y)*info.width+x)*4;if(raw[p+3]>180){upper.push(x);upperY.push(y);}
 }
 return {raw,w:info.width,h:info.height,box,headX:upper.reduce((a,b)=>a+b,0)/upper.length,headY:upperY.reduce((a,b)=>a+b,0)/upperY.length};
}
async function build(stage){
 const file=path.join(work,stage+'-walk-sheet-source.png'),meta=await sharp(file).metadata();
 const width=meta.width/8,height=meta.height/4;
 if(!Number.isInteger(width)||!Number.isInteger(height))throw Error('Grid dimensions are not integral');
 const cels=[];
 for(let i=0;i<32;i++)cels.push(await readCel(file,{left:i%8*width,top:Math.floor(i/8)*height,width,height}));
 const heights=cels.map(c=>c.box.height).sort((a,b)=>a-b),factor=216/heights[16],frames=[],records=[];
 const referenceHeadY=232-cels[0].box.height*factor+(cels[0].headY-cels[0].box.top)*factor;
 for(let i=0;i<32;i++){
  const c=cels[i],b=c.box,scaledWidth=Math.round(b.width*factor),scaledHeight=Math.round(b.height*factor);
  // Correct only whole-image camera translation; never transform anatomy.
  const left=Math.round(136+(b.left-c.headX)*factor),top=Math.round(referenceHeadY-(c.headY-b.top)*factor);
  if(left<3||top<3||left+scaledWidth>253)throw Error('Fixed scale cannot fit full character');
  const cut=await sharp(c.raw,{raw:{width:c.w,height:c.h,channels:4}}).extract(b).resize(scaledWidth,scaledHeight).png().toBuffer();
  const frame=await sharp({create:{width:256,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:cut,left,top}]).png().toBuffer();
  frames.push(frame);records.push({index:i,sourceBounds:b,sourceHeadX:c.headX,sourceHeadY:c.headY,fixedScale:factor,packedGround:top+scaledHeight});
 }
 fs.mkdirSync(out,{recursive:true});
 const layers=frames.map((input,i)=>({input,left:i%8*256,top:Math.floor(i/8)*256}));
 await sharp({create:{width:2048,height:1024,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(layers).png().toFile(path.join(out,stage+'-walk.png'));
 await sharp({create:{width:2048,height:1024,channels:4,background:'#fff8ed'}}).composite(layers).png().toFile(path.join(work,stage+'-frame-contact.png'));
 await sharp({create:{width:2048,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:frames[0],left:0,top:0},{input:frames[16],left:256,top:0}]).png().toFile(path.join(out,stage+'-idle.png'));
 fs.writeFileSync(path.join(work,stage+'-calibration.json'),JSON.stringify({method:'whole-character cels in authored time order; shared scale and two-axis camera registration',records},null,2));
 return {reference_height:216,stride:80,cycle_seconds:2.4,sequences:{walk:{file:stage+'-walk.png',count:32,columns:8},idle:{file:stage+'-idle.png',count:2,columns:8}}};
}
async function main(){
 const stage=process.argv.find(s=>s.startsWith('--stage='))?.slice(8)||'adult';
 const spec=await build(stage);const file=path.join(out,'manifest.json');
 const manifest=fs.existsSync(file)?JSON.parse(fs.readFileSync(file,'utf8')):{version:3,method:'complete sequential drawings from one generated sheet',canvas:[256,256],root:[128,232],stages:{}};
 manifest.method='32 whole-character image edits from one fixed identity; pose and color review; no rig, parts, deformation or dissolve';
 manifest.stages[stage]=spec;fs.writeFileSync(file,JSON.stringify(manifest,null,2));console.log(stage+' 32 chronological whole cels ready for visual review');
}
main().catch(e=>{console.error(e);process.exitCode=1});
