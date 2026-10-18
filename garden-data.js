export const CROPS=[
 {id:'carrot',name:'당근',seed:4,seconds:120,harvests:0,art:'assets/garden-thin-v2/carrot-icon.png'},
 {id:'herb',name:'허브',seed:7,seconds:240,harvests:2,art:'assets/garden-thin-v2/herb-icon.png'},
 {id:'berry',name:'산딸기',seed:10,seconds:360,harvests:5,art:'assets/garden-thin-v2/berry-icon.png'},
 {id:'mushroom',name:'버섯',seed:12,seconds:480,harvests:9,art:'assets/garden-thin-v2/mushroom-icon.png'},
 {id:'tomato',name:'토마토',seed:14,seconds:600,harvests:12,art:'assets/garden-thin-v2/tomato-icon.png'},
 {id:'pumpkin',name:'호박',seed:18,seconds:720,harvests:18,art:'assets/garden-thin-v2/pumpkin-icon.png'}
];
export const GARDEN_DISHES=[
 ['carrot-soup','텃밭 당근 수프','carrot',2,'dish-0-0','정식',34,8,4],
 ['carrot-cake','텃밭 당근 케이크','carrot',3,'dish-0-2','간식',24,14,5],
 ['herb-pasta','텃밭 허브 파스타','herb',2,'dish-4-1','정식',38,10,5],
 ['herb-tea','텃밭 허브차','herb',1,'dish-4-2','음료',12,12,10],
 ['berry-tart','텃밭 산딸기 타르트','berry',3,'dish-5-2','간식',28,16,5],
 ['berry-tea','텃밭 산딸기차','berry',1,'dish-5-3','음료',12,13,9],
 ['mushroom-soup','텃밭 버섯 수프','mushroom',2,'dish-7-0','정식',36,10,6],
 ['mushroom-quiche','텃밭 버섯 키슈','mushroom',3,'dish-7-2','정식',42,14,8],
 ['carrot-rice','텃밭 당근 채소밥','carrot',2,'dish-0-1','정식',36,8,5],
 ['carrot-noodles','텃밭 당근 국수','carrot',2,'dish-0-3','정식',35,9,5],
 ['carrot-juice','텃밭 당근 사과주스','carrot',1,'dish-drink-1','음료',14,12,9],
 ['herb-omelette','텃밭 허브 오믈렛','herb',2,'dish-4-0','정식',34,12,6],
 ['herb-soup','텃밭 허브 수프','herb',2,'dish-4-3','정식',30,10,7],
 ['alpine-herb-soup','텃밭 설산 허브 수프','herb',3,'dish-signature-11-0','정식',38,14,8],
 ['berry-toast','텃밭 산딸기 토스트','berry',2,'dish-5-0','간식',24,14,5],
 ['berry-salad','텃밭 산딸기 샐러드','berry',2,'dish-5-1','정식',26,12,7],
 ['berry-oatmeal','텃밭 숲딸기 오트죽','berry',2,'dish-signature-8-0','정식',34,12,7],
 ['berry-ginger-tea','텃밭 산딸기 생강차','berry',1,'dish-drink-11','음료',12,14,10],
 ['mushroom-rice','텃밭 버섯 덮밥','mushroom',2,'dish-7-1','정식',40,10,6],
 ['mushroom-udon','텃밭 버섯 우동','mushroom',2,'dish-7-3','정식',38,12,7],
 ['bamboo-mushroom-rice','텃밭 죽순 버섯밥','mushroom',3,'dish-signature-10-0','정식',42,14,8],
 ['tomato-pasta','텃밭 토마토 파스타','tomato',2,'garden-tomato-pasta-v1','정식',44,15,8],
 ['pumpkin-soup','텃밭 호박 수프','pumpkin',2,'garden-pumpkin-soup-v1','정식',40,16,10]
].map(([id,name,crop,amount,art,category,hunger,happy,energy])=>({id:'garden-'+id,name,crop,amount,art,category,hunger,happy,energy,price:1,garden:true,description:'직접 수확한 '+CROPS.find(c=>c.id===crop).name+(['carrot','mushroom'].includes(crop)?'으로':'로')+' 만든 정성 가득한 요리.',icon:'assets/food/'+art+'.png'}));
