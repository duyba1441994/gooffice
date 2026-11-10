# msi-localize-vi.ps1 — Vietnamese-localize the GoOffice MSI installer wizard.
#
# Why: LibreOffice's multilang MSI keeps its UI tables (Control/Dialog/
# RadioButton/UIText/ActionText/Error/LaunchCondition) in the FIRST setup
# language (en-US, hard-wired in instsetoo_native/CustomTarget_install.mk:54),
# so the installation wizard is always English even though the Vietnamese
# translations exist upstream (instsetoo_native/inc_openoffice/windows/
# msi_languages.po, 501/559 strings translated at libreoffice-26.8.2.2).
#
# What it does: opens the MSI in transaction mode through Windows Installer
# COM and UPDATEs every cell whose English text has a Vietnamese msgstr in
# the po. Strings without a translation stay English. Style prefixes like
# "{&DialogDefaultBold}" and [ProductName]-style placeholders are preserved.
#
# Usage: powershell -File msi-localize-vi.ps1 -MsiPath <msi> -PoPath <po>
#        [-WhatIfOnly]

param(
    [Parameter(Mandatory = $true)][string]$MsiPath,
    [Parameter(Mandatory = $true)][string]$PoPath,
    [switch]$WhatIfOnly
)

$ErrorActionPreference = 'Stop'
$script:stats = @{}

# ---------- 1. Parse the po into msgid -> msgstr map ----------

function Unescape-Po([string]$s) {
    $s = $s -replace '\\"', '"'
    $s = $s -replace '\\n', "`r`n"
    $s = $s -replace '\\t', "`t"
    $s = $s -replace '\\\\', '\'
    return $s
}

$script:map = @{}
$idBuf = New-Object System.Text.StringBuilder
$strBuf = New-Object System.Text.StringBuilder
$state = 'none'    # none | id | str

function Flush-Entry {
    if ($script:state -ne 'none') {
        $id = Unescape-Po $idBuf.ToString()
        $st = Unescape-Po $strBuf.ToString()
        if (($id -ne '') -and ($st -ne '') -and (-not $script:map.ContainsKey($id))) {
            $script:map[$id] = $st
        }
    }
    $idBuf.Length = 0
    $strBuf.Length = 0
    $script:state = 'none'
}

foreach ($line in (Get-Content -LiteralPath $PoPath -Encoding UTF8)) {
    if ($line -match '^msgid\s+"(.*)"\s*$') {
        Flush-Entry
        $script:state = 'id'
        [void]$idBuf.Append($Matches[1])
        continue
    }
    if ($line -match '^msgstr\s+"(.*)"\s*$') {
        [void]$strBuf.Append($Matches[1])
        $script:state = 'str'
        continue
    }
    if ($line -match '^"(.*)"\s*$') {
        if ($script:state -eq 'str') { [void]$strBuf.Append($Matches[1]) }
        elseif ($script:state -eq 'id') { [void]$idBuf.Append($Matches[1]) }
        continue
    }
    if ($line -match '^\s*$') { Flush-Entry }
}
Flush-Entry

Write-Host ("po entries with Vietnamese translation: {0}" -f $script:map.Count)

# ---------- 1b. Fallback overrides for wizard-critical strings ----------
# Upstream leaves several highly visible wizard strings untranslated (empty
# msgstr) or with poor wording; these are user-approved GoOffice glossary
# translations applied when the po has nothing better.

