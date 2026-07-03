/* ============================================================
   Avto Bozor Mini App — wired to /api/cars (car_api.py blueprint)
   Override the base by setting window.CARS_API_BASE before this script.
   ============================================================ */
const API = (window.CARS_API_BASE || "/api/cars");
const API_ORIGIN = new URL(API, location.href).origin;          // media lives on the API origin
const absUrl = u => (u && u[0] === "/") ? API_ORIGIN + u : u;    // make root-relative media URLs absolute (cross-origin)
const UID = (window.Telegram?.WebApp?.initDataUnsafe?.user?.id)
            || new URLSearchParams(location.search).get("uid") || null;   // null outside Telegram
const UNAME = window.Telegram?.WebApp?.initDataUnsafe?.user?.username || null;
const INIT_DATA = window.Telegram?.WebApp?.initData || "";
function apiFetch(path, opts={}){
  // GETs stay "simple" (only safelisted headers) so they don't trigger a CORS
  // preflight. Writes carry init_data in the body, not a custom header.
  opts.headers = Object.assign({Accept:"application/json"}, opts.headers||{});
  return fetch(API + path, opts);
}
async function jget(path){
  const r = await apiFetch(path);
  if(!r.ok) throw new Error("HTTP "+r.status);
  return r.json();
}
function authBody(extra){return Object.assign({telegram_user_id:UID, telegram_username:UNAME, init_data:INIT_DATA}, extra||{});}
function authQS(extra){return new URLSearchParams(Object.assign({telegram_user_id:UID}, extra||{})).toString();}
async function jpost(path, body){
  const r = await apiFetch(path,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(authBody(body))});
  const d = await r.json().catch(()=>({}));
  if(!r.ok) throw Object.assign(new Error("HTTP "+r.status),{status:r.status,data:d});
  return d;
}
async function jdelete(path){
  const r = await apiFetch(path,{method:"DELETE"});
  const d = await r.json().catch(()=>({}));
  if(!r.ok) throw Object.assign(new Error("HTTP "+r.status),{status:r.status,data:d});
  return d;
}

/* ---------- Telegram shim ---------- */
const TG = window.Telegram?.WebApp || {ready(){},expand(){},disableVerticalSwipes(){},initDataUnsafe:{},themeParams:{},
  BackButton:{show(){},hide(){},onClick(cb){this._cb=cb}},HapticFeedback:{impactOccurred(){},selectionChanged(){}}};
TG.ready?.(); TG.expand?.(); TG.disableVerticalSwipes?.();

/* ---------- activity log ----------
   app.js owns 'cars' logging now (logger.js must NOT be included on this page,
   or it will double-log and re-log on back-from-sell). Fires on any genuine open
   — main menu OR channel deep-link — because init() always runs here. */
const LOG_ENDPOINT = "https://vegukin-api.duckdns.org/api/log-interaction";
function logOpen(){
  
  // Sole logger for 'cars' (index.html no longer logs cars). Skip only when
  // returning from the sell page (sell.js sets cars_back on its load).
  try{ if(sessionStorage.getItem("cars_back")==="1"){ sessionStorage.removeItem("cars_back"); return; } }catch(e){}
  let tries=0;
  (function attempt(){
    const w = window.Telegram && window.Telegram.WebApp;      // read live, not the stubbed TG
    const u = w && w.initDataUnsafe && w.initDataUnsafe.user;
    if(u){
      try{ fetch(LOG_ENDPOINT, {method:"POST", headers:{"Content-Type":"application/json"}, keepalive:true,
        body: JSON.stringify({user_id:u.id, username:u.username||u.first_name||"unknown", action:"cars"})}).catch(()=>{}); }catch(e){}
      return;
    }
    if(tries++ < 10) setTimeout(attempt, 300);                // wait for initData on a cold channel launch
  })();
}
function haptic(t="light"){try{t==="sel"?TG.HapticFeedback.selectionChanged():TG.HapticFeedback.impactOccurred(t)}catch(e){}}
function dialPhone(num){
  // WKWebView (Telegram iOS) blocks location.href='tel:'; a programmatic <a> click within
  // the user gesture is handled reliably. Strip spaces/dashes — malformed tel: fails on iOS.
  const tel="tel:"+String(num).replace(/[^\d+]/g,"");
  try{ const a=document.createElement("a"); a.href=tel; a.style.display="none"; document.body.appendChild(a); a.click(); a.remove(); return; }catch(e){}
  try{ location.href=tel; }catch(e){}
}
function openTgHandle(h){
  const u="https://t.me/"+String(h).replace(/^@/,"");
  try{ if(TG.openTelegramLink){ TG.openTelegramLink(u); return; } }catch(e){}
  try{ if(TG.openLink){ TG.openLink(u); return; } }catch(e){}
  window.open(u,"_blank");
}
function copyText(t){
  try{ if(navigator.clipboard&&navigator.clipboard.writeText){ navigator.clipboard.writeText(String(t)); return true; } }catch(e){}
  try{ const i=document.createElement("input"); i.value=String(t); i.style.position="fixed"; i.style.opacity="0"; document.body.appendChild(i); i.select(); document.execCommand("copy"); i.remove(); return true; }catch(e){}
  return false;
}

/* ---------- helpers ---------- */
const NA="Keltirilmagan";
const na=v=>(v===null||v===undefined||v==="")?NA:v;
const won=v=>v==null?"—":v.toLocaleString("en-US").replace(/,/g," ")+" ₩";
const wonS=v=>v==null?"—":(v/1e6).toFixed(1).replace(/\.0$/,"")+"M";
const km=v=>v==null?NA:v>=1000?(v/1000).toFixed(0)+"k km":v+" km";
const mb=b=>(b/1048576).toFixed(1);
const transLabel=v=>({automatic:"Avtomat",manual:"Mexanika"})[v]||NA;
const fuelLabel=v=>({petrol:"Benzin",diesel:"Dizel",lpg:"LPG",hybrid:"Gibrid"})[v]||NA;
const FUEL={petrol:"Benzin",diesel:"Dizel",lpg:"LPG",hybrid:"Gibrid"};
const esc=s=>(s||"").replace(/[&<>]/g,m=>({"&":"&amp;","<":"&lt;",">":"&gt;"}[m]));
const median=a=>{if(!a.length)return null;const s=[...a].sort((x,y)=>x-y),m=s.length>>1;return s.length%2?s[m]:Math.round((s[m-1]+s[m])/2)};
function computeStats(cars){
  const av=cars.filter(c=>c.status==="active"&&c.price_krw!=null).map(c=>c.price_krw),
        so=cars.filter(c=>c.status==="sold"&&c.price_krw!=null).map(c=>c.price_krw);
  const quant=(s,p)=>{const i=(s.length-1)*p,b=Math.floor(i),r=i-b;return s[b+1]!=null?s[b]+r*(s[b+1]-s[b]):s[b];};
  const f=a=>{
    const s=[...a].sort((x,y)=>x-y),n=s.length;
    let lo=n?s[0]:null,hi=n?s[n-1]:null;
    if(n>=4){const q1=quant(s,.25),q3=quant(s,.75),iqr=q3-q1;   // Tukey fences clamp lone outliers (e.g. a 15M among 2–4M)
      lo=Math.max(s[0],Math.round(q1-1.5*iqr));hi=Math.min(s[n-1],Math.round(q3+1.5*iqr));if(lo>=hi){lo=s[0];hi=s[n-1];}}
    return{n,min:n?s[0]:null,max:n?s[n-1]:null,med:median(a),lo,hi,vals:a};
  };
  return{av:f(av),so:f(so),countAv:cars.filter(c=>c.status==="active").length,countSo:cars.filter(c=>c.status==="sold").length};
}
const emptyStats=()=>({av:{n:0,min:null,max:null,med:null,lo:null,hi:null,vals:[]},so:{n:0,min:null,max:null,med:null,lo:null,hi:null,vals:[]},countAv:0,countSo:0});
function robustOf(arr){
  const s=[...arr].sort((x,y)=>x-y),n=s.length;
  const quant=p=>{const i=(n-1)*p,b=Math.floor(i),r=i-b;return s[b+1]!=null?s[b]+r*(s[b+1]-s[b]):s[b];};
  let lo=n?s[0]:null,hi=n?s[n-1]:null;
  if(n>=4){const q1=quant(.25),q3=quant(.75),iqr=q3-q1;lo=Math.max(s[0],Math.round(q1-1.5*iqr));hi=Math.min(s[n-1],Math.round(q3+1.5*iqr));if(lo>=hi){lo=s[0];hi=s[n-1];}}
  return{n,med:median(arr),lo,hi};
}
// Compare a car against similar-year cars (±1yr, then ±2yr) when ≥4 exist — a 2009 car
// shouldn't be judged against 2014 ones. Falls back to the whole model otherwise.
function localStats(c,modelCars){
  if(c.year==null||!modelCars)return null;
  const base=modelCars.filter(x=>x.status==="active"&&x.price_krw!=null&&x.year!=null);
  for(const w of [1,2]){
    const near=base.filter(x=>Math.abs(x.year-c.year)<=w);
    if(near.length>=4)return Object.assign(robustOf(near.map(x=>x.price_krw)),{local:true,w});
  }
  return null;
}
function dealClass(p,m){if(m==null||p==null)return"";const d=(p-m)/m;return d<-0.05?"low":d>0.05?"high":"mid";}
function dealColor(c){return c==="low"?"var(--low)":c==="high"?"var(--high)":c==="mid"?"var(--mid)":"var(--dim)";}
const hueFromId=id=>(id*47)%360;
function phGradient(hue){return`<div class="photo" style="background:linear-gradient(150deg,hsl(${hue} 42% 62%),hsl(${(hue+30)%360} 46% 40%))"><svg viewBox="0 0 100 60" style="position:absolute;inset:0;width:100%;height:100%;opacity:.3" preserveAspectRatio="xMidYMid meet"><path d="M12 40 L20 27 Q23 23 30 22 L60 22 Q68 22 74 28 L86 33 Q90 35 90 40 L90 44 L12 44 Z" fill="#fff"/><circle cx="30" cy="44" r="6" fill="#0f1722"/><circle cx="74" cy="44" r="6" fill="#0f1722"/><circle cx="30" cy="44" r="2.6" fill="#fff"/><circle cx="74" cy="44" r="2.6" fill="#fff"/></svg></div>`;}

