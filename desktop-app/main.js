'use strict';

const { app, BrowserWindow, Menu, dialog, shell } = require('electron');
const path = require('path');

let mainWindow = null;

/* Une seule instance : si l'utilisateur reclique sur l'icône, on réutilise la fenêtre ouverte. */
if (!app.requestSingleInstanceLock()) {
  app.quit();
}

/* Identifiant Windows (raccourci correct, notifications, barre des tâches). */
app.setAppUserModelId('com.eschool.bulletins');

function createWindow () {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1024,
    minHeight: 700,
    title: 'e-School - Gestion des bulletins',
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
              message: 'e-School - Gestion des bulletins',
              detail: 'Version ' + app.getVersion() +
                '\nÉlèves, notes, bulletins, personnel et finances.' +
                '\n\nDonnées enregistrées localement sur cet ordinateur,' +
                '\nou sur la base partagée configurée dans les Paramètres.' +
                '\nAucune connexion internet n\'est nécessaire.'
            });
          }
        },
        {
          label: 'Où sont mes données ?',
          click: () => {
            shell.openPath(app.getPath('userData'));
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
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