$script:fallback = @{
    'Welcome to the Installation Wizard for [ProductName]' = 'Chào mừng bạn đến với Trình hướng dẫn cài đặt [ProductName]'
    'Welcome to the Patch for [ProductName]'               = 'Chào mừng bạn đến với Trình hướng dẫn cài bản vá cho [ProductName]'
    'Resuming the Installation Wizard for [ProductName]'   = 'Tiếp tục Trình hướng dẫn cài đặt [ProductName]'
    'Installation Wizard Completed'                        = 'Hoàn tất cài đặt'
    'Click Finish to exit the wizard.'                     = 'Nhấn Hoàn tất để thoát khỏi trình hướng dẫn.'
    'The Installation Wizard has successfully installed [ProductName]. Click Finish to exit the wizard.'  = 'Trình hướng dẫn cài đặt đã cài đặt thành công [ProductName]. Nhấn Hoàn tất để thoát.'
    'The Installation Wizard has successfully uninstalled [ProductName]. Click Finish to exit the wizard.' = 'Trình hướng dẫn cài đặt đã gỡ bỏ thành công [ProductName]. Nhấn Hoàn tất để thoát.'
    '[ProductName] Setup is preparing the Installation Wizard which will guide you through the program setup process. Please wait.' = 'Trình cài đặt [ProductName] đang chuẩn bị Trình hướng dẫn cài đặt để hướng dẫn bạn suốt quá trình cài đặt. Vui lòng đợi.'
    'Please select a setup type.'                          = 'Vui lòng chọn kiểu cài đặt.'
    '[ProductName] will be installed with the default components, including user interface languages and spelling dictionaries matching your current language settings.' = '[ProductName] sẽ được cài đặt với các thành phần mặc định, bao gồm ngôn ngữ giao diện và từ điển kiểm tra chính tả phù hợp với thiết lập ngôn ngữ hiện tại.'
    'Choose which program features you want installed and where they will be installed. For example you can select user interface languages and spelling dictionaries.' = 'Chọn các tính năng muốn cài đặt và nơi cài đặt chúng. Ví dụ: bạn có thể chọn ngôn ngữ giao diện và từ điển kiểm tra chính tả.'
    '&Back'    = '&Trước'
    '&Cancel'  = 'Hủy bỏ'
    'Cancel'   = 'Hủy bỏ'
    '&Finish'  = '&Hoàn tất'
    '&Install' = '&Cài đặt'
    '&Remove'  = '&Gỡ bỏ'
    '&Update'  = '&Cập nhật'
    '&Continue'= '&Tiếp tục'
    '&Yes'     = '&Có'
    '&No'      = '&Không'
    '&Browse'  = '&Duyệt'
    '&Next'    = '&Tiếp >'
}

# ---------- 2. Open the MSI ----------

$installer = New-Object -ComObject WindowsInstaller.Installer
$dbMode = 1; if ($WhatIfOnly) { $dbMode = 0 }    # 1 = transact, 0 = read-only
$db = $installer.GetType().InvokeMember('OpenDatabase','InvokeMethod',$null,$installer,@($MsiPath, $dbMode))

function New-View([string]$sql) {
    $v = $db.GetType().InvokeMember('OpenView','InvokeMethod',$null,$db,@($sql))
    $v.GetType().InvokeMember('Execute','InvokeMethod',$null,$v,$null) | Out-Null
    return $v
}
function Get-Str($rec, [int]$i) { $rec.GetType().InvokeMember('StringData','GetProperty',$null,$rec,@($i)) }
function Set-Str($rec, [int]$i, [string]$v) { $rec.GetType().InvokeMember('StringData','SetProperty',$null,$rec,@($i, $v)) }

