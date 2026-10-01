// Interleave complete VARCO in-between drawings with the authored walk cels.
// Each new cel stays a whole character; no anatomical pieces are separated.
const fs=require('fs');
const path=require('path');
const sharp=require('sharp');
const root=path.resolve(__dirname,'..');
const ids=['rabbit','otter','squirrel','hedgehog','raccoon','fox','bear','owl','cat','puppy','hamster','panda','red_panda','lamb','koala','penguin'];
const chosen=process.argv.find(x=>x.startsWith('--species='));
const species=chosen?chosen.slice(10).split(','):ids;
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));

function isolate(raw,w,h){
  const out=Buffer.alloc(w*h*4),mask=new Uint8Array(w*h);
  for(let p=0;p<w*h;p++){
    const k=p*4,r=raw[k],g=raw[k+1],b=raw[k+2];
    const spill=Math.min(g-r,b-r);
    let alpha=spill<=10?1:Math.max(0,1-(spill-10)/210);
    if(alpha<.025)alpha=0;
    out[k]=alpha?clamp(Math.round(r/alpha),0,255):0;
    out[k+1]=alpha?clamp(Math.round((g-(1-alpha)*245)/alpha),0,255):0;
    out[k+2]=alpha?clamp(Math.round((b-(1-alpha)*245)/alpha),0,255):0;
    out[k+3]=Math.round(alpha*255);
    mask[p]=out[k+3]>=38?1:0;
  }
  const seen=new Uint8Array(w*h);
  let best=[];
  for(let seed=0;seed<mask.length;seed++){
    if(!mask[seed]||seen[seed])continue;
    const queue=[seed];seen[seed]=1;
    for(let q=0;q<queue.length;q++){
      const p=queue[q],x=p%w,y=(p/w)|0;
      for(const n of [x?p-1:-1,x+1<w?p+1:-1,y?p-w:-1,y+1<h?p+w:-1])
        if(n>=0&&mask[n]&&!seen[n]){seen[n]=1;queue.push(n)}
    }
    if(queue.length>best.length)best=queue;
  }
  if(best.length<1000)throw Error('Missing complete character');
  const keep=new Uint8Array(w*h);
  for(const p of best)keep[p]=1;
  let left=w,top=h,right=0,bottom=0;
  for(let p=0;p<mask.length;p++){
    const k=p*4;
    if(!keep[p]){out.fill(0,k,k+4);continue}
    const x=p%w,y=(p/w)|0;
    left=Math.min(left,x);right=Math.max(right,x);
    top=Math.min(top,y);bottom=Math.max(bottom,y);
  }
  let footLeft=w,footRight=0;
  const footTop=Math.max(top,Math.floor(bottom-(bottom-top+1)*.13));
  for(let y=footTop;y<=bottom;y++)for(let x=left;x<=right;x++)
    if(out[(y*w+x)*4+3]>90){footLeft=Math.min(footLeft,x);footRight=Math.max(footRight,x)}
  const rootX=footLeft<=footRight?(footLeft+footRight)/2:(left+right)/2;
  return {raw:out,bound:{left,top,width:right-left+1,height:bottom-top+1},rootX,pixels:best.length};
}