/* brand colors for picker monograms (DB has no color) */
const BRAND_COLOR={Hyundai:"#0b2c5e",Kia:"#bb162b",Chevrolet:"#c9971c",Genesis:"#1c1c22",Samsung:"#1428a0",SsangYong:"#c8102e",Renault:"#f5a623",Daewoo:"#0b5fa5",Toyota:"#eb0a1e",BMW:"#16588e",Nissan:"#c3002f"};
const brandColor=b=>BRAND_COLOR[b]||"#41506a";
const brandMono=b=>((b||"?").trim()[0]||"?").toUpperCase();
const BRAND_LOGO={Hyundai:"hyundai",Chevrolet:"chevrolet",Kia:"kia",BMW:"bmw",Genesis:"genesis",Audi:"audi",Infiniti:"infiniti",Jaguar:"jaguar",SsangYong:"ssangyong","Samsung/Renault":"samsung",Mercedes:"mercedes-benz",Volvo:"volvo",Honda:"honda",Toyota:"toyota",Volkswagen:"volkswagen",Lexus:"lexus"};
const logoSrc=b=>BRAND_LOGO[b]?`logo/${BRAND_LOGO[b]}-logo.png`:null;
function brandIcon(b,cls){
  const s=logoSrc(b);
  if(s)return`<div class="logo lg ${cls||""}"><img src="${s}" alt="" loading="lazy" onerror="this.parentElement.classList.remove('lg');this.parentElement.style.background='${brandColor(b)}';this.parentElement.textContent='${brandMono(b)}'"></div>`;
  return`<div class="logo ${cls||""}" style="background:${brandColor(b)}">${brandMono(b)}</div>`;
}
const slugify=s=>(s||"").replace(/[^a-zA-Z0-9]/g,"");
const modelSlug=(b,m)=>slugify(b)+"_"+slugify(m);

/* ---------- state + caches ---------- */
let CURRENT={brand:null,model:null};
let MODEL_CARS=[], ST=emptyStats();
const FAV=new Set(); let ALERTS=[]; let TAB="browse";
const SEEN=new Set((()=>{try{return JSON.parse(localStorage.getItem("cars_seen")||"[]");}catch(e){return [];}})());
function markSeen(id){
  if(SEEN.has(id))return;
  SEEN.add(id);
  try{localStorage.setItem("cars_seen",JSON.stringify([...SEEN].slice(-1500)));}catch(e){}
  document.querySelectorAll(`.card[data-id="${id}"]`).forEach(cd=>{
    cd.classList.add("seen");
    if(!cd.querySelector(".seenmark")){
      const s=document.createElement("span");s.className="seenmark";
      s.innerHTML='<svg viewBox="0 0 24 24"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z"/><circle cx="12" cy="12" r="3"/></svg>Ko\u02bbrilgan';
      cd.appendChild(s);
    }
  });
}
const modelCache={};   // "brand|model" -> {cars, stats}
const byId={};         // id -> car (list or full)
let CATALOG=[];
let qModel=null, aModelSel=null;
const groupDigits=s=>String(s).replace(/\D/g,"").replace(/\B(?=(\d{3})+(?!\d))/g," ");
const numVal=id=>+(document.getElementById(id).value.replace(/\s/g,""))||0;
function attachGroup(id){const el=document.getElementById(id);if(!el)return;
  el.addEventListener("input",()=>{const start=el.selectionStart,before=el.value.slice(0,start).replace(/\D/g,"").length;
    el.value=groupDigits(el.value);
    let pos=0,seen=0;while(pos<el.value.length&&seen<before){if(el.value[pos]>="0"&&el.value[pos]<="9")seen++;pos++;}
    try{el.setSelectionRange(pos,pos);}catch(e){}});}
["qPrice","qMile","aPrice","aMile"].forEach(attachGroup);

async function getModelSet(brand,model){
  const key=brand+"|"+(model||"");
  if(modelCache[key]) return modelCache[key];
  const r=await jget(`/model?brand=${encodeURIComponent(brand)}`+(model?`&model=${encodeURIComponent(model)}`:""));
  const cars=r.cars||[];
  cars.forEach(c=>{byId[c.id]=Object.assign(byId[c.id]||{},c);});
  const e={cars,stats:computeStats(cars)};
  modelCache[key]=e; return e;
}
const modelMedCached=c=>{const e=modelCache[c.brand+"|"+(c.model||"")];return e?e.stats.av.med:null;};

/* ---------- shared card ---------- */
function thumbInner(c){
  const full=c.photo?absUrl(c.photo):"";
  const onErr=full?`this.onerror=null;this.src='${full}'`:`this.remove()`;
  const src=c.thumb?absUrl(c.thumb):full;
  return `<div class="photo">${phGradient(hueFromId(c.id))}</div>`+
         (src?`<img class="thumbimg" src="${src}" loading="lazy" onerror="${c.thumb?onErr:`this.remove()`}">`:"");
}
function card(c,showModel){
  const med=modelMedCached(c);
  const hasPrice=c.price_krw!=null;
  const dc=(c.status==="sold"||!hasPrice||med==null)?"":dealClass(c.price_krw,med);
  const isDeal=c.status==="active"&&hasPrice&&med&&c.price_krw<med*0.9;
  const chips=[c.mileage_km!=null?km(c.mileage_km):null,
              c.transmission!=null?transLabel(c.transmission):null,
              c.fuel!=null?fuelLabel(c.fuel):null].filter(Boolean);
  const ygen=[c.year,c.generation].filter(v=>v!=null&&v!=="").join(" · ")||"Ma'lumot kam";
  const when=c.posted_rel||c.posted_at||"";
  return`<div class="card ${c.status==="sold"?"sold":""} ${SEEN.has(c.id)?"seen":""}" data-id="${c.id}">
   ${SEEN.has(c.id)?'<span class="seenmark"><svg viewBox="0 0 24 24"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z"/><circle cx="12" cy="12" r="3"/></svg>Ko\u02bbrilgan</span>':''}
   <div class="ph">${thumbInner(c)}
    <span class="badge2 ${c.status==="sold"?"so":"av"}">${c.status==="sold"?"Sotilgan":"Mavjud"}</span>
    ${isDeal?'<span class="deal">🔥 Arzon</span>':''}
    <button class="fav ${FAV.has(c.id)?"on":""}" data-fav="${c.id}" aria-label="Saqlash"><svg viewBox="0 0 24 24"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg></button>
   </div>
   <div class="body">
    ${showModel?`<div class="ctitle">${esc(c.brand||"")} ${esc(c.model||"")}</div>`:""}
    <div class="price num ${hasPrice?"":"noprice"}">${hasPrice?`${c.status!=="sold"?`<span class="dot" style="background:${dealColor(dc)}"></span>`:""}${won(c.price_krw)}`:"Narxi keltirilmagan"}</div>
    <div class="ygen">${ygen} ${c.negotiable&&c.status!=="sold"?'<span class="neg">Kelishiladi</span>':''}</div>
    ${chips.length?`<div class="specs">${chips.map(x=>`<span>${x}</span>`).join("")}</div>`:""}
    <div class="foot"><svg viewBox="0 0 24 24"><path d="M12 8v5l3 2"/><circle cx="12" cy="12" r="9"/></svg>${esc(when)}</div>
   </div></div>`;
}
async function persistFav(id, want){
  want?FAV.add(id):FAV.delete(id);
  updateFavBadge();
  if(!UID) return true;                         // local-only outside Telegram
  try{
    if(want) await jpost("/favorites",{listing_id:id});
    else     await jdelete("/favorites?"+authQS({listing_id:id}));
    return true;
  }catch(e){ want?FAV.delete(id):FAV.add(id); updateFavBadge(); return false; }
}
function bindList(el){
  el.addEventListener("click",e=>{
    const f=e.target.closest("[data-fav]");
    if(f){e.stopPropagation();const id=+f.dataset.fav;const want=!FAV.has(id);
      f.classList.toggle("on",want);haptic('sel');
      persistFav(id,want).then(ok=>{if(!ok)f.classList.toggle("on",!want);else if(TAB==="fav")renderFav();});
      return;}
    const cd=e.target.closest(".card");if(cd){haptic('light');openDetail(+cd.dataset.id);}
  });
}
const loadingHTML=`<div class="loading"><div class="spinner"></div></div>`;
const errHTML=(msg)=>`<div class="empty"><div class="e">⚠️</div><h3>${msg||"Xatolik"}</h3><p>Internet aloqasini tekshiring</p><button class="cta" data-retry>Qayta urinish</button></div>`;

