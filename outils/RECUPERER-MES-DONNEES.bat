@echo off
setlocal
title GestSchool - recuperation des donnees
cls
echo.
echo   ============================================================
echo    GestSchool - RECUPERER MES DONNEES
echo   ============================================================
echo.
echo    Ce programme ne supprime rien.
echo    Il retrouve la base enregistree avant la mise a jour et la
echo    remet en place dans le logiciel.
echo.
echo    Laissez la fenetre ouverte jusqu'a la fin.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='%~f0'; $c=[IO.File]::ReadAllText($p,[Text.Encoding]::UTF8); $m='#'+'PSSTART'+'#'; $i=$c.IndexOf($m); if($i -lt 0){ Write-Host 'Script incomplet.'; exit 1 }; Invoke-Expression $c.Substring($i+$m.Length)"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo.
  echo Le programme s'est arrete avec le code %RC%.
  pause
)
exit /b %RC%
#PSSTART#
# ==========================================================================
#  GestSchool - RECUPERER MES DONNEES
#  Ce programme ne supprime rien. Il :
#    1. trouve les donnees du logiciel sur l'ordinateur : dossier de
#       l'ancien nom « e-School Gestion Bulletins », dossier actuel
#       « GestSchool », et navigateurs (Chrome, Edge, Brave) si l'ancienne
#       version a ete ouverte en double-cliquant sur le fichier .html ;
#    2. en fait une copie de securite sur le Bureau ;
#    3. classe TOUTES les bases trouvees de la plus complete a la plus vide
#       et ecrit un fichier .json par base ;
#    4. remet en place la base la plus complete ;
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
$global:GS_MAXJSON = 6

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

function PropExists {
  param($Obj, [string]$Name)
  if ($null -eq $Obj) { return $false }
  return ($null -ne $Obj.PSObject.Properties[$Name])
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

# Statistiques d'une base : sert a classer les bases trouvees. La plus
# complete (celle qui a le plus d'eleves) est proposee en premier.
function Get-DbStats {
  param($Obj)
  $classes = 0
  $students = 0
  $grades = 0
  $payments = 0
  $expenses = 0
  foreach ($c in @($Obj.classes)) {
    if ($null -eq $c) { continue }
    $classes = $classes + 1
    $students = $students + (ArrCount $c.students)
    if ((PropExists $c 'grades') -and $null -ne $c.grades) {
      foreach ($g in @($c.grades.PSObject.Properties)) {
        foreach ($sub in @($g.Value.PSObject.Properties)) {
          foreach ($v in @($sub.Value)) { if ($null -ne $v -and "$v" -ne '') { $grades = $grades + 1 } }
        }
      }
    }
  }
  if ((PropExists $Obj 'finance') -and $null -ne $Obj.finance) {
    if ((PropExists $Obj.finance 'pays') -and $null -ne $Obj.finance.pays) {
      foreach ($p in @($Obj.finance.pays.PSObject.Properties)) { $payments = $payments + (ArrCount $p.Value) }
    }
    if (PropExists $Obj.finance 'expenses') { $expenses = ArrCount $Obj.finance.expenses }
  }
  $users = ArrCount $Obj.users
  $archived = ArrCount $Obj.archivedStudents
  $sessions = ArrCount $Obj.sessions
  $score = ($students * 1000) + ($classes * 200) + ($payments * 3) + $expenses + ($archived * 5)
  return [pscustomobject]@{
    classes = $classes; students = $students; grades = $grades; payments = $payments
    expenses = $expenses; users = $users; archived = $archived; sessions = $sessions
    score = $score
  }
}

# Toutes les bases presentes dans un dossier de donnees (il peut y en avoir
# plusieurs : la base d'avant la mise a jour et celle, vide, ecrite apres).
function Find-DbObjects {
  param([string]$Dir)
  $out = @()
  $ls = Join-Path $Dir 'Local Storage\leveldb'
  if (-not (Test-Path -LiteralPath $ls)) { return $out }
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
      foreach ($m in [regex]::Matches($t, '\{"v":\s*\d+,')) {
        $json = Get-JsonAt -Text $t -Start $m.Index
        if (-not $json) { continue }
        $o = $null
        try { $o = $json | ConvertFrom-Json } catch { $o = $null }
        if ($null -eq $o) { continue }
        if (-not (PropExists $o 'school')) { continue }
        if (-not (PropExists $o 'users')) { continue }
        if (-not (PropExists $o 'classes')) { continue }
        $admins = 0
        foreach ($u in @($o.users)) { if ($u -ne $null -and $u.role -eq 'admin') { $admins = $admins + 1 } }
        if ($admins -lt 1) { continue }
        $out = $out + [pscustomobject]@{ Obj = $o; Json = $json; Dir = $Dir; File = $f.Name; When = $f.LastWriteTime }
      }
    }
  }
  return $out
}

