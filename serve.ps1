# A+ Study Hub local server — no installs needed, uses built-in Windows PowerShell
param([switch]$NoBrowser)
$port = 8765
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try {
    $listener.Start()
} catch {
    Write-Host ""
    Write-Host "Couldn't start on port $port - the server is probably already running (maybe in the background)." -ForegroundColor Yellow
    Write-Host "Just open http://localhost:$port/index.html in your browser."
    if (-not $NoBrowser) { Start-Process "http://localhost:$port/index.html" }
    Start-Sleep 6
    exit 0
}

Write-Host ""
Write-Host "  A+ Study Hub is running at http://localhost:$port/index.html" -ForegroundColor Green
Write-Host "  Keep this window open while studying. Close it when you're done." -ForegroundColor Gray
Write-Host ""

if (-not $NoBrowser) { Start-Process "http://localhost:$port/index.html" }

$types = @{ ".html"="text/html; charset=utf-8"; ".js"="text/javascript"; ".css"="text/css"; ".json"="application/json"; ".png"="image/png"; ".jpg"="image/jpeg"; ".svg"="image/svg+xml"; ".ico"="image/x-icon" }

while ($listener.IsListening) {
    try {
        $ctx  = $listener.GetContext()
        $path = [Uri]::UnescapeDataString($ctx.Request.Url.LocalPath.TrimStart('/'))
        if ([string]::IsNullOrWhiteSpace($path)) { $path = "index.html" }
        $file = Join-Path $root $path
        if ((Test-Path $file -PathType Leaf) -and ($file -like "$root*")) {
            $bytes = [IO.File]::ReadAllBytes($file)
            $ext = [IO.Path]::GetExtension($file).ToLower()
            $ct = $types[$ext]; if (-not $ct) { $ct = "application/octet-stream" }
            $ctx.Response.ContentType = $ct
            $ctx.Response.ContentLength64 = $bytes.Length
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $ctx.Response.StatusCode = 404
        }
        $ctx.Response.Close()
    } catch { }
}