/* ---------- BROWSE ---------- */
let SORT="new",STATUS="all",ALL_MODE=false;
const SORTS=[["new","Yangi"],["value","Eng arzonlari"],["plow","Narx ↑"],["phigh","Narx ↓"],["mlow","Yurgani ↑"],["ynew","Yili ↓"]];
const STAT=[["all","Hammasi"],["active","Mavjud"],["sold","Sotilgan"]];
function sortCars(a){const f={plow:(x,y)=>(x.price_krw??Infinity)-(y.price_krw??Infinity),phigh:(x,y)=>(y.price_krw??-Infinity)-(x.price_krw??-Infinity),mlow:(x,y)=>(x.mileage_km||1e9)-(y.mileage_km||1e9),ynew:(x,y)=>(y.year||0)-(x.year||0),new:()=>0,value:(x,y)=>valueScore(x)-valueScore(y)}[SORT];return[...a].sort(f);}
function valueScore(c){if(c.price_krw==null)return 1e9;const ageP=(2026-(c.year||2014)),mileP=(c.mileage_km||150000)/10000;return c.price_krw/1e6+ageP*0.15+mileP*0.08;}
function renderMsum(){
  const {av}=ST;
  if(!av.n){document.getElementById("msum").innerHTML=`<div class="msum"><div class="top"><div class="m" style="font-size:16px">Hozircha sotuvda yo'q</div><div class="cnt"><b>${ST.countSo}</b> sotilgan</div></div></div>`;return;}
  const lo=av.lo,hi=av.hi,span=(hi-lo)||1;
  const pos=v=>Math.max(0,Math.min(100,((v-lo)/span)*100));
  document.getElementById("msum").innerHTML=`<div class="msum">
   <div class="top"><div class="m num">${won(av.med)}<small>o'rtacha narx</small></div>
    <div class="cnt"><b>${ST.countAv}</b> mavjud · <b>${ST.countSo}</b> sotilgan<br>${wonS(lo)}–${wonS(hi)} ₩</div></div>
   <div class="rangebar"><div class="med" style="left:${pos(av.med)}%"></div></div>
   <div class="rends"><span>${wonS(lo)} ₩</span><span>${wonS(hi)} ₩</span></div></div>`;
}
function renderBrowse(){
  document.getElementById("sortRow").innerHTML=SORTS.map(([k,l])=>`<button class="chip ${SORT===k?"on":""}" data-sort="${k}">${l}</button>`).join("");
  document.getElementById("statusRow").innerHTML=STAT.map(([k,l])=>`<div class="seg ${STATUS===k?"on "+(k==="active"?"av":k==="sold"?"so":""):""}" data-status="${k}">${l}</div>`).join("");
  let rows=sortCars(MODEL_CARS.filter(c=>STATUS==="all"?true:c.status===STATUS));
  const emptyMsg=ALL_MODE
    ?`<div class="empty"><div class="e">🚗</div><h3>Hozircha e'lon yo'q</h3><p>Tez orada yangi mashinalar qo'shiladi</p></div>`
    :`<div class="empty"><div class="e">🚗</div><h3>Bu modelda e'lon yo'q</h3><p>Yuqoridagi nomdan boshqa modelni tanlang</p></div>`;
  const cells=rows.map(c=>card(c,ALL_MODE));
  let html;
  if(cells.length){ cells.splice(Math.min(6,cells.length),0,channelCard()); html=cells.join(""); }
  else { html=emptyMsg+channelCard(); }
  document.getElementById("browseList").innerHTML=html;
}
function channelCard(){
  return `<button class="chcard" onclick="openChannel()" aria-label="Vegukin Avto kanali">
    <span class="ch-ic"><svg viewBox="0 0 24 24" fill="currentColor"><path d="M21.9 4.27l-3.3 15.56c-.24 1.1-.9 1.37-1.82.85l-5.03-3.71-2.43 2.34c-.27.27-.5.5-1.02.5l.36-5.18L18.4 6.2c.4-.36-.09-.56-.62-.2L7.24 12.9l-4.87-1.52c-1.06-.33-1.08-1.06.22-1.57l19.06-7.35c.88-.33 1.65.2 1.36 1.93z"/></svg></span>
    <span class="ch-tw"><span class="ch-t">Vegukin Avto — kanal</span><span class="ch-s">Barcha yangi e'lonlar shu yerda jonli chiqadi</span></span>
    <span class="ch-cta">Ochish</span>
  </button>`;
}
function openChannel(){
  const u="https://t.me/vegukin_car"; haptic("light");
  try{ if(TG.openTelegramLink){ TG.openTelegramLink(u); return; } }catch(e){}
  try{ if(TG.openLink){ TG.openLink(u); return; } }catch(e){}
  location.href=u;
}
function setHeaderBrand(brand,model){
  document.getElementById("hTitle").textContent=(brand||"")+(model?" "+model:"");
  const lg=document.getElementById("hLogo");if(!lg)return;
  const s=brand?logoSrc(brand):null;
  if(s){lg.style.background="#fff";lg.style.color="";lg.innerHTML=`<img src="${s}" alt="" onerror="this.parentElement.style.background='${brandColor(brand)}';this.parentElement.textContent='${brandMono(brand)}'">`;}
  else if(brand){lg.style.background=brandColor(brand);lg.style.color="#fff";lg.textContent=brandMono(brand);}
  else{lg.textContent="";}
}
async function setCurrent(sel){
  ALL_MODE=false;
  CURRENT={brand:sel.brand,model:sel.model||""};
  setHeaderBrand(CURRENT.brand,CURRENT.model);
  document.getElementById("brandSel").classList.add("switch");
  document.getElementById("hSub").textContent="Yuklanmoqda…";
  document.getElementById("msum").innerHTML=loadingHTML;document.getElementById("browseList").innerHTML="";
  try{const e=await getModelSet(CURRENT.brand,CURRENT.model);MODEL_CARS=e.cars;ST=e.stats;}
  catch(err){document.getElementById("browseList").innerHTML=errHTML("Yuklab bo'lmadi");document.getElementById("browseList").querySelector("[data-retry]").onclick=()=>setCurrent(sel);return;}
  renderMsum();renderBrowse();
  document.getElementById("hSub").innerHTML=`<b class="av">${ST.countAv}</b> mavjud · <b class="so">${ST.countSo}</b> sotilgan`;
}
async function showAll(){
  // Ko'rish feed: ALL cars, newest first (server orders active-first, posted desc),
  // no model selected. Sort/status chips still work; tap the brand selector to narrow.
  ALL_MODE=true;
  CURRENT={brand:null,model:""};
  document.getElementById("hLogo").textContent="";document.getElementById("hLogo").style.background="";
  document.getElementById("hTitle").textContent="Avto Bozor";
  document.getElementById("hSub").textContent="Yuklanmoqda…";
  document.getElementById("brandSel").classList.add("switch");
  document.getElementById("msum").innerHTML="";
  document.getElementById("browseList").innerHTML=loadingHTML;
  try{
    const r=await jget("/search?");
    MODEL_CARS=r.cars||[];
    MODEL_CARS.forEach(c=>byId[c.id]=Object.assign(byId[c.id]||{},c));
    document.getElementById("hSub").innerHTML=`<b class="av">${r.count??MODEL_CARS.length}</b> ta e'lon`;
  }catch(err){
    document.getElementById("browseList").innerHTML=errHTML("Yuklab bo'lmadi");
    const b=document.getElementById("browseList").querySelector("[data-retry]");if(b)b.onclick=showAll;return;
  }
  renderBrowse();
}
document.getElementById("sortRow").addEventListener("click",e=>{const b=e.target.closest("[data-sort]");if(b){SORT=b.dataset.sort;haptic('sel');renderBrowse();}});
document.getElementById("statusRow").addEventListener("click",e=>{const b=e.target.closest("[data-status]");if(b){STATUS=b.dataset.status;haptic('sel');renderBrowse();}});
bindList(document.getElementById("browseList"));
document.getElementById("brandSel").onclick=()=>{if(TAB==="browse")openPicker(sel=>{if(sel)setCurrent(sel);else showAll();},true);};

