'use strict';

const { app, BrowserWindow, Menu, dialog, shell, session } = require('electron');
const path = require('path');
const fs = require('fs');

/* Le logiciel s'appelle GestSchool. */
const APP_NAME = 'GestSchool';
app.setName(APP_NAME);

/* Le logiciel portait avant le nom « e-School Gestion Bulletins ». Ses données
   (classes, élèves, notes, comptes, finances) sont dans un dossier de
   %APPDATA%. Ce dossier est repris tel quel : rien n'est effacé, rien n'est à
   ressaisir. */
const LEGACY_DATA_DIR = 'e-School Gestion Bulletins';

/* Clé sous laquelle le logiciel range TOUTE sa base dans le stockage local du
   navigateur intégré. Sa présence dans les fichiers du dossier de données est
   la preuve qu'un dossier contient réellement des données. */
const DATA_MARK = 'mbi_gestion_bulletins_v1';

function storageHasData (dir) {
  if (!dir) return false;
  const ls = path.join(dir, 'Local Storage', 'leveldb');
  let names;
  try { names = fs.readdirSync(ls); } catch (e) { return false; }
  for (const name of names) {
    if (!/\.(ldb|log)$/i.test(name)) continue;
    const file = path.join(ls, name);
    try {
      if (fs.statSync(file).size < 200) continue;
      if (fs.readFileSync(file).includes(DATA_MARK)) return true;
    } catch (e) { /* fichier verrouillé : on essaie le suivant */ }
  }
  return false;
}

function storageNewest (dir) {
  let newest = 0;
  const ls = path.join(dir, 'Local Storage', 'leveldb');
  let names = [];
  try { names = fs.readdirSync(ls); } catch (e) { return 0; }
  for (const name of names) {
    if (!/\.(ldb|log)$/i.test(name)) continue;
    try { newest = Math.max(newest, fs.statSync(path.join(ls, name)).mtimeMs); } catch (e) {}
  }
  return newest;
}

/* Tous les dossiers de %APPDATA% qui contiennent la base, du plus récent au
   plus ancien. */
function dataFolders (base) {
  const found = [];
  let names = [];
  try { names = fs.readdirSync(base); } catch (e) { return found; }
  for (const name of names) {
    if (!/gestschool|e-?school|gestion|bulletin/i.test(name)) continue;
    const dir = path.join(base, name);
    try { if (!fs.statSync(dir).isDirectory()) continue; } catch (e) { continue; }
    if (storageHasData(dir)) found.push(dir);
  }
  return found.sort((a, b) => storageNewest(b) - storageNewest(a));
}

/* Copie le stockage d'un dossier vers un autre (sans rien supprimer côté
   source). Renvoie true si le dossier de destination contient la base. */
function copyStorage (from, to) {
  for (const sub of ['Local Storage', 'Session Storage', 'IndexedDB', 'Preferences']) {
    const src = path.join(from, sub);
    if (!fs.existsSync(src)) continue;
    try {
      fs.mkdirSync(to, { recursive: true });
      fs.rmSync(path.join(to, sub), { recursive: true, force: true });
      fs.cpSync(src, path.join(to, sub), { recursive: true });
    } catch (e) { /* copie impossible : on tentera l'autre solution */ }
  }
  return storageHasData(to);
}

/* Dossier de données à utiliser, décidé avant le premier accès à userData :
   1. le dossier du nom actuel s'il contient la base ;
   2. sinon un ancien dossier qui la contient (« e-School Gestion Bulletins »),
      recopié dans le dossier actuel ; à défaut, utilisé directement ;
   3. sinon première installation : renommage de l'ancien dossier s'il existe.
   Un dossier « GestSchool » vide (créé par un démarrage précédent) ne doit
   jamais masquer les données de l'ancien nom : c'est ce qui faisait démarrer
   le logiciel sur une base vide. */
