@echo off
setlocal EnableExtensions
title NULL REMOVER
color 0A
cd /d "%~dp0"
chcp 65001 >nul 2>&1

:: Tek dosya: asil program asagidaki PowerShell blogudur.
:: Bu bolum sadece cift-tik / surukle-birak icin baslatici.
set "TMPPS=%TEMP%\Null_Remover_%RANDOM%%RANDOM%.ps1"
:: Isaretleyiciyi parcali kur ki IndexOf yanlis eslesmesin (sadece gercek ayirici satiri)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$c = Get-Content -LiteralPath '%~f0' -Raw -Encoding UTF8; $m = '#' + ' >>>PS>>>'; $i = $c.IndexOf($m); if ($i -lt 0) { throw 'PowerShell blogu bulunamadi' }; $ps = $c.Substring($i + $m.Length).TrimStart([char]13, [char]10); [System.IO.File]::WriteAllText('%TMPPS%', $ps, (New-Object System.Text.UTF8Encoding $false))"
if errorlevel 1 (
  echo [HATA] PowerShell blogu cikarilamadi.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%TMPPS%" %*
set "ERR=%ERRORLEVEL%"
del /f /q "%TMPPS%" >nul 2>&1
exit /b %ERR%

# >>>PS>>>
#Requires -Version 5.1
<#
.SYNOPSIS
  Windows reserved-name (nul, con, prn...) scanner and remover.
  Menu UI + drag-drop. Single file: Null_Remover.cmd
  Languages: Turkish (default) / English
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$DropPaths
)

$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'NULL REMOVER - Windows Reserved Name Tool'

try {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    } else {
        chcp 65001 | Out-Null
        $OutputEncoding = [System.Text.Encoding]::UTF8
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    }
} catch {}

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
$script:ReservedRx = '^(CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])(\..*)?$'
$script:SkipDirNames = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)
@(
    '$Recycle.Bin', 'System Volume Information', 'Recovery',
    'Windows\WinSxS', 'Windows\Installer', 'Windows\Servicing',
    'Config.Msi', 'hiberfil.sys', 'pagefile.sys', 'swapfile.sys'
) | ForEach-Object { [void]$script:SkipDirNames.Add($_) }

# ---------------------------------------------------------------------------
# i18n  (default: tr)
# ---------------------------------------------------------------------------
$script:Lang = 'tr'

