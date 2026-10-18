const { app, BrowserWindow, Menu, dialog, shell } = require('electron');
const path = require('path');
const fs = require('fs');

let mainWindow;

function createWindow () {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1024,
    minHeight: 700,
    title: 'e-School - Gestion des bulletins scolaires',
    icon: path.join(__dirname, 'app/icon.png'),
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      enableRemoteModule: false
    }
  });

  // Charger l'application
  mainWindow.loadFile(path.join(__dirname, 'app/index.html'));

  // Ouvrir les liens externes dans le navigateur système
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  // Menu personnalisé
  const template = [
    {
      label: 'Fichier',
      submenu: [
        {
          label: 'Exporter une sauvegarde',
          click: () => {
            mainWindow.webContents.send('menu-action', 'backup');
          }
        },
        {
          label: 'Restaurer une sauvegarde',
          click: () => {
            mainWindow.webContents.send('menu-action', 'restore');
          }
        },
        { type: 'separator' },
        {
          label: 'Imprimer',
          accelerator: 'Ctrl+P',
          click: () => {
            mainWindow.webContents.print();
          }
        },
        { type: 'separator' },
        {
          label: 'Quitter',
          accelerator: process.platform === 'darwin' ? 'Cmd+Q' : 'Alt+F4',
          click: () => {
            app.quit();
          }
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
        { label: 'Coller', accelerator: 'Ctrl+V', role: 'paste' }
      ]
    },
    {
      label: 'Affichage',
      submenu: [
        { label: 'Recharger', accelerator: 'Ctrl+R', role: 'reload' },
        { label: 'Outils de développement', accelerator: 'F12', role: 'toggleDevTools' },
        { type: 'separator' },
        { label: 'Plein écran', accelerator: 'F11', role: 'togglefullscreen' },
        { label: 'Zoom +', accelerator: 'Ctrl+=', role: 'zoomIn' },
        { label: 'Zoom -', accelerator: 'Ctrl+-', role: 'zoomOut' },
        { label: 'Zoom par défaut', accelerator: 'Ctrl+0', role: 'resetZoom' }
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
              message: 'e-School - Gestion des bulletins scolaires',
              detail: 'Version 1.0.0\nApplication de bureau pour la gestion des notes et bulletins scolaires.\nDonnées enregistrées localement sur votre ordinateur.'
            });
          }
        }
      ]
    }
  ];

  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