async function build(name,stage){
  const source=path.join(root,'design','walk-v4','raw',`${name}-${stage}-inbetween.png`);
  if(!fs.existsSync(source))return null;
  const loaded=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  if(loaded.info.width!==1024||loaded.info.height!==1024)throw Error(`${name}/${stage}: expected 1024 square`);
  const frames=[];
  for(let i=0;i<16;i++){
    const cell=Buffer.alloc(256*256*4),x0=(i%4)*256,y0=(i>>2)*256;
    for(let y=0;y<256;y++)loaded.data.copy(cell,y*1024,(y+y0)*1024*4+x0*4,(y+y0)*1024*4+(x0+256)*4);
    frames.push(isolate(cell,256,256));
  }
  const manifest=JSON.parse(fs.readFileSync(path.join(root,'assets','species-v3',name,'manifest.json')));
  const target=manifest.stages[stage].reference_height;
  const factor=Math.min(target/Math.max(...frames.map(f=>f.bound.height)),248/Math.max(...frames.map(f=>f.bound.width)));
  const original=path.join(root,'assets','species-v3',name,`${stage}-walk.png`);
  const old=sharp(original);
  const cels=[];
  const heights=[];
  for(let i=0;i<16;i++){
    cels.push(await old.clone().extract({left:i*256,top:0,width:256,height:256}).png().toBuffer());
    const frame=frames[i],b=frame.bound,w=Math.round(b.width*factor),h=Math.round(b.height*factor);
    const outputLeft=Math.round(128+(b.left-frame.rootX)*factor);
    const top=232-h;
    if(outputLeft<2||top<2||outputLeft+w>254||top+h>254)throw Error(`${name}/${stage}/${i}: clipped`);
    const cut=await sharp(frame.raw,{raw:{width:256,height:256,channels:4}}).extract(b).resize(w,h,{kernel:'lanczos3'}).png().toBuffer();
    const cel=await sharp({create:{width:256,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:cut,left:outputLeft,top}]).png().toBuffer();
    cels.push(cel);heights.push(h);
  }
  const dir=path.join(root,'assets','walk-v4',name);fs.mkdirSync(dir,{recursive:true});
  const file=path.join(dir,`${stage}.png`);
  await sharp({create:{width:8192,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(cels.map((input,i)=>({input,left:i*256,top:0}))).png().toFile(file);
  const reviewDir=path.join(root,'design','walk-v4','review');fs.mkdirSync(reviewDir,{recursive:true});
  const reviewCels=await Promise.all(cels.map(c=>sharp(c).resize(128,128).png().toBuffer()));
  await sharp({create:{width:1024,height:512,channels:4,background:'#fffdf8'}})
    .composite(reviewCels.map((input,i)=>({input,left:(i%8)*128,top:Math.floor(i/8)*128})))
    .png().toFile(path.join(reviewDir,`${name}-${stage}.png`));
  return {name,stage,frames:32,referenceHeight:target,newFrameHeights:heights,minPixels:Math.min(...frames.map(f=>f.pixels)),file:path.relative(root,file)};
}

(async()=>{
  const report=[];
  for(const name of species)for(const stage of ['baby','adult']){
    const result=await build(name,stage);
    if(result)report.push(result);
  }
  const dir=path.join(root,'design','walk-v4');fs.mkdirSync(dir,{recursive:true});
  if(report.length===32){
    const reviewDir=path.join(dir,'review');
    for(let page=0;page<4;page++){
      const layers=[];
      for(let row=0;row<8;row++){
        const name=ids[page*4+(row>>1)],stage=row%2?'adult':'baby';
        const label=Buffer.from(`<svg width="128" height="128"><rect width="128" height="128" fill="#e8ece9"/><text x="8" y="28" font-size="18" font-family="Arial" fill="#44392e">${name}</text><text x="8" y="50" font-size="16" font-family="Arial" fill="#736354">${stage}</text></svg>`);
        layers.push({input:label,left:0,top:row*128});
        const file=path.join(root,'assets','walk-v4',name,stage+'.png');
        const strip=sharp(file);
        for(let col=0;col<8;col++){
          const frame=await strip.clone().extract({left:(col*4+1)*256,top:0,width:256,height:256}).resize(128,128).png().toBuffer();
          layers.push({input:frame,left:128+col*128,top:row*128});
        }
      }
      await sharp({create:{width:1152,height:1024,channels:4,background:'#fffdf8'}})
        .composite(layers).png().toFile(path.join(reviewDir,`all-${page+1}.png`));
    }
  }
  fs.writeFileSync(path.join(dir,'build-report.json'),JSON.stringify(report,null,2));
  console.log(`WALK_V4_BUILT=${report.length}/32`);
})().catch(e=>{console.error(e);process.exitCode=1});