$script:L = @{
    tr = @{
        BannerSub1          = 'Agent / tool hatalarindan kalan hayalet dosyalari temizler'
        PauseDefault        = 'Devam etmek icin bir tusa bas...'
        PauseClose          = 'Kapatmak icin bir tusa bas...'
        InvalidChoice       = 'Gecersiz secim. ({0})'
        ErrPrefix           = '+HATA'
        PathMissing         = 'Yol yok: {0}'
        ScanStarted         = 'Tarama basladi: {0}'
        ScanMode            = 'Mod: {0}'
        ModeRecurse         = 'recursive'
        ModeFlat            = 'sadece bu klasor'
        Scanning            = '  taraniyor... dizin={0}  bulunan={1}  kuyruk={2}   '
        ScanDone            = 'Tarama bitti. Dizin: {0} | Bulunan: {1} | Erisim hatasi: {2}'
        NoneFound           = 'Reserved isimli dosya/klasor bulunamadi.'
        ResultsTitle        = 'SONUC: {0} adet'
        ColNo               = 'No'
        ColType             = 'Tip'
        ColSize             = 'Boyut'
        ColPath             = 'Yol'
        StillExists         = 'hala mevcut'
        NothingToDelete     = 'Silinecek oge yok.'
        BulkConfirmTitle    = 'TOPLU SILME ONAYI'
        BulkConfirmWarn     = '{0} oge silinecek. Bu islem geri alinamaz.'
        ConfirmPrompt       = '  Onaylamak icin  {0}  yaz (buyuk harf): '
        ConfirmWord         = 'EVET'
        Cancelled           = 'Iptal edildi.'
        CancelledShort      = 'Iptal.'
        Summary             = 'Ozet: {0} silindi, {1} hata'
        SelectiveTitle      = 'SECIMLI SILME'
        SelectiveHint       = 'Ornekler:  1   |  1,3,5   |  1-4   |  2,5-7   |  a (hepsi)  |  q (iptal)'
        SelectPrompt        = '  Secim: '
        NoValidSelection    = 'Gecerli secim yok.'
        SelectedItems       = 'Secilen {0} oge:'
        DeleteConfirmPrompt = '  Silmek icin {0} yaz: '
        PostWhatNext        = 'NE YAPILSIN?'
        PostDeleteAll       = '    [1]  Hepsini sil (onayli toplu silme)'
        PostDeleteSel       = '    [2]  Secimli sil (numara ile sec)'
        PostShowAgain       = '    [3]  Listeyi tekrar goster'
        PostSave            = '    [4]  Sonuclari dosyaya kaydet (Desktop\nul_scan.txt)'
        PostBack            = '    [0]  Ana menuye don'
        YourChoice          = 'Seciminiz:'
        Saved               = 'Kaydedildi: {0}'
        ScanCTitle          = 'C:\ TAM DISK TARAMASI'
        ScanCWarn1          = 'Bu islem uzun surebilir (dakikalar). Sistem klasorleri atlanir.'
        ScanCWarn2          = 'Sadece TARAMA yapilir; silme icin sonra onay istenir.'
        ScanCStart          = '  Baslatmak icin Enter, iptal icin q: '
        CustomTitle         = 'OZEL YOL TARAMA'
        CustomExample       = '  Ornek: C:\GOO3\www   veya   D:\projects'
        PathPrompt          = '  Yol: '
        PathEmpty           = 'Yol girilmedi.'
        PathNotFound        = 'Yol bulunamadi: {0}'
        ModeThisFolder      = '    [1] Sadece bu klasor'
        ModeRecursive       = '    [2] Alt klasorlerle (recursive)'
        ModePrompt          = 'Mod:'
        QuickTitle          = 'HIZLI TEK DOSYA / KLASOR SIL'
        QuickHint           = 'Tam yolu yaz (orn: C:\GOO3\www\mgm\nul)'
        PathNone            = 'Yol yok.'
        WillDelete          = '  Silinecek: {0}'
        ConfirmEVET         = '  Onay {0}: '
        AboutTitle          = 'HAKKINDA'
        About1              = 'Windows reserved aygit adlari dosya olarak olusunca Explorer silemez.'
        About2              = 'Bu arac \\?\ extended path ile siler.'
        About3              = 'Hedef isimler: nul, con, prn, aux, com0-9, lpt0-9 (+ uzantili varyantlar)'
        About4              = 'Surukle-birak: Null_Remover.cmd uzerine dosya/klasor birak.'
        About5              = 'Tek dosya: baslatici + PowerShell ayni .cmd icinde.'
        About6              = 'Guvenlik: toplu silmede {0} yazman gerekir.'
        About7              = 'Dil: ana menuden Turkce / English secilebilir (varsayilan: Turkce).'
        AboutWarn           = 'C:\ taramasi sistemde cok yer gezer; admin olmadan bazi dizinler atlanir.'
        DropTitle           = 'SURUKLE-BIRAK MODU'
        DropScanFolder      = 'Klasor taraniyor (1 seviye): {0}'
        DropNone            = '  reserved isim yok'
        MainTitle           = 'A N A   M E N U'
        Main1               = '    [1]  C:\ tum dizinlerde tara  (sonra silme secenegi)'
        Main2               = '    [2]  Ozel yol tara           (klasor sec, recursive opsiyon)'
        Main3               = '    [3]  Hizli sil               (tek dosya yolu gir)'
        Main4               = '    [4]  Hakkinda / yardim'
        Main5               = '    [5]  Dil / Language          (simdi: Turkce)'
        Main0               = '    [0]  Cikis'
        MainTip             = '  |  Ipucu: Explorer nul suruklemiyorsa klasoru .cmd uzerine birak  |'
        MainChoice          = 'Seciminiz [0-5]:'
        Bye                 = '  Gorusuruz.'
        LangTitle           = 'DIL / LANGUAGE'
        LangCurrent         = 'Aktif dil: Turkce'
        LangOpt1            = '    [1]  Turkce'
        LangOpt2            = '    [2]  English'
        LangOpt0            = '    [0]  Geri'
        LangPrompt          = 'Seciminiz:'
        LangSetTr           = 'Dil Turkce olarak ayarlandi.'
        LangSetEn           = 'Language set to English.'
    }
    en = @{
        BannerSub1          = 'Cleans ghost files left by agent / tool errors'
        PauseDefault        = 'Press any key to continue...'
        PauseClose          = 'Press any key to close...'
        InvalidChoice       = 'Invalid choice. ({0})'
        ErrPrefix           = '+ERR '
        PathMissing         = 'Path not found: {0}'
        ScanStarted         = 'Scan started: {0}'
        ScanMode            = 'Mode: {0}'
        ModeRecurse         = 'recursive'
        ModeFlat            = 'this folder only'
        Scanning            = '  scanning... dirs={0}  found={1}  queue={2}   '
        ScanDone            = 'Scan done. Dirs: {0} | Found: {1} | Access errors: {2}'
        NoneFound           = 'No reserved-name files/folders found.'
        ResultsTitle        = 'RESULT: {0} item(s)'
        ColNo               = 'No'
        ColType             = 'Type'
        ColSize             = 'Size'
        ColPath             = 'Path'
        StillExists         = 'still exists'
        NothingToDelete     = 'Nothing to delete.'
        BulkConfirmTitle    = 'BULK DELETE CONFIRMATION'
        BulkConfirmWarn     = '{0} item(s) will be deleted. This cannot be undone.'
        ConfirmPrompt       = '  Type  {0}  to confirm (uppercase): '
        ConfirmWord         = 'YES'
        Cancelled           = 'Cancelled.'
        CancelledShort      = 'Cancelled.'
        Summary             = 'Summary: {0} deleted, {1} failed'
        SelectiveTitle      = 'SELECTIVE DELETE'
        SelectiveHint       = 'Examples:  1   |  1,3,5   |  1-4   |  2,5-7   |  a (all)  |  q (cancel)'
        SelectPrompt        = '  Selection: '
        NoValidSelection    = 'No valid selection.'
        SelectedItems       = 'Selected {0} item(s):'
        DeleteConfirmPrompt = '  Type {0} to delete: '
        PostWhatNext        = 'WHAT NEXT?'
        PostDeleteAll       = '    [1]  Delete all (confirmed bulk delete)'
        PostDeleteSel       = '    [2]  Selective delete (pick by number)'
        PostShowAgain       = '    [3]  Show list again'
        PostSave            = '    [4]  Save results to file (Desktop\nul_scan.txt)'
        PostBack            = '    [0]  Back to main menu'
        YourChoice          = 'Your choice:'
        Saved               = 'Saved: {0}'
        ScanCTitle          = 'C:\ FULL DRIVE SCAN'
        ScanCWarn1          = 'This may take a while (minutes). System folders are skipped.'
        ScanCWarn2          = 'SCAN only; delete requires confirmation afterwards.'
        ScanCStart          = '  Press Enter to start, q to cancel: '
        CustomTitle         = 'CUSTOM PATH SCAN'
        CustomExample       = '  Example: C:\GOO3\www   or   D:\projects'
        PathPrompt          = '  Path: '
        PathEmpty           = 'No path entered.'
        PathNotFound        = 'Path not found: {0}'
        ModeThisFolder      = '    [1] This folder only'
        ModeRecursive       = '    [2] Include subfolders (recursive)'
        ModePrompt          = 'Mode:'
        QuickTitle          = 'QUICK DELETE FILE / FOLDER'
        QuickHint           = 'Enter full path (e.g. C:\GOO3\www\mgm\nul)'
        PathNone            = 'No path.'
        WillDelete          = '  Will delete: {0}'
        ConfirmEVET         = '  Confirm {0}: '
        AboutTitle          = 'ABOUT'
        About1              = 'When Windows reserved device names exist as files, Explorer cannot delete them.'
        About2              = 'This tool deletes via \\?\ extended paths.'
        About3              = 'Targets: nul, con, prn, aux, com0-9, lpt0-9 (+ extension variants)'
        About4              = 'Drag-drop: drop files/folders onto Null_Remover.cmd.'
        About5              = 'Single file: launcher + PowerShell in the same .cmd.'
        About6              = 'Safety: bulk delete requires typing {0}.'
        About7              = 'Language: switch Turkish / English from the main menu (default: Turkish).'
        AboutWarn           = 'C:\ scan walks a lot of the system; some dirs need admin.'
        DropTitle           = 'DRAG-AND-DROP MODE'
        DropScanFolder      = 'Scanning folder (1 level): {0}'
        DropNone            = '  no reserved names'
        MainTitle           = 'M A I N   M E N U'
        Main1               = '    [1]  Scan all of C:\           (then delete options)'
        Main2               = '    [2]  Scan custom path          (folder, optional recursive)'
        Main3               = '    [3]  Quick delete              (enter a single path)'
        Main4               = '    [4]  About / help'
        Main5               = '    [5]  Language / Dil            (now: English)'
        Main0               = '    [0]  Exit'
        MainTip             = '  |  Tip: if Explorer cannot drag nul, drop the folder on this .cmd  |'
        MainChoice          = 'Your choice [0-5]:'
        Bye                 = '  Goodbye.'
        LangTitle           = 'LANGUAGE / DIL'
        LangCurrent         = 'Current language: English'
        LangOpt1            = '    [1]  Turkce'
        LangOpt2            = '    [2]  English'
        LangOpt0            = '    [0]  Back'
        LangPrompt          = 'Your choice:'
        LangSetTr           = 'Dil Turkce olarak ayarlandi.'
        LangSetEn           = 'Language set to English.'
    }
}

