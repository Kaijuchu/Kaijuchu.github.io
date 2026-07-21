# Background auto-sync loop - runs sync.ps1 every 15 minutes. No admin rights needed.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
while ($true) {
    try { & "$here\sync.ps1" -Quiet } catch { }
    Start-Sleep -Seconds 900
}
