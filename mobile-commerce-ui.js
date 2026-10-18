import {MobileLicense,createMobileRequest,COMMERCE_ORIGIN} from './mobile-commerce.js';
export function connectMobileCommerce(options={}){
  const native=window.BoksilAndroid,platform=native?'android':'apple',key='boksil-mobile-account-v1';
  const storage=native?.loadAccountToken?{get:()=>native.loadAccountToken(),set:t=>native.saveAccountToken(t),clear:()=>native.saveAccountToken('')}:{get:()=>localStorage.getItem(key),set:t=>localStorage.setItem(key,t),clear:()=>localStorage.removeItem(key)};
  const gate=document.createElement('section');gate.id='mobile-license-gate';gate.setAttribute('role','dialog');gate.setAttribute('aria-modal','true');gate.setAttribute('aria-label','모바일 구매와 계정 연결');
  gate.innerHTML='<div class="mobile-license-card"><h1>내 작은 집 연결하기</h1><p>Android와 iPhone Safari 웹앱은 각각 별도 구매 상품이에요. 홈페이지에서 구매한 뒤 주문 페이지에서 내 계정에 등록해 주세요.</p><p id="mobile-license-status" role="status"></p><p id="mobile-device-code"></p><div class="mobile-license-actions"><button data-mobile-connect>계정 연결</button><a data-mobile-approve hidden target="_blank" rel="noopener noreferrer">브라우저에서 연결 승인</a><a data-mobile-buy target="_blank" rel="noopener noreferrer">홈페이지에서 구매하기</a><button data-mobile-refresh>구매 복원 · 다시 확인</button><button data-mobile-disconnect>계정 연결 해제</button></div><small>결제와 계정 승인은 홈페이지에서 진행해요. 이용권 확인에는 인터넷이 필요하며, 저장한 집과 성장 기록은 유지됩니다.</small></div>';
  document.body.append(gate);
  const account=document.createElement('button');account.id='mobile-account';account.className='icon-button';account.textContent='구매';account.setAttribute('aria-label','모바일 구매와 계정 연결');document.querySelector('.header-actions').prepend(account);
  let open=false,busy=false;
  const status=gate.querySelector('#mobile-license-status'),approve=gate.querySelector('[data-mobile-approve]'),code=gate.querySelector('#mobile-device-code');
  function external(url){if(native?.openCommerceUrl){native.openCommerceUrl(url);return true;}return false;}
  const update=document.createElement('button');update.textContent='업데이트 확인';update.hidden=!native;gate.querySelector('.mobile-license-actions').append(update);
  const request=options.request||createMobileRequest();
  update.onclick=()=>action(async()=>{if(!client.licensed)throw Error('구매한 계정을 먼저 연결해 주세요.');update.disabled=true;try{const release=await request('/api/mobile/releases');if(!release.available||!Number.isSafeInteger(release.versionCode))throw Error('배포된 업데이트를 확인하지 못했어요.');if(release.versionCode<=Number(native.versionCode?.()||0)){client.message='현재 최신 버전이에요.';paint();return;}const result=await request('/api/mobile/download',{},client.token),url=new URL(result.url);if(url.origin!==COMMERCE_ORIGIN||!/^\/api\/mobile\/files\/[a-f0-9]{64}$/.test(url.pathname))throw Error('업데이트 주소를 확인하지 못했어요.');client.message='새 버전 '+release.versionName+'을 내려받아 기존 앱 위에 설치해 주세요. 앱을 삭제하지 않으면 플레이 기록을 유지할 수 있어요.';paint();external(url.href);}finally{update.disabled=false;}});
  const client=new MobileLicense({platform,request:options.request||createMobileRequest(),storage:options.storage||storage,onChange:()=>paint()});
  function paint(){
    const locked=!client.licensed;gate.hidden=!locked&&!open;
    document.querySelector('.game').inert=locked||open;
    document.body.classList.toggle('mobile-license-locked',locked);
    status.textContent=client.message;
    code.textContent=client.pending?'연결 코드: '+client.pending.userCode:'';
    approve.hidden=!client.pending;if(client.pending)approve.href=client.pending.verificationUrl;
    let close=gate.querySelector('[data-mobile-close]');
    if(client.licensed&&!close){close=document.createElement('button');close.dataset.mobileClose='';close.textContent='내 집으로 돌아가기';close.onclick=()=>{open=false;paint();};gate.querySelector('.mobile-license-actions').append(close);}
    if(close)close.hidden=!client.licensed;
  }
  async function action(fn){if(busy)return;busy=true;try{await fn();}catch(e){client.message=e.message;paint();}finally{busy=false;}}
  gate.querySelector('[data-mobile-connect]').onclick=()=>action(async()=>{await client.start();});
  approve.onclick=e=>{if(external(approve.href))e.preventDefault();};
  const buy=gate.querySelector('[data-mobile-buy]');buy.href=COMMERCE_ORIGIN+'/shop.html?view=checkout&product=boksil-pet-'+platform;buy.onclick=e=>{if(external(buy.href))e.preventDefault();};
  gate.querySelector('[data-mobile-refresh]').onclick=()=>action(()=>client.refresh());
  gate.querySelector('[data-mobile-disconnect]').onclick=()=>client.disconnect();
  account.onclick=()=>{open=true;paint();};
  setInterval(()=>{if(client.pending&&!document.hidden)action(()=>client.poll());},5000);
  setInterval(()=>{if(client.token&&!document.hidden)action(()=>client.refresh());},45000);
  let licensed=false;setInterval(()=>{if(licensed!==client.licensed){licensed=client.licensed;paint();}},500);
  const restore=()=>{paint();action(()=>client.refresh());};
  window.addEventListener('boksil-app-resume',restore);document.addEventListener('visibilitychange',()=>{if(!document.hidden)restore();});
  paint();action(()=>client.refresh());return client;
}
