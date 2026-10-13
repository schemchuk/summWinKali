$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
  -Argument '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Users\shemc\myVSCodeProjects\summWinKali\backup-windows-auto.ps1"'
$trigger = New-ScheduledTaskTrigger -AtLogOn -User 'shemc'
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
  -ExecutionTimeLimit (New-TimeSpan -Hours 4) -RestartCount 2 -RestartInterval (New-TimeSpan -Minutes 5)
$principal = New-ScheduledTaskPrincipal -UserId 'shemc' -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName 'Backup-To-Data-Drive' -Action $action -Trigger $trigger `
  -Settings $settings -Principal $principal -Description 'Mirror user folders to external Data drive if connected' -Force

Get-ScheduledTask -TaskName 'Backup-To-Data-Drive' | Format-List TaskName, State
