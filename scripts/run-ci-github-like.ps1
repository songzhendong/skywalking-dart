# Simulate GitHub Actions CI locally:
#   - job "test": ubuntu-like dart:stable, NO Flutter, same commands as .github/workflows/ci.yml
#   - job "smoke-oap": apache/skywalking-oap-server:10.1.0 + verify_native --quick
#
# Usage:
#   .\scripts\run-ci-github-like.ps1
#   .\scripts\run-ci-github-like.ps1 -SkipSmoke
param(
    [switch] $SkipSmoke
)

$ErrorActionPreference = 'Stop'
# Keep in sync with .github/workflows/ci.yml smoke-oap service image (literal; GHA cannot use env there)
$OapDockerImage = 'apache/skywalking-oap-server:9.7.0'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root

$docker = Get-Command docker.exe -ErrorAction SilentlyContinue
if (-not $docker) {
    throw 'Docker is required for GitHub-like CI. Install Docker Desktop, or use .\scripts\run-ci-local.ps1 (host Dart, approximate).'
}

function Invoke-DockerQuiet {
    param([string[]] $Args)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & docker.exe @Args 2>&1 | Out-Null
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    return $code
}

# Mount path: Docker Desktop on Windows accepts C:\... style paths.
$mount = "${root}:/app"

Write-Host '=== [test] job (dart:stable, same as setup-dart + workflow) ===' -ForegroundColor Cyan
Write-Host '    dart pub get --no-example' -ForegroundColor DarkGray
Write-Host '    dart analyze lib bin test' -ForegroundColor DarkGray
Write-Host '    dart test' -ForegroundColor DarkGray

$testCmd = @'
set -e
cd /app
dart pub get --no-example
dart analyze lib bin test
dart test
'@ -replace "`r`n", "`n"

docker.exe run --rm `
    -v $mount `
    -w /app `
    dart:stable `
    bash -eo pipefail -c $testCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host '=== [test] FAILED (exit' $LASTEXITCODE ')' -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host '=== [test] passed ===' -ForegroundColor Green

if ($SkipSmoke) {
    Write-Host 'Skipped smoke-oap (-SkipSmoke)' -ForegroundColor Yellow
    exit 0
}

Write-Host '=== [smoke-oap] job (OAP 10.1.0 + verify_native --quick) ===' -ForegroundColor Cyan
$container = 'skywalking-dart-ci-oap'
Invoke-DockerQuiet @('rm', '-f', $container) | Out-Null

$runCode = Invoke-DockerQuiet @(
    'run', '-d', '--name', $container,
    '-p', '11800:11800',
    '-e', 'SW_HEALTH_CHECKER=default',
    $OapDockerImage
)
if ($runCode -ne 0) { throw "docker run OAP failed (exit $runCode)" }

try {
    $ready = $false
    for ($i = 1; $i -le 60; $i++) {
        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $client.Connect('127.0.0.1', 11800)
            Write-Host "OAP gRPC ready after ${i}s (127.0.0.1:11800)"
            $ready = $true
            break
        } catch {
            Start-Sleep -Seconds 2
        } finally {
            $client.Dispose()
        }
    }
    if (-not $ready) { throw 'OAP gRPC 11800 not reachable within 120s' }

    # TCP open != OAP ready to accept segments; allow JVM/storage init (flaky without this on Windows Docker).
    Write-Host 'OAP TCP up; warming up gRPC (20s)...' -ForegroundColor DarkGray
    Start-Sleep -Seconds 20

    $smokeCmd = 'set -e; cd /app; dart pub get --no-example; dart run bin/verify_native.dart --quick'

    # Published 11800:11800 on host; container reaches host via host.docker.internal (Windows/macOS/Linux Docker Desktop).
    docker.exe run --rm `
        -v $mount `
        -w /app `
        --add-host=host.docker.internal:host-gateway `
        -e SW_AGENT_COLLECTOR_BACKEND_SERVICES=host.docker.internal:11800 `
        -e SKYWALKING_SERVICE_NAME=ci-smoke-my-app `
        dart:stable `
        bash -eo pipefail -c $smokeCmd

    if ($LASTEXITCODE -ne 0) {
        Write-Host '=== [smoke-oap] FAILED (exit' $LASTEXITCODE ')' -ForegroundColor Red
        exit $LASTEXITCODE
    }
    Write-Host '=== [smoke-oap] passed ===' -ForegroundColor Green
}
finally {
    cmd /c "docker rm -f $container" 2>nul | Out-Null
}

Write-Host '=== GitHub-like CI: all passed ===' -ForegroundColor Green
exit 0
