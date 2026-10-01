// Converts complete VARCO character sheets into aligned game frames.
// Each output cel remains a complete drawing; no body parts are separated.
const fs=require('fs');
const path=require('path');
const sharp=require('sharp');
const root=path.resolve(__dirname,'..');
const variant=process.argv.includes('--dizzy')?'dizzy-v1':'emotions-v1';
const rawDir=path.join(root,'design',variant,'raw');
const outputDir=path.join(root,'assets',variant);
const species=['rabbit','otter','squirrel','hedgehog','raccoon','fox','bear','owl','cat','puppy','hamster','panda','red_panda','lamb','koala','penguin'];
const clamp=(v,lo,hi)=>Math.max(lo,Math.min(hi,v));

function largestComponent(data,w,h){
  const seen=new Uint8Array(w*h);
  let best=[];
  for(let seed=0;seed<w*h;seed++){
    if(seen[seed]||data[seed*4+3]<38)continue;
    const queue=[seed];seen[seed]=1;
    for(let q=0;q<queue.length;q++){
      const p=queue[q],x=p%w,y=(p/w)|0;
      for(const n of [x? p-1:-1,x+1<w?p+1:-1,y?p-w:-1,y+1<h?p+w:-1]){
        if(n>=0&&!seen[n]&&data[n*4+3]>=38){seen[n]=1;queue.push(n)}
      }
    }
    if(queue.length>best.length)best=queue;
  }
  const keep=new Uint8Array(w*h);
  for(const p of best)keep[p]=1;
  let left=w,top=h,right=0,bottom=0;
  for(let p=0;p<w*h;p++){
    if(!keep[p]){data.fill(0,p*4,p*4+4);continue}
    const x=p%w,y=(p/w)|0;
    left=Math.min(left,x);right=Math.max(right,x);
    top=Math.min(top,y);bottom=Math.max(bottom,y);
  }
  if(best.length<1000)throw Error('Character component missing');
  return {left,top,width:right-left+1,height:bottom-top+1,pixels:best.length};
}

function removeCyan(data,w,h){
  const out=Buffer.alloc(w*h*4);
  for(let p=0;p<w*h;p++){
    const i=p*4,r=data[i],g=data[i+1],b=data[i+2];
    const spill=Math.min(g-r,b-r);
    let a=spill<=10?1:Math.max(0,1-(spill-10)/210);
    if(a<.025)a=0;
    out[i]=a?clamp(Math.round(r/a),0,255):0;
    out[i+1]=a?clamp(Math.round((g-(1-a)*245)/a),0,255):0;
    out[i+2]=a?clamp(Math.round((b-(1-a)*245)/a),0,255):0;
    out[i+3]=Math.round(a*255);
  }
  return out;
}

async function makeFrame(source,bound,w,h,scale){
  const width=Math.max(1,Math.round(bound.width*scale));
  const height=Math.max(1,Math.round(bound.height*scale));
  const left=Math.round(128+(bound.left-w/2)*scale);
  const top=Math.round(232-height);
  if(left<2||top<2||left+width>254||top+height>254)
    throw Error('Clipped frame '+JSON.stringify({left,top,width,height,scale,bound}));
  const cut=await sharp(source,{raw:{width:w,height:h,channels:4}}).extract(bound).resize(width,height,{kernel:'lanczos3'}).png().toBuffer();
  return sharp({create:{width:256,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:cut,left,top}]).png().toBuffer();
}

