/* ============================================================
   Avto Bozor — E'lon berish (user post-creation), user side only.
   Talks to /api/cars (car_api.py). Admin/approval lives elsewhere.
   ============================================================ */
const API = (window.CARS_API_BASE || "/api/cars");
// Mark that we're on the sell page — when the user goes back to cars.html,
// app.js logOpen() sees this and skips re-logging the 'cars' open.
try{ sessionStorage.setItem("cars_back", "1"); }catch(e){}
const API_ORIGIN = new URL(API, location.href).origin;
const absUrl = u => (u && u[0] === "/") ? API_ORIGIN + u : u;
const UID   = (window.Telegram?.WebApp?.initDataUnsafe?.user?.id) || new URLSearchParams(location.search).get("uid") || null;
const UNAME = window.Telegram?.WebApp?.initDataUnsafe?.user?.username || null;
const INIT_DATA = window.Telegram?.WebApp?.initData || "";

/* ---------- Telegram ---------- */
const TG = window.Telegram?.WebApp || {ready(){},expand(){},disableVerticalSwipes(){},initDataUnsafe:{},
  BackButton:{show(){},hide(){},onClick(cb){this._cb=cb}},HapticFeedback:{impactOccurred(){},selectionChanged(){},notificationOccurred(){}}};
TG.ready?.(); TG.expand?.(); TG.disableVerticalSwipes?.();
/* theme follows the marketplace choice (localStorage cars_theme), applied by the inline bootstrap in <head> */
const haptic=(t="light")=>{try{t==="sel"?TG.HapticFeedback.selectionChanged():t==="ok"?TG.HapticFeedback.notificationOccurred("success"):t==="err"?TG.HapticFeedback.notificationOccurred("error"):TG.HapticFeedback.impactOccurred(t);}catch(e){}};

/* ---------- API ---------- */
const authBody = extra => Object.assign({telegram_user_id:UID, telegram_username:UNAME, init_data:INIT_DATA}, extra||{});
async function jget(path){const r=await fetch(API+path,{headers:{Accept:"application/json"}});if(!r.ok)throw new Error("HTTP "+r.status);return r.json();}
async function jsend(path, method, body){
  const r=await fetch(API+path,{method,headers:{"Content-Type":"application/json",Accept:"application/json"},body:JSON.stringify(authBody(body))});
  const d=await r.json().catch(()=>({})); if(!r.ok) throw Object.assign(new Error("HTTP "+r.status),{status:r.status,data:d}); return d;
}
const jpost  = (p,b)=>jsend(p,"POST",b);
const jpatch = (p,b)=>jsend(p,"PATCH",b);
async function jdelete(path){const r=await fetch(API+path+"?"+new URLSearchParams({telegram_user_id:UID||"",init_data:INIT_DATA}),{method:"DELETE",headers:{Accept:"application/json"}});const d=await r.json().catch(()=>({}));if(!r.ok)throw Object.assign(new Error("HTTP "+r.status),{status:r.status,data:d});return d;}
function uploadMedia(listingId, item, onProgress){
  return new Promise((resolve,reject)=>{
    const fd=new FormData();
    fd.append("telegram_user_id", UID||""); fd.append("init_data", INIT_DATA||"");
    fd.append("ord", String(item.ord)); fd.append("media_type", item.type);
    fd.append("file", item.blob, item.name);
    const x=new XMLHttpRequest(); x.open("POST", API+"/listings/"+listingId+"/media");
    x.upload.onprogress=e=>{ if(e.lengthComputable&&onProgress) onProgress(e.loaded/e.total); };
    x.onload=()=>{ if(x.status>=200&&x.status<300){ try{resolve(JSON.parse(x.responseText));}catch(_){resolve({});} } else { let d={};try{d=JSON.parse(x.responseText);}catch(_){} reject(Object.assign(new Error("HTTP "+x.status),{data:d})); } };
    x.onerror=()=>reject(new Error("network"));
    x.send(fd);
  });
}

/* ---------- brand assets (mirror marketplace) ---------- */
const BRAND_COLOR={Hyundai:"#0b2c5e",Kia:"#bb162b",Chevrolet:"#c9971c",Genesis:"#1c1c22",Samsung:"#1428a0",SsangYong:"#c8102e",Renault:"#f5a623",Daewoo:"#0b5fa5",Toyota:"#eb0a1e",BMW:"#16588e",Nissan:"#c3002f"};
const BRAND_LOGO={Hyundai:"hyundai",Chevrolet:"chevrolet",Kia:"kia",BMW:"bmw",Genesis:"genesis",Audi:"audi",Infiniti:"infiniti",Jaguar:"jaguar",SsangYong:"ssangyong","Samsung/Renault":"samsung",Mercedes:"mercedes-benz",Volvo:"volvo",Honda:"honda",Toyota:"toyota",Volkswagen:"volkswagen",Lexus:"lexus", Daewoo:"daewoo", Nissan:"nissan"};
const brandColor=b=>BRAND_COLOR[b]||"#41506a";
const brandMono =b=>((b||"?").trim()[0]||"?").toUpperCase();
const logoSrc   =b=>BRAND_LOGO[b]?`logo/${BRAND_LOGO[b]}-logo.png`:null;
const ALL_BRANDS=[...new Set([...Object.keys(BRAND_LOGO),"Hyundai","Kia","Chevrolet","Genesis","Samsung/Renault","SsangYong","Daewoo","BMW","Mercedes","Audi","Volkswagen","Toyota","Honda","Lexus","Nissan","Volvo","Jaguar","Infiniti"])];

