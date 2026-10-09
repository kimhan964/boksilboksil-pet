export const SKINS = [
  {id:'forest',country:'기본',name:'숲속의 작은 집',file:'room.png',description:'초록 커튼과 햇살 가득한 나무 바닥',color:'#8a9a72'},
  {id:'korea',country:'한국',name:'햇살 한옥',file:'room-korea.png',description:'한지와 나무 창살, 고요한 마당의 풍경',color:'#a48564'},
  {id:'japan',country:'일본',name:'느긋한 다다미방',file:'room-japan.png',description:'종이 미닫이문과 다다미, 둥근 정원 창',color:'#91a17e'},
  {id:'france',country:'프랑스',name:'라벤더 시골집',file:'room-france.png',description:'파스텔 창틀과 헤링본 바닥, 들판의 햇살',color:'#a399b1'},
  {id:'finland',country:'핀란드',name:'자작나무 숲속집',file:'room-finland.png',description:'밝은 나무 바닥과 눈 내린 소나무 숲',color:'#87a4a9'},
  {id:'morocco',country:'모로코',name:'포근한 리아드',file:'room-morocco.png',description:'아치 창문과 은은한 타일, 따뜻한 흙빛',color:'#c0997d'}
];
export function findSkin(id){return SKINS.find(s=>s.id===id)||SKINS[0];}
