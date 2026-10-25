# ==========================================================================
#  GestSchool - RECUPERER MES DONNEES
#  Ce programme ne supprime rien. Il :
#    1. trouve les donnees du logiciel sur l'ordinateur : dossier de
#       l'ancien nom « e-School Gestion Bulletins », dossier actuel
#       « GestSchool », et navigateurs (Chrome, Edge, Brave) si l'ancienne
#       version a ete ouverte en double-cliquant sur le fichier .html ;
#    2. en fait une copie de securite sur le Bureau ;
#    3. remet l'ancienne base dans le dossier utilise par GestSchool ;
#    4. fabrique, si possible, un fichier de sauvegarde .json restaurable ;
#    5. retrouve les anciennes sauvegardes .json deja exportees.
#  Double-cliquer sur RECUPERER-MES-DONNEES.bat pour l'executer.
# ==========================================================================

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
try { $Host.UI.RawUI.WindowTitle = 'GestSchool - recuperation des donnees' } catch { }

$MARK = 'mbi_gestion_bulletins_v1'
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$desk = [Environment]::GetFolderPath('Desktop')
if (-not $desk -or -not (Test-Path -LiteralPath $desk)) { $desk = [Environment]::GetFolderPath('MyDocuments') }
$outDir = Join-Path $desk ('GestSchool-recuperation-' + $stamp)
$global:GS_LINES = New-Object System.Collections.Generic.List[string]

function Say {
  param([string]$Text = '')
  Write-Host $Text
  [void]$global:GS_LINES.Add($Text)
}

function Head {
  param([string]$Text)
  Say ''
  Say ('--- ' + $Text + ' ' + ('-' * [Math]::Max(3, 58 - $Text.Length)))
}

function ArrCount {
  param($Value)
  if ($null -eq $Value) { return 0 }
  return @($Value).Count
}