/* ---------- SEARCH ---------- */
let qFuel=new Set(),qStatus="all",searchTimer=null;
function renderSearchChips(){
  document.getElementById("qFuel").innerHTML=Object.entries(FUEL).map(([k,v])=>`<button class="chip ${qFuel.has(k)?"on":""}" data-qf="${k}">${v}</button>`).join("");
  document.getElementById("qStatus").innerHTML=STAT.map(([k,l])=>`<button class="chip ${qStatus===k?"on":""}" data-qs="${k}">${l}</button>`).join("");
}
const scheduleSearch=()=>{clearTimeout(searchTimer);searchTimer=setTimeout(runSearch,300);};
async function runSearch(){
  const p=new URLSearchParams();
  if(qModel){p.set("brand",qModel.brand);if(qModel.model)p.set("model",qModel.model);}
  const pm=numVal("qPrice");if(pm)p.set("price_max",pm);
  const mm=numVal("qMile");if(mm)p.set("mileage_max",mm);
  const yf=numVal("qYear");if(yf)p.set("year_from",yf);
  if(qFuel.size)p.set("fuel",[...qFuel].join(","));
  if(qStatus!=="all")p.set("status",qStatus);
  document.getElementById("searchList").innerHTML=loadingHTML;
  try{
    const r=await jget("/search?"+p.toString());
    (r.cars||[]).forEach(c=>byId[c.id]=Object.assign(byId[c.id]||{},c));
    document.getElementById("resCount").textContent=`${r.count} ta natija`;
    document.getElementById("searchList").innerHTML=r.cars.length?r.cars.map(c=>card(c,true)).join(""):`<div class="empty"><div class="e">🔍</div><h3>Hech narsa topilmadi</h3><p>Filtrlarni kengaytiring</p></div>`;
  }catch(e){document.getElementById("searchList").innerHTML=errHTML("Qidiruv ishlamadi");const b=document.getElementById("searchList").querySelector("[data-retry]");if(b)b.onclick=runSearch;}
}
["qPrice","qMile","qYear"].forEach(id=>document.getElementById(id).addEventListener("input",scheduleSearch));
document.getElementById("qFuel").addEventListener("click",e=>{const b=e.target.closest("[data-qf]");if(b){const k=b.dataset.qf;qFuel.has(k)?qFuel.delete(k):qFuel.add(k);haptic('sel');renderSearchChips();runSearch();}});
document.getElementById("qStatus").addEventListener("click",e=>{const b=e.target.closest("[data-qs]");if(b){qStatus=b.dataset.qs;haptic('sel');renderSearchChips();runSearch();}});
bindList(document.getElementById("searchList"));

/* ---------- FAVORITES ---------- */
async function renderFav(){
  const el=document.getElementById("favList");
  if(!UID){el.innerHTML=`<div class="empty"><div class="e">🤍</div><h3>Telegram orqali oching</h3><p>Sevimlilarni saqlash uchun ilovani Telegram'da oching</p></div>`;return;}
  el.innerHTML=loadingHTML;
  try{
    const r=await jget("/favorites?"+authQS());
    (r.cars||[]).forEach(c=>byId[c.id]=Object.assign(byId[c.id]||{},c));
    FAV.clear();(r.cars||[]).forEach(c=>FAV.add(c.id));updateFavBadge();
    el.innerHTML=r.cars.length?r.cars.map(c=>card(c,true)).join(""):`<div class="empty"><div class="e">🤍</div><h3>Sevimlilar bo'sh</h3><p>Yoqqan mashinalarni ❤ tugmasi bilan saqlang</p><button class="cta" data-goto="browse">Ko'rishni boshlash</button></div>`;
  }catch(e){el.innerHTML=errHTML("Yuklab bo'lmadi");const b=el.querySelector("[data-retry]");if(b)b.onclick=renderFav;}
}
bindList(document.getElementById("favList"));
document.getElementById("favList").addEventListener("click",e=>{const g=e.target.closest("[data-goto]");if(g)switchTab(g.dataset.goto);});
function updateFavBadge(){
  const btn=document.querySelector('.nav [data-tab="fav"]');let b=btn.querySelector(".badge");
  if(FAV.size){if(!b){b=document.createElement("span");b.className="badge";btn.appendChild(b);}b.textContent=FAV.size;}else if(b)b.remove();
}

/* ---------- ALERTS (server-backed) ---------- */
let aFuel=new Set();
function renderAlertChips(){document.getElementById("aFuel").innerHTML=Object.entries(FUEL).map(([k,v])=>`<button class="chip ${aFuel.has(k)?"on":""}" data-af="${k}">${v}</button>`).join("");}
document.getElementById("aFuel").addEventListener("click",e=>{const b=e.target.closest("[data-af]");if(b){const k=b.dataset.af;aFuel.has(k)?aFuel.delete(k):aFuel.add(k);haptic('sel');renderAlertChips();}});
document.getElementById("addAlert").onclick=async()=>{
  if(!UID){alert("Xabarnoma yaratish uchun ilovani Telegram'da oching");return;}
  const body={};
  if(aModelSel){body.brand=aModelSel.brand;if(aModelSel.model)body.model=aModelSel.model;}
  const pr=numVal("aPrice");if(pr)body.price_max=pr;
  const mm=numVal("aMile");if(mm)body.mileage_max=mm;
  const yf=numVal("aYear");if(yf)body.year_from=yf;
  if(aFuel.size)body.fuel=[...aFuel];
  const btn=document.getElementById("addAlert");btn.disabled=true;
  try{
    await jpost("/alerts",body);haptic('medium');
    document.getElementById("aPrice").value="";document.getElementById("aMile").value="";document.getElementById("aYear").value="";aFuel.clear();renderAlertChips();
    await renderAlerts();
  }catch(e){
    if(e.status===422)alert("Kamida bitta filtr tanlang (model, narx, yurgani, yil yoki yoqilg'i).");
    else if(e.status===409)alert(e.data&&e.data.error==="duplicate_alert"?"Bunday xabarnoma allaqachon mavjud.":"Xabarnomalar soni chegarasiga yetdingiz.");
    else alert("Xatolik yuz berdi. Qayta urinib ko'ring.");
  }finally{btn.disabled=false;}
};
function alertName(a){return a.brand?`${a.brand}${a.model?" "+a.model:""}`:"Har qanday model";}
async function renderAlerts(){
  const el=document.getElementById("alertList");
  if(!UID){el.innerHTML=`<div class="empty"><div class="e">🔔</div><h3>Telegram orqali oching</h3><p>Xabarnomalarni sozlash uchun ilovani Telegram'da oching</p></div>`;return;}
  el.innerHTML=loadingHTML;
  try{
    const r=await jget("/alerts?"+authQS());ALERTS=r.alerts||[];
    if(TAB==="alerts")document.getElementById("hSub").innerHTML=`${ALERTS.length} ta faol`;
    el.innerHTML=ALERTS.length?ALERTS.map(a=>{
      const cr=[];if(a.price_max)cr.push(`≤ ${won(a.price_max)}`);if(a.mileage_max)cr.push(`≤ ${km(a.mileage_max)}`);if(a.year_from)cr.push(`${a.year_from}+`);(a.fuel||[]).forEach(f=>cr.push(FUEL[f]||f));
      return`<div class="alert"><div class="ic"><svg viewBox="0 0 24 24"><path d="M18 8a6 6 0 00-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 01-3.4 0"/></svg></div>
       <div class="info"><div class="nm">${esc(alertName(a))}</div><div class="cr">${cr.length?cr.map(c=>`<span>${c}</span>`).join(""):"<span>Barcha e'lonlar</span>"}</div></div>
       <button class="del" data-del="${a.id}"><svg viewBox="0 0 24 24"><path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6"/></svg></button></div>`;
    }).join(""):`<div class="empty"><div class="e">🔔</div><h3>Xabarnoma yo'q</h3><p>Yangi mos e'lon chiqsa, sizga bildiramiz</p></div>`;
  }catch(e){el.innerHTML=errHTML("Yuklab bo'lmadi");const b=el.querySelector("[data-retry]");if(b)b.onclick=renderAlerts;}
}
document.getElementById("alertList").addEventListener("click",async e=>{const d=e.target.closest("[data-del]");if(d){haptic('light');try{await jdelete("/alerts/"+d.dataset.del+"?"+authQS());await renderAlerts();}catch(err){alert("O'chirib bo'lmadi");}}});