async function buildSpecies(name,stage){
  const input=path.join(rawDir,`${name}-${stage}-4.png`);
  if(!fs.existsSync(input))return null;
  const {data,info}=await sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  if(info.width!==1024||info.height!==1024)throw Error(`${name}/${stage}: expected 1024 square`);
  const w=512,h=512,frames=[];
  for(let i=0;i<4;i++){
    const x0=(i%2)*w,y0=(i>>1)*h;
    const cell=Buffer.alloc(w*h*4);
    for(let y=0;y<h;y++)data.copy(cell,y*w*4,((y+y0)*1024+x0)*4,((y+y0)*1024+x0+w)*4);
    const clean=removeCyan(cell,w,h);
    const bound=largestComponent(clean,w,h);
    frames.push({clean,bound});
  }
  const manifest=JSON.parse(fs.readFileSync(path.join(root,'assets/species-v3',name,'manifest.json')));
  const target=manifest.stages[stage].reference_height;
  const height=Math.max(...frames.map(x=>x.bound.height));
  const width=Math.max(...frames.map(x=>x.bound.width));
  const scale=Math.min(target/height,246/width);
  const pngs=[];
  for(const f of frames)pngs.push(await makeFrame(f.clean,f.bound,w,h,scale));
  const dest=path.join(outputDir,name);fs.mkdirSync(dest,{recursive:true});
  await sharp({create:{width:1024,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}})
    .composite(pngs.map((input,i)=>({input,left:i*256,top:0}))).png().toFile(path.join(dest,`${stage}.png`));
  return {name,stage,scale,target,sourceBounds:frames.map(f=>f.bound),file:`${name}/${stage}.png`};
}

async function buildToy(){
  const file=path.join(root,'design/acorn-toy-v1/acorn-source.png');
  if(!fs.existsSync(file))return;
  const {data,info}=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const clean=Buffer.alloc(info.width*info.height*4);
  for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
    const i=(y*info.width+x)*4;
    const spill=Math.min(data[i+1]-data[i],data[i+2]-data[i]);
    const a=clamp((120-spill)/70,0,1);
    const bg=(y*info.width)*4;
    for(let c=0;c<3;c++)clean[i+c]=a>0.03?clamp(Math.round((data[i+c]-(1-a)*data[bg+c])/a),0,255):0;
    clean[i+3]=a>0.03?Math.round(a*255):0;
  }
  const bound=largestComponent(clean,info.width,info.height);
  const cut=await sharp(clean,{raw:{width:info.width,height:info.height,channels:4}}).extract(bound).resize({width:256,height:256,fit:'inside',kernel:'lanczos3'}).png().toBuffer();
  const out=path.join(root,'assets/decor/acorn-wobble-v1.png');
  await sharp(cut).png().toFile(out);
  return {file:'assets/decor/acorn-wobble-v1.png',bound};
}

async function makeReviews(){
  const reviewDir=path.join(root,'design',variant,'review');
  fs.mkdirSync(reviewDir,{recursive:true});
  for(let page=0;page<4;page++){
    const layers=[];
    for(let row=0;row<8;row++){
      const name=species[page*4+(row>>1)],stage=row%2?'adult':'baby';
      const file=path.join(outputDir,name,stage+'.png');
      const label=Buffer.from(`<svg width="154" height="192"><rect width="154" height="192" fill="#e8ece9"/><text x="12" y="36" font-size="20" font-family="Arial" fill="#44392e">${name}</text><text x="12" y="68" font-size="18" font-family="Arial" fill="#736354">${stage}</text></svg>`);
      layers.push({input:label,left:0,top:row*192});
      const source=sharp(file);
      for(let col=0;col<4;col++){
        const cell=await source.clone().extract({left:col*256,top:0,width:256,height:256}).resize(192,192).png().toBuffer();
        layers.push({input:cell,left:154+col*192,top:row*192});
      }
    }
    await sharp({create:{width:922,height:1536,channels:4,background:'#fffdf8'}}).composite(layers).png().toFile(path.join(reviewDir,`page-${page+1}.png`));
  }
}

async function main(){
  fs.mkdirSync(outputDir,{recursive:true});
  const report=[];
  for(const name of species)for(const stage of ['baby','adult']){
    const result=await buildSpecies(name,stage);
    if(result)report.push(result);
  }
  const toy=variant==='emotions-v1'?await buildToy():null;
  if(report.length===32)await makeReviews();
  fs.writeFileSync(path.join(root,'design',variant,'build-report.json'),JSON.stringify({frames:report,toy},null,2));
  console.log(`Built ${report.length}/32 ${variant} full-body strips and toy: ${!!toy}`);
}
main().catch(e=>{console.error(e);process.exitCode=1});
