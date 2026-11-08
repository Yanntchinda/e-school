const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const html = fs.readFileSync('e-school/e-school/index.html','utf8');
// Names are escaped for HTML, not rewritten: real hyphens are preserved too.
const escSource = html.match(/const esc=s=>[^\n]+/)[0];
const latinStart=html.indexOf('function pdfLatin('), latinEnd=html.indexOf('\nconst pdfEsc=',latinStart);
assert(latinStart>=0 && latinEnd>latinStart);
const ctx={};vm.createContext(ctx);
vm.runInContext(escSource+'\n'+html.slice(latinStart,latinEnd)+'\nglobalThis.escapeName=esc;globalThis.pdfName=pdfLatin;',ctx);
assert.equal(ctx.escapeName('Marie Anne Jean-Pierre'), 'Marie Anne Jean-Pierre');
assert.equal(ctx.pdfName('Marie Anne Jean-Pierre'), 'Marie Anne Jean-Pierre');
assert(html.includes('esc(teacher.name)') && html.includes('esc(pp)'));
assert(html.includes('-webkit-hyphens:none; hyphens:none;'));
assert(html.includes("'.doc-sheet *, .a5-pair *{-webkit-hyphens:none;hyphens:none}'"));
console.log('Noms d’enseignants : espaces et tirets saisis conservés, césure désactivée.');