/* ---------- DETAIL ---------- */
let DCAR=null;
const viewsLabel=n=>`<svg viewBox="0 0 24 24"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z"/><circle cx="12" cy="12" r="3"/></svg>${n} marta ko'rilgan`;
function bumpViews(id){jpost("/car/"+id+"/view",{}).then(r=>{if(r&&r.views!=null){if(byId[id])byId[id].views=r.views;const el=document.getElementById("dViews");if(el)el.innerHTML=viewsLabel(r.views);}}).catch(()=>{});}
async function openDetail(id){
  markSeen(id);
  const det=document.getElementById("detail");
  document.getElementById("gallery").innerHTML="";
  document.getElementById("dbody").innerHTML=loadingHTML;
  document.getElementById("abar").className="abar hide";
  det.classList.add("on");det.scrollTo(0,0);document.getElementById("nav").classList.add("hide");
  syncBack();
  let c;
  try{c=(byId[id]&&byId[id].media)?byId[id]:await jget("/car?id="+id);byId[id]=c;}
  catch(e){document.getElementById("dbody").innerHTML=errHTML("E'lon yuklanmadi");return;}
  let st=emptyStats(),modelCars=[];
  try{const e=await getModelSet(c.brand,c.model);st=e.stats;modelCars=e.cars;}catch(_){}
  renderDetail(c,st,modelCars);
  bumpViews(c.id);
}
function closeDetail(){haptic("light");document.getElementById("detail").classList.remove("on");document.getElementById("nav").classList.remove("hide");syncBack();}
function renderDetail(c,st,modelCars){
  DCAR=c;
  const med=st.av.med,dc=dealClass(c.price_krw,med);
  const media=(c.media&&c.media.length)?c.media:[{type:"photo",url:null}];
  let slides="",dots="";media.forEach((m,i)=>{
    const base=m.thumb?`<img class="gthumb" src="${absUrl(m.thumb)}" onerror="this.remove()">`:phGradient(hueFromId(c.id));
    const inner=m.type==="video"
      ? `${base}<div class="playbadge"><svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg></div>`
      : `${base}${m.url?`<img class="gimg" src="${absUrl(m.url)}" onload="this.classList.add('on')" onerror="this.remove()">`:""}`;
    slides+=`<div class="slide" data-mi="${i}">${inner}</div>`;dots+=`<i class="${i?"":"on"}"></i>`;});
  document.getElementById("gallery").innerHTML=`<div class="strip" id="strip">${slides}</div>
   <div class="top"><button class="gbtn" id="dBack"><svg viewBox="0 0 24 24"><path d="M15 18l-6-6 6-6"/></svg></button>
    <button class="gbtn ${FAV.has(c.id)?"on":""}" id="dFav"><svg viewBox="0 0 24 24"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg></button></div>
   <div class="count" id="gCount">1 / ${media.length}</div><div class="dots" id="gDots">${dots}</div>`;
  const legal=c.legal_status==="legal"?"Legal":c.legal_status==="no_oformleniya"?"Oformleniyasiz":NA;
  const sr=(k,v)=>`<div class="r"><span class="k">${k}</span><span class="v">${v}</span></div>`;
  const rawtext=c.raw_text?esc(c.raw_text):"Matn keltirilmagan";
  const hasPhone=!!c.contact, hasHandle=!!c.contact_handle;
  document.getElementById("dbody").innerHTML=`
   <div class="dhead">
    <div class="t">${[c.year,c.brand,c.model,c.generation].filter(v=>v!=null&&v!=="").join(" ")||"E'lon"}</div>
    <div class="pr"><span class="p num ${c.price_krw==null?"noprice":""}" style="color:${c.price_krw==null?"var(--dim)":c.status==="sold"?"var(--sold)":dealColor(dc)}">${c.price_krw==null?"Narx keltirilmagan":won(c.price_krw)}</span>
     ${c.negotiable&&c.status!=="sold"?'<span class="tag neg">🤝 Kelishiladi</span>':''}${c.status==="sold"?'<span class="tag sold">Sotilgan</span>':''}</div>
    <div class="pills">${[c.year!=null?`📅 ${c.year}`:null,c.mileage_km!=null?km(c.mileage_km):null,c.fuel!=null?fuelLabel(c.fuel):null,c.transmission!=null?transLabel(c.transmission):null].filter(Boolean).map(x=>`<span class="pill">${x}</span>`).join("")||`<span class="pill" style="color:var(--dim)">${NA}</span>`}</div>
    <div class="dviews" id="dViews">${c.views?viewsLabel(c.views):""}</div>
   </div>
   <div class="notice"><span class="ni">ℹ️</span><span>Ma'lumotlar e'lon matnidan avtomatik o'qilgan va xato bo'lishi mumkin. Aniq narx va tafsilotlar uchun quyidagi <b>e'lon matnini</b> diqqat bilan o'qing.</span></div>
   <div class="sec" id="msgSec"><div class="h">E'lon matni</div>
    <div class="msgcard"><div class="msgtext" id="msgText">${rawtext}</div>
     <button class="morebtn" id="moreBtn" hidden>Ko'proq o'qish</button>
     <div class="msgsrc"><svg viewBox="0 0 24 24"><path d="M22 2L11 13M22 2l-7 20-4-9-9-4z"/></svg>Manba: ${esc(c.source_name||NA)} kanali</div></div></div>
   ${priceAnalysis(c,st,modelCars)}
   <div class="sec"><div class="h">Batafsil</div><div class="specgrid">
    ${sr("Avlod",na(c.generation))}${sr("Yili",na(c.year))}${sr("Yurgani",c.mileage_km!=null?c.mileage_km.toLocaleString("en-US").replace(/,/g," ")+" km":NA)}
    ${sr("Karobka",transLabel(c.transmission))}${sr("Yoqilg'i",fuelLabel(c.fuel))}${sr("Holati",legal)}
    ${sr("Nomiga o'tkazish",c.registration_required==null?NA:c.registration_required?"Shart":"Shart emas")}${sr("E'lon",na(c.posted_rel||c.posted_at))}${sr("Manba",na(c.source_name))}
   </div></div>
   ${(hasPhone||hasHandle)?`<div class="sec"><div class="h">Bog'lanish</div><div class="contactcard">
    ${hasPhone?`<div class="crow"><span class="cic">📞</span><span class="ctx"><b class="num">${esc(c.contact)}</b><span>Sotuvchi telefoni</span></span><button class="cbtn" id="cCall">Qo'ng'iroq</button><button class="cbtn ghost" id="cCopy">Nusxa</button></div>`:""}
    ${hasHandle?`<div class="crow"><span class="cic">✈️</span><span class="ctx"><b>@${esc(String(c.contact_handle).replace(/^@/,""))}</b><span>Telegram orqali yozish</span></span><button class="cbtn" id="cTg">Yozish</button></div>`:""}
   </div></div>`:""}
   <div class="sec"><div class="h">O'xshash mashinalar (narx bo'yicha)</div>${comparables(c,st,modelCars)}</div>`;
  const cLabel=hasPhone?"Bog'lanish":hasHandle?"Telegram orqali":"Raqam e'lon matnida";
  document.getElementById("abar").className="abar";
  document.getElementById("abar").innerHTML=`
   <button class="btn ghost ${FAV.has(c.id)?"on":""}" id="dFav2"><svg viewBox="0 0 24 24"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg></button>
   <button class="btn primary" id="callBtn">${hasPhone||hasHandle?'<svg viewBox="0 0 24 24"><path d="M22 16.9v3a2 2 0 01-2.2 2 19.8 19.8 0 01-8.6-3 19.5 19.5 0 01-6-6 19.8 19.8 0 01-3-8.6A2 2 0 014.1 2h3a2 2 0 012 1.7c.1 1 .4 1.9.7 2.8a2 2 0 01-.5 2.1L8.1 9.9a16 16 0 006 6l1.3-1.3a2 2 0 012.1-.4c.9.3 1.8.6 2.8.7a2 2 0 011.7 2z"/></svg>':'<svg viewBox="0 0 24 24"><path d="M4 5h16M4 12h16M4 19h10"/></svg>'}${cLabel}</button>`;
  const strip=document.getElementById("strip");
  strip.addEventListener("scroll",()=>{const i=Math.round(strip.scrollLeft/strip.clientWidth);document.getElementById("gCount").textContent=`${i+1} / ${media.length}`;[...document.getElementById("gDots").children].forEach((d,k)=>d.classList.toggle("on",k===i));},{passive:true});
  strip.querySelectorAll("[data-mi]").forEach(el=>el.addEventListener("click",()=>openViewer(c,+el.dataset.mi)));
  const mt=document.getElementById("msgText"),moreBtn=document.getElementById("moreBtn");
  if(mt.scrollHeight>170){mt.classList.add("clamp");moreBtn.hidden=false;moreBtn.onclick=()=>{const cl=mt.classList.toggle("clamp");moreBtn.textContent=cl?"Ko'proq o'qish":"Yopish";haptic('light');};}
  const togFav=()=>{const want=!FAV.has(c.id);haptic('sel');
    document.getElementById("dFav").classList.toggle("on",want);document.getElementById("dFav2").classList.toggle("on",want);
    persistFav(c.id,want).then(ok=>{if(!ok){document.getElementById("dFav").classList.toggle("on",!want);document.getElementById("dFav2").classList.toggle("on",!want);}});};
  document.getElementById("dFav").onclick=togFav;document.getElementById("dFav2").onclick=togFav;
  document.getElementById("dBack").onclick=closeDetail;
  document.getElementById("callBtn").onclick=()=>{haptic('medium');
    if(hasPhone){dialPhone(c.contact);}
    else if(hasHandle){openTgHandle(c.contact_handle);}
    else{const s=document.getElementById("msgSec");if(s){s.scrollIntoView({behavior:"smooth",block:"start"});const mc=s.querySelector(".msgcard");if(mc){mc.classList.add("flash");setTimeout(()=>mc.classList.remove("flash"),1600);}}}
  };
  const cCall=document.getElementById("cCall");if(cCall)cCall.onclick=()=>{haptic('medium');dialPhone(c.contact);};
  const cCopy=document.getElementById("cCopy");if(cCopy)cCopy.onclick=()=>{haptic('light');if(copyText(c.contact)){cCopy.textContent="Nusxalandi ✓";cCopy.classList.add("ok");setTimeout(()=>{cCopy.textContent="Nusxa";cCopy.classList.remove("ok");},1500);}};
  const cTg=document.getElementById("cTg");if(cTg)cTg.onclick=()=>{haptic('light');openTgHandle(c.contact_handle);};
  document.getElementById("dbody").querySelectorAll("[data-id]").forEach(el=>el.onclick=()=>{document.getElementById("detail").scrollTo(0,0);openDetail(+el.dataset.id);});
}
try{TG.BackButton.onClick(()=>{
  if(document.getElementById("viewer").classList.contains("on"))closeViewer();
  else if(document.getElementById("detail").classList.contains("on"))closeDetail();
  else if(TAB!=="browse")switchTab("browse");
});}catch(e){}