function T {
    param(
        [Parameter(Mandatory = $true)][string]$Key,
        [object[]]$FormatArgs
    )
    $map = $script:L[$script:Lang]
    if (-not $map -or -not $map.ContainsKey($Key)) {
        $map = $script:L['tr']
    }
    $s = $map[$Key]
    if ($null -eq $s) { return $Key }
    if ($FormatArgs -and $FormatArgs.Count -gt 0) {
        return ($s -f $FormatArgs)
    }
    return $s
}

function Get-ConfirmWord {
    return (T 'ConfirmWord')
}

function Test-IsConfirm([string]$ans) {
    # Accept both languages so users are not trapped mid-session
    $a = if ($null -eq $ans) { '' } else { $ans.Trim() }
    return ($a -eq 'EVET' -or $a -eq 'YES')
}

# ---------------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------------
function Write-Banner {
    Clear-Host
    $c = 'Cyan'
    $sub = T 'BannerSub1'
    if ($sub.Length -gt 66) { $sub = $sub.Substring(0, 66) }
    $subPad = $sub.PadRight(66)
    Write-Host ''
    Write-Host '  +====================================================================+' -ForegroundColor $c
    Write-Host '  |                                                                    |' -ForegroundColor $c
    Write-Host '  |   ##    ## ##     ## ##       ##                                  |' -ForegroundColor White
    Write-Host '  |   ###   ## ##     ## ##       ##                                  |' -ForegroundColor White
    Write-Host '  |   ####  ## ##     ## ##       ##                                  |' -ForegroundColor White
    Write-Host '  |   ## ## ## ##     ## ##       ##                                  |' -ForegroundColor White
    Write-Host '  |   ##  #### ##     ## ##       ##                                  |' -ForegroundColor White
    Write-Host '  |   ##   ### ##     ## ##       ##                                  |' -ForegroundColor White
    Write-Host '  |   ##    ##  #######  ######## ########                            |' -ForegroundColor White
    Write-Host '  |                                                                    |' -ForegroundColor $c
    Write-Host '  |          R E S E R V E D   N A M E   R E M O V E R                |' -ForegroundColor Yellow
    Write-Host '  |                                                                    |' -ForegroundColor $c
    Write-Host '  |   Windows: nul  con  prn  aux  com1-9  lpt1-9                     |' -ForegroundColor DarkGray
    Write-Host ("  |   {0}|" -f $subPad) -ForegroundColor DarkGray
    Write-Host '  |                                                                    |' -ForegroundColor $c
    Write-Host '  +====================================================================+' -ForegroundColor $c
    Write-Host ''
}