function Storage-HasData {
  param([string]$Dir)
  if (-not $Dir) { return $false }
  $ls = Join-Path $Dir 'Local Storage\leveldb'
  if (-not (Test-Path -LiteralPath $ls)) { return $false }
  $files = @(Get-ChildItem -LiteralPath $ls -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.(ldb|log)$' })
  foreach ($f in $files) {
    if ($f.Length -lt 200) { continue }
    try {
      $bytes = [IO.File]::ReadAllBytes($f.FullName)
      if ([Text.Encoding]::GetEncoding(28591).GetString($bytes).Contains($MARK)) { return $true }
      if ([Text.Encoding]::Unicode.GetString($bytes).Contains($MARK)) { return $true }
    } catch { }
  }
  return $false
}

function Storage-Size {
  param([string]$Dir)
  $ls = Join-Path $Dir 'Local Storage\leveldb'
  if (-not (Test-Path -LiteralPath $ls)) { return 0 }
  $files = @(Get-ChildItem -LiteralPath $ls -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.(ldb|log)$' })
  $sum = 0
  foreach ($f in $files) { $sum = $sum + $f.Length }
  return $sum
}

function Storage-Newest {
  param([string]$Dir)
  $newest = New-Object System.DateTime 2000, 1, 1
  $ls = Join-Path $Dir 'Local Storage\leveldb'
  if (-not (Test-Path -LiteralPath $ls)) { return $newest }
  $files = @(Get-ChildItem -LiteralPath $ls -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.(ldb|log)$' })
  foreach ($f in $files) { if ($f.LastWriteTime -gt $newest) { $newest = $f.LastWriteTime } }
  return $newest
}

function Get-JsonAt {
  param([string]$Text, [int]$Start)
  $depth = 0
  $inStr = $false
  $esc = $false
  for ($i = $Start; $i -lt $Text.Length; $i++) {
    $c = $Text[$i]
    if ($inStr) {
      if ($esc) { $esc = $false }
      elseif ($c -eq '\') { $esc = $true }
      elseif ($c -eq '"') { $inStr = $false }
    } else {
      if ($c -eq '"') { $inStr = $true }
      elseif ($c -eq '{') { $depth = $depth + 1 }
      elseif ($c -eq '}') {
        $depth = $depth - 1
        if ($depth -eq 0) { return $Text.Substring($Start, $i - $Start + 1) }
      }
    }
  }
  return $null
}

function Find-DbObject {
  param([string]$Dir)
  $ls = Join-Path $Dir 'Local Storage\leveldb'
  if (-not (Test-Path -LiteralPath $ls)) { return $null }
  $files = @(Get-ChildItem -LiteralPath $ls -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.(ldb|log)$' } | Sort-Object LastWriteTime -Descending)
  foreach ($f in $files) {
    if ($f.Length -lt 100) { continue }
    try { $bytes = [IO.File]::ReadAllBytes($f.FullName) } catch { continue }
    $texts = @(
      [Text.Encoding]::GetEncoding(28591).GetString($bytes),
      [Text.Encoding]::UTF8.GetString($bytes),
      [Text.Encoding]::Unicode.GetString($bytes)
    )
    foreach ($t in $texts) {
      $found = [regex]::Matches($t, '\{"v":\s*\d+,')
      foreach ($m in $found) {
        $json = Get-JsonAt -Text $t -Start $m.Index
        if (-not $json) { continue }
        $o = $null
        try { $o = $json | ConvertFrom-Json } catch { $o = $null }
        if ($null -eq $o) { continue }
        if ($null -eq $o.PSObject.Properties['school']) { continue }
        if ($null -eq $o.PSObject.Properties['users']) { continue }
        if ($null -eq $o.PSObject.Properties['classes']) { continue }
        $admins = 0
        foreach ($u in @($o.users)) { if ($u -ne $null -and $u.role -eq 'admin') { $admins = $admins + 1 } }
        if ($admins -lt 1) { continue }
        return $o
      }
    }
  }
  return $null
}

function Save-BackupJson {
  param($Obj, [string]$Path)
  $classes = 0
  $students = 0
  $payments = 0
  $expenses = 0
  foreach ($c in @($Obj.classes)) {
    if ($null -eq $c) { continue }
    $classes = $classes + 1
    $students = $students + (ArrCount $c.students)
  }
  if ($null -ne $Obj.PSObject.Properties['finance'] -and $null -ne $Obj.finance) {
    if ($null -ne $Obj.finance.PSObject.Properties['pays'] -and $null -ne $Obj.finance.pays) {
      foreach ($p in $Obj.finance.pays.PSObject.Properties) { $payments = $payments + (ArrCount $p.Value) }
    }
    if ($null -ne $Obj.finance.PSObject.Properties['expenses']) { $expenses = ArrCount $Obj.finance.expenses }
  }
  $counts = [ordered]@{
    classes  = $classes
    students = $students
    payments = $payments
    expenses = $expenses
    archived = (ArrCount $Obj.archivedStudents)
    sessions = (ArrCount $Obj.sessions)
    users    = (ArrCount $Obj.users)
  }
  $pack = [ordered]@{
    app         = 'gestschool'
    format      = 2
    exported_at = (Get-Date).ToString('o')
    school      = [ordered]@{
      name = [string]$Obj.school.name
      city = [string]$Obj.school.city
      year = [string]$Obj.school.year
    }
    counts      = $counts
    data        = $Obj
  }
  $text = $pack | ConvertTo-Json -Depth 100 -Compress
  [IO.File]::WriteAllText($Path, $text, (New-Object System.Text.UTF8Encoding($false)))
  return $counts
}

function Copy-Store {
  param([string]$From, [string]$To, [switch]$LocalStorageOnly)
  $subs = @('Local Storage', 'Session Storage', 'IndexedDB', 'Preferences')
  if ($LocalStorageOnly) { $subs = @('Local Storage', 'Session Storage') }
  try { New-Item -ItemType Directory -Force -Path $To | Out-Null } catch { return $false }
  foreach ($sub in $subs) {
    $src = Join-Path $From $sub
    if (-not (Test-Path -LiteralPath $src)) { continue }
    $dst = Join-Path $To $sub
    if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force -ErrorAction SilentlyContinue }
    Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force -ErrorAction SilentlyContinue
  }
  return (Storage-HasData -Dir $To)
}

function Find-BackupFiles {
  param([string[]]$Dirs)
  $found = @()
  foreach ($d in $Dirs) {
    if (-not $d -or -not (Test-Path -LiteralPath $d)) { continue }
    $files = @(Get-ChildItem -LiteralPath $d -Filter '*.json' -File -Recurse -Depth 3 -ErrorAction SilentlyContinue)
    foreach ($f in $files) {
      if ($f.Length -lt 500) { continue }
      if ($f.FullName.StartsWith($outDir)) { continue }
      $head = ''
      try {
        $n = [int][Math]::Min(6000, $f.Length)
        $buffer = New-Object -TypeName 'System.Byte[]' -ArgumentList $n
        $fs = [IO.File]::OpenRead($f.FullName)
        [void]$fs.Read($buffer, 0, $n)
        $fs.Close()
        $head = [Text.Encoding]::UTF8.GetString($buffer)
      } catch { continue }
      if ($head.Contains('"users"') -and $head.Contains('"classes"')) { $found = $found + $f }
    }
  }
  return $found
}

# Dossiers de stockage des navigateurs : si l'ancienne version a ete ouverte
# en double-cliquant sur un fichier .html, les donnees sont la.
function Get-BrowserProfiles {
  param([string]$LocalApp)
  $roots = @(
    @{ Name = 'Google Chrome'; Dir = (Join-Path $LocalApp 'Google\Chrome\User Data') },
    @{ Name = 'Microsoft Edge'; Dir = (Join-Path $LocalApp 'Microsoft\Edge\User Data') },
    @{ Name = 'Brave'; Dir = (Join-Path $LocalApp 'BraveSoftware\Brave-Browser\User Data') }
  )
  $list = @()
  foreach ($r in $roots) {
    if (-not (Test-Path -LiteralPath $r.Dir)) { continue }
    $subs = @(Get-ChildItem -LiteralPath $r.Dir -Directory -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -eq 'Default' -or $_.Name -like 'Profile *' })
    foreach ($s in $subs) {
      $list = $list + [pscustomobject]@{ Path = $s.FullName; Browser = $r.Name; Profile = $s.Name }
    }
  }
  return $list
}

# --------------------------------------------------------------------------
Say '=========================================================='
Say '   GestSchool - recuperation des donnees'
Say '=========================================================='
Say ''
Say 'Ce programme ne supprime RIEN.'
Say 'Il remet en place les donnees enregistrees avant la mise a jour.'
Say ''

try { New-Item -ItemType Directory -Force -Path $outDir | Out-Null } catch { }

$roaming = [Environment]::GetFolderPath('ApplicationData')
$localApp = [Environment]::GetFolderPath('LocalApplicationData')
$target = Join-Path $roaming 'GestSchool'

Head '0. Logiciel et navigateurs ouverts'
$runningApp = @()
try {
  $runningApp = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -eq 'GestSchool' -or $_.ProcessName -eq 'e-School Gestion Bulletins'
  })
} catch { }
$runningWeb = @()
try {
  $runningWeb = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -eq 'chrome' -or $_.ProcessName -eq 'msedge' -or $_.ProcessName -eq 'brave'
  })
} catch { }
if ($runningApp.Count -gt 0 -or $runningWeb.Count -gt 0) {
  if ($runningApp.Count -gt 0) { Say '  GestSchool est encore ouvert.' }
  if ($runningWeb.Count -gt 0) { Say '  Un navigateur (Chrome, Edge ou Brave) est encore ouvert.' }
  Say '  Fermez-les pour que la copie soit complete.'
  Write-Host '  Appuyez sur Entree une fois ferme...' -NoNewline
  try { [void](Read-Host) } catch { }
} else {
  Say '  Application et navigateurs fermes : parfait.'
}