/* ---- stats markup ---- */
function priceAnalysis(c,st,modelCars){
  const av=st.av;
  if(!av.n)return"";                         // no comparable market at all
  const loc=localStats(c,modelCars),base=loc||av;   // year-local when ≥4 similar-year cars exist
  const med=base.med,compN=base.n,hasPrice=c.price_krw!=null,sold=c.status==="sold";
  // robust scale bounds (outliers trimmed), extended only to fit THIS car if it's the outlier
  const lo=Math.min(base.lo,hasPrice?c.price_krw:base.lo),hi=Math.max(base.hi,hasPrice?c.price_krw:base.hi),span=(hi-lo)||1;
  const diff=hasPrice&&med?Math.round((c.price_krw-med)/med*100):null;
  const pos=v=>Math.max(4,Math.min(96,((v-lo)/span)*100));

  // 1) one-line verdict — only for an on-sale car with enough comparables
  let verdict="";
  if(hasPrice&&!sold){
    if(compN>=3&&diff!=null){
      let cls,label;
      if(diff<=-12){cls="low";label="Juda arzon";}
      else if(diff<=-4){cls="low";label="Arzon";}
      else if(diff<4){cls="mid";label="Bozor narxida";}
      else if(diff<12){cls="high";label="Qimmatroq";}
      else{cls="high";label="Qimmat";}
      const sub=Math.abs(diff)<4?"o'rtachaga yaqin":`o'rtachadan <b>${Math.abs(diff)}% ${diff<0?"arzon":"qimmat"}</b>`;
      verdict=`<div class="pa-verdict ${cls}"><span class="pa-dot"></span><b>${label}</b><span>${sub}</span></div>`;
    }else{
      verdict=`<div class="pa-verdict mid"><span class="pa-dot"></span><b>Ma'lumot kam</b><span>faqat ${compN} ta taqqoslash bor</span></div>`;
    }
  }

  // 2) single price scale: cheapest -> priciest, with this car + average marked
  const pinCol=sold?"var(--sold)":dealColor(dealClass(c.price_krw,med));
  const pin=hasPrice?`<div class="pa-pin" style="left:${pos(c.price_krw)}%;--pc:${pinCol}"><b>${wonS(c.price_krw)}</b><i></i></div>`:"";
  const scale=`<div class="pa-scale"><div class="pa-bars">${pin}
    <div class="pa-track"><span class="pa-med" style="left:${pos(med)}%"></span></div></div>
    <div class="pa-ends"><span>arzon ${wonS(lo)}</span><span>qimmat ${wonS(hi)}</span></div></div>`;

  // 3) context line — make the comparison basis explicit (similar-year vs whole model)
  const basis=loc?`${c.year} y. atrofidagi <b>${compN}</b> ta · o'rtacha <b>${wonS(med)}</b>`:`<b>${st.countAv}</b> ta sotuvda · o'rtacha <b>${wonS(med)}</b>`;
  const ctx=`<div class="pa-ctx"><span>${basis}</span>${st.so.n?`<span><b>${st.countSo}</b> ta sotilgan${st.so.med!=null?` · ${wonS(st.so.med)}`:""}</span>`:""}</div>`;

  return`<div class="sec"><div class="h">Narx tahlili</div><div class="pa">${verdict}${scale}${ctx}</div></div>`;
}
function comparables(c,st,modelCars){
  const peers=(modelCars||[]).filter(x=>x.price_krw!=null&&x.id!==c.id).sort((a,b)=>a.price_krw-b.price_krw).slice(0,20);
  if(!peers.length)return`<div class="thin" style="padding:2px">Taqqoslash uchun e'lon yo'q</div>`;
  return`<div class="cmph">${peers.map(x=>{
    const col=x.status==="sold"?"var(--sold)":dealColor(dealClass(x.price_krw,st.av.med));
    const ph=x.thumb||x.photo;
    return`<div class="cmpc" data-id="${x.id}">
     <div class="cmpc-ph">${phGradient(hueFromId(x.id))}${ph?`<img src="${absUrl(ph)}" loading="lazy" onerror="this.remove()">`:""}${x.status==="sold"?`<span class="cmpc-badge">Sotilgan</span>`:""}</div>
     <div class="cmpc-p num"><span class="cmpc-dot" style="background:${col}"></span>${won(x.price_krw)}</div>
     <div class="cmpc-m">${x.year!=null?x.year:NA} · ${km(x.mileage_km)}</div></div>`;}).join("")}</div>`;
}