function Write-Section([string]$Title) {
    Write-Host ''
    Write-Host ('  ---- {0} ' -f $Title).PadRight(70, '-') -ForegroundColor DarkCyan
    Write-Host ''
}

function Write-Info([string]$Msg)  { Write-Host ('  * {0}' -f $Msg) -ForegroundColor Gray }
function Write-Ok([string]$Msg)    { Write-Host ('  +OK    {0}' -f $Msg) -ForegroundColor Green }
function Write-Err([string]$Msg)   { Write-Host ('  {0}  {1}' -f (T 'ErrPrefix'), $Msg) -ForegroundColor Red }
function Write-Warn([string]$Msg)  { Write-Host ('  !      {0}' -f $Msg) -ForegroundColor Yellow }

function Pause-Key([string]$Msg) {
    if ([string]::IsNullOrWhiteSpace($Msg)) { $Msg = T 'PauseDefault' }
    Write-Host ''
    Write-Host ("  {0}" -f $Msg) -ForegroundColor DarkGray
    try { $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } catch { Read-Host | Out-Null }
}

function Read-MenuChoice([string]$Prompt, [string[]]$Valid) {
    while ($true) {
        Write-Host ''
        Write-Host ("  {0} " -f $Prompt) -NoNewline -ForegroundColor White
        $c = (Read-Host).Trim()
        if ($Valid -contains $c) { return $c }
        Write-Warn (T 'InvalidChoice' @($Valid -join ', '))
    }
}