function Localize-Table {
    param([string]$Table, [int]$TextPos, [string[]]$NamedCols = @(), [switch]$StripStyle)

    # Named-column select where proven (Control); SELECT * elsewhere - its
    # column order is NOT the schema order, so TextPos must be measured
    # empirically per table (RadioButton.Text = 8).
    $view = if ($NamedCols.Count -gt 0) {
        $allCols = ($NamedCols -join '`, `')
        New-View ("SELECT ``{0}`` FROM ``{1}``" -f $allCols, $Table)
    } else {
        New-View ("SELECT * FROM ``{0}``" -f $Table)
    }
    $updated = 0; $kept = 0

    while ($rec = $view.GetType().InvokeMember('Fetch','InvokeMethod',$null,$view,$null)) {
        $text = Get-Str $rec $textPos
        if (($null -eq $text) -or ($text -eq '')) { continue }

        $prefix = ''
        $core = $text
        if ($StripStyle -and $text -match '^(\{&[^}]+\})(.*)$') { $prefix = $Matches[1]; $core = $Matches[2] }
        $core = $core.Trim()

        # lookup order: po full text -> po core -> fallback full text -> fallback core
        $vi = $null
        if ($script:map.ContainsKey($text))      { $vi = $script:map[$text] }
        if (-not $vi -and $script:map.ContainsKey($core)) { $vi = $script:map[$core] }
        if (-not $vi -and $script:fallback.ContainsKey($text)) { $vi = $script:fallback[$text] }
        if (-not $vi -and $script:fallback.ContainsKey($core)) { $vi = $script:fallback[$core] }

        if ($vi -and ($vi -ne $core)) {
                if ($vi -notmatch '^\{&') { $vi = $prefix + $vi }
                if (-not $WhatIfOnly) {
                    Set-Str $rec $textPos $vi
                    $view.GetType().InvokeMember('Modify','InvokeMethod',$null,$view,@(2, $rec)) | Out-Null   # 2 = MSIMODIFY_UPDATE
                }
                $updated++
                continue
        }
        $kept++
    }
    Write-Host ("{0}: vietnamese={1} kept-english={2}" -f $Table, $updated, $kept)
    $script:stats[$Table] = $updated
}

# ---------- 3. Localize the UI tables ----------

# Control.Text carries {&style} prefixes; named select MUST include the Text
# column itself as its last column (Text = position 3 here, verified 162 updates)
Localize-Table -Table 'Control'     -TextPos 3 -NamedCols @('Dialog_','Control','Text') -StripStyle
# RadioButton: InstallShield-style schema, NO Dialog_ column; Text is column 8
# (1=Property 2=Order 3=Value 4/5/6/7=geometry 8=Text)
Localize-Table -Table 'RadioButton' -TextPos 8
# UIText.Text: size units, "up", volume labels etc. (column 2)
Localize-Table -Table 'UIText'      -TextPos 2
# ActionText.Description: progress descriptions (column 2)
Localize-Table -Table 'ActionText'  -TextPos 2
# Error.Description: MSI error messages (column 2)
Localize-Table -Table 'Error'       -TextPos 2
# LaunchCondition.Description (column 2)
Localize-Table -Table 'LaunchCondition' -TextPos 2

# ---------- 4. Wizard title property ----------

$view = New-View "SELECT ``Property``, ``Value`` FROM ``Property``"
while ($rec = $view.GetType().InvokeMember('Fetch','InvokeMethod',$null,$view,$null)) {
    if ((Get-Str $rec 1) -eq 'STR_INSTALLATION_WIZARD') {
        $viTitle = $script:map['Installation Wizard']
        if (-not $viTitle) { $viTitle = 'Trình hướng dẫn cài đặt' }
        Set-Str $rec 2 $viTitle
        $view.GetType().InvokeMember('Modify','InvokeMethod',$null,$view,@(2, $rec)) | Out-Null
        $script:stats['Property.STR_INSTALLATION_WIZARD'] = 1
        Write-Host 'Property STR_INSTALLATION_WIZARD -> Vietnamese'
        break
    }
}

# ---------- 5. Commit or report ----------

if ($WhatIfOnly) {
    Write-Host 'WhatIfOnly: changes NOT committed.'
} else {
    $db.GetType().InvokeMember('Commit','InvokeMethod',$null,$db,$null) | Out-Null
    Write-Host 'MSI committed.'
}
Write-Host 'Summary:'
$script:stats.GetEnumerator() | ForEach-Object { Write-Host ("  {0}: {1}" -f $_.Key, $_.Value) }