function Save-BackupJson {
  param($Obj, [string]$Path)
  $st = Get-DbStats -Obj $Obj
  $counts = [ordered]@{
    classes  = $st.classes
    students = $st.students
    payments = $st.payments
    expenses = $st.expenses
    archived = $st.archived
    sessions = $st.sessions
    users    = $st.users
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
  return $st
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

function New-DbFile {
  param($Candidate, [int]$Rank, [string]$OutDir)
  $st = Get-DbStats -Obj $Candidate.Obj
  $name = 'DONNEES-' + $Rank
  if ($Rank -eq 1) { $name = $name + '_LA-PLUS-COMPLETE' }
  $name = $name + '_' + $st.classes + 'classes_' + $st.students + 'eleves.json'
  $path = Join-Path $OutDir $name
  $saved = Save-BackupJson -Obj $Candidate.Obj -Path $path
  return [pscustomobject]@{ Path = $path; Name = $name; Stats = $saved }
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
$browserName = @{}
foreach ($b in $browserProfiles) {
  $profiles = $profiles + $b.Path
  $browserName[$b.Path] = $b.Browser
}
$profiles = @($profiles | Select-Object -Unique)

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

Head '3. Bases retrouvees, de la plus complete a la plus vide'
$all = @()
foreach ($p in $profiles) {
  if (-not (Storage-HasData -Dir $p)) { continue }
  $all = $all + @(Find-DbObjects -Dir $p)
}
$seen = @{}
$uniq = @()
foreach ($c in $all) {
  $h = ''
  try {
    $sha = [System.Security.Cryptography.SHA1]::Create()
    $h = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($c.Json))).Replace('-', '')
  } catch { $h = $c.Json.Length.ToString() + '|' + $c.File }
  if ($seen.ContainsKey($h)) { continue }
  $seen[$h] = $true
  $st = Get-DbStats -Obj $c.Obj
  $c | Add-Member -NotePropertyName Stats -NotePropertyValue $st -Force
  $c | Add-Member -NotePropertyName Score -NotePropertyValue $st.score -Force
  $uniq = $uniq + $c
}
$ranked = @($uniq | Sort-Object Score -Descending)

if ($ranked.Count -eq 0) {
  Say '  Aucune base GestSchool / e-School identifiable sur cet ordinateur.'
} else {
  $rank = 0
  foreach ($c in $ranked) {
    $rank = $rank + 1
    $who = 'logiciel'
    if ($browserName.ContainsKey($c.Dir)) { $who = 'navigateur ' + $browserName[$c.Dir] }
    $nm = ''
    if ((PropExists $c.Obj.school) -and $c.Obj.school.name) { $nm = ' - ' + [string]$c.Obj.school.name }
    Say ('  ' + $rank + '. ' + $c.Stats.classes + ' classe(s), ' + $c.Stats.students + ' eleve(s), ' + $c.Stats.users + ' compte(s), ' + $c.Stats.payments + ' versement(s)  [' + $who + ']' + $nm)
  }
}

$files = @()
if ($ranked.Count -gt 0) {
  $rank = 0
  foreach ($c in $ranked) {
    $rank = $rank + 1
    if ($rank -gt $global:GS_MAXJSON) { break }
    if ($c.Stats.students -le 0 -and $c.Stats.classes -le 0) { continue }
    try {
      $made = New-DbFile -Candidate $c -Rank $rank -OutDir $outDir
      $files = $files + $made
      Say ''
      Say ('  Fichier ecrit : ' + $made.Path)
      Say ('      ' + $made.Stats.classes + ' classe(s), ' + $made.Stats.students + ' eleve(s), ' + $made.Stats.users + ' compte(s)')
    } catch { Say ('  Ecriture impossible du fichier n' + [char]176 + ' ' + $rank + ' : ' + $_.Exception.Message) }
  }
}
if ($files.Count -eq 0) {
  Say ''
  Say '  Aucun fichier .json n a pu etre ecrit (les bases trouvees sont vides).'
}

Head '4. Remise en place dans GestSchool'
$restored = $false
$alreadyHad = $false
if (-not (Test-Path -LiteralPath $target)) {
  try { New-Item -ItemType Directory -Force -Path $target | Out-Null } catch { }
}
$targetHas = Storage-HasData -Dir $target
$targetStats = $null
if ($targetHas) {
  $tCands = @(Find-DbObjects -Dir $target)
  if ($tCands.Count -gt 0) {
    $targetBest = $tCands | Sort-Object { (Get-DbStats -Obj $_.Obj).score } -Descending | Select-Object -First 1
    $targetStats = Get-DbStats -Obj $targetBest.Obj
  }
}
$sourceBest = $null
if ($ranked.Count -gt 0) { $sourceBest = $ranked[0] }
if ($null -ne $sourceBest -and $sourceBest.Dir -eq $target) { $sourceBest = $null }

if ($null -ne $sourceBest -and $null -ne $targetStats) {
  $sStats = $sourceBest.Stats
  if (($sStats.score -gt $targetStats.score) -and ($targetStats.students -eq 0) -and ($targetStats.classes -eq 0)) {
    Say '  Le dossier actuel ne contient aucune classe : il sera remplace.'
    $moved = Join-Path $outDir 'dossier-actuel-avant-remise-en-place'
    try { Copy-Item -LiteralPath (Join-Path $target 'Local Storage') -Destination (Join-Path $moved 'Local Storage') -Recurse -Force -ErrorAction SilentlyContinue } catch { }
    if (Copy-Store -From $sourceBest.Dir -To $target -LocalStorageOnly:($browserName.ContainsKey($sourceBest.Dir))) {
      $restored = $true
      Say ('      -> donnees remises en place : ' + $sStats.classes + ' classe(s), ' + $sStats.students + ' eleve(s)')
    } else {
      Say '      -> copie impossible (fichier verrouille ?)'
    }
  } else {
    Say '  Le dossier actuel contient deja des donnees (' + $targetStats.classes + ' classe(s), ' + $targetStats.students + ' eleve(s)) : rien n a ete remplace.'
  }
} elseif ($null -ne $sourceBest) {
  $sStats = $sourceBest.Stats
  Say ('  Copie de la base la plus complete (' + $sStats.classes + ' classe(s), ' + $sStats.students + ' eleve(s))')
  if (Copy-Store -From $sourceBest.Dir -To $target -LocalStorageOnly:($browserName.ContainsKey($sourceBest.Dir))) {
    $restored = $true
    Say ('      -> donnees remises dans ' + $target)
  } else {
    Say '      -> copie impossible (fichier verrouille ?)'
  }
} elseif ($targetHas) {
  $alreadyHad = $true
  Say '  Une base est deja en place dans GestSchool.'
  Say '  Ouvrez GestSchool : vos donnees devraient s afficher.'
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

# Petit mode d'emploi depose a cote des fichiers
try {
  $readme = @(
    'GestSchool - donnees recuperees',
    '',
    'Les fichiers DONNEES-1_..., DONNEES-2_... de ce dossier contiennent les bases',
    'trouvees sur cet ordinateur, de la plus complete (n 1) a la plus vide.',
    '',
    'Pour les remettre dans le logiciel :',
    '  1. Ouvrez GestSchool.',
    '  2. Menu Parametres > Importer un fichier de recuperation (.json)...',
    '  3. Choisissez DONNEES-1_LA-PLUS-COMPLETE_....json',
    '  4. Le logiciel affiche le nombre de classes, d''eleves et de comptes :',
    '     si cela correspond, cliquez sur Restaurer.',
    '',
    'Si le fichier n 1 est vide, essayez le n 2, puis le n 3.',
    'Le fichier RAPPORT.txt contient le detail de ce qui a ete trouve.'
  ) -join "`r`n"
  [IO.File]::WriteAllText((Join-Path $outDir 'LISEZ-MOI.txt'), $readme, (New-Object System.Text.UTF8Encoding($true)))
} catch { }

# --------------------------------------------------------------------------
$finalHas = Storage-HasData -Dir $target
Say ''
Say '=========================================================='
if ($restored -or $finalHas) {
  Say '   VOS DONNEES SONT EN PLACE.'
  Say ''
  Say '   1. Fermez cette fenetre.'
  Say '   2. Ouvrez GestSchool (icone du Bureau ou du menu Demarrer).'
  Say '   3. Vos classes, eleves, notes et finances doivent apparaitre.'
  if (-not $restored) { Say '' ; Say '   (Le dossier contenait deja une base : rien n a ete ecrase.)' }
} elseif ($files.Count -gt 0) {
  Say '   DONNEES RETROUVEES DANS UN FICHIER, A IMPORTER DANS LE LOGICIEL.'
  Say ''
  Say '   1. Ouvrez GestSchool.'
  Say '   2. Parametres > Importer un fichier de recuperation (.json)...'
  Say ('   3. Choisissez : ' + $files[0].Name)
  Say '      (le logiciel affiche le nombre de classes et d''eleves avant de restaurer)'
  Say ''
  Say '   Si ce fichier est vide, essayez DONNEES-2, DONNEES-3...'
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
