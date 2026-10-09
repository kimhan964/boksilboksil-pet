// Canvas adaptation of the desktop furniture_palette shader. Cache only a few
// small props; preserve alpha, dark outlines, glass and green natural details.
export const FURNITURE_COLORS=[['원래 색',null],['크림','#e7d5b8'],['세이지','#a5b397'],['더스티 로즈','#c7a4a0'],['안개 블루','#a7b8c1'],['월넛','#ae927b']];
export const FURNITURE_FINISHES=['원본 질감','원목결','리넨결','매끈한 무광'];
const cache=new Map();
export function normalizeStyle(value={}){return {color:Number.isInteger(value.color)&&value.color>=0&&value.color<6?value.color:0,finish:Number.isInteger(value.finish)&&value.finish>=0&&value.finish<4?value.finish:0,design:Number.isInteger(value.design)&&value.design>=0&&value.design<3?value.design:0};}
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t);};
export function furnitureImage(img,id,value){
 const s=normalizeStyle(value);if(!img.complete||!img.naturalWidth||(!s.color&&!s.finish))return img;
 const key=img.src+':'+s.color+':'+s.finish;if(cache.has(key))return cache.get(key);
 const c=document.createElement('canvas');c.width=img.naturalWidth;c.height=img.naturalHeight;const ctx=c.getContext('2d',{willReadFrequently:true});ctx.drawImage(img,0,0);const data=ctx.getImageData(0,0,c.width,c.height),p=data.data;
 const hex=FURNITURE_COLORS[s.color][1]||'#ffffff',accent=[1,3,5].map(i=>parseInt(hex.slice(i,i+2),16)/255),nature=['plant','aquarium','window_seat'].includes(id)||id.startsWith('personal-');
 for(let i=0;i<p.length;i+=4){if(!p[i+3])continue;const rgb=[p[i]/255,p[i+1]/255,p[i+2]/255],peak=Math.max(...rgb);let surface=smooth(.12,.30,peak)*(1-smooth(.93,.99,peak))*smooth(-.015,.04,rgb[0]-rgb[2]);if(nature)surface*=smooth(-.025,.01,rgb[0]-rgb[1]);const light=rgb[0]*.2126+rgb[1]*.7152+rgb[2]*.0722;
  const x=(i/4)%c.width,y=Math.floor(i/4/c.width),detail=s.finish===1?Math.sin(y*.06+Math.sin(x*.012)*3)*.020:s.finish===2?(Math.sin(x*.18)+Math.sin(y*.18))*.012:0;
  for(let ch=0;ch<3;ch++){let v=rgb[ch];if(s.color)v+=(accent[ch]*Math.max(.25,Math.min(1.18,light/.72))-v)*surface*.75;if(s.finish===3)v+=(light-v)*surface*.08;p[i+ch]=Math.max(0,Math.min(255,Math.round((v+detail*surface)*255)));}
 }
 ctx.putImageData(data,0,0);if(cache.size>=16)cache.delete(cache.keys().next().value);cache.set(key,c);return c;
}
