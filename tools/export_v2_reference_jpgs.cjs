const fs=require('fs'),path=require('path'),sharp=require('sharp');
const root=path.resolve(__dirname,'..'),v3=process.argv.includes('--v3'),version=v3?'all-species-v3':'all-species-v2',base=path.join(root,'design',version,'masters'),out=path.join(root,'design',version,'reference-jpg');
const ids=['rabbit','otter','squirrel','hedgehog','raccoon','fox','bear','owl','cat','puppy','hamster','panda','red_panda','lamb','koala','penguin'];
async function main(){fs.mkdirSync(out,{recursive:true});for(const id of ids){fs.mkdirSync(path.join(out,id),{recursive:true});for(const stage of ['baby','adult'])await sharp(path.join(base,id,stage+'.png')).resize(384,384,{fit:'inside'}).jpeg({quality:88,chromaSubsampling:'4:4:4'}).toFile(path.join(out,id,stage+'.jpg'));console.log('REFERENCE_JPG '+id)}}
main().catch(error=>{console.error(error);process.exit(1)});
