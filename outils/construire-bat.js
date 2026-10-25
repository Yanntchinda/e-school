/* Régénère RECUPERER-MES-DONNEES.bat à partir de recuperer-donnees.ps1.
   Le .bat est un fichier unique, double-cliquable : cmd n'exécute que ses
   premières lignes (le lanceur), puis PowerShell lit le reste du fichier à
   partir du marqueur « #PSSTART# » et l'exécute. Le marqueur est reconstruit
   par morceaux dans le lanceur pour qu'il n'apparaisse qu'une fois.

   Usage : node outils/construire-bat.js                                   */
'use strict';
const fs = require('fs');
const path = require('path');

const dir = __dirname;
const source = path.join(dir, 'recuperer-donnees.ps1');
const target = path.join(dir, 'RECUPERER-MES-DONNEES.bat');

const head = [
  '@echo off',
  'setlocal',
  'title GestSchool - recuperation des donnees',
  'cls',
  'echo.',
  'echo   ============================================================',
  'echo    GestSchool - RECUPERER MES DONNEES',
  'echo   ============================================================',
  'echo.',
  'echo    Ce programme ne supprime rien.',
  'echo    Il retrouve la base enregistree avant la mise a jour et la',
  'echo    remet en place dans le logiciel.',
  'echo.',
  'echo    Laissez la fenetre ouverte jusqu\'a la fin.',
  'echo.',
  'powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=\'%~f0\'; $c=[IO.File]::ReadAllText($p,[Text.Encoding]::UTF8); $m=\'#\'+\'PSSTART\'+\'#\'; $i=$c.IndexOf($m); if($i -lt 0){ Write-Host \'Script incomplet.\'; exit 1 }; Invoke-Expression $c.Substring($i+$m.Length)"',
  'set "RC=%ERRORLEVEL%"',
  'if not "%RC%"=="0" (',
  '  echo.',
  '  echo Le programme s\'est arrete avec le code %RC%.',
  '  pause',
  ')',
  'exit /b %RC%',
  '#PSSTART#',
  ''
].join('\n');

const body = fs.readFileSync(source, 'utf8').replace(/\r\n/g, '\n');
const out = (head + body).replace(/\n/g, '\r\n');
fs.writeFileSync(target, out, 'utf8');
console.log('Écrit : ' + target + ' (' + out.length + ' octets)');