Head '1. Dossiers de donnees trouves'
$profiles = @()
foreach ($n in @('GestSchool', 'e-School Gestion Bulletins', 'e-School', 'eSchool')) {
  $p = Join-Path $roaming $n
  if (Test-Path -LiteralPath $p) { $profiles = $profiles + $p }
}
foreach ($d in @(Get-ChildItem -LiteralPath $roaming -Directory -ErrorAction SilentlyContinue)) {
  $lsDir = Join-Path $d.FullName 'Local Storage\leveldb'
  if (($profiles -notcontains $d.FullName) -and (Test-Path -LiteralPath $lsDir)) {
    $profiles = $profiles + $d.FullName
  }
}
$browserProfiles = @(Get-BrowserProfiles -LocalApp $localApp)
foreach ($b in $browserProfiles) { $profiles = $profiles + $b.Path }
$profiles = @($profiles | Select-Object -Unique)

$browserName = @{}
foreach ($b in $browserProfiles) { $browserName[$b.Path] = $b.Browser }

if ($profiles.Count -eq 0) {
  Say '  Aucun dossier de donnees trouve.'
  Say ('  (recherche dans : ' + $roaming + ')')
} else {
  foreach ($p in $profiles) {
    $size = Storage-Size -Dir $p
    $has = Storage-HasData -Dir $p
    $newest = Storage-Newest -Dir $p
    $tag = 'vide'
    if ($has) { $tag = 'DONNEES TROUVEES' }
    elseif ($size -gt 0) { $tag = 'fichiers presents, sans la base' }
    $origin = 'logiciel'
    if ($browserName.ContainsKey($p)) { $origin = 'navigateur ' + $browserName[$p] }
    Say ('  ' + $p)
    Say ('      ' + $tag + '  -  ' + $origin + '  -  ' + [Math]::Round($size / 1024, 1) + ' Ko  -  dernier fichier : ' + $newest.ToString('dd/MM/yyyy HH:mm'))
  }
}

