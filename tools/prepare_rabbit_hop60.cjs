// Lay out complete key drawings as endpoint references; no part animation.
const fs=require('fs'),path=require('path'),sharp=require('sharp');
const root=path.resolve(__dirname,'..'),work=path.join(root,'design/rabbit-frame-pilot-v7');
async function main(){
 const src=path.join(work,'raw/key-poses-refined.png'),m=await sharp(src).metadata();
 for(const folder of ['keys','guides','blank-guides','generated','frames'])fs.mkdirSync(path.join(work,folder),{recursive:true});
 const order=[0,1,2,4,3,5,6,7,8,9,10,11],keys=[];
 for(let i=0;i<12;i++){
  const n=order[i],left=Math.round(n%4*m.width/4),right=Math.round((n%4+1)*m.width/4),top=Math.round(Math.floor(n/4)*m.height/3),bottom=Math.round((Math.floor(n/4)+1)*m.height/3);
  const buf=await sharp(src).extract({left,top,width:right-left,height:bottom-top}).resize(512,512).png().toBuffer();
  keys.push(buf);fs.writeFileSync(path.join(work,'keys',`${String(i).padStart(2,'0')}.png`),buf);
 }
 for(let i=0;i<12;i++){
  const layers=Array.from({length:6},(_,j)=>({input:keys[(i+(j>=3?1:0))%12],left:j%3*512,top:Math.floor(j/3)*576+32}));
  await sharp({create:{width:1536,height:1152,channels:3,background:'#00ffff'}}).composite(layers).png().toFile(path.join(work,'guides',`${String(i).padStart(2,'0')}.png`));
  await sharp({create:{width:1536,height:1152,channels:3,background:'#00ffff'}}).composite([layers[0],layers[5]]).png().toFile(path.join(work,'blank-guides',`${String(i).padStart(2,'0')}.png`));
 }
 fs.writeFileSync(path.join(work,'key-order.json'),JSON.stringify({source:src,order,reason:'Forward rising leap follows initial upright push; landing reaches forefeet before rear feet'},null,2));
 console.log('12 whole-body keys and endpoint guide sheets prepared');
}
main().catch(e=>{console.error(e);process.exitCode=1});
