// Assemble newly generated whole-body drawings; no synthesized motion or rigs.
const fs=require('fs'),path=require('path'),sharp=require('sharp'),cp=require('child_process');
const root=path.resolve(__dirname,'..'),work=path.join(root,'design/rabbit-frame-pilot-v7');
async function main(){
 const frames=[],selection=[];
 for(let i=0;i<12;i++){
  const sourceFolder=[4,5].includes(i)?'repairs':'generated';
  const source=path.join(work,sourceFolder,`${String(i).padStart(2,'0')}.png`),m=await sharp(source).metadata();
  for(let j=0;j<5;j++){
   let cel;
   if(j===0)cel=await sharp({create:{width:512,height:576,channels:3,background:'#00ffff'}}).composite([{input:path.join(work,'keys',`${String(i).padStart(2,'0')}.png`),left:0,top:32}]).png().toBuffer();
   else {
    const left=Math.round(j%3*m.width/3),right=Math.round((j%3+1)*m.width/3),top=Math.round(Math.floor(j/3)*m.height/2),bottom=Math.round((Math.floor(j/3)+1)*m.height/2);
    // Restore the fixed source camera cell, not the character's individual bounds.
    const full=await sharp(source).extract({left,top,width:right-left,height:bottom-top}).resize(512,576).png().toBuffer();
    cel=full;
   }
   const index=frames.length;frames.push(cel);
   fs.writeFileSync(path.join(work,'frames',`${String(index).padStart(2,'0')}.png`),cel);
   selection.push({index,interval:i,position:j,phase:index/60,source:j===0?`keys/${String(i).padStart(2,'0')}.png`:`${sourceFolder}/${String(i).padStart(2,'0')}.png`,sourceCell:j});
  }
 }
 const layers=Array.from({length:64},(_,i)=>({input:frames[Math.min(i,59)],left:i%8*512,top:Math.floor(i/8)*576}));
 await sharp({create:{width:4096,height:4608,channels:3,background:'#00ffff'}}).composite(layers).png().toFile(path.join(work,'selected-source.png'));
 fs.writeFileSync(path.join(work,'selected-frames.json'),JSON.stringify({frames:selection,padding_cells:4},null,2));
 cp.execFileSync(process.execPath,[path.join(root,'tools/pack_rabbit_whole_body.cjs'),path.join(work,'selected-source.png'),'8','8',path.join(work,'packed-selected')],{stdio:'inherit'});
 const packed=Array.from({length:60},(_,i)=>({input:path.join(work,'packed-selected',`${String(i).padStart(2,'0')}.png`),left:i%8*256,top:Math.floor(i/8)*256}));
 await sharp({create:{width:2048,height:2048,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(packed).png().toFile(path.join(work,'adult-walk.png'));
 await sharp({create:{width:2048,height:2048,channels:3,background:'#fff8ed'}}).composite(packed).png().toFile(path.join(work,'contact-60.png'));
 const manifest={version:7,method:'60 newly drawn VARCO whole-body cels: 12 new keys plus 48 generated inbetweens, no rig, no AI interpolation, no crossfade',canvas:[256,256],root:[128,232],stages:{adult:{reference_height:216,stride:24,cycle_seconds:1.5,locomotion:'short_hop',launch_phase:12/60,land_phase:40/60,lift_canvas:18,sequences:{walk:{file:'adult-walk.png',count:60,columns:8,phases:Array.from({length:60},(_,i)=>i/60)},idle:{file:'adult-idle.png',count:1,columns:1}}}}};
 fs.writeFileSync(path.join(work,'manifest.json'),JSON.stringify(manifest,null,2));
 fs.copyFileSync(path.join(work,'packed-selected/00.png'),path.join(work,'adult-idle.png'));
 console.log('60-cel candidate ready in design folder; runtime installation requires visual review');
}
main().catch(e=>{console.error(e);process.exitCode=1});
