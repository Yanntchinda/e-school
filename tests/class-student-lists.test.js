const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const html = fs.readFileSync('e-school/e-school/index.html', 'utf8');
const listStart = html.indexOf('function classStudentListHtml(');
const listEnd = html.indexOf('\n/* ---------- Corbeille générale', listStart);
const actionStart = html.indexOf("A['print-all-student-contacts']=");
const actionEnd = html.indexOf("A['print-all']=", actionStart);
assert(listStart >= 0 && listEnd > listStart && actionStart >= 0 && actionEnd > actionStart);

const cls = {name:'6e <A>', students:[
  {id:'2',name:'ZOA Anne Marie',sex:'F',dob:'2010-05-02',pob:'douala',parentPhone:'699123456'},
  {id:'1',name:'ABENA & FILS',dob:'',parentPhone:''},
  {id:'3',name:'ÉTOUNDI Paul',sex:'M',dob:'2011-12-03',parentPhone:'677000000'}
]};
const ctx = {
  A:{}, cls, archive:false, admin:true, printed:null, message:null,
  viewSchool:()=>({name:'École & collège'}), viewYear:()=> '2026/2027',
  cmpName:(a,b)=>a.name.localeCompare(b.name,'fr',{sensitivity:'base'}),
  esc:s=>String(s == null?'':s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])),
  formatBirthPlace:s=>String(s||'').replace(/(^|[^\p{L}\p{M}])(\p{L})/gu,(_,sep,c)=>sep+c.toLocaleUpperCase('fr')),
  frDate:s=>s.split('-').reverse().join('/'), parentInfo:s=>({phone:s.parentPhone||''}), sexLabel:s=>s.sex==='F'?'Féminin':s.sex==='M'?'Masculin':'—',
  financeState:id=>({'1':{defined:false,rest:0},'2':{defined:true,rest:12000},'3':{defined:true,rest:-1000}}[id]),
  money:n=>n+' FCFA',
};
ctx.isAdmin=()=>ctx.admin;ctx.isReadOnlySession=()=>ctx.archive;ctx.curClass=()=>ctx.cls;
ctx.classes=[cls,{name:'5e',students:[]}];ctx.visibleClasses=()=>ctx.classes;
ctx.toast=message=>{ctx.message=message};ctx.printHtml=body=>{ctx.printed=body};
vm.createContext(ctx);
vm.runInContext(html.slice(listStart,listEnd)+'\n'+html.slice(actionStart,actionEnd),ctx);
const contacts=ctx.classStudentListHtml(cls,'contacts');
assert(contacts.includes('ABENA &amp; FILS'));
assert(contacts.indexOf('ABENA') < contacts.indexOf('ÉTOUNDI') && contacts.indexOf('ÉTOUNDI') < contacts.indexOf('ZOA'));
assert(contacts.includes('<th>Nom et prénom(s)</th><th>Sexe</th><th>Date de naissance</th><th>Lieu de naissance</th><th>Numéro des parents</th><th class="obs-col">Observation</th><th class="obs-col">Observation 2</th><th class="obs-col">Observation 3</th>'));
assert(contacts.includes('<td>Féminin</td><td>02/05/2010</td><td>Douala</td><td>699123456</td>'));
assert(contacts.includes('Classe : <b>6e &lt;A&gt;</b>') && contacts.includes('<th class="obs-col">Observation</th>'));
assert.equal((contacts.match(/<td><\/td><td><\/td><td><\/td><\/tr>/g)||[]).length,3);
const fees=ctx.classStudentListHtml(cls,'fees');
assert(fees.includes('Non défini') && fees.includes('12000 FCFA') && fees.includes('-1000 FCFA'));
assert(!fees.includes('699123456'));
assert(!fees.includes('Observation 2') && !fees.includes('Observation 3'));
assert.equal((fees.match(/<td><\/td><\/tr>/g)||[]).length,3);
ctx.A['print-all-student-contacts']();assert(ctx.printed.includes('6e &lt;A&gt;') && ctx.printed.includes('Classe : <b>5e</b>'));
assert(ctx.printed.includes('<td colspan="9">Aucun élève dans cette classe.</td>'));
assert(html.includes('@page class-contact-page{size:A4 landscape'));
assert(html.includes('.class-list.contacts-list th.obs-col{white-space:nowrap;'));
assert.equal((ctx.printed.match(/<section class="class-list contacts-list">/g)||[]).length,2);
ctx.printed=null;ctx.classes=[];ctx.A['print-all-student-contacts']();assert.equal(ctx.printed,null);assert(ctx.message.includes('Aucune classe'));
ctx.classes=[cls];ctx.archive=true;ctx.A['print-all-student-contacts']();assert(ctx.printed.includes('6e &lt;A&gt;'));
ctx.archive=false;ctx.printed=null;ctx.A['print-student-list']({dataset:{kind:'fees'}});assert.equal(ctx.printed,fees);
ctx.printed=null;ctx.archive=true;ctx.A['print-student-list']({dataset:{kind:'fees'}});assert.equal(ctx.printed,null);assert(ctx.message.includes('archivées'));
ctx.archive=false;ctx.admin=false;ctx.A['print-student-list']({dataset:{kind:'fees'}});assert.equal(ctx.printed,null);assert(ctx.message.includes('administrateur'));
ctx.A['print-all-student-contacts']();assert.equal(ctx.printed,null);
assert(html.includes('data-act="print-all-student-contacts"'));
assert(!html.includes('data-kind="contacts"'));
assert(html.includes('#printRoot .class-list + .class-list{break-before:page;page-break-before:always}'));
for(const path of ['e-school/e-school/gestion-bulletins.html','e-school/gestion-bulletins.html','desktop-app/app/index.html','version-portable/GestSchool.html']) assert.equal(fs.readFileSync(path,'utf8'),html, path);
console.log('Listes de classe : tri, champs, soldes, sécurité et copies vérifiés.');