function Get-ExtPath([string]$p) {
    if ([string]::IsNullOrWhiteSpace($p)) { return $p }
    if ($p.StartsWith('\\?\')) { return $p }
    if ($p.StartsWith('\\')) { return '\\?\UNC\' + $p.Substring(2) }
    return '\\?\' + $p
}

function Test-IsReserved([string]$Name) {
    return $Name -match $script:ReservedRx
}

function Test-StillExists([string]$ExtPath) {
    try {
        if ([System.IO.File]::Exists($ExtPath)) { return $true }
        if ([System.IO.Directory]::Exists($ExtPath)) { return $true }
        return $false
    } catch { return $false }
}

function Should-SkipDir([string]$Name, [string]$FullPath) {
    if ($script:SkipDirNames.Contains($Name)) { return $true }
    try {
        $attr = [System.IO.File]::GetAttributes((Get-ExtPath $FullPath))
        if (($attr -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return $true }
    } catch {}
    return $false
}

# ---------------------------------------------------------------------------
# Scan
# ---------------------------------------------------------------------------
function Find-ReservedItems {
    param(
        [string]$Root,
        [switch]$Recurse,
        [switch]$Quiet
    )

    $results = New-Object System.Collections.Generic.List[object]
    if (-not (Test-Path -LiteralPath $Root)) {
        Write-Err (T 'PathMissing' @($Root))
        return @()
    }

    $rootResolved = $Root
    try { $rootResolved = (Resolve-Path -LiteralPath $Root).Path } catch {}

    $queue = New-Object System.Collections.Generic.Queue[string]
    $queue.Enqueue($rootResolved)

    $dirsVisited = 0
    $lastStatus = [datetime]::UtcNow
    $errors = 0

    if (-not $Quiet) {
        Write-Info (T 'ScanStarted' @($rootResolved))
        $modeLabel = if ($Recurse) { T 'ModeRecurse' } else { T 'ModeFlat' }
        Write-Info (T 'ScanMode' @($modeLabel))
        Write-Host ''
    }

    while ($queue.Count -gt 0) {
        $dir = $queue.Dequeue()
        $dirsVisited++

        if (-not $Quiet -and (([datetime]::UtcNow - $lastStatus).TotalSeconds -ge 1.5)) {
            $lastStatus = [datetime]::UtcNow
            Write-Host ((T 'Scanning') -f $dirsVisited, $results.Count, $queue.Count) -NoNewline -ForegroundColor DarkGray
        }

        $entries = $null
        try {
            $entries = [System.IO.Directory]::EnumerateFileSystemEntries($dir)
        } catch {
            $errors++
            continue
        }

        foreach ($entry in $entries) {
            $name = [System.IO.Path]::GetFileName($entry)
            $isDir = $false
            $ext = Get-ExtPath $entry

            try {
                $attr = [System.IO.File]::GetAttributes($ext)
                $isDir = ($attr -band [System.IO.FileAttributes]::Directory) -ne 0
            } catch {
                try { $isDir = [System.IO.Directory]::Exists($ext) } catch { $isDir = $false }
            }

            if (Test-IsReserved $name) {
                $size = $null
                $type = if ($isDir) { 'DIR' } else { 'FILE' }
                if (-not $isDir) {
                    try {
                        $fi = New-Object System.IO.FileInfo($ext)
                        $size = $fi.Length
                    } catch { $size = 0 }
                }
                $results.Add([pscustomobject]@{
                    Index    = 0
                    Type     = $type
                    Name     = $name
                    Size     = $size
                    FullPath = $entry
                })
            }

            if ($Recurse -and $isDir -and -not (Test-IsReserved $name)) {
                if (-not (Should-SkipDir -Name $name -FullPath $entry)) {
                    $queue.Enqueue($entry)
                }
            }
        }
    }

    if (-not $Quiet) {
        Write-Host ''
        Write-Host ''
        Write-Info (T 'ScanDone' @($dirsVisited, $results.Count, $errors))
    }

    $i = 1
    foreach ($r in $results) { $r.Index = $i; $i++ }
    return @($results)
}

function Show-Results {
    param([object[]]$Items)

    if (-not $Items -or $Items.Count -eq 0) {
        Write-Ok (T 'NoneFound')
        return
    }

    Write-Section (T 'ResultsTitle' @($Items.Count))
    Write-Host ('  {0,4}  {1,-6}  {2,10}  {3}' -f (T 'ColNo'), (T 'ColType'), (T 'ColSize'), (T 'ColPath')) -ForegroundColor Yellow
    Write-Host ('  {0,4}  {1,-6}  {2,10}  {3}' -f '----', '------', '----------', '----') -ForegroundColor DarkGray

    foreach ($it in $Items) {
        $sz = if ($null -eq $it.Size) { '-' } else { $it.Size }
        $color = if ($it.Name -match '^(?i)nul') { 'Magenta' } else { 'White' }
        Write-Host ('  {0,4}  {1,-6}  {2,10}  {3}' -f $it.Index, $it.Type, $sz, $it.FullPath) -ForegroundColor $color
    }
    Write-Host ''
}

# ---------------------------------------------------------------------------
# Delete
# ---------------------------------------------------------------------------
function Remove-ReservedItem {
    param([object]$Item)

    $full = $Item.FullPath
    $ext = Get-ExtPath $full
    $isDir = ($Item.Type -eq 'DIR')

    try {
        if ($isDir) {
            $null = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', "rmdir /s /q `"$ext`"") -Wait -PassThru -NoNewWindow -WindowStyle Hidden
            if (Test-StillExists $ext) {
                [System.IO.Directory]::Delete($ext, $true)
            }
        } else {
            $null = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', "del /f /q `"$ext`"") -Wait -PassThru -NoNewWindow -WindowStyle Hidden
            if (Test-StillExists $ext) {
                [System.IO.File]::Delete($ext)
            }
        }

        if (Test-StillExists $ext) {
            return [pscustomobject]@{ Ok = $false; Path = $full; Error = (T 'StillExists') }
        }
        return [pscustomobject]@{ Ok = $true; Path = $full; Error = $null }
    } catch {
        return [pscustomobject]@{ Ok = $false; Path = $full; Error = $_.Exception.Message }
    }
}

function Invoke-BulkDelete {
    param([object[]]$Items)

    if (-not $Items -or $Items.Count -eq 0) {
        Write-Warn (T 'NothingToDelete')
        return
    }

    Write-Section (T 'BulkConfirmTitle')
    Write-Warn (T 'BulkConfirmWarn' @($Items.Count))
    Write-Host ''
    Write-Host (T 'ConfirmPrompt' @(Get-ConfirmWord)) -NoNewline -ForegroundColor Yellow
    $ans = Read-Host
    if (-not (Test-IsConfirm $ans)) {
        Write-Warn (T 'Cancelled')
        return
    }

    $ok = 0; $fail = 0
    foreach ($it in $Items) {
        $r = Remove-ReservedItem -Item $it
        if ($r.Ok) {
            Write-Ok $r.Path
            $ok++
        } else {
            Write-Err ("{0} -> {1}" -f $r.Path, $r.Error)
            $fail++
        }
    }
    Write-Host ''
    Write-Info (T 'Summary' @($ok, $fail))
}

function Invoke-SelectiveDelete {
    param([object[]]$Items)

    if (-not $Items -or $Items.Count -eq 0) {
        Write-Warn (T 'NothingToDelete')
        return
    }

    Show-Results -Items $Items
    Write-Section (T 'SelectiveTitle')
    Write-Info (T 'SelectiveHint')
    Write-Host ''
    Write-Host (T 'SelectPrompt') -NoNewline -ForegroundColor White
    $raw = (Read-Host).Trim()

    if ($raw -match '^(?i)q|quit|iptal|c$') {
        Write-Warn (T 'CancelledShort')
        return
    }

    $selected = @()
    if ($raw -match '^(?i)a|all|hepsi$') {
        $selected = $Items
    } else {
        $indexes = New-Object System.Collections.Generic.HashSet[int]
        foreach ($part in ($raw -split ',')) {
            $part = $part.Trim()
            if ($part -match '^(\d+)-(\d+)$') {
                $a = [int]$Matches[1]; $b = [int]$Matches[2]
                if ($a -gt $b) { $t = $a; $a = $b; $b = $t }
                for ($i = $a; $i -le $b; $i++) { [void]$indexes.Add($i) }
            } elseif ($part -match '^\d+$') {
                [void]$indexes.Add([int]$part)
            }
        }
        $selected = @($Items | Where-Object { $indexes.Contains([int]$_.Index) })
    }

    if ($selected.Count -eq 0) {
        Write-Warn (T 'NoValidSelection')
        return
    }

    Write-Host ''
    Write-Info (T 'SelectedItems' @($selected.Count))
    foreach ($s in $selected) {
        Write-Host ("    [{0}] {1}" -f $s.Index, $s.FullPath) -ForegroundColor Magenta
    }
    Write-Host ''
    Write-Host (T 'DeleteConfirmPrompt' @(Get-ConfirmWord)) -NoNewline -ForegroundColor Yellow
    $ans = Read-Host
    if (-not (Test-IsConfirm $ans)) {
        Write-Warn (T 'Cancelled')
        return
    }

    $ok = 0; $fail = 0
    foreach ($it in $selected) {
        $r = Remove-ReservedItem -Item $it
        if ($r.Ok) { Write-Ok $r.Path; $ok++ }
        else { Write-Err ("{0} -> {1}" -f $r.Path, $r.Error); $fail++ }
    }
    Write-Host ''
    Write-Info (T 'Summary' @($ok, $fail))
}

# ---------------------------------------------------------------------------
# Post-scan actions menu
# ---------------------------------------------------------------------------
function Show-PostScanMenu {
    param(
        [object[]]$Items,
        [string]$RootLabel
    )

    if (-not $Items -or $Items.Count -eq 0) {
        Pause-Key
        return
    }

    Show-Results -Items $Items

    while ($true) {
        Write-Section (T 'PostWhatNext')
        Write-Host (T 'PostDeleteAll') -ForegroundColor White
        Write-Host (T 'PostDeleteSel') -ForegroundColor White
        Write-Host (T 'PostShowAgain') -ForegroundColor White
        Write-Host (T 'PostSave') -ForegroundColor White
        Write-Host (T 'PostBack') -ForegroundColor DarkGray
        $c = Read-MenuChoice (T 'YourChoice') @('0', '1', '2', '3', '4')

        switch ($c) {
            '1' { Invoke-BulkDelete -Items $Items; Pause-Key; return }
            '2' { Invoke-SelectiveDelete -Items $Items; Pause-Key; return }
            '3' { Show-Results -Items $Items }
            '4' {
                $out = Join-Path ([Environment]::GetFolderPath('Desktop')) 'nul_scan.txt'
                $lines = @(
                    "NULL REMOVER SCAN",
                    "Root: $RootLabel",
                    "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
                    "Count: $($Items.Count)",
                    "Lang: $($script:Lang)",
                    ('-' * 60)
                )
                foreach ($it in $Items) {
                    $lines += ("[{0}] {1}  size={2}  {3}" -f $it.Index, $it.Type, $it.Size, $it.FullPath)
                }
                $lines | Set-Content -LiteralPath $out -Encoding UTF8
                Write-Ok (T 'Saved' @($out))
            }
            '0' { return }
        }
    }
}

# ---------------------------------------------------------------------------
# Menu actions
# ---------------------------------------------------------------------------
function Action-ScanDriveC {
    Write-Banner
    Write-Section (T 'ScanCTitle')
    Write-Warn (T 'ScanCWarn1')
    Write-Warn (T 'ScanCWarn2')
    Write-Host ''
    Write-Host (T 'ScanCStart') -NoNewline
    $x = Read-Host
    if ($x -match '^(?i)q') { return }

    $items = Find-ReservedItems -Root 'C:\' -Recurse
    Show-PostScanMenu -Items $items -RootLabel 'C:\'
}

function Action-ScanCustom {
    Write-Banner
    Write-Section (T 'CustomTitle')
    Write-Host (T 'CustomExample') -ForegroundColor DarkGray
    Write-Host ''
    Write-Host (T 'PathPrompt') -NoNewline -ForegroundColor White
    $path = (Read-Host).Trim().Trim('"')
    if ([string]::IsNullOrWhiteSpace($path)) {
        Write-Warn (T 'PathEmpty')
        Pause-Key
        return
    }
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Err (T 'PathNotFound' @($path))
        Pause-Key
        return
    }

    Write-Host ''
    Write-Host (T 'ModeThisFolder') -ForegroundColor White
    Write-Host (T 'ModeRecursive') -ForegroundColor White
    $m = Read-MenuChoice (T 'ModePrompt') @('1', '2')
    $rec = ($m -eq '2')

    $items = Find-ReservedItems -Root $path -Recurse:$rec
    Show-PostScanMenu -Items $items -RootLabel $path
}

function Action-QuickDeletePath {
    Write-Banner
    Write-Section (T 'QuickTitle')
    Write-Info (T 'QuickHint')
    Write-Host ''
    Write-Host (T 'PathPrompt') -NoNewline
    $path = (Read-Host).Trim().Trim('"')
    if ([string]::IsNullOrWhiteSpace($path)) {
        Write-Warn (T 'PathNone')
        Pause-Key
        return
    }

    $item = [pscustomobject]@{
        Index = 1; Type = 'FILE'; Name = [IO.Path]::GetFileName($path)
        Size = $null; FullPath = $path
    }
    $ext = Get-ExtPath $path
    try {
        $a = [IO.File]::GetAttributes($ext)
        if (($a -band [IO.FileAttributes]::Directory) -ne 0) { $item.Type = 'DIR' }
    } catch {}

    Write-Host ''
    Write-Host (T 'WillDelete' @($path)) -ForegroundColor Magenta
    Write-Host (T 'ConfirmEVET' @(Get-ConfirmWord)) -NoNewline -ForegroundColor Yellow
    if (-not (Test-IsConfirm (Read-Host))) {
        Write-Warn (T 'CancelledShort')
        Pause-Key
        return
    }
    $r = Remove-ReservedItem -Item $item
    if ($r.Ok) { Write-Ok $r.Path } else { Write-Err ("{0} -> {1}" -f $r.Path, $r.Error) }
    Pause-Key
}

function Action-About {
    Write-Banner
    Write-Section (T 'AboutTitle')
    Write-Info (T 'About1')
    Write-Info (T 'About2')
    Write-Host ''
    Write-Info (T 'About3')
    Write-Info (T 'About4')
    Write-Info (T 'About5')
    Write-Info (T 'About6' @(Get-ConfirmWord))
    Write-Info (T 'About7')
    Write-Host ''
    Write-Warn (T 'AboutWarn')
    Pause-Key
}

function Action-Language {
    Write-Banner
    Write-Section (T 'LangTitle')
    Write-Info (T 'LangCurrent')
    Write-Host ''
    Write-Host (T 'LangOpt1') -ForegroundColor Green
    Write-Host (T 'LangOpt2') -ForegroundColor Green
    Write-Host (T 'LangOpt0') -ForegroundColor DarkGray
    $c = Read-MenuChoice (T 'LangPrompt') @('0', '1', '2')
    switch ($c) {
        '1' {
            $script:Lang = 'tr'
            Write-Ok (T 'LangSetTr')
            Pause-Key
        }
        '2' {
            $script:Lang = 'en'
            Write-Ok (T 'LangSetEn')
            Pause-Key
        }
        '0' { return }
    }
}

# ---------------------------------------------------------------------------
# Drag-drop mode
# ---------------------------------------------------------------------------
function Invoke-DropMode {
    param([string[]]$Paths)

    Write-Banner
    Write-Section (T 'DropTitle')

    $ok = 0; $fail = 0
    foreach ($raw in $Paths) {
        if ([string]::IsNullOrWhiteSpace($raw)) { continue }
        $path = $raw.Trim().Trim('"')
        $ext = Get-ExtPath $path
        $leaf = [System.IO.Path]::GetFileName($path.TrimEnd('\', '/'))

        $isDir = $false
        try {
            $a = [System.IO.File]::GetAttributes($ext)
            $isDir = ($a -band [System.IO.FileAttributes]::Directory) -ne 0
        } catch {
            $isDir = Test-Path -LiteralPath $path -PathType Container
        }

        if ($isDir -and -not (Test-IsReserved $leaf)) {
            Write-Info (T 'DropScanFolder' @($path))
            $items = Find-ReservedItems -Root $path -Quiet
            if ($items.Count -eq 0) {
                Write-Warn (T 'DropNone')
                continue
            }
            foreach ($it in $items) {
                $r = Remove-ReservedItem -Item $it
                if ($r.Ok) { Write-Ok $r.Path; $ok++ } else { Write-Err ("{0} -> {1}" -f $r.Path, $r.Error); $fail++ }
            }
        } else {
            $item = [pscustomobject]@{
                Index = 1
                Type  = $(if ($isDir) { 'DIR' } else { 'FILE' })
                Name  = $leaf
                Size  = $null
                FullPath = $path
            }
            $r = Remove-ReservedItem -Item $item
            if ($r.Ok) { Write-Ok $r.Path; $ok++ } else { Write-Err ("{0} -> {1}" -f $r.Path, $r.Error); $fail++ }
        }
    }

    Write-Host ''
    Write-Info (T 'Summary' @($ok, $fail))
    Write-Host ''
    Pause-Key (T 'PauseClose')
    exit $(if ($fail -gt 0) { 1 } else { 0 })
}

# ---------------------------------------------------------------------------
# Main menu loop
# ---------------------------------------------------------------------------
function Show-MainMenu {
    while ($true) {
        Write-Banner
        Write-Host '  +------------------------------------------------------------------+' -ForegroundColor DarkCyan
        $title = T 'MainTitle'
        $pad = [Math]::Max(0, [int]((66 - $title.Length) / 2))
        Write-Host ('  |{0}{1}{2}|' -f (' ' * $pad), $title, (' ' * (66 - $pad - $title.Length))) -ForegroundColor Cyan
        Write-Host '  +------------------------------------------------------------------+' -ForegroundColor DarkCyan
        Write-Host ''
        Write-Host (T 'Main1') -ForegroundColor Green
        Write-Host (T 'Main2') -ForegroundColor Green
        Write-Host (T 'Main3') -ForegroundColor Yellow
        Write-Host (T 'Main4') -ForegroundColor White
        Write-Host (T 'Main5') -ForegroundColor Magenta
        Write-Host (T 'Main0') -ForegroundColor DarkGray
        Write-Host ''
        Write-Host '  +------------------------------------------------------------------+' -ForegroundColor DarkCyan
        Write-Host (T 'MainTip') -ForegroundColor DarkGray
        Write-Host '  +------------------------------------------------------------------+' -ForegroundColor DarkCyan

        $c = Read-MenuChoice (T 'MainChoice') @('0', '1', '2', '3', '4', '5')
        switch ($c) {
            '1' { Action-ScanDriveC }
            '2' { Action-ScanCustom }
            '3' { Action-QuickDeletePath }
            '4' { Action-About }
            '5' { Action-Language }
            '0' {
                Write-Host ''
                Write-Host (T 'Bye') -ForegroundColor Cyan
                Write-Host ''
                return
            }
        }
    }
}

# --- entry ---
if ($DropPaths -and $DropPaths.Count -gt 0) {
    Invoke-DropMode -Paths $DropPaths
} else {
    Show-MainMenu
}
