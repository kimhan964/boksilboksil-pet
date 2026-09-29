const path=require('path'),sharp=require('sharp');
const root=path.resolve(__dirname,'..');
const pilot=process.argv.includes('--pilot');
const ids=['rabbit','otter','squirrel','hedgehog','raccoon','fox','bear','owl','cat','puppy','hamster','panda','red_panda','lamb','koala','penguin'];
const stages=['baby','adult'],actions=[['idle',0],['walk',3],['pet',4]];
const width=1240,rowHeight=132,top=48;
function folder(id){return id==='rabbit'?path.join(root,'assets','rabbit-v3'):(pilot?path.join(root,'design','all-species-v2','pilot-runtime',id):path.join(root,'assets','species-v2',id))}
async function frame(id,stage,action,index){
 return sharp(path.join(folder(id),stage+'-'+action+'.png')).extract({left:index*256,top:0,width:256,height:256}).resize(116,116).png().toBuffer();
}
async function main(){
 const layers=[];
 const header=Buffer.from('<svg width="1240" height="48"><rect width="1240" height="48" fill="#e6eee9"/><text x="12" y="30" font-size="20" font-family="Arial" fill="#26362e">VARCO complete-character cels · baby and adult · 16 species</text></svg>');
 layers.push({input:header,left:0,top:0});
 for(let row=0;row<ids.length;row++){
  const id=ids[row],y=top+row*rowHeight;
  const background=row%2?'#f0eee9':'#f7f5f0';
  const label=Buffer.from('<svg width="160" height="132"><rect width="160" height="132" fill="'+background+'"/><text x="10" y="70" font-size="17" font-family="Arial" fill="#403b35">'+id+'</text></svg>');
  layers.push({input:label,left:0,top:y});
  let column=0;
  for(const stage of stages)for(const entry of actions){
   const action=entry[0],index=entry[1],x=160+column*176;
   const title=Buffer.from('<svg width="176" height="132"><rect width="176" height="132" fill="'+background+'"/><text x="4" y="15" font-size="12" font-family="Arial" fill="#6a6259">'+stage+' · '+action+'</text></svg>');
   layers.push({input:title,left:x,top:y});
   layers.push({input:await frame(id,stage,action,index),left:x+30,top:y+16});
   column++;
  }
 }
 const output=pilot?path.join(root,'design','all-species-v2','pilot-review','pilot-overview.png'):path.join(root,'design','all-species-v2','production-review','all-species-preview.png');
 await sharp({create:{width,height:top+ids.length*rowHeight,channels:4,background:'#f7f5f0'}}).composite(layers).png().toFile(output);
 console.log('PREVIEW_CREATED');
}
main().catch(error=>{console.error(error);process.exit(1)});
