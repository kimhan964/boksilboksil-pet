export const COMMERCE_ORIGIN='https://boksilboksil.kr';
const TOKEN=/^[a-f0-9]{64}$/;
// Purchase rights are never read from the play save or a payment return URL.
export class MobileLicense {
  constructor({platform,request,storage,now=()=>performance.now(),onChange=()=>{}}){
    if(!['android','apple'].includes(platform))throw Error('지원하지 않는 플랫폼입니다.');
    Object.assign(this,{platform,request,storage,now,onChange});
    this.token='';this.validUntil=0;this.generation=0;this.pending=null;this.message='계정을 연결하고 구매한 이용권을 확인해 주세요.';
    try{const token=storage.get();if(TOKEN.test(token||''))this.token=token;}catch{}
  }
  get licensed(){return !!this.token&&this.now()<this.validUntil;}
  changed(){this.onChange(this);}
  async start(){
    const data=await this.request('/api/mobile/device/start',{});
    const u=new URL(data.verificationUrl);
    if(u.origin!==COMMERCE_ORIGIN||u.pathname!=='/payment.html'||u.searchParams.get('view')!=='device'||u.searchParams.get('code')!==data.userCode||!TOKEN.test(data.deviceSecret||'')||!data.deviceId||!/^[A-F0-9]{12}$/.test(data.userCode||''))throw Error('계정 연결 주소를 확인하지 못했어요.');
    this.pending={...data,until:this.now()+Math.min(Number(data.expiresIn)||600,600)*1000};
    this.message='브라우저에서 로그인하고 같은 연결 코드를 승인해 주세요.';this.changed();return data;
  }
  async poll(){
    const p=this.pending;if(!p)return false;
    if(this.now()>=p.until){this.pending=null;this.message='연결 코드가 만료됐어요. 계정 연결을 다시 눌러 주세요.';this.changed();return false;}
    const generation=this.generation;
    const data=await this.request('/api/mobile/device/poll',{deviceId:p.deviceId},p.deviceSecret);
    if(this.pending!==p||generation!==this.generation)return false;
    if(data.status==='pending')return false;
    if(data.status!=='approved'||!TOKEN.test(data.accessToken||''))throw Error('계정 연결 결과를 확인하지 못했어요.');
    this.token=data.accessToken;this.pending=null;try{this.storage.set(this.token);}catch{}await this.refresh();return true;
  }
  async refresh(){
    if(!this.token){this.changed();return false;}
    const generation=this.generation;
    try{
      const data=await this.request('/api/mobile/entitlements?platform='+this.platform,undefined,this.token);
      if(generation!==this.generation)return this.licensed;
      if(data.productId!=='boksil-pet-'+this.platform||typeof data.licensed!=='boolean')throw Error('이용권 응답을 확인하지 못했어요.');
      const seconds=Number(data.validForSeconds);
      this.validUntil=data.licensed&&Number.isFinite(seconds)&&seconds>0?this.now()+Math.min(seconds,60)*1000:0;
      this.message=this.licensed?'구매한 모바일 이용권을 확인했어요.': '이 계정에 이 플랫폼의 모바일 이용권이 없어요. 주문 페이지에서 구매를 등록해 주세요.';
    }catch(e){
      if(generation!==this.generation)return false;
      if(e.status===401)this.disconnect();
      this.message=e.status===401?'계정 연결이 만료됐어요. 다시 연결해 주세요.':'이용권을 확인하려면 인터넷 연결이 필요해요.';
    }
    this.changed();return this.licensed;
  }
  disconnect(){this.generation++;this.token='';this.pending=null;this.validUntil=0;try{this.storage.clear();}catch{}this.message='계정 연결을 해제했어요. 플레이 기록은 그대로 보관돼요.';this.changed();}
}

export function createMobileRequest(origin=COMMERCE_ORIGIN){return async(path,data,token)=>{
  const headers={};if(data!==undefined)headers['Content-Type']='application/json';if(token)headers.Authorization='Bearer '+token;
  const response=await fetch(origin+path,{method:data===undefined?'GET':'POST',headers,credentials:'omit',cache:'no-store',redirect:'error',body:data===undefined?undefined:JSON.stringify(data),signal:AbortSignal.timeout(15000)});
  const value=await response.json();if(!response.ok){const e=Error(value.error||'연결 상태를 확인해 주세요.');e.status=response.status;throw e;}return value;
};}
