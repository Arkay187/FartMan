param([string[]]$Tests, [switch]$Build)
# Runs the headless play-tests in tools/tests, each with a time limit so a broken
# test can never hang. Run from the project folder:
#     pwsh tools/run_tests.ps1                 (all tests)
#     pwsh tools/run_tests.ps1 -Tests test_flight
#     pwsh tools/run_tests.ps1 -Build          (rebuild every scene first, then all tests)
$godot = "D:\Prototypes\Godot\Godot_v4.7.2-stable_win64.exe"
$project = Split-Path $PSScriptRoot -Parent
# Output files are named per run, so two runs at once (e.g. two worktrees) never mix up results.
$runId = [guid]::NewGuid().ToString("N").Substring(0, 8)
$out = Join-Path $env:TEMP "fartman_test_out_$runId.txt"
$err = Join-Path $env:TEMP "fartman_test_err_$runId.txt"

function Run-Godot([string[]]$GodotArgs, [int]$Seconds) {
    $p = Start-Process -FilePath $godot -ArgumentList (@('--headless', '--path', "`"$project`"") + $GodotArgs) `
        -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -NoNewWindow
    if (-not $p.WaitForExit($Seconds * 1000)) { $p.Kill(); "TIMED OUT after $Seconds s, killed" }
    $problems = @(Get-Content $err | Where-Object { $_ -match 'ERROR|WARNING' })
    "errors/warnings: $($problems.Count)"
    $problems | Select-Object -First 8
}

if ($Build) {
    "=== import (registers new class_name scripts)"
    Run-Godot @('--import') 180
    "=== build scenes"
    Run-Godot @('--script', 'res://tools/build_scenes.gd') 120
    Get-Content $out | Where-Object { $_ -match 'save .*: [^0]|pack .*: [^0]' }
}

if (-not $Tests) {
    $Tests = Get-ChildItem (Join-Path $PSScriptRoot 'tests') -Filter 'test_*.gd' | ForEach-Object { $_.BaseName }
}
foreach ($t in $Tests) {
    "--- $t"
    Run-Godot @('--fixed-fps', '60', '--script', "res://tools/tests/$t.gd") 120
    Get-Content $out | Select-Object -Skip 2 |
        Where-Object { $_ -cnotmatch '^(Toot|Trump|Thunder|Squeeeeak)' } |
        ForEach-Object { $_ -replace '\| squeaks.*?->', '->' }
}
