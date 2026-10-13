$ErrorActionPreference = 'Stop'
$log = "$env:LOCALAPPDATA\summwinkali-backup.log"
"=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') start ===" | Out-File $log -Append

$dl = (Get-Volume -FileSystemLabel 'Data' -ErrorAction SilentlyContinue).DriveLetter
if (-not $dl) {
    "Disk Data not connected - skipped." | Out-File $log -Append
    exit 0
}

$dirs = 'Documents','Downloads','Desktop','Pictures','Videos','Music'
$dst  = "$dl`:\Backup\Windows"
$code = 0
foreach ($d in $dirs) {
    & robocopy "$env:USERPROFILE\$d" "$dst\$d" /MIR /XJ /R:2 /W:2 /NFL /NDL /NP /LOG+:"$log"
    if ($LASTEXITCODE -ge 8) { $code = 1 }   # >=8 - real errors; <8 - success/copied
}
"=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') done (code $code) ===" | Out-File $log -Append
exit $code