Head '2. Copie de securite'
$index = 0
foreach ($p in $profiles) {
  $index = $index + 1
  $dest = Join-Path $outDir ('dossier-' + $index + '-' + $p.Split('\')[-1])
  try { New-Item -ItemType Directory -Force -Path $dest | Out-Null } catch { }
  $copied = 0
  foreach ($sub in @('Local Storage', 'Session Storage', 'IndexedDB')) {
    $src = Join-Path $p $sub
    if (-not (Test-Path -LiteralPath $src)) { continue }
    try {
      Copy-Item -LiteralPath $src -Destination (Join-Path $dest $sub) -Recurse -Force -ErrorAction SilentlyContinue
      $copied = $copied + 1
    } catch { }
  }
  Say ('  ' + $p + '  ->  ' + $copied + ' sous-dossier(s) copie(s)')
}

Head '3. Base de donnees retrouvee'
$withData = @($profiles | Where-Object { Storage-HasData -Dir $_ } | Sort-Object { Storage-Newest -Dir $_ } -Descending)
if ($withData.Count -eq 0) {
  Say '  Aucune base GestSchool / e-School identifiable sur cet ordinateur.'
} else {
  foreach ($p in $withData) {
    $who = 'logiciel'
    if ($browserName.ContainsKey($p)) { $who = 'navigateur ' + $browserName[$p] }
    Say ('  ' + (Storage-Newest -Dir $p).ToString('dd/MM/yyyy HH:mm') + '  ' + $who + '  ' + $p)
  }
}

$best = $null
if ($withData.Count -gt 0) { $best = $withData[0] }
$jsonPath = ''
$counts = $null
$extractOk = $false
if ($best) {
  $db = Find-DbObject -Dir $best
  if ($null -ne $db) {
    $jsonPath = Join-Path $outDir ('DONNEES-RECUPEREES_' + $stamp + '.json')
    try { $counts = Save-BackupJson -Obj $db -Path $jsonPath; $extractOk = $true } catch { $counts = $null; $jsonPath = '' }
  }
}
if ($extractOk) {
  Say ''
  Say ('  Etablissement : ' + $counts['classes'] + ' classe(s), ' + $counts['students'] + ' eleve(s), ' + $counts['users'] + ' compte(s), ' + $counts['payments'] + ' versement(s).')
  Say ('  Fichier de sauvegarde cree : ' + $jsonPath)
} elseif ($best) {
  Say ''
  Say '  La base est bien la, mais elle est compressee par le logiciel :'
  Say '  elle ne peut pas etre transformee en fichier .json.'
  Say '  C est normal : l etape 4 la remet directement en place.'
}

Head '4. Remise en place dans GestSchool'
$restored = $false
$alreadyHad = $false
if (-not (Test-Path -LiteralPath $target)) {
  try { New-Item -ItemType Directory -Force -Path $target | Out-Null } catch { }
}
$targetHas = Storage-HasData -Dir $target
$sources = @($withData | Where-Object { $_ -ne $target })

if ($targetHas) {
  $alreadyHad = $true
  Say '  Le dossier actuel de GestSchool contient deja une base : rien n a ete remplace.'
  Say '  Ouvrez GestSchool : vos donnees devraient s afficher.'
  Say '  Si vous voulez plutot remettre une autre version des donnees, utilisez le'
  Say '  fichier .json de l etape 3 : GestSchool > Parametres > Restaurer une sauvegarde.'
} elseif ($sources.Count -gt 0) {
  foreach ($src in $sources) {
    $who = 'dossier ' + $src
    if ($browserName.ContainsKey($src)) { $who = 'navigateur ' + $browserName[$src] }
    Say ('  Copie depuis : ' + $who)
    $localOnly = $browserName.ContainsKey($src)
    if (Copy-Store -From $src -To $target -LocalStorageOnly:$localOnly) {
      $restored = $true
      Say ('      -> donnees remises dans ' + $target)
      break
    } else {
      Say '      -> copie impossible (fichier verrouille ?)'
    }
  }
} else {
  Say '  Aucune base a remettre en place.'
}

Head '5. Anciennes sauvegardes .json'
$searchDirs = @(
  [Environment]::GetFolderPath('Desktop'),
  (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'),
  [Environment]::GetFolderPath('MyDocuments'),
  (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'OneDrive'),
  $roaming
)
$backups = @(Find-BackupFiles -Dirs $searchDirs | Sort-Object LastWriteTime -Descending)
if ($backups.Count -eq 0) {
  Say '  Aucun fichier sauvegarde-gestschool_*.json trouve.'
} else {
  $i2 = 0
  foreach ($b in $backups) {
    $i2 = $i2 + 1
    if ($i2 -le 10) { Say ('  ' + $b.LastWriteTime.ToString('dd/MM/yyyy HH:mm') + '  ' + [Math]::Round($b.Length / 1024) + ' Ko  ' + $b.FullName) }
    try { Copy-Item -LiteralPath $b.FullName -Destination (Join-Path $outDir $b.Name) -Force -ErrorAction SilentlyContinue } catch { }
  }
  Say ('  ' + $backups.Count + ' fichier(s) copie(s) dans le dossier de recuperation.')
}

# --------------------------------------------------------------------------
$finalHas = Storage-HasData -Dir $target
Say ''
Say '=========================================================='
if ($finalHas) {
  Say '   VOS DONNEES SONT EN PLACE.'
  Say ''
  Say '   1. Fermez cette fenetre.'
  Say '   2. Ouvrez GestSchool (icone du Bureau ou du menu Demarrer).'
  Say '   3. Vos classes, eleves, notes et finances doivent apparaitre.'
  if (-not $restored) { Say '' ; Say '   (Le dossier contenait deja une base : rien n a ete ecrase.)' }
} elseif ($extractOk) {
  Say '   SAUVEGARDE RETROUVEE, A RESTAURER DANS LE LOGICIEL.'
  Say ''
  Say '   1. Ouvrez GestSchool.'
  Say '   2. Parametres > Restaurer une sauvegarde...'
  Say ('   3. Choisissez : ' + $jsonPath)
} else {
  Say '   AUCUNE DONNEE RETROUVEE AUTOMATIQUEMENT.'
  Say ''
  Say '   Le dossier ci-dessous contient tout ce qui a ete trouve sur cet'
  Say '   ordinateur. Envoyez-le (ou son fichier RAPPORT.txt) pour analyse :'
  Say ('      ' + $outDir)
  Say ''
  Say '   Verifiez aussi qu il ne reste pas une ancienne sauvegarde .json'
  Say '   dans Telechargements, le Bureau, Documents ou OneDrive.'
}
Say '=========================================================='
Say ''
Say ('Dossier de recuperation : ' + $outDir)

try {
  [IO.File]::WriteAllText((Join-Path $outDir 'RAPPORT.txt'), ($global:GS_LINES -join "`r`n"), (New-Object System.Text.UTF8Encoding($true)))
} catch { }

try { Start-Process -FilePath $outDir } catch { }

Write-Host ''
Write-Host 'Appuyez sur une touche pour fermer cette fenetre...'
try { $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } catch { Start-Sleep -Seconds 30 }
