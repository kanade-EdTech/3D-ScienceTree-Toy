$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotExe = Join-Path $env:LOCALAPPDATA 'Programs\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
Push-Location $projectRoot
try {
    if (-not (Test-Path -LiteralPath 'tools/export_templates/web_nothreads_release.zip')) {
        python tools/fetch_web_template.py
        if ($LASTEXITCODE -ne 0) { throw 'Web template download failed.' }
    }
    New-Item -ItemType Directory -Path 'build/toy-web' -Force | Out-Null
    & $godotExe --headless --path $projectRoot --export-release Web 'build/toy-web/index.html'
    if ($LASTEXITCODE -ne 0) { throw 'Godot export failed.' }
    python tools/package_toy_web.py
    if ($LASTEXITCODE -ne 0) { throw 'Web packaging failed.' }
} finally {
    Pop-Location
}
