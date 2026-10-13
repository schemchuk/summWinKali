$dirs = 'Documents','Downloads','Desktop','Pictures','Videos','Music'
$dst  = 'E:\Backup\Windows'
foreach ($d in $dirs) {
    Write-Host "=== $d ==="
    & robocopy "$env:USERPROFILE\$d" "$dst\$d" /MIR /R:2 /W:2 /NFL /NDL /NP /TEE /LOG+:"$dst\backup.log"
    Write-Host "exit: $LASTEXITCODE"
}
Write-Host "BACKUP FINISHED"
