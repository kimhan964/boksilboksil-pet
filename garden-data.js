export const CROPS=[
 {id:'carrot',name:'당근',seed:4,seconds:120,harvests:0,art:'assets/garden/carrot.svg'},
 {id:'herb',name:'허브',seed:7,seconds:240,harvests:2,art:'assets/garden/herb.svg'},
 {id:'berry',name:'산딸기',seed:10,seconds:360,harvests:5,art:'assets/garden/berry.svg'},
 {id:'mushroom',name:'버섯',seed:12,seconds:480,harvests:9,art:'assets/garden/mushroom.svg'}
];
export const GARDEN_DISHES=[
 ['carrot-soup','텃밭 당근 수프','carrot',2,'dish-0-0','정식',34,8,4],
 ['carrot-cake','텃밭 당근 케이크','carrot',3,'dish-0-2','간식',24,14,5],
 ['herb-pasta','텃밭 허브 파스타','herb',2,'dish-4-1','정식',38,10,5],
 ['herb-tea','텃밭 허브차','herb',1,'dish-4-2','음료',12,12,10],
 ['berry-tart','텃밭 산딸기 타르트','berry',3,'dish-5-2','간식',28,16,5],
 ['berry-tea','텃밭 산딸기차','berry',1,'dish-5-3','음료',12,13,9],
 ['mushroom-soup','텃밭 버섯 수프','mushroom',2,'dish-7-0','정식',36,10,6],
 ['mushroom-quiche','텃밭 버섯 키슈','mushroom',3,'dish-7-2','정식',42,14,8]
].map(([id,name,crop,amount,art,category,hunger,happy,energy])=>({id:'garden-'+id,name,crop,amount,art,category,hunger,happy,energy,price:1,garden:true,description:'직접 수확한 '+CROPS.find(c=>c.id===crop).name+'으로 만든 정성 가득한 요리.',icon:'assets/food/'+art+'.png'}));