/* ---------- media viewer (zoom + real streaming video download) ---------- */
const viewer=document.getElementById("viewer"),vTrack=document.getElementById("vTrack");
const V={car:null,media:[],i:0,scale:1,tx:0,ty:0,pointers:new Map(),mode:null,startDist:0,startScale:1,startTx:0,startTy:0,focal:{x:0,y:0},panStart:null,swipeX:0,trackBase:0,lastTap:0,dl:{}};
const vW=()=>viewer.clientWidth||window.innerWidth, vH=()=>viewer.clientHeight||window.innerHeight;
const vCur=()=>V.media[V.i], vDist=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y), clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
function vPhotoHTML(c,m,k){
  const blur=m.thumb?`<img class="vblur" src="${absUrl(m.thumb)}" aria-hidden="true">`:phGradient(hueFromId(c.id));
  const full=m.url?`<img class="vimg" src="${absUrl(m.url)}" draggable="false" onload="this.classList.add('on')">`:"";
  return`<div class="vzoom" id="vz${k}"><div class="pic">${blur}${full}</div></div>`;
}
function vVideoHTML(c,m,k){
  const poster=`<div class="vposter">${m.thumb?`<img class="vblur" src="${absUrl(m.thumb)}" aria-hidden="true">`:phGradient(hueFromId(c.id))}</div>`;
  if(!m.url)return`<div class="vvideo" id="vv${k}">${poster}<div class="vplaying">Video mavjud emas</div></div>`;
  return`<div class="vvideo" id="vv${k}">${poster}
    <button class="vplay" id="vload${k}" title="Yuklab olish"><svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg></button>
    ${m.size_bytes?`<div class="vsize" id="vsize${k}">${mb(m.size_bytes)} MB</div>`:""}
    <div class="vdl" id="vdl${k}" hidden><div class="spin"></div><div class="vdltext" id="vdlt${k}">0.0 / ${m.size_bytes?mb(m.size_bytes):"?"} MB</div>
     <div class="vbar"><i id="vbi${k}"></i></div><div class="vsub" id="vsub${k}">Yuklab olinmoqda…</div></div>
  </div>`;
}
function startVideoLoad(k){
  const lb=document.getElementById("vload"+k),sz=document.getElementById("vsize"+k),dl=document.getElementById("vdl"+k);
  if(lb)lb.hidden=true;if(sz)sz.hidden=true;if(dl)dl.hidden=false;
  maybeStartVideo(k);
}
function openViewer(car,idx){
  V.car=car;V.media=(car.media&&car.media.length)?car.media:[{type:"photo",url:null}];V.i=idx||0;V.scale=1;V.tx=0;V.ty=0;V.pointers.clear();V.mode=null;
  Object.values(V.dl).forEach(t=>t&&t.abort&&t.abort());V.dl={};V.media.forEach(m=>{m._loading=false;});
  vTrack.innerHTML=V.media.map((m,k)=>`<div class="vslide">${m.type==="video"?vVideoHTML(car,m,k):vPhotoHTML(car,m,k)}</div>`).join("");
  vTrack.classList.remove("anim");setTrackX(-V.i*vW());
  document.getElementById("vCount").textContent=`${V.i+1} / ${V.media.length}`;
  viewer.classList.add("on");
  V.media.forEach((m,k)=>{const lb=document.getElementById("vload"+k);if(lb)lb.onclick=()=>(m._done&&m._url)?playVideo(k):startVideoLoad(k);});
  syncBack();
}
function stopAllVideos(){if(vTrack)vTrack.querySelectorAll("video").forEach(v=>{try{v.pause();}catch(e){}});}
function closeViewer(){stopAllVideos();viewer.classList.remove("on");Object.values(V.dl).forEach(t=>t&&t.abort&&t.abort());V.dl={};syncBack();}
document.getElementById("vClose").onclick=closeViewer;
const setTrackX=px=>{vTrack.style.transform=`translateX(${px}px)`;};
function applyZoom(){const z=document.getElementById("vz"+V.i);if(z)z.style.transform=`translate(${V.tx}px,${V.ty}px) scale(${V.scale})`;}
function clampPan(){const mx=(V.scale-1)*vW()/2,my=(V.scale-1)*vH()/2;V.tx=clamp(V.tx,-mx,mx);V.ty=clamp(V.ty,-my,my);}
function zAnim(on){const z=document.getElementById("vz"+V.i);if(z)z.classList.toggle("anim",on);}
function resetZoom(a){V.scale=1;V.tx=0;V.ty=0;if(a)zAnim(true);applyZoom();if(a)setTimeout(()=>zAnim(false),280);}
function goSlide(i){i=clamp(i,0,V.media.length-1);const changed=i!==V.i;stopAllVideos();V.i=i;V.scale=1;V.tx=0;V.ty=0;
  vTrack.classList.add("anim");setTrackX(-V.i*vW());applyZoom();
  document.getElementById("vCount").textContent=`${V.i+1} / ${V.media.length}`;
  setTimeout(()=>vTrack.classList.remove("anim"),300);
}
viewer.addEventListener("pointerdown",e=>{
  viewer.setPointerCapture?.(e.pointerId);V.pointers.set(e.pointerId,{x:e.clientX,y:e.clientY});const cur=vCur();
  if(V.pointers.size===2&&cur.type==="photo"){const[a,b]=[...V.pointers.values()];V.startDist=vDist(a,b)||1;V.startScale=V.scale;V.startTx=V.tx;V.startTy=V.ty;V.focal={x:(a.x+b.x)/2,y:(a.y+b.y)/2};V.mode="pinch";zAnim(false);}
  else if(V.pointers.size===1){
    if(cur.type==="photo"){const now=Date.now();if(now-V.lastTap<280){doubleTap(e);V.lastTap=0;V.mode=null;return;}V.lastTap=now;}
    V.panStart={x:e.clientX,y:e.clientY,tx:V.tx,ty:V.ty};V.swipeX=e.clientX;V.trackBase=-V.i*vW();V.mode=(cur.type==="photo"&&V.scale>1)?"pan":"swipe";vTrack.classList.remove("anim");}
});
viewer.addEventListener("pointermove",e=>{
  if(!V.pointers.has(e.pointerId))return;V.pointers.set(e.pointerId,{x:e.clientX,y:e.clientY});
  if(V.mode==="pinch"&&V.pointers.size>=2){const[a,b]=[...V.pointers.values()];const scale=clamp(V.startScale*vDist(a,b)/V.startDist,1,5);
    const cx=vW()/2,cy=vH()/2,fx=(V.focal.x-cx-V.startTx)/V.startScale,fy=(V.focal.y-cy-V.startTy)/V.startScale;
    V.scale=scale;V.tx=V.startTx-fx*(scale-V.startScale);V.ty=V.startTy-fy*(scale-V.startScale);clampPan();applyZoom();}
  else if(V.mode==="pan"&&V.panStart){V.tx=V.panStart.tx+(e.clientX-V.panStart.x);V.ty=V.panStart.ty+(e.clientY-V.panStart.y);clampPan();applyZoom();}
  else if(V.mode==="swipe"){let dx=e.clientX-V.swipeX;if((V.i===0&&dx>0)||(V.i===V.media.length-1&&dx<0))dx*=0.35;setTrackX(V.trackBase+dx);}
});
function endPointer(e){
  V.pointers.delete(e.pointerId);
  if(V.mode==="pinch"){if(V.pointers.size<2){if(V.scale<1.03)resetZoom(true);V.mode=V.scale>1&&V.pointers.size===1?"pan":null;if(V.mode==="pan"){const p=[...V.pointers.values()][0];V.panStart={x:p.x,y:p.y,tx:V.tx,ty:V.ty};}}return;}
  if(V.mode==="swipe"&&V.pointers.size===0){const dx=e.clientX-V.swipeX,th=vW()*0.18;if(dx<=-th)goSlide(V.i+1);else if(dx>=th)goSlide(V.i-1);else goSlide(V.i);V.mode=null;return;}
  if(V.pointers.size===0)V.mode=null;
}
viewer.addEventListener("pointerup",endPointer);viewer.addEventListener("pointercancel",endPointer);
function doubleTap(e){const cx=vW()/2,cy=vH()/2;if(V.scale>1.05){V.scale=1;V.tx=0;V.ty=0;}else{V.scale=2.6;V.tx=-(e.clientX-cx)*(V.scale-1);V.ty=-(e.clientY-cy)*(V.scale-1);clampPan();}zAnim(true);applyZoom();setTimeout(()=>zAnim(false),270);}
async function maybeStartVideo(i){
  const m=V.media[i];if(!m||m.type!=="video"||!m.url||m._done||m._loading)return;m._loading=true;
  const bi=document.getElementById("vbi"+i),txt=document.getElementById("vdlt"+i);
  try{
    const ctrl=new AbortController();V.dl[i]=ctrl;
    const resp=await fetch(absUrl(m.url),{signal:ctrl.signal});if(!resp.ok)throw new Error("HTTP "+resp.status);
    const total=+resp.headers.get("Content-Length")||m.size_bytes||0;
    if(resp.body&&resp.body.getReader){
      const reader=resp.body.getReader();let loaded=0;const chunks=[];
      while(true){const{done,value}=await reader.read();if(done)break;chunks.push(value);loaded+=value.length;
        if(bi&&total)bi.style.width=(loaded/total*100)+"%";
        if(txt)txt.textContent=`${mb(loaded)} / ${total?mb(total):"?"} MB${total?" · "+Math.round(loaded/total*100)+"%":""}`;}
      m._url=URL.createObjectURL(new Blob(chunks,{type:resp.headers.get("Content-Type")||"video/mp4"}));
    }else{m._url=m.url;} // streaming unsupported -> play directly
    m._done=true;m._loading=false;delete V.dl[i];
    playVideo(i);  // download done -> play immediately
  }catch(e){
    if(e.name==="AbortError"){m._loading=false;return;}
    m._loading=false;delete V.dl[i];
    const sub=document.getElementById("vsub"+i),dl=document.getElementById("vdl"+i);
    if(sub)sub.textContent="Xatolik — qayta urinish uchun bosing";
    if(dl)dl.onclick=()=>{dl.onclick=null;maybeStartVideo(i);};
  }
}
function playVideo(k){
  const vv=document.getElementById("vv"+k),m=V.media[k];if(!vv||!m||!m._url)return;
  const existing=vv.querySelector("video");if(existing){existing.play&&existing.play().catch(()=>{});return;}
  ["vdl"+k,"vload"+k,"vsize"+k].forEach(id=>{const el=document.getElementById(id);if(el)el.hidden=true;});
  const pos=vv.querySelector(".vposter");if(pos)pos.style.display="none";
  const v=document.createElement("video");v.className="vvid";v.src=m._url;v.controls=true;v.autoplay=true;v.playsInline=true;
  v.style.cssText="position:absolute;inset:0;width:100%;height:100%;object-fit:contain;z-index:3;background:#000";
  vv.appendChild(v);
  v.play&&v.play().catch(()=>{});
}

