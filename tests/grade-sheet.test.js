const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const html = fs.readFileSync('e-school/e-school/index.html','utf8');
const start = html.indexOf('function gradeSheetHtml('), end = html.indexOf('\nfunction refreshSummary()', start);
const actionStart=html.indexOf("A['print-grade-sheet']=");
const actionEnd=html.indexOf("A['print-all-student-contacts']=",actionStart);
assert(start>=0 && end>start && actionStart>=0 && actionEnd>actionStart);
const cls={name:'4e <ALL>',subjects:[{id:'fr',name:'Français & texte',coef:1.5},{id:'math',name:'Mathématiques',coef:4}],
  students:[{id:'b',name:'ZOA'},{id:'a',name:'AZEMBOU'}],
  grades:{a:{fr:[0,13.5,null,null,20],math:[null,8]},b:{fr:[17,0]}}};
const ctx={cls,admin:true,selected:'1',printed:null,message:null,A:{},
  cmpName:(a,b)=>a.name.localeCompare(b.name,'fr'),
  esc:s=>String(s==null?'':s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])),
  isNote:v=>v!=null&&v!==''&&Number.isFinite(Number(v)),viewSchool:()=>({name:'École'}),viewYear:()=> '2026/2027'};
ctx.isAdmin=()=>ctx.admin;ctx.curClass=()=>ctx.cls;ctx.$=()=>({value:ctx.selected});ctx.toast=m=>{ctx.message=m};ctx.printHtml=v=>{ctx.printed=v};
vm.createContext(ctx);vm.runInContext(html.slice(start,end)+'\n'+html.slice(actionStart,actionEnd),ctx);
const first=ctx.gradeSheetHtml(cls,1),second=ctx.gradeSheetHtml(cls,2),fifth=ctx.gradeSheetHtml(cls,5);
assert(first.includes('1<sup>re</sup> SÉQUENCE') && first.includes('4e &lt;ALL&gt;'));
assert(first.includes('Français &amp; texte') && first.includes('<td>1,5</td><td>4</td>'));
assert(first.includes('<td class="low">0</td><td></td><td></td>'));
assert(first.indexOf('AZEMBOU')<first.indexOf('ZOA'));
assert(second.includes('2<sup>e</sup> SÉQUENCE') && second.includes('<td>13,5</td><td class="low">8</td>'));
assert(fifth.includes('<td>20</td>'));
ctx.A['print-grade-sheet']();assert.equal(ctx.printed,first);
ctx.printed=null;ctx.selected='6';ctx.A['print-grade-sheet']();assert.equal(ctx.printed,null);assert(ctx.message.includes('séquence'));
ctx.selected='1';ctx.admin=false;ctx.A['print-grade-sheet']();assert.equal(ctx.printed,null);assert(ctx.message.includes('administrateur'));
ctx.admin=true;ctx.cls={name:'Vide',students:[{id:'a',name:'X'}],subjects:[]};ctx.A['print-grade-sheet']();assert.equal(ctx.printed,null);assert(ctx.message.includes('matières'));
const many={name:'Grande classe',students:[{id:'a',name:'Nom'}],subjects:Array.from({length:31},(_,i)=>({id:'s'+i,name:'Matière '+i,coef:1})),grades:{a:{s30:[5]}}};
const all=ctx.gradeSheetHtml(many,1);assert.equal((all.match(/<section class="grade-sheet">/g)||[]).length,3);
assert(all.includes('Matière 30') && all.includes('matières 3/3') && all.includes('<td class="low">5</td>'));
assert(html.includes('data-act="print-grade-sheet"') && html.includes('@page grade-sheet-page{size:A4 landscape'));
console.log('Feuille de notes : séquences, zéros, notes manquantes, accès et pagination des matières vérifiés.');
