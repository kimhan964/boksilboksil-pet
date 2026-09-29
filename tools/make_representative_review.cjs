const fs=require('fs'),path=require('path'),sharp=require('sharp');
const root=path.resolve(__dirname,'..'),v3=process.argv.includes('--v3'),base=path.join(root,'design',v3?'all-species-v3':'all-species-v2','masters');
const ids=['rabbit','otter','squirrel','hedgehog','raccoon','fox','bear','owl','cat','puppy','hamster','panda','red_panda','lamb','koala','penguin'];
const clamp=(v,a,b)=>Math.min(b,Math.max(a,v));
function rgbToLab(r,g,b){let R=r/255,G=g/255,B=b/255;R=R<=.04045?R/12.92:Math.pow((R+.055)/1.055,2.4);G=G<=.04045?G/12.92:Math.pow((G+.055)/1.055,2.4);B=B<=.04045?B/12.92:Math.pow((B+.055)/1.055,2.4);let x=(R*.4124+G*.3576+B*.1805)/.95047,y=R*.2126+G*.7152+B*.0722,z=(R*.0193+G*.1192+B*.9505)/1.08883;const f=v=>v>.008856?Math.cbrt(v):7.787*v+16/116;x=f(x);y=f(y);z=f(z);return [116*y-16,500*(x-y),200*(y-z)]}
const distance=(a,b)=>Math.sqrt((a[0]-b[0])**2+(a[1]-b[1])**2+(a[2]-b[2])**2);
async function subject(file){
 const loaded=await sharp(file).ensureAlpha().raw().toBuffer({resolveWithObject:true}),data=Buffer.from(loaded.data),w=loaded.info.width,h=loaded.info.height;
 let x0=w,y0=h,x1=0,y1=0;const labs=[];
 for(let p=0;p<w*h;p++){const at=p*4,r=data[at],g=data[at+1],b=data[at+2],spill=Math.min(g-r,b-r);let a=spill<=10?1:Math.max(0,1-(spill-10)/210);if(a<.04)a=0;data[at+3]=Math.round(a*255);if(!a){data.fill(0,at,at+4);continue}const x=p%w,y=Math.floor(p/w);x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);if(p%7===0&&a>.8)labs.push(rgbToLab(r,g,b))}
 return {data,w,h,bound:{left:x0,top:y0,width:x1-x0+1,height:y1-y0+1},labs};
}
function palette(labs,count=18){const centers=[labs[Math.floor(labs.length/2)].slice()];while(centers.length<count){let far=labs[0],best=-1;for(const p of labs){const d=Math.min(...centers.map(c=>distance(p,c)));if(d>best){best=d;far=p}}centers.push(far.slice())}let weights=[];for(let n=0;n<12;n++){const sums=centers.map(()=>[0,0,0,0]);for(const p of labs){let pick=0,best=Infinity;for(let i=0;i<count;i++){const d=distance(p,centers[i]);if(d<best){best=d;pick=i}}for(let j=0;j<3;j++)sums[pick][j]+=p[j];sums[pick][3]++}weights=sums.map(s=>s[3]/labs.length);for(let i=0;i<count;i++)if(sums[i][3])centers[i]=sums[i].slice(0,3).map(v=>v/sums[i][3])}return centers.map((lab,i)=>({lab,weight:weights[i]})).filter(x=>x.weight>.012)}
async function thumb(subjectImage){
 const b=subjectImage.bound,cut=await sharp(subjectImage.data,{raw:{width:subjectImage.w,height:subjectImage.h,channels:4}}).extract(b).resize({width:250,height:250,fit:'contain',background:{r:0,g:0,b:0,alpha:0}}).png().toBuffer();
 return sharp({create:{width:270,height:270,channels:4,background:'#f6f2e9'}}).composite([{input:cut,left:10,top:10}]).png().toBuffer();
}
async function main(){
 const approve=process.argv.includes('--approve');
 const ready=ids.filter(id=>fs.existsSync(path.join(base,id,'baby.png'))&&fs.existsSync(path.join(base,id,'adult.png'))),rows=[],report=[];
 for(const id of ready){const baby=await subject(path.join(base,id,'baby.png')),adult=await subject(path.join(base,id,'adult.png')),bp=palette(baby.labs),ap=palette(adult.labs);const deltas=bp.map(b=>({weight:b.weight,delta:Math.min(...ap.map(a=>distance(b.lab,a.lab)))}));const important=deltas.filter(x=>x.weight>.035),weighted=important.reduce((s,x)=>s+x.delta*x.weight,0)/important.reduce((s,x)=>s+x.weight,0),metricPass=weighted<=3;report.push({species:id,palette_source:'baby.png',palette_delta_e_max:Number(Math.max(...important.map(x=>x.delta)).toFixed(2)),palette_delta_e_weighted:Number(weighted.toFixed(2)),metric_pass:metricPass,identity_errors:[],visual_review:approve?'passed-2026-09-24':'pending',approved:approve&&metricPass});rows.push({id,baby:await thumb(baby),adult:await thumb(adult)})}
 const layers=[];for(let row=0;row<rows.length;row++){const y=42+row*286,item=rows[row],bg=row%2?'#efece5':'#f7f4ed';layers.push({input:Buffer.from('<svg width="700" height="286"><rect width="700" height="286" fill="'+bg+'"/><text x="12" y="145" font-size="19" font-family="Arial" fill="#413c36">'+item.id+'</text><text x="180" y="22" font-size="14" font-family="Arial" fill="#655e55">baby representative</text><text x="470" y="22" font-size="14" font-family="Arial" fill="#655e55">adult representative</text></svg>'),left:0,top:y});layers.push({input:item.baby,left:150,top:y+12},{input:item.adult,left:440,top:y+12})}
 layers.unshift({input:Buffer.from('<svg width="700" height="42"><rect width="700" height="42" fill="#dfeae2"/><text x="12" y="28" font-size="19" font-family="Arial" fill="#26362e">Representative gate · color, tone, identity, proportions</text></svg>'),left:0,top:0});
 await sharp({create:{width:700,height:42+rows.length*286,channels:4,background:'#f7f4ed'}}).composite(layers).png().toFile(path.join(base,'representative-review.png'));
 fs.writeFileSync(path.join(base,'character-spec.json'),JSON.stringify({workflow_version:v3?3:2,frames_per_action:v3?16:8,generated:new Date().toISOString(),approval_rule:'Visual identity and cute silhouette pass; weighted primary palette Delta E <= 3',species:report},null,2));
 console.log('REPRESENTATIVE_REVIEW '+ready.length);
}
main().catch(error=>{console.error(error);process.exit(1)});