function chooseUserDataDir () {
  const base = app.getPath('appData');
  const target = path.join(base, APP_NAME);
  const legacy = path.join(base, LEGACY_DATA_DIR);
  let note = '';
  try {
    if (!fs.existsSync(target) && fs.existsSync(legacy)) {
      try {
        fs.renameSync(legacy, target);
        note = 'ancien dossier renomme';
      } catch (e) {
        app.setPath('userData', legacy);
        return { dir: legacy, note: 'renommage impossible : ancien dossier utilise' };
      }
    }
    if (storageHasData(target)) return { dir: target, note: note || 'dossier actuel' };
    const others = dataFolders(base).filter(d => d !== target);
    if (others.length) {
      if (copyStorage(others[0], target) && storageHasData(target)) {
        return { dir: target, note: 'donnees de ' + path.basename(others[0]) + ' recopiees' };
      }
      app.setPath('userData', others[0]);
      return { dir: others[0], note: 'donnees lues dans ' + path.basename(others[0]) };
    }
  } catch (e) {
    return { dir: target, note: 'erreur : ' + e.message };
  }
  return { dir: target, note: note || 'aucune donnee existante' };
}

let userDataInfo = { dir: '', note: '' };
try {
  userDataInfo = chooseUserDataDir();
  app.setPath('userData', userDataInfo.dir);
} catch (e) { /* chemin indisponible : Electron utilise son dossier habituel */ }

let mainWindow = null;

/* Une seule instance : si l'utilisateur reclique sur l'icône, on réutilise la fenêtre ouverte. */
if (!app.requestSingleInstanceLock()) {
  app.quit();
}

/* Identifiant Windows (raccourci correct, notifications, barre des tâches). */
app.setAppUserModelId('com.eschool.bulletins');

/* Journal de démarrage : note dans quel dossier les données ont été trouvées.
   Il sert uniquement au dépannage (fichier demarrage.log du dossier de
   données), il ne contient aucune donnée scolaire. */
function writeDiagnostic () {
  try {
    const file = path.join(app.getPath('userData'), 'demarrage.log');
    let text = '';
    try { if (fs.statSync(file).size > 200000) text = ''; } catch (e) {}
    try { text = text || fs.readFileSync(file, 'utf8'); } catch (e) { text = ''; }
    const lines = (text + '\n').split('\n').filter(Boolean).slice(-400);
    lines.push(new Date().toISOString() + '  version ' + app.getVersion() +
      '  dossier : ' + userDataInfo.dir + '  (' + userDataInfo.note + ')');
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, lines.join('\n') + '\n');
  } catch (e) { /* journal facultatif */ }
}

/* Sauvegardes automatiques : chaque jour, le logiciel dépose une sauvegarde
   complète dans Documents\GestSchool-Sauvegardes, sans aucune fenêtre et sans
   écraser les précédentes. C'est le filet de sécurité si un dossier de données
   venait à être perdu. */
const AUTO_BACKUP_PREFIX = 'auto-sauvegarde-';

function backupsFolder () {
  let docs = '';
  try { docs = app.getPath('documents'); } catch (e) { docs = app.getPath('home'); }
  return path.join(docs, 'GestSchool-Sauvegardes');
}

function pruneBackups (folder, keep) {
  try {
    const files = fs.readdirSync(folder)
      .filter(n => n.indexOf(AUTO_BACKUP_PREFIX) === 0)
      .map(n => {
        try { return { n, t: fs.statSync(path.join(folder, n)).mtimeMs }; } catch (e) { return null; }
      })
      .filter(Boolean)
      .sort((a, b) => b.t - a.t);
    files.slice(keep).forEach(f => { try { fs.unlinkSync(path.join(folder, f.n)); } catch (e) {} });
  } catch (e) {}
}

function installAutoBackup () {
  try {
    const folder = backupsFolder();
    session.defaultSession.on('will-download', (event, item) => {
      const name = item.getFilename() || '';
      if (name.indexOf(AUTO_BACKUP_PREFIX) !== 0) return;
      try {
        fs.mkdirSync(folder, { recursive: true });
        item.setSavePath(path.join(folder, name));
      } catch (e) { return; }
      item.once('done', () => pruneBackups(folder, 40));
    });
  } catch (e) { /* fonction facultative */ }
}

function createWindow () {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1024,
    minHeight: 700,
    title: 'GestSchool',
    icon: path.join(__dirname, 'app/icon.png'),
    show: false,
    backgroundColor: '#e9edf4',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true,
      spellcheck: false
    }
  });

  mainWindow.loadFile(path.join(__dirname, 'app/index.html'));

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  /* Les liens externes s'ouvrent dans le navigateur du système, jamais dans l'application. */
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    if (/^https?:/i.test(url)) shell.openExternal(url);
    return { action: 'deny' };
  });
  mainWindow.webContents.on('will-navigate', (event, url) => {
    if (!url.startsWith('file:')) {
      event.preventDefault();
      if (/^https?:/i.test(url)) shell.openExternal(url);
    }
  });

  buildMenu();
}

