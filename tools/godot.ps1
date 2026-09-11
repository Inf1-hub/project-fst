param(
    [ValidateSet('editor', 'run', 'check', 'test', 'playtest', 'benchmark')]
    [string]$Task = 'editor',
    [string]$GodotPath = $env:GODOT_PATH
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $GodotPath) {
    $GodotPath = 'C:\app\godot\Godot_v4.7.2-stable_win64_console.exe'
}
if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw "Godot executable missing: $GodotPath. Set GODOT_PATH or pass -GodotPath."
}
$expectedVersion = (Get-Content -LiteralPath (Join-Path $projectRoot 'engine.version') -Raw).Trim()
$actualVersion = (& $GodotPath --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $actualVersion -ne $expectedVersion) {
    throw "Engine mismatch. Expected $expectedVersion; found $actualVersion."
}
$logDirectory = Join-Path $projectRoot '.local'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
function Invoke-GodotCheck([string]$Name, [string[]]$Arguments) {
    $logPath = Join-Path $logDirectory "$Name.log"
    & $GodotPath --headless --path $projectRoot --log-file $logPath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Godot $Name failed: exit $LASTEXITCODE. See $logPath" }
    if (Select-String -LiteralPath $logPath -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) {
        throw "Godot $Name reported errors. See $logPath"
    }
}
switch ($Task) {
    'editor' { & $GodotPath --path $projectRoot --editor }
    'run' { & $GodotPath --path $projectRoot }
    'check' {
        Invoke-GodotCheck 'import' @('--editor', '--import')
        Invoke-GodotCheck 'smoke' @('--quit-after', '2')
        Write-Host 'PASS: engine version, resource import and bootstrap startup.'
    }
    'test' {
        Invoke-GodotCheck 'terrain_contract' @('--quit-after', '1200', '--script', 'res://tests/terrain_contract_test.gd')
        if (-not (Select-String -LiteralPath (Join-Path $logDirectory 'terrain_contract.log') -Pattern 'TERRAIN CONTRACT: 0 failures' -Quiet)) { throw 'Terrain contract tests did not complete.' }
        Invoke-GodotCheck 'tactical_layout' @('--quit-after', '1200', '--script', 'res://tests/tactical_layout_test.gd')
        if (-not (Select-String -LiteralPath (Join-Path $logDirectory 'tactical_layout.log') -Pattern 'TACTICAL TEST: 0 failures' -Quiet)) { throw 'Tactical layout tests did not complete.' }
        Invoke-GodotCheck 'camera_test' @('--quit-after', '1200', '--script', 'res://tests/camera_test.gd')
        if (-not (Select-String -LiteralPath (Join-Path $logDirectory 'camera_test.log') -Pattern 'CAMERA TEST: 0 failures' -Quiet)) { throw 'Camera tests did not complete.' }
        Invoke-GodotCheck 'room_flow' @('--quit-after', '1200', '--script', 'res://tests/room_flow_test.gd')
        if (-not (Select-String -LiteralPath (Join-Path $logDirectory 'room_flow.log') -Pattern 'ROOM FLOW: 0 failures' -Quiet)) { throw 'Room flow tests did not complete.' }
        Invoke-GodotCheck 'mvp_test' @('--quit-after', '1200', '--script', 'res://tests/mvp_test.gd')
        if (-not (Select-String -LiteralPath (Join-Path $logDirectory 'mvp_test.log') -Pattern 'MVP TESTS: 0 failures' -Quiet)) {
            throw 'MVP tests did not reach the completion marker.'
        }
    }
    'benchmark' {
        & $GodotPath --path $projectRoot --log-file (Join-Path $logDirectory 'benchmark.log') --disable-vsync --script res://tests/stress_test.gd
    }
    'playtest' {
        Invoke-GodotCheck 'playthrough' @('--fixed-fps', '60', '--quit-after', '55000', '--script', 'res://tests/playthrough_test.gd')
        if (-not (Select-String -LiteralPath (Join-Path $logDirectory 'playthrough.log') -Pattern 'PLAYTHROUGH PASS:' -Quiet)) {
            throw 'Playthrough did not reach the next floor.'
        }
    }
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