/* ---------- option sets (selectable, not free text) ---------- */
const TRANS=[["automatic","Avtomat"],["manual","Mexanika"]];
const FUEL =[["petrol","Benzin"],["diesel","Dizel"],["lpg","LPG"],["hybrid","Gibrid"]];
const LEGAL=[["legal","Legal"],["nolegal","Nolegal"]];
const REG  =[["1","Ha, kerak"],["0","Shart emas"]];
const NOW=new Date().getFullYear();
const YEARS=[]; for(let y=NOW+1;y>=1990;y--) YEARS.push(y);

/* ---------- helpers ---------- */
const $=id=>document.getElementById(id);
const esc=s=>(s||"").replace(/[&<>"]/g,m=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[m]));
const won=v=>v==null?"—":Number(v).toLocaleString("en-US").replace(/,/g," ")+" ₩";
const group=s=>{s=(s||"").replace(/\D/g,"");return s?Number(s).toLocaleString("en-US").replace(/,/g," "):"";};
const digits=s=>(s||"").replace(/\D/g,"");
const transLabel=v=>(TRANS.find(x=>x[0]===v)||[])[1]||"";
const fuelLabel =v=>(FUEL.find(x=>x[0]===v)||[])[1]||"";
const uid=()=>Math.random().toString(36).slice(2,9);
let toastT; function toast(msg){const t=$("toast");t.textContent=msg;t.classList.add("on");clearTimeout(toastT);toastT=setTimeout(()=>t.classList.remove("on"),2600);}

/* ---------- state ---------- */
let CATALOG=[];          // [{brand, models:[{model}]}]
let MYLIST=[];           // user's listings
let DRAFT=null;          // current form model
let FORCE=false;         // submit despite duplicate
let BUSY=false;

/* ============================================================
   MY LISTINGS
   ============================================================ */
async function loadList(){
  try{ MYLIST=await jget("/my/listings?"+new URLSearchParams({telegram_user_id:UID||"",init_data:INIT_DATA})); }
  catch(e){ MYLIST=[]; }
  renderList();
}
const STATUS_BADGE={pending:["pending","Ko'rib chiqilmoqda"],approved:["approved","Joylandi"],rejected:["rejected","Rad etildi"],changes_requested:["changes","O'zgartirish kerak"],draft:["pending","Qoralama"]};
function badgeFor(l){
  if(l.status==="sold") return ['sold',"Sotilgan"];
  return STATUS_BADGE[l.moderation_status]||["pending",l.moderation_status||"—"];
}
function renderList(){
  const box=$("myList");
  if(!MYLIST.length){
    box.innerHTML=`<div class="empty">
      <div class="ic"><svg viewBox="0 0 24 24"><path d="M3 13l2-5a2 2 0 012-1h10a2 2 0 012 1l2 5"/><path d="M5 13h14v5a1 1 0 01-1 1h-1a2 2 0 01-4 0H10a2 2 0 01-4 0H5a1 1 0 01-1-1z"/><circle cx="7.5" cy="17" r="1.4"/><circle cx="16.5" cy="17" r="1.4"/></svg></div>
      <h3>Hali e'lon yo'q</h3><p>Yuqoridagi tugma orqali birinchi e'loningizni joylang — bir necha daqiqada tayyor bo'ladi.</p></div>`;
    return;
  }
  box.innerHTML=MYLIST.map(l=>{
    const [bc,bl]=badgeFor(l);
    const title=`${esc(l.brand||"")} ${esc(l.model||"")}${l.year?` · ${l.year}`:""}`;
    const thumb=l.thumb?`<img src="${absUrl(l.thumb)}" alt="" onerror="this.style.display='none';this.parentElement.innerHTML=NOIMG">`:NOIMG;
    const canEdit=l.status!=="sold";
    const canSold=l.status==="active"&&l.moderation_status==="approved";
    const note=l.moderation_status==="rejected"&&l.review_note?`<div class="note bad"><span class="ni">⚠️</span><span>${esc(l.review_note)}</span></div>`:
               l.moderation_status==="changes_requested"&&l.review_note?`<div class="note"><span class="ni">✏️</span><span>${esc(l.review_note)}</span></div>`:"";
    return `<div class="mycard" data-id="${l.id}">
      <div class="ph">${thumb}</div>
      <div class="bd">
        <span class="statusbadge ${bc}">${bl}</span>
        <div class="tt">${title}</div>
        <div class="pr num">${l.price_krw!=null?won(l.price_krw):"Kelishiladi"}</div>
        <div class="meta">${l.mileage_km!=null?group(String(l.mileage_km))+" km":""}${l.fuel?` · ${fuelLabel(l.fuel)}`:""}${l.views?` · 👁 ${l.views}`:""}</div>
        <div class="acts">
          ${canEdit?`<button class="mini" data-act="edit">Tahrirlash</button>`:""}
          ${canSold?`<button class="mini sold" data-act="sold">Sotildi</button>`:""}
          <button class="mini del" data-act="del">O'chirish</button>
        </div>
      </div>
      ${note?`<div style="flex-basis:100%">${note}</div>`:""}
    </div>`;
  }).join("");
}
const NOIMG=`<div class="noimg"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="8.5" cy="10" r="1.5"/><path d="M21 16l-5-5-7 7"/></svg></div>`;

$("myList").addEventListener("click", async e=>{
  const card=e.target.closest(".mycard"); if(!card) return;
  const id=+card.dataset.id, act=e.target.closest("[data-act]")?.dataset.act;
  const l=MYLIST.find(x=>x.id===id); if(!l) return;
  if(act==="edit") return openForm(l);
  if(act==="sold") return confirmModal("warn","Sotildi deb belgilash?","E'lon bozorda sotilgan sifatida ko'rsatiladi.","Ha, sotildi", async()=>{
    try{ await jpost("/listings/"+id+"/sold",{}); haptic("ok"); toast("Sotilgan deb belgilandi"); await loadList(); }catch(err){ toast("Xatolik"); }
  });
  if(act==="del") return confirmModal("bad","E'lonni o'chirish?","Bu amalni qaytarib bo'lmaydi.","O'chirish", async()=>{
    try{ await jdelete("/listings/"+id); haptic("ok"); toast("O'chirildi"); await loadList(); }catch(err){ toast("Xatolik"); }
  });
});

/* ============================================================
   FORM
   ============================================================ */
function blankDraft(){return {id:null,editing:false,brand:"",model:"",generation:"",year:null,mileage:null,
  transmission:"",fuel:"",price:null,negotiable:false,legal:"",registration:"",
  phone:"",telegram:UNAME?("@"+UNAME):"",desc:"",media:[]};}

function openForm(listing){
  FORCE=false;
  if(listing){
    DRAFT={id:listing.id,editing:true,brand:listing.brand||"",model:listing.model||"",generation:listing.generation||"",
      year:listing.year||null,mileage:listing.mileage_km??null,transmission:listing.transmission||"",fuel:listing.fuel||"",
      price:listing.price_krw??null,negotiable:!!listing.negotiable,
      legal:listing.legal_status||"",registration:listing.registration_required==null?"":String(listing.registration_required?1:0),
      phone:listing.contact_phone||listing.contact_norm||"",telegram:listing.contact_handle?("@"+String(listing.contact_handle).replace(/^@/,"")):"",
      desc:listing.raw_text||"",media:(listing.media||[]).map(m=>({key:uid(),type:m.media_type==="video"?"video":"photo",url:absUrl(m.thumb||m.url||m.local_path),serverMid:m.id,locked:true,ord:m.ord||0}))};
  }else{
    DRAFT=blankDraft();
  }
  renderForm();
  showForm();
}

function selectField(id,value,placeholder,withLogo){
  const empty=!value;
  return `<div class="selectfield ${withLogo&&value?'':''}" id="${id}">
    ${withLogo?`<span class="sf-logo" id="${id}_logo" ${value?"":'style="display:none"'}></span>`:""}
    <span class="sf-tx ${empty?'ph':''}" id="${id}_tx">${esc(value||placeholder)}</span>
    <span class="sf-cv"><svg viewBox="0 0 24 24"><path d="M6 9l6 6 6-6"/></svg></span></div>`;
}
function segHTML(id,opts,val,cols){
  return `<div class="segmented c${cols||opts.length}" id="${id}">${opts.map(([k,l])=>`<div class="seg ${val===k?'on':''}" data-v="${k}">${l}</div>`).join("")}</div>`;
}
function chipsHTML(id,opts,val){
  return `<div class="chips" id="${id}">${opts.map(([k,l])=>`<div class="chip ${val===k?'on':''}" data-v="${k}">${l}</div>`).join("")}</div>`;
}

function renderForm(){
  const d=DRAFT;
  $("topTitle").textContent=d.editing?"E'lonni tahrirlash":"Yangi e'lon";
  $("formScroll").innerHTML=`
    <div class="formsec">
      <div class="h"><svg viewBox="0 0 24 24" fill="none" stroke-linecap="round"><rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="8.5" cy="10" r="1.5"/><path d="M21 15l-5-4-8 6"/></svg> Rasm va video <span style="color:var(--faint);font-weight:500">(${d.media.length}/10)</span></div>
      <div class="media" id="mediaGrid"></div>
      <div class="mediahint">${d.editing?"Yuborilgandan keyin rasmlarni o'zgartirib bo'lmaydi.":"Birinchisi muqova bo'ladi. Bosib turib muqovani almashtiring. Maksimal 10 ta, har bir video ≤ 50MB."}</div>
    </div>

    <div class="formsec">
      <div class="h"><svg viewBox="0 0 24 24" fill="none"><path d="M5 11l1.5-4.5A2 2 0 018.4 5h7.2a2 2 0 011.9 1.5L19 11"/><rect x="3" y="11" width="18" height="6" rx="1.5"/></svg> Mashina</div>
      <div class="field"><label>Marka <span class="req">*</span></label>${selectField("fBrand",d.brand,"Markani tanlang",true)}</div>
      <div class="field"><label>Model <span class="req">*</span></label>${selectField("fModel",d.model,"Modelni tanlang",false)}</div>
      <div class="field row2">
        <div class="field"><label>Yili <span class="req">*</span></label>${selectField("fYear",d.year?String(d.year):"","Yil",false)}</div>
        <div class="field"><label>Avlod (ixtiyoriy)</label><div class="inp"><input id="fGen" placeholder="masalan: DN8" value="${esc(d.generation)}"></div></div>
      </div>
      <div class="field"><label>Yurgan masofasi</label><div class="inp"><input id="fMile" inputmode="numeric" placeholder="150 000" value="${d.mileage!=null?group(String(d.mileage)):""}"><span class="suf">km</span></div></div>
      <div class="field"><label>Uzatma qutisi</label>${segHTML("fTrans",TRANS,d.transmission,2)}</div>
      <div class="field"><label>Yoqilg'i turi</label>${chipsHTML("fFuel",FUEL,d.fuel)}</div>
    </div>

    <div class="formsec">
      <div class="h"><svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9"/><path d="M12 7v10M9.5 9.2c0-1 .9-1.7 2.3-1.7s2.4.7 2.4 1.8c0 2.2-4.7 1.4-4.7 3.7 0 1.1 1 1.8 2.4 1.8s2.4-.7 2.4-1.7"/></svg> Narx</div>
      <div class="field"><label>Narxi (₩) <span class="req">*</span></label><div class="inp" id="priceWrap"><input id="fPrice" inputmode="numeric" placeholder="7 000 000" value="${d.price!=null?group(String(d.price)):""}"><span class="suf">₩</span></div></div>
      <div class="field"><div class="toggle"><div class="tg-tx"><b>Narx kelishiladi</b><span>Xaridor bilan kelishish mumkin</span></div><div class="sw ${d.negotiable?'on':''}" id="fNeg"></div></div></div>
      <div class="field"><label>Rasmiy holati</label>${segHTML("fLegal",LEGAL,d.legal,2)}</div>
      <div class="field"><label>Nomiga o'tkazish kerakmi?</label>${segHTML("fReg",REG,d.registration,2)}</div>
    </div>

    <div class="formsec">
      <div class="h"><svg viewBox="0 0 24 24" fill="none"><path d="M5 4h3l2 5-2.5 1.5a11 11 0 005 5L14 13l5 2v3a2 2 0 01-2 2A15 15 0 013 6a2 2 0 012-2z"/></svg> Aloqa</div>
      <div class="field"><label>Telefon raqam</label><div class="inp"><span class="pre">+82</span><input id="fPhone" inputmode="numeric" placeholder="10 1234 5678" value="${esc(d.phone)}"></div></div>
      <div class="field"><label>Telegram</label><div class="inp"><input id="fTg" placeholder="@username" value="${esc(d.telegram)}"></div></div>
      <div class="mediahint">Kamida bittasini to'ldiring.</div>
    </div>

    <div class="formsec">
      <div class="h"><svg viewBox="0 0 24 24" fill="none"><path d="M4 6h16M4 12h16M4 18h10"/></svg> Tavsif</div>
      <textarea class="ta" id="fDesc" maxlength="2000" placeholder="Holati, butligi, almashtirilgan qismlar, sababi...">${esc(d.desc)}</textarea>
      <div class="charcount"><span id="descCount">${d.desc.length}</span>/2000</div>
    </div>`;

  renderMedia();
  bindForm();
  $("btnSubmit").textContent=d.editing?"Saqlash":"Ko'rib chiqishga yuborish";
}

function bindForm(){
  const d=DRAFT;
  // selectable openers
  $("fBrand").onclick=()=>openBrandSheet();
  $("fModel").onclick=()=>{ if(!d.brand)return toast("Avval markani tanlang"); openModelSheet(); };
  $("fYear").onclick=()=>openYearSheet();
  if(d.brand) setBrandUI(d.brand);
  // segmented / chips
  bindSeg("fTrans",v=>d.transmission=(d.transmission===v?"":v));
  bindSeg("fLegal",v=>d.legal=(d.legal===v?"":v));
  bindSeg("fReg",v=>d.registration=(d.registration===v?"":v));
  bindChips("fFuel",v=>d.fuel=(d.fuel===v?"":v));
  // toggles
  $("fNeg").onclick=function(){d.negotiable=!d.negotiable;this.classList.toggle("on",d.negotiable);haptic("sel");};
  // text/number
  $("fGen").oninput=e=>d.generation=e.target.value.trim();
  grpBind($("fMile"),v=>d.mileage=v);
  grpBind($("fPrice"),v=>d.price=v);
  $("fPhone").oninput=e=>{const v=digits(e.target.value).slice(0,11);e.target.value=v.replace(/(\d{2,3})(\d{3,4})(\d{0,4})/,(m,a,b,c)=>c?`${a} ${b} ${c}`:b?`${a} ${b}`:a);d.phone=v;};
  $("fPhone").value && ($("fPhone").oninput({target:$("fPhone")}));
  $("fTg").oninput=e=>d.telegram=e.target.value.trim();
  $("fDesc").oninput=e=>{d.desc=e.target.value;$("descCount").textContent=d.desc.length;};
}
function bindSeg(id,fn){const el=$(id);if(!el)return;el.onclick=e=>{const s=e.target.closest(".seg");if(!s)return;fn(s.dataset.v);[...el.children].forEach(c=>c.classList.remove("on"));const cur=fn===undefined?null:s.dataset.v;el.querySelectorAll(".seg").forEach(c=>c.classList.toggle("on",c.dataset.v===valOf(id)));haptic("sel");};}
function bindChips(id,fn){const el=$(id);if(!el)return;el.onclick=e=>{const c=e.target.closest(".chip");if(!c)return;fn(c.dataset.v);el.querySelectorAll(".chip").forEach(x=>x.classList.toggle("on",x.dataset.v===valOf(id)));haptic("sel");};}
function valOf(id){const d=DRAFT;return id==="fTrans"?d.transmission:id==="fLegal"?d.legal:id==="fReg"?d.registration:id==="fFuel"?d.fuel:"";}
function grpBind(inp,set){inp.oninput=e=>{const el=e.target,start=el.selectionStart,before=el.value;el.value=group(el.value);set(digits(el.value)?+digits(el.value):null);const diff=el.value.length-before.length;try{el.setSelectionRange(start+diff,start+diff);}catch(_){}}; if(inp.value) set(digits(inp.value)?+digits(inp.value):null);}

function setBrandUI(brand){
  const tx=$("fBrand_tx"),lg=$("fBrand_logo");
  tx.textContent=brand; tx.classList.remove("ph");
  if(lg){const s=logoSrc(brand);lg.style.display="grid";
    if(s){lg.style.background="#fff";lg.innerHTML=`<img src="${s}" alt="" onerror="this.parentElement.style.background='${brandColor(brand)}';this.parentElement.textContent='${brandMono(brand)}'">`;}
    else{lg.style.background=brandColor(brand);lg.textContent=brandMono(brand);}}
}
function setField(id,text){const tx=$(id+"_tx");tx.textContent=text;tx.classList.toggle("ph",!text);}

/* ---------- media ---------- */
function renderMedia(){
  const g=$("mediaGrid"); if(!g)return; const d=DRAFT;
  let html=d.media.map((m,i)=>{
    const inner = m.processing
      ? `<div class="loadcell"><span class="cspin"></span><small>Tayyorlanmoqda…</small></div>`
      : (m.type==="video"
          ? `<video src="${m.url}" muted playsinline preload="metadata"></video><span class="vtag"><svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg></span>`
          : `<img src="${m.url}" alt="">`);
    const cover = (!m.processing && i===0) ? `<span class="cover">Muqova</span>`
                : (!m.processing && !m.locked) ? `<span class="setcover">Muqova qilish</span>` : "";
    const rm = (!m.processing && !m.locked) ? `<button class="rm" data-rm="${m.key}"><svg viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg></button>` : "";
    const up = m.uploading ? `<div class="upov"><span class="cspin"></span></div><div class="bar"><i style="width:${Math.round((m.progress||0)*100)}%"></i></div>` : "";
    return `<div class="cell" data-mk="${m.key}">${inner}${cover}${rm}${up}</div>`;
  }).join("");
  if(!d.editing && d.media.length<10)
    html+=`<button class="cell up" id="addMedia"><div class="upin"><svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg><small>Qo'shish</small></div></button>`;
  g.innerHTML=html;
  const add=$("addMedia"); if(add) add.onclick=()=>$("fileInput").click();
  g.querySelectorAll("[data-rm]").forEach(b=>b.onclick=e=>{e.stopPropagation();removeMedia(b.dataset.rm);});
  g.querySelectorAll(".cell").forEach(c=>{const m=d.media.find(x=>x.key===c.dataset.mk);if(m&&!m.locked&&!m.processing)c.onclick=ev=>{if(ev.target.closest("[data-rm]"))return;setCover(c.dataset.mk);};});
}
function updateMediaCount(){const c=document.querySelector("#formScroll .formsec .h span");if(c)c.textContent=`(${DRAFT.media.length}/10)`;}
function setCover(key){const d=DRAFT,i=d.media.findIndex(m=>m.key===key);if(i<=0)return;const[m]=d.media.splice(i,1);d.media.unshift(m);d.media.forEach((x,j)=>x.ord=j);renderMedia();haptic("sel");}
function removeMedia(key){const d=DRAFT,i=d.media.findIndex(m=>m.key===key);if(i<0)return;try{URL.revokeObjectURL(d.media[i].url);}catch(_){}
  d.media.splice(i,1);d.media.forEach((x,j)=>x.ord=j);renderMedia();updateMediaCount();}
$("fileInput").addEventListener("change", async e=>{
  const files=[...e.target.files]; e.target.value="";
  const queue=[];
  for(const f of files){
    if(DRAFT.media.length>=10){toast("Maksimal 10 ta");break;}
    const isVid=f.type.startsWith("video");
    if(isVid){ if(f.size>50*1024*1024){toast("Video 50MB dan katta");continue;} }
    else if(!f.type.startsWith("image")){ continue; }
    const item={key:uid(),type:isVid?"video":"photo",processing:true,ord:DRAFT.media.length,_file:f};
    DRAFT.media.push(item); queue.push(item);
  }
  renderMedia(); updateMediaCount();              // spinners appear instantly
  for(const item of queue){
    try{
      if(item.type==="video"){ item.blob=item._file; item.url=URL.createObjectURL(item._file); }
      else{ const blob=await resizeImage(item._file,1600,.82); item.blob=blob; item.url=URL.createObjectURL(blob); }
    }catch(_){}
    item.processing=false; item._file=null; renderMedia();
  }
});
function resizeImage(file,maxSide,q){
  return new Promise(res=>{
    const img=new Image(), url=URL.createObjectURL(file);
    img.onload=()=>{ URL.revokeObjectURL(url);
      let {width:w,height:h}=img; const s=Math.min(1,maxSide/Math.max(w,h));
      const cw=Math.max(1,Math.round(w*s)), ch=Math.max(1,Math.round(h*s));
      const c=document.createElement("canvas"); c.width=cw; c.height=ch;
      c.getContext("2d").drawImage(img,0,0,cw,ch);
      c.toBlob(b=>res(b||file),"image/jpeg",q);
    };
    img.onerror=()=>{URL.revokeObjectURL(url);res(file);};
    img.src=url;
  });
}

/* ============================================================
   SHEET PICKERS
   ============================================================ */
let sheetMode=null;
function openSheet(title,search){$("sheetTitle").textContent=title;$("sheetSearchWrap").style.display=search?"flex":"none";$("sheetSearch").value="";$("sheetBack").classList.add("on");$("sheet").classList.add("on");haptic("light");}
function closeSheet(){$("sheetBack").classList.remove("on");$("sheet").classList.remove("on");sheetMode=null;}
$("sheetX").onclick=closeSheet; $("sheetBack").onclick=closeSheet;

function brandsForSheet(q){
  const set=new Map();
  CATALOG.forEach(b=>set.set(b.brand,true));
  ALL_BRANDS.forEach(b=>{if(!set.has(b))set.set(b,true);});
  let arr=[...set.keys()];
  if(q)arr=arr.filter(b=>b.toLowerCase().includes(q.toLowerCase()));
  return arr.sort((a,b)=>a.localeCompare(b));
}
function openBrandSheet(){
  sheetMode="brand"; openSheet("Markani tanlang",true); renderBrandSheet("");
  $("sheetSearch").oninput=e=>renderBrandSheet(e.target.value);
}
function renderBrandSheet(q){
  $("sheetBody").innerHTML=`<div class="brandgrid">${brandsForSheet(q).map(b=>{
    const s=logoSrc(b);
    const lg=s?`<div class="lg"><img src="${s}" alt="" onerror="this.parentElement.style.background='${brandColor(b)}';this.parentElement.textContent='${brandMono(b)}'"></div>`:`<div class="lg" style="background:${brandColor(b)}">${brandMono(b)}</div>`;
    return `<button class="bcard" data-b="${esc(b)}">${lg}<span>${esc(b)}</span></button>`;}).join("")}</div>`;
  $("sheetBody").querySelectorAll("[data-b]").forEach(c=>c.onclick=()=>{
    const b=c.dataset.b;
    if(b!==DRAFT.brand){DRAFT.brand=b;DRAFT.model="";setField("fModel","");$("fModel_tx").textContent="Modelni tanlang";$("fModel_tx").classList.add("ph");}
    setBrandUI(b);closeSheet();haptic("sel");
  });
}
function modelsForBrand(brand){const c=CATALOG.find(x=>x.brand===brand);return c?c.models.map(m=>m.model):[];}
function openModelSheet(){
  sheetMode="model"; openSheet("Modelni tanlang",true); renderModelSheet("");
  $("sheetSearch").oninput=e=>renderModelSheet(e.target.value);
}
function renderModelSheet(q){
  let list=modelsForBrand(DRAFT.brand);
  if(q)list=list.filter(m=>m.toLowerCase().includes(q.toLowerCase()));
  const rows=list.map(m=>`<div class="optrow ${DRAFT.model===m?'on':''}" data-m="${esc(m)}"><span class="ot">${esc(m)}</span><span class="chk"><svg viewBox="0 0 24 24"><path d="M5 13l4 4L19 7"/></svg></span></div>`).join("");
  $("sheetBody").innerHTML=rows+`<div class="optrow" data-other="1"><span class="ot" style="color:var(--accent)">＋ Boshqa model (qo'lda)</span></div>`;
  $("sheetBody").querySelectorAll("[data-m]").forEach(r=>r.onclick=()=>{DRAFT.model=r.dataset.m;setField("fModel",r.dataset.m);closeSheet();haptic("sel");});
  $("sheetBody").querySelector("[data-other]").onclick=()=>{ closeSheet(); textPrompt("Model nomi","masalan: Sonata",DRAFT.model).then(v=>{ if(v){DRAFT.model=v;setField("fModel",v);} }); };
}
function openYearSheet(){
  sheetMode="year"; openSheet("Yilni tanlang",false);
  $("sheetBody").innerHTML=`<div class="yeargrid">${YEARS.map(y=>`<div class="yc ${DRAFT.year===y?'on':''}" data-y="${y}">${y}</div>`).join("")}</div>`;
  $("sheetBody").querySelectorAll("[data-y]").forEach(c=>c.onclick=()=>{DRAFT.year=+c.dataset.y;setField("fYear",c.dataset.y);closeSheet();haptic("sel");});
}

/* ============================================================
   VALIDATION + SUBMIT
   ============================================================ */
function collect(){
  const d=DRAFT, errors=[]; 
  if(!d.brand)errors.push("fBrand");
  if(!d.model)errors.push("fModel");
  if(!d.year)errors.push("fYear");
  if(!d.price)errors.push("priceWrap");
  if(!d.editing && d.media.length<1)errors.push("mediaGrid");
  const phone=digits(d.phone), tg=(d.telegram||"").replace(/^@/,"").trim();
  if(!phone && !tg)errors.push("fPhone");
  if(phone && phone.length<9)errors.push("fPhone");
  const payload={
    brand:d.brand, model:d.model, generation:d.generation||null, year:d.year,
    mileage_km:d.mileage, transmission:d.transmission||null, fuel:d.fuel||null,
    price_krw:d.price, negotiable:d.negotiable,
    legal_status:d.legal||null, registration_required:d.registration===""?null:+d.registration,
    contact_phone:phone||null, contact_handle:tg||null, description:d.desc||null
  };
  return {ok:!errors.length, errors, payload, msg:errors.length?"Majburiy maydonlarni to'ldiring":""};
}
function markErrors(ids){
  document.querySelectorAll(".err").forEach(e=>e.classList.remove("err"));
  ids.forEach(id=>{const el=$(id);if(el){el.classList.add("err");}});
  const first=$(ids[0]); if(first) first.scrollIntoView({behavior:"smooth",block:"center"});
  haptic("err");
}
function setBusy(b){BUSY=b;const btn=$("btnSubmit");btn.disabled=b;btn.innerHTML=b?`<span class="spinner"></span>`:(DRAFT&&DRAFT.editing?"Saqlash":"Ko'rib chiqishga yuborish");}

async function doSubmit(){
  if(BUSY||!DRAFT)return;
  const v=collect();
  if(!v.ok){markErrors(v.errors);toast(v.msg);return;}
  document.querySelectorAll(".err").forEach(e=>e.classList.remove("err"));

  // EDIT MODE → just patch fields (media locked)
  if(DRAFT.editing){
    setBusy(true);
    try{ await jpost("/listings/"+DRAFT.id+"/edit", v.payload); haptic("ok"); toast("Saqlandi ✓"); DRAFT=null; await loadList(); showList(); }
    catch(e){ toast("Xatolik: "+(e.data?.error||"qayta urining")); }
    setBusy(false); return;
  }

  setBusy(true);
  try{
    // 1) duplicate pre-check (nicer UX; /submit enforces the same rule server-side)
    let dup=null;
    try{ dup=await jpost("/listings/check-duplicate",{brand:v.payload.brand,model:v.payload.model,year:v.payload.year,fuel:v.payload.fuel,mileage_km:v.payload.mileage_km,price_krw:v.payload.price_krw,phone:v.payload.contact_phone}); }catch(_){}
    if(dup&&dup.matches&&dup.matches.length){ setBusy(false); return showDupModal(dup.matches); }
    // 2) create draft listing
    if(!DRAFT.id){ const r=await jpost("/listings", v.payload); DRAFT.id=r.id; }
    else { await jpost("/listings/"+DRAFT.id+"/edit", v.payload); }
    // 3) upload media that isn't on the server yet
    const pending=DRAFT.media.filter(m=>!m.serverMid);
    for(const m of pending){
      m.uploading=true; renderMedia();
      try{ const res=await uploadMedia(DRAFT.id,m,p=>{m.progress=p;const bar=document.querySelector(`[data-mk="${m.key}"] .bar i`);if(bar)bar.style.width=Math.round(p*100)+"%";}); m.serverMid=res.id||true; }
      finally{ m.uploading=false; }
      renderMedia();
    }
    // 4) finalize → pending review (server re-checks duplicates, may reject with 409)
    try{
      await jpost("/listings/"+DRAFT.id+"/submit",{});
    }catch(e){
      if(e.data&&e.data.error==="duplicate"&&e.data.matches&&e.data.matches.length){ setBusy(false); return showDupModal(e.data.matches); }
      throw e;
    }
    haptic("ok"); toast("E'lon ko'rib chiqishga yuborildi ✓");
    DRAFT=null; await loadList(); showList();
  }catch(e){
    toast("Xatolik: "+(e.data?.error||e.message||"qayta urining"));
  }
  setBusy(false);
}
$("btnSubmit").onclick=doSubmit;

/* ---------- duplicate modal ---------- */
function showDupModal(matches){
  const items=matches.slice(0,3).map(m=>{
    const view=(m.viewable&&m.id)?`<a class="dupview" href="cars.html?startapp=car${m.id}">Ko'rish →</a>`:(m.own?`<span class="dupown">Sizning e'loningiz</span>`:"");
    return `<div class="dupitem">
    ${m.thumb?`<img src="${absUrl(m.thumb)}" alt="">`:""}
    <div class="dt"><b>${esc(m.brand||"")} ${esc(m.model||"")}${m.year?` · ${m.year}`:""}</b><span>${m.price_krw!=null?won(m.price_krw):""}${m.source_name?` · ${esc(m.source_name)}`:""}</span></div>
    ${view}</div>`;
  }).join("");
  openModal(`<div class="mic warn"><svg viewBox="0 0 24 24" fill="none"><path d="M12 9v4M12 17h.01M10.3 3.9L1.8 18a2 2 0 001.7 3h17a2 2 0 001.7-3L14.7 3.9a2 2 0 00-3.4 0z"/></svg></div>
    <h3>Bu mashina allaqachon joylangan</h3>
    <p>Xuddi shu mashina bozorda mavjud, shuning uchun takroriy e'lon qabul qilinmaydi.</p>
    ${items}
    <p class="dupnote">Agar bu xatolik bo'lsa, admin bilan bog'laning: <a href="https://t.me/otabeksattarov">@otabeksattarov</a></p>
    <div class="mbtns"><button class="btn primary" id="dupClose">Tushunarli</button></div>`);
  $("dupClose").onclick=closeModal;
}

/* ---------- generic modal ---------- */
function openModal(html){$("modal").innerHTML=html;$("modalBack").classList.add("on");}
function closeModal(){$("modalBack").classList.remove("on");}
$("modalBack").addEventListener("click",e=>{if(e.target===$("modalBack"))closeModal();});
function confirmModal(kind,title,body,okText,onOk){
  openModal(`<div class="mic ${kind}"><svg viewBox="0 0 24 24" fill="none">${kind==="bad"?'<path d="M3 6h18M8 6V4h8v2M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/>':'<path d="M12 9v4M12 17h.01M10.3 3.9L1.8 18a2 2 0 001.7 3h17a2 2 0 001.7-3L14.7 3.9a2 2 0 00-3.4 0z"/>'}</svg></div>
    <h3>${esc(title)}</h3><p>${esc(body)}</p>
    <div class="mbtns"><button class="btn ${kind==='bad'?'danger':'primary'}" id="cfOk">${esc(okText)}</button><button class="btn ghost" id="cfNo">Bekor qilish</button></div>`);
  $("cfOk").onclick=()=>{closeModal();onOk&&onOk();};
  $("cfNo").onclick=closeModal;
}
function textPrompt(title,ph,val){
  return new Promise(res=>{
    openModal(`<h3>${esc(title)}</h3><div class="inp" style="margin:14px 0"><input id="tpIn" placeholder="${esc(ph)}" value="${esc(val||"")}"></div>
      <div class="mbtns"><button class="btn primary" id="tpOk">Saqlash</button><button class="btn ghost" id="tpNo">Bekor qilish</button></div>`);
    setTimeout(()=>$("tpIn").focus(),60);
    $("tpOk").onclick=()=>{const v=$("tpIn").value.trim();closeModal();res(v||null);};
    $("tpNo").onclick=()=>{closeModal();res(null);};
  });
}

/* ---------- preview ---------- */
$("btnPreview").onclick=()=>{
  const d=DRAFT, cover=d.media[0];
  openModal(`<h3 style="margin-bottom:12px">Ko'rinishi</h3>
    ${cover?`<img src="${cover.url}" style="width:100%;height:180px;object-fit:cover;border-radius:13px;margin-bottom:12px">`:""}
    <p style="color:var(--ink);font-weight:700;font-size:16px;margin-bottom:4px">${esc(d.brand)} ${esc(d.model)}${d.year?` · ${d.year}`:""}</p>
    <p style="color:var(--ink);font-weight:800;font-size:17px;margin-bottom:8px">${won(d.price)}${d.negotiable?" · kelishiladi":""}</p>
    <p>${[d.mileage!=null?group(String(d.mileage))+" km":null,transLabel(d.transmission),fuelLabel(d.fuel)].filter(Boolean).join(" · ")}</p>
    ${d.desc?`<p style="margin-top:8px;white-space:pre-wrap">${esc(d.desc)}</p>`:""}
    <div class="mbtns"><button class="btn ghost" id="pvClose">Yopish</button></div>`);
  $("pvClose").onclick=closeModal;
};

/* ============================================================
   NAV
   ============================================================ */
function showList(){ $("viewForm").classList.remove("on");$("viewList").classList.add("on");$("subBar").style.display="none";
  $("topTitle").textContent="Mening e'lonlarim"; TG.BackButton?.show?.(); window.scrollTo(0,0); }
function showForm(){ $("viewList").classList.remove("on");$("viewForm").classList.add("on");$("subBar").style.display="flex";
  TG.BackButton?.show?.(); window.scrollTo(0,0); }
function backFromForm(){
  const dirty=DRAFT && (DRAFT.brand||DRAFT.model||DRAFT.media.length||DRAFT.desc);
  if(dirty && !DRAFT.editing) return confirmModal("warn","Chiqilsinmi?","Kiritilgan ma'lumotlar saqlanmaydi.","Chiqish",()=>{DRAFT=null;showList();});
  DRAFT=null; showList();
}
function handleBack(){ if($("viewForm").classList.contains("on")) backFromForm(); else goToCars(); }
function goToCars(){ if(history.length>1) history.back(); else location.href="cars.html"; }
$("navBack").onclick=handleBack;
TG.BackButton?.onClick?.(handleBack);
$("btnNew").onclick=()=>openForm(null);

/* ============================================================
   INIT
   ============================================================ */
(async function init(){
  TG.BackButton?.show?.();
  try{ CATALOG=await jget("/catalog"); }catch(e){ CATALOG=[]; }
  await loadList();
})();