/* Déclenche une action de l'application en cliquant son bouton,
   exactement comme le ferait l'utilisateur. Aucun code de l'app n'est dupliqué. */
function runAction (act) {
  if (!mainWindow) return;
  const code = `(() => {
    const b = document.createElement('button');
    b.setAttribute('data-act', ${JSON.stringify(act)});
    b.style.display = 'none';
    document.body.appendChild(b);
    b.click();
    b.remove();
  })();`;
  mainWindow.webContents.executeJavaScript(code, true).catch(() => {});
}

function buildMenu () {
  const isMac = process.platform === 'darwin';

  const template = [
    {
      label: 'Fichier',
      submenu: [
        {
          label: 'Exporter une sauvegarde',
          accelerator: 'Ctrl+S',
          click: () => runAction('backup')
        },
        {
          label: 'Restaurer une sauvegarde',
          click: () => runAction('restore-start')
        },
        { type: 'separator' },
        {
          label: 'Imprimer…',
          accelerator: 'Ctrl+P',
          click: () => {
            if (mainWindow) mainWindow.webContents.executeJavaScript('window.print()', true).catch(() => {});
          }
        },
        { type: 'separator' },
        {
          label: 'Quitter',
          accelerator: isMac ? 'Cmd+Q' : 'Alt+F4',
          click: () => app.quit()
        }
      ]
    },
    {
      label: 'Édition',
      submenu: [
        { label: 'Annuler', accelerator: 'Ctrl+Z', role: 'undo' },
        { label: 'Rétablir', accelerator: 'Ctrl+Y', role: 'redo' },
        { type: 'separator' },
        { label: 'Couper', accelerator: 'Ctrl+X', role: 'cut' },
        { label: 'Copier', accelerator: 'Ctrl+C', role: 'copy' },
        { label: 'Coller', accelerator: 'Ctrl+V', role: 'paste' },
        { label: 'Tout sélectionner', accelerator: 'Ctrl+A', role: 'selectAll' }
      ]
    },
    {
      label: 'Affichage',
      submenu: [
        { label: 'Recharger', accelerator: 'Ctrl+R', role: 'reload' },
        { label: 'Plein écran', accelerator: 'F11', role: 'togglefullscreen' },
        { type: 'separator' },
        { label: 'Zoom +', accelerator: 'Ctrl+=', role: 'zoomIn' },
        { label: 'Zoom -', accelerator: 'Ctrl+-', role: 'zoomOut' },
        { label: 'Zoom par défaut', accelerator: 'Ctrl+0', role: 'resetZoom' },
        { type: 'separator' },
        { label: 'Outils de développement', accelerator: 'F12', role: 'toggleDevTools' }
      ]
    },
    {
      label: 'Aide',
      submenu: [
        {
          label: 'À propos',
          click: () => {
            dialog.showMessageBox(mainWindow, {
              type: 'info',
              title: 'À propos',
              message: 'GestSchool',
              detail: 'Version ' + app.getVersion() +
                '\nÉlèves, notes, bulletins, personnel et finances.' +
                '\n\nDonnées enregistrées localement sur cet ordinateur,' +
                '\nou sur la base partagée configurée dans les Paramètres.' +
                '\nAucune connexion internet n\'est nécessaire.' +
                '\n\nCopyright © 2026 GESTSCHOOL. Tous droits réservés.' +
                '\nDéveloppé et édité par TCHINDA NOTSAWO ANAIS YANN.' +
                '\nContact : yanntchinda813@gmail.com'
            });
          }
        },
        {
          label: 'Où sont mes données ?',
          click: () => {
            shell.openPath(app.getPath('userData'));
          }
        },
        {
          label: 'Sauvegardes automatiques (Documents)',
          click: () => {
            const folder = backupsFolder();
            try { fs.mkdirSync(folder, { recursive: true }); } catch (e) {}
            shell.openPath(folder);
          }
        }
      ]
    }
  ];

  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

/* Empêche toute impression avant que la page ne soit prête. */
app.on('second-instance', () => {
  if (mainWindow) {
    if (mainWindow.isMinimized()) mainWindow.restore();
    mainWindow.focus();
  }
});

app.whenReady().then(() => {
  writeDiagnostic();
  installAutoBackup();
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
