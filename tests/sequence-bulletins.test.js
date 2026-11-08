const assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm');
const html=fs.readFileSync('e-school/e-school/index.html','utf8');
function slice(a,b){const i=html.indexOf(a),j=html.indexOf(b,i);assert(i>=0&&j>i,`missing ${a}`);return html.slice(i,j)}
const c={
  cls:{id:'c',lang:'fr',name:'4e ALL',students:[{id:'a',name:'Alice'},{id:'b',name:'Bob'},{id:'c',name:'Chantal'}],
    subjects:[{id:'m',name:'Math',coef:2},{id:'f',name:'Français',coef:1}],
    grades:{a:{m:[0,20,15,3,12],f:[12,18,9,null,10]},b:{m:[10,20,7,18,12],f:[18,18,8,19,10]},c:{m:['',null,null,null,null]}},remarks:{a:{t1:'Trimestriel'}}},
  calcCache:{},
  LB:{fr:{order:['n1','n2','m','coef','pts'],n1:t=>'N'+((t-1)*2+1)+'/20',n2:t=>'N'+((t-1)*2+2)+'/20',m:'M/20',coef:'Coef.',pts:'Pts',title:()=> 'BULLETIN DE NOTES',sub:'REPORT CARD',year:'Année',tr:t=>t+' Trimestre',cls:'Classe',name:'Nom',sex:'Sexe',statut:'Statut',pp:'Professeur',cel:'Tél',subject:'Matière',rank:'Rang',obs:'Observation',grp:'MOYENNE ',legend:'Légende'}},
  viewSchool:()=>({name:'École',year:'2026/2027'}), viewUsers:()=>[],
  esc:s=>String(s==null?'':s).replace(/[&<>"']/g,ch=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch])),
  fmt:(v,d=2)=>v==null||isNaN(v)?'':Number(v).toFixed(d).replace('.',','),fmt1:v=>v==null?'':Number(v).toFixed(1).replace('.',','),
  discVal:()=>2,discSum:()=>0,discNum:x=>x,annualStats:()=>({per:{},mn:null,mx:null,passCount:0,pass:null}),
  honourInfo:()=>({on:true,fel:true,enc:true}),rankHtml:r=>r?String(r.r):'',ordSup:n=>String(n),obs:()=>'',
  ppName:()=>'',ppTel:()=>'',studentPhotoSrc:()=>'',bulletinHeaderSrc:()=>'',clsSup:s=>s,sexLabel:()=>'',statusLabel:()=>'',formatBirthPlace:s=>s,docFootHtml:()=>''
};
vm.createContext(c);
vm.runInContext(slice('const seqIdx=t=>','function missingCount(')+'\n'+slice('function bBottomHtml(', '// ===================== Synchronisation'),c);
const seq1=c.compute(c.cls,1,1),seq3=c.compute(c.cls,2,3);
assert.equal(seq1.per.a.avg,4);assert.equal(seq1.per.b.avg,38/3);assert.equal(seq1.per.a.rank.r,2);
assert.equal(seq1.per.c.avg,null);assert.equal(seq3.per.a.avg,13);assert.equal(seq3.per.b.avg,22/3);
const first=c.bulletinHtml(c.cls,'a',1,1,seq1),third=c.bulletinHtml(c.cls,'a',2,3,seq3),missing=c.bulletinHtml(c.cls,'c',1,1,seq1);
assert(first.includes('1<sup>re</sup> Séquence') && first.includes('N1/20') && first.includes('Moyenne séquentielle'));
assert(first.includes('0,00') && !first.includes('20,00') && !first.includes('Moyenne trimestrielle'));
assert(!first.includes('Trimestriel') && !first.includes('chk on')); // trimester remark and awards do not leak
assert(third.includes('3<sup>e</sup> Séquence') && third.includes('N3/20') && third.includes('15,00') && !third.includes('N4/20'));
assert(!missing.includes('0,00'));
const mappingCtx={bulletinHtml:(cls,sid,t,seq)=>`[${t}:${seq||'-'}]`,honourHtml:(cls,sid,t)=>`[hon${t}]`};
vm.createContext(mappingCtx);vm.runInContext(slice('function sequenceBulletinHtml(', '\nfunction printSequenceBulletins('),mappingCtx);
assert.equal(mappingCtx.sequenceBulletinHtml({},'s',1),'[1:1]');
assert.equal(mappingCtx.sequenceBulletinHtml({},'s',2),'[1:-][hon1]');
assert.equal(mappingCtx.sequenceBulletinHtml({},'s',3),'[2:3]');
assert.equal(mappingCtx.sequenceBulletinHtml({},'s',4),'[2:-][hon2]');
assert.equal(mappingCtx.sequenceBulletinHtml({},'s',5),'[3:-][hon3]');
assert(html.includes('data-act="print-sequence-all"') && html.includes('data-act="print-sequence-one"'));
for(const p of ['e-school/e-school/gestion-bulletins.html','e-school/gestion-bulletins.html','desktop-app/app/index.html','version-portable/GestSchool.html'])assert.equal(fs.readFileSync(p,'utf8'),html);
console.log('Bulletins séquentiels et mapping trimestriel : calculs, titres et impression vérifiés.');
