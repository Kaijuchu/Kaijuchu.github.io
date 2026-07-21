# A+ Study Hub - smart sync: stages changes, writes a descriptive commit, pushes to GitHub.
param([switch]$Quiet)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
function Say($m, $c = "Gray") { if (-not $Quiet) { Write-Host $m -ForegroundColor $c } }

# ---- locate git (system install, or GitHub Desktop's bundled copy) ----
$git = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $git) {
    $d = Get-ChildItem "$env:LOCALAPPDATA\GitHubDesktop" -Directory -Filter "app-*" -ErrorAction SilentlyContinue |
         Sort-Object Name -Descending | Select-Object -First 1
    if ($d -and (Test-Path "$($d.FullName)\resources\app\git\cmd\git.exe")) { $git = "$($d.FullName)\resources\app\git\cmd\git.exe" }
}
if (-not $git) { Say "Git not found. Install Git for Windows or GitHub Desktop." Red; if (-not $Quiet) { Read-Host "Enter to close" }; exit 1 }
if (-not (Test-Path "$root\.git")) { Say "Not connected yet - run github-sync.bat option 1 first." Yellow; if (-not $Quiet) { Read-Host "Enter to close" }; exit 1 }

& $git add -A 2>$null
& $git diff --cached --quiet 2>$null
if ($LASTEXITCODE -eq 0) { Say "Nothing changed - already up to date." Green; if (-not $Quiet) { Start-Sleep 2 }; exit 0 }

# ---- gather what changed ----
$friendly = @{
    "index.html"        = "study app"
    "serve.ps1"         = "server"
    "start-app.bat"     = "launcher"
    "start-hidden.vbs"  = "launcher"
    "autostart.bat"     = "autostart"
    "github-sync.bat"   = "sync tools"
    "sync.ps1"          = "sync tools"
    "sync-quiet.vbs"    = "sync tools"
    ".gitignore"        = "git config"
}
$stat = @{}
foreach ($l in (& $git diff --cached --numstat)) {
    $p = $l -split "`t"
    if ($p.Count -ge 3) {
        $a = 0; $d = 0
        [int]::TryParse($p[0], [ref]$a) | Out-Null
        [int]::TryParse($p[1], [ref]$d) | Out-Null
        $stat[$p[2]] = @{ add = $a; del = $d; status = "M" }
    }
}
foreach ($l in (& $git diff --cached --name-status)) {
    $p = $l -split "`t"
    if ($p.Count -ge 2) {
        $f = $p[-1]
        if (-not $stat.ContainsKey($f)) { $stat[$f] = @{ add = 0; del = 0; status = "M" } }
        $stat[$f].status = $p[0].Substring(0,1)
    }
}

# ---- inspect the app diff to describe the change in plain English ----
$tags = @()
if ($stat.ContainsKey("index.html")) {
    $diff  = (& $git diff --cached -- index.html) -join "`n"
    $added = ($diff -split "`n" | Where-Object { $_ -match '^\+' -and $_ -notmatch '^\+\+\+' }) -join "`n"
    $both  = ($diff -split "`n" | Where-Object { $_ -match '^[+-]' -and $_ -notmatch '^(\+\+\+|---)' }) -join "`n"

    $qCount = ([regex]::Matches($added, '\{\s*d:"')).Count
    if ($qCount -gt 0) { $tags += "$qCount new question$(if($qCount -ne 1){'s'})" }
    if ($both -match '(animation|@keyframes|background:|border-radius|box-shadow|gradient|backdrop-filter)') { $tags += "styling" }
    if ($both -match '(viewBox|UIC\[|<svg|stroke-linecap)')                                                  { $tags += "icons" }
    if ($both -match '(callGemini|callClaude|apiKey|gemKey|tutorSystem)')                                    { $tags += "AI features" }
    if ($both -match '(PBQS|SCENS|PC_PARTS|CONNECTORS|buildModel)')                                          { $tags += "labs" }
    if ($both -match '(settingsView|setPref|exportProgress|S\.theme)')                                       { $tags += "settings" }
    if ($added -match '(?m)^\+\s*(function |async function |const \w+\s*=\s*\()')                            { $tags += "new logic" }
    $tags = $tags | Select-Object -Unique
}

$totalAdd = ($stat.Values | ForEach-Object { $_.add } | Measure-Object -Sum).Sum
$totalDel = ($stat.Values | ForEach-Object { $_.del } | Measure-Object -Sum).Sum
if ($null -eq $totalAdd) { $totalAdd = 0 }
if ($null -eq $totalDel) { $totalDel = 0 }
$counts   = "(+$totalAdd/-$totalDel)"

if ($stat.Count -eq 1 -and $stat.ContainsKey("index.html")) {
    $title = if ($tags.Count) { "Update study app: " + ($tags -join ", ") + " $counts" } else { "Update study app $counts" }
} else {
    $areas = @()
    foreach ($f in $stat.Keys) { $areas += $(if ($friendly[$f]) { $friendly[$f] } else { $f }) }
    $areas = $areas | Select-Object -Unique
    $lead  = if ($tags.Count) { ($tags -join ", ") } else { ($areas -join ", ") }
    $title = "Update $lead $counts"
}
if ($title.Length -gt 72) { $title = $title.Substring(0, 69) + "..." }

$body = @("Changed files:")
foreach ($f in ($stat.Keys | Sort-Object)) {
    $s = switch ($stat[$f].status) { "A" { "added" } "D" { "deleted" } "R" { "renamed" } default { "modified" } }
    $body += "  - {0}: {1} (+{2}/-{3})" -f $f, $s, $stat[$f].add, $stat[$f].del
}
$body += ""
$body += "Synced $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
$bodyText = $body -join "`n"

Say ""
Say "  $title" Cyan
Say $bodyText

& $git commit -m $title -m $bodyText | Out-Null
& $git pull --rebase origin main 2>$null | Out-Null
& $git push origin main 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Say ""
    Say "Push failed - open GitHub Desktop, confirm you're signed in, then run this again." Red
    if (-not $Quiet) { Read-Host "Enter to close" }
    exit 1
}
Say ""
Say "  Synced. Live site updates in about a minute:" Green
Say "  https://kaijuchu.github.io" Green
if (-not $Quiet) { Start-Sleep 4 }
