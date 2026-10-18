export const HOME_FILES={sofa:'sofa',table:'table',rug:'play_rug',plant:'plant_stand',lamp:'lamp',shelf:'shelf',bed:'daybed',chair:'reading_chair',aquarium:'aquarium',clock:'wall_clock',tv:'tv',record:'record_player',vanity:'vanity',window_seat:'window_seat',turntable:'turntable',wall_shelf:'wall_shelf',dresser:'dresser',fireplace:'fireplace',alarm_clock:'alarm_clock',toy_ball:'toy_ball',toy_mouse:'toy_mouse',acorn:'acorn',water:'water-cup',basket:'toy-basket',bathtub:'bathtub',toy_plush:'carrot-plush'};
export const softHomeFile=id=>HOME_FILES[id]?'thin-home-v3/'+HOME_FILES[id]+'.webp':null;
export const EXTRA_HOME=[
 {id:'bathtub',name:'둥근 거품 욕조',price:110,cat:'가구',w:.29,group:'feed',count:8,minutes:15,activity:'bath'},
 {id:'toy_plush',name:'안아 주는 당근 인형',price:30,cat:'놀이감',w:.08,group:'play',count:3,minutes:5,activity:'plush'}
];
export function prepareSoftHome(catalog){
 const names={sofa:'푹신한 작은 소파',table:'둥근 나무 식탁',rug:'발바닥 놀이 러그',plant:'새싹 화분대',lamp:'노란 버섯 조명',shelf:'도토리 작은 책장',bed:'포근한 이불 침대',chair:'파란 독서 의자',record:'작은 음악 장식장',wall_shelf:'도토리 벽 책장',toy_mouse:'클로버 생쥐 놀이감',basket:'장난감 보물 바구니'};
 for(const item of catalog){if(names[item.id])item.name=names[item.id];const file=softHomeFile(item.id)||softHomeFile(item.kind)||(item.id.startsWith('personal-')&&item.id.endsWith('-plant')?softHomeFile('plant'):null);if(file){item.file=file;item.soft=true;}}
 return catalog;
}
export function furnitureFrame(spec,time=0,using=false){
 const frame=using?Math.floor((Math.max(0,time)/spec.duration%1)*spec.count):0;
 return {x:frame%spec.columns*spec.cell[0],y:Math.floor(frame/spec.columns)*spec.cell[1],w:spec.cell[0],h:spec.cell[1]};
}
export function ladderLift(elapsed,height){
 const smooth=t=>{t=Math.max(0,Math.min(1,t));return t*t*(3-2*t);};
 return elapsed<3.2?height*smooth(elapsed/3.2):elapsed<4.2?height:height*(1-smooth((elapsed-4.2)/3.2));
}
