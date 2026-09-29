const fs=require('fs'),path=require('path'),sharp=require('sharp');
async function main(){
 const dir=path.resolve(__dirname,'../design/rabbit-v3');
 const buffers=[];
 for(let i=0;i<96;i++)buffers.push(await sharp(path.join(dir,'animation-preview',String(i).padStart(3,'0')+'.png')).ensureAlpha().raw().toBuffer());
 await sharp(Buffer.concat(buffers),{raw:{width:816,height:380*96,channels:4,pageHeight:380}})
  .gif({delay:83,loop:0,colours:128,dither:0,effort:7}).toFile(path.join(dir,'rabbit-animations.gif'));
 const pngs=['baby-game-preview.png','adult-game-preview.png'];
 await sharp({create:{width:1632,height:800,channels:4,background:'#f6f3ec'}})
  .composite(await Promise.all(pngs.map(async(name,i)=>({input:await sharp(path.join(dir,name)).png().toBuffer(),left:i*816,top:40}))))
  .png().toFile(path.join(dir,'stages-game-preview.png'));
 console.log('PREVIEW_GIF_CREATED');
}
main().catch(e=>{console.error(e);process.exit(1)});