/* ---------- brand → model picker ---------- */
let pickerCB=null,pickerBrand=null,pfQuery="",pickerAny=false;
const sheet=document.getElementById("sheet"),sheetBack=document.getElementById("sheetBack");
function openPicker(cb,allowAny){pickerCB=cb;pickerAny=!!allowAny;pickerBrand=null;pfQuery="";document.getElementById("sheetSearch").value="";renderPicker();sheetBack.classList.add("on");sheet.classList.add("on");haptic('light');}
function clearPickField(icId,txId,fieldId,placeholder){
  const ic=document.getElementById(icId);ic.classList.remove("haslogo");ic.style.background="var(--accent)";ic.textContent="🚗";
  const tx=document.getElementById(txId);tx.textContent=placeholder;tx.classList.remove("has");
  document.getElementById(fieldId).classList.remove("has");
}
function closePicker(){sheet.classList.remove("on");sheetBack.classList.remove("on");}
function renderPicker(){
  const cont=document.getElementById("sheetCont"),bk=document.getElementById("sheetBk"),q=pfQuery.trim().toLowerCase();
  if(!pickerBrand){
    document.getElementById("sheetTitle").textContent="Markani tanlang";bk.hidden=true;
    const items=CATALOG.filter(b=>!q||b.brand.toLowerCase().includes(q));
    const anyCard=pickerAny&&!q?`<div class="brandcard" data-any="1"><div class="logo" style="background:var(--accent)"><svg viewBox="0 0 24 24" style="width:26px;height:26px;fill:none;stroke:#fff;stroke-width:2"><path d="M3 6h18M3 12h18M3 18h18"/></svg></div><div class="bn">Har qanday</div><div class="bc">barcha markalar</div></div>`:"";
    cont.innerHTML=items.length||anyCard?`<div class="brandgrid">`+anyCard+items.map(b=>`<div class="brandcard" data-brand="${esc(b.brand)}">${brandIcon(b.brand)}<div class="bn">${esc(b.brand)}</div><div class="bc">${b.total} e'lon</div></div>`).join("")+`</div>`:`<div class="thin">Hech narsa topilmadi</div>`;
  }else{
    const b=CATALOG.find(x=>x.brand===pickerBrand);
    document.getElementById("sheetTitle").textContent=b.brand;bk.hidden=false;
    const items=b.models.filter(m=>!q||m.model.toLowerCase().includes(q));
    cont.innerHTML=`<div class="modelrow allrow" data-model="*">${brandIcon(b.brand)}<div class="mn">Barcha ${esc(b.brand)}</div><div class="mc">${b.total}</div><span class="cv">›</span></div>`
     +items.map(m=>`<div class="modelrow" data-model="${esc(m.model)}">${brandIcon(b.brand)}<div class="mn">${esc(m.model)}</div><div class="mc">${m.count} e'lon</div><span class="cv">›</span></div>`).join("");
  }
}
document.getElementById("sheetCont").addEventListener("click",e=>{
  const any=e.target.closest("[data-any]");if(any){pickerCB&&pickerCB(null);haptic('light');closePicker();return;}
  const br=e.target.closest("[data-brand]");if(br){pickerBrand=br.dataset.brand;pfQuery="";document.getElementById("sheetSearch").value="";renderPicker();haptic('sel');return;}
  const md=e.target.closest("[data-model]");if(md){const model=md.dataset.model==="*"?"":md.dataset.model;pickerCB&&pickerCB({brand:pickerBrand,model});haptic('light');closePicker();}
});
document.getElementById("sheetSearch").addEventListener("input",e=>{pfQuery=e.target.value;renderPicker();});
document.getElementById("sheetBk").onclick=()=>{pickerBrand=null;pfQuery="";document.getElementById("sheetSearch").value="";renderPicker();haptic('light');};
document.getElementById("sheetClose").onclick=closePicker;sheetBack.onclick=closePicker;
function setPickField(icId,txId,fieldId,sel){
  const ic=document.getElementById(icId),s=logoSrc(sel.brand);
  if(s){ic.textContent="";ic.classList.add("haslogo");ic.style.background="#fff center/72% no-repeat url('"+s+"')";}
  else{ic.classList.remove("haslogo");ic.textContent=brandMono(sel.brand);ic.style.background=brandColor(sel.brand);}
  document.getElementById(txId).textContent=sel.model?`${sel.brand} ${sel.model}`:`Barcha ${sel.brand}`;
  document.getElementById(txId).classList.add("has");document.getElementById(fieldId).classList.add("has");
}
document.getElementById("qModelField").onclick=()=>openPicker(sel=>{qModel=sel;if(sel)setPickField("qModelIc","qModelTxt","qModelField",sel);else clearPickField("qModelIc","qModelTxt","qModelField","Marka va modelni tanlang");runSearch();},true);
document.getElementById("aModelField").onclick=()=>openPicker(sel=>{aModelSel=sel;if(sel)setPickField("aModelIc","aModelTxt","aModelField",sel);else clearPickField("aModelIc","aModelTxt","aModelField","Barcha mashinalar");},true);

/* ---------- tabs ---------- */
function switchTab(tab){
  if(document.getElementById("detail").classList.contains("on"))closeDetail();
  TAB=tab;haptic('sel');
  document.querySelectorAll(".nav button").forEach(b=>b.classList.toggle("on",b.dataset.tab===tab));
  ["browse","search","sell","fav","alerts"].forEach(t=>document.getElementById("pg"+t[0].toUpperCase()+t.slice(1)).classList.toggle("on",t===tab));
  if(tab==="browse"){
    if(ALL_MODE){
      document.getElementById("hLogo").textContent="";document.getElementById("hLogo").style.background="";
      document.getElementById("hTitle").textContent="Avto Bozor";
      document.getElementById("hSub").innerHTML=`<b class="av">${MODEL_CARS.length}</b> ta e'lon`;
    }else{
      setHeaderBrand(CURRENT.brand,CURRENT.model);
      document.getElementById("hSub").innerHTML=ST?`<b class="av">${ST.countAv}</b> mavjud · <b class="so">${ST.countSo}</b> sotilgan`:"";
    }
    document.getElementById("brandSel").classList.add("switch");
  }else{
    const t={search:["Qidirish","Atributlar bo'yicha toping"],sell:["Sotish","O'z e'loningizni joylang"],
      fav:["Sevimlilar",`${FAV.size} ta saqlangan`],alerts:["Xabarnomalar",`${ALERTS.length} ta faol`]}[tab];
    document.getElementById("hLogo").textContent="";document.getElementById("hLogo").style.background="";
    document.getElementById("hTitle").textContent=t[0];document.getElementById("hSub").textContent=t[1];
    document.getElementById("brandSel").classList.remove("switch");
  }
  if(tab==="fav")renderFav();if(tab==="alerts")renderAlerts();if(tab==="search"&&!document.getElementById("searchList").children.length)runSearch();
  syncBack();
  window.scrollTo(0,0);
}
function syncBack(){
  const show=document.getElementById("viewer").classList.contains("on")
    ||document.getElementById("detail").classList.contains("on")||TAB!=="browse";
  try{show?TG.BackButton.show():TG.BackButton.hide();}catch(e){}
}
document.getElementById("nav").addEventListener("click",e=>{const b=e.target.closest("[data-tab]");if(!b)return;if(b.dataset.tab==="sell"){ try{sessionStorage.setItem("cars_back","1")}catch(e){} location.href="sell.html"; return; }switchTab(b.dataset.tab);});

/* ---------- theme ---------- */
let dark=(()=>{try{const t=localStorage.getItem("cars_theme");if(t)return t==="dark";}catch(e){}return false;})();
const applyTheme=()=>document.documentElement.setAttribute("data-theme",dark?"dark":"light");
document.getElementById("themeBtn").onclick=()=>{dark=!dark;applyTheme();try{localStorage.setItem("cars_theme",dark?"dark":"light");}catch(e){}haptic('sel');};

/* ---------- init ---------- */
function resolveSlug(sp){
  if(!sp) return null;
  for(const b of CATALOG) for(const m of b.models) if(modelSlug(b.brand,m.model)===sp) return {brand:b.brand,model:m.model};
  // bare-brand slug (e.g. "Volvo", "BMW" from a no-model relay button) -> that brand's first model
  for(const b of CATALOG) if(slugify(b.brand)===sp && b.models.length) return {brand:b.brand,model:b.models[0].model};
  return null;
}
function firstModel(){if(CATALOG.length&&CATALOG[0].models.length)return{brand:CATALOG[0].brand,model:CATALOG[0].models[0].model};return null;}
async function init(){
  logOpen();
  applyTheme();renderSearchChips();renderAlertChips();
  try{CATALOG=await jget("/catalog");}catch(e){CATALOG=[];}
  if(UID){try{const r=await jget("/favorites/ids?"+authQS());(r.ids||[]).forEach(id=>FAV.add(id));updateFavBadge();}catch(e){}}
  const sp=(TG.initDataUnsafe&&TG.initDataUnsafe.start_param)||new URLSearchParams(location.search).get("startapp")||"";
  const carm=sp.match(/^car(\d+)$/);
  if(carm){const id=+carm[1];
    try{const c=await jget("/car?id="+id);byId[id]=c;await setCurrent({brand:c.brand,model:c.model});switchTab("browse");openDetail(id);return;}
    catch(e){/* fall through to normal entry */}
  }
  const target=resolveSlug(sp);
  if(target){
    aModelSel=target;setPickField("aModelIc","aModelTxt","aModelField",target);
    await setCurrent(target);
  }else{
    // Main-menu open (no model deep-link): Ko'rish shows ALL cars, newest first.
    await showAll();
  }
  switchTab("browse");
}
init();
