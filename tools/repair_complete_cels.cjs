// Recover complete character illustrations when generated sheets do not obey
// the requested grid. Never split a character into anatomical pieces.
const fs=require('fs'),path=require('path'),sharp=require('sharp');
const B=require('./build_all_species_frames.cjs');
const root=path.resolve(__dirname,'..'),report=[];
const output=path.join(root,'design/gameplay-audit-2026-10-02');
const apply=process.argv.includes('--apply');
async function main(){
 for(const id of fs.readdirSync(path.join(root,'assets/species-v3'))){
  const dir=path.join(root,'assets/species-v3',id),manifest=JSON.parse(fs.readFileSync(path.join(dir,'manifest.json')));
  for(const stage of ['baby','adult'])for(const [action,spec] of Object.entries(manifest.stages[stage].sequences)){
   const {data,info}=await sharp(path.join(dir,spec.file)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
   const suspect=[];
   for(let f=0;f<spec.count;f++){
    let x0=256,y0=256,x1=-1,y1=-1;
    const alpha=(x,y)=>data[((Math.floor(f/spec.columns)*256+y)*info.width+f%spec.columns*256+x)*4+3]>90;
    for(let y=0;y<256;y++)for(let x=0;x<256;x++)if(alpha(x,y)){x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y)}
    let top=0,bottom=0,left=0,right=0;
    for(let x=x0;x<=x1;x++){top+=alpha(x,y0);bottom+=alpha(x,y1)}
    for(let y=y0;y<=y1;y++){left+=alpha(x0,y);right+=alpha(x1,y)}
    if(Math.max(top/(x1-x0+1),bottom/(x1-x0+1),left/(y1-y0+1),right/(y1-y0+1))>.60) suspect.push(f);
   }
   if(!suspect.length)continue;
   const source=path.join(root,'design/all-species-v3/production-sources',id,stage,action+'.png');
   const loaded=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true}),w=loaded.info.width,h=loaded.info.height;
   const raw=Buffer.alloc(w*h*4),mask=new Uint8Array(w*h);
   for(let p=0;p<w*h;p++){
    const at=p*4,r=loaded.data[at],g=loaded.data[at+1],b=loaded.data[at+2],spill=Math.min(g-r,b-r);
    let a=spill<=10?1:Math.max(0,1-(spill-10)/210);if(a<.025)a=0;
    raw[at]=a?Math.min(255,Math.round(r/a)):0;
    raw[at+1]=a?Math.max(0,Math.min(255,Math.round((g-(1-a)*245)/a))):0;
    raw[at+2]=a?Math.max(0,Math.min(255,Math.round((b-(1-a)*245)/a))):0;
    raw[at+3]=Math.round(a*255);mask[p]=a>0?1:0;
   }
   const islands=B.components(mask,w,h).sort((a,b)=>b.n-a.n);
   const chars=islands.filter(c=>c.n>islands[0].n*.30 && c.y1-c.y0>45 && c.x1-c.x0>45);
   const heights=chars.map(c=>c.y1-c.y0).sort((a,b)=>a-b),rowTolerance=heights[Math.floor(heights.length/2)]*.55;
   chars.sort((a,b)=>(a.y0+a.y1)-(b.y0+b.y1));
   const rows=[];
   for(const c of chars){const cy=(c.y0+c.y1)/2;let row=rows.find(r=>Math.abs(r.y-cy)<rowTolerance);if(!row){row={y:cy,chars:[]};rows.push(row)}row.chars.push(c)}
   const ordered=rows.sort((a,b)=>a.y-b.y).flatMap(r=>r.chars.sort((a,b)=>a.x0-b.x0));
   const frames=ordered.map(c=>{
    const cw=c.x1-c.x0+1,ch=c.y1-c.y0+1,cut=Buffer.alloc(cw*ch*4),keep=new Uint8Array(w*h),queue=[c.seed];keep[c.seed]=1;
    for(let q=0;q<queue.length;q++){const p=queue[q],x=p%w,y=Math.floor(p/w);for(const n of [x>0?p-1:-1,x+1<w?p+1:-1,y>0?p-w:-1,y+1<h?p+w:-1])if(n>=0&&mask[n]&&!keep[n]){keep[n]=1;queue.push(n)}}
    for(const p of queue){const x=p%w-c.x0,y=Math.floor(p/w)-c.y0;raw.copy(cut,(y*cw+x)*4,p*4,p*4+4)}
    return {raw:cut,w:cw,h:ch,...B.inspect(cut,cw,ch)};
   });
   const entry={species:id,stage,action,suspect,source_characters:frames.length,repair:apply};report.push(entry);
   if(!apply)continue;
   if(frames.length<8||frames.length>20)throw Error('Ambiguous source count '+JSON.stringify(entry));
   const factor=B.safeFactor(frames,manifest.stages[stage].reference_height/frames[0].bound.height);
   const transfer=B.paletteTransfer(frames[0],B.palette(await B.readMaster(id,'baby'))),images=[],anchors=[];
   for(let f=0;f<16;f++){
    const src=frames[Math.round(f/15*(frames.length-1))],b=src.bound;
    images.push(await B.renderFrame(src,factor,0,transfer));
    const bird=['owl','penguin'].includes(id),mouth=[128+(b.width*(bird?.62:.70)-src.root[0])*factor,232+(b.height*(bird?.40:.41)-src.root[1])*factor];
    anchors.push({mouth,hand:[mouth[0]-10*factor,mouth[1]+(72-Math.max(0,Math.sin(f/15*Math.PI))*30)*factor],source_root:src.root,source_bounds:[0,0,b.width,b.height],scale:factor,source_component:Math.round(f/15*(frames.length-1))});
   }
   if(action!=='walk'){
    const idle=await sharp(path.join(dir,stage+'-idle.png')).extract({left:0,top:0,width:256,height:256}).png().toBuffer();
    for(const f of [0,15]){images[f]=idle;anchors[f]=manifest.stages[stage].sequences.idle.anchors[0]}
   }
   await sharp({create:{width:4096,height:256,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(images.map((input,i)=>({input,left:i*256,top:0}))).png().toFile(path.join(dir,spec.file));
   spec.anchors=anchors;spec.extraction='whole connected character; ordered by source rows; resampled to 16 cels';
   fs.writeFileSync(path.join(dir,'manifest.json'),JSON.stringify(manifest,null,2));
   console.log('REPAIRED '+id+'/'+stage+'/'+action+' source='+frames.length);
  }
 }
 fs.writeFileSync(path.join(output,apply?'complete-cel-repair.json':'complete-cel-edge-audit.json'),JSON.stringify(report,null,2));
 console.log('SUSPECT_SEQUENCES='+report.length);
 if(!apply&&report.length)process.exitCode=1;
}
main().catch(e=>{console.error(e);process.exit(1)});
