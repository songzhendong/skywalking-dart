# Simulate GitHub Actions CI locally (keep in sync with .github/workflows/ci.yml).
#
#   test:     dart:stable container, no Flutter (pub get --no-example, analyze, test)
#   smoke:    OAP docker on host :11800 + host dart compile exe + verify (127.0.0.1:11800)
#
# Usage:
#   .\scripts\run-ci-github-like.ps1
#   .\scripts\run-ci-github-like.ps1 -SkipSmoke
param(
    [switch] $SkipSmoke
)

$ErrorActionPreference = 'Stop'
# Literal image — must match ci.yml "Start OAP" step (GHA cannot use env in services.image).
$OapDockerImage = 'apache/skywalking-oap-server:10.1.0'
$OapContainer = 'ci-oap'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root

$dart = Get-Command dart.exe -ErrorAction SilentlyContinue
if (-not $dart) {
    $flutterDart = 'C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe'
    if (Test-Path $flutterDart) { $dart = Get-Command $flutterDart }
}
if (-not $dart) {
    throw 'dart.exe not found on PATH (install Dart SDK or Flutter).'
}

$docker = Get-Command docker.exe -ErrorAction SilentlyContinue
if (-not $docker) {
    throw 'Docker is required. Use -SkipSmoke for test-only, or install Docker Desktop.'
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

function Test-TcpPort {
    param([string] $HostName, [int] $Port)
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $client.Connect($HostName, $Port)
        return $true
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

function Invoke-VerifyNativeQuick {
    param([string] $DartExe)
    $env:SW_AGENT_COLLECTOR_BACKEND_SERVICES = '127.0.0.1:11800'
    $env:SKYWALKING_SERVICE_NAME = 'ci-smoke-my-app'
    Push-Location $root
    try {
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & $DartExe run bin/verify_native.dart --quick 2>&1 | ForEach-Object { Write-Host $_ }
        $code = $LASTEXITCODE
        $ErrorActionPreference = $prevEap
        return [int]$code
    } finally {
        Pop-Location
    }
}

$mount = "${root}:/app"

Write-Host '=== [test] job (dart:stable) ===' -ForegroundColor Cyan
$testCmd = @'
set -e
cd /app
dart pub get --no-example
dart analyze lib bin test
dart test
'@ -replace "`r`n", "`n"

docker.exe run --rm -v $mount -w /app dart:stable bash -eo pipefail -c $testCmd
if ($LASTEXITCODE -ne 0) {
    Write-Host '=== [test] FAILED ===' -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host '=== [test] passed ===' -ForegroundColor Green

if ($SkipSmoke) {
    Write-Host 'Skipped smoke-oap (-SkipSmoke)' -ForegroundColor Yellow
    exit 0
}

Write-Host '=== [smoke-oap] job (OAP on host + dart run, same as GHA) ===' -ForegroundColor Cyan
Invoke-DockerQuiet @('rm', '-f', $OapContainer) | Out-Null
$imgId = (docker.exe images -q $OapDockerImage 2>$null | Select-Object -First 1)
if (-not $imgId) {
    Write-Host "Pulling $OapDockerImage ..." -ForegroundColor DarkGray
    docker.exe pull $OapDockerImage
    if ($LASTEXITCODE -ne 0) {
        throw @"
Cannot pull OAP image (Docker Hub unreachable?). Options:
  - Fix Docker network / mirror, then re-run this script
  - Run test only: .\scripts\run-ci-github-like.ps1 -SkipSmoke
"@
    }
}

$id = docker.exe run -d --name $OapContainer `
    -p 11800:11800 `
    -e SW_HEALTH_CHECKER=default `
    $OapDockerImage 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host $id
    throw "docker run OAP failed (exit $LASTEXITCODE)"
}
Write-Host "OAP container $id"

$running = docker.exe inspect -f '{{.State.Running}}' $OapContainer 2>$null
if ($running -ne 'true') {
    Write-Host 'OAP container not running; logs:' -ForegroundColor Red
    docker.exe logs $OapContainer 2>&1 | Write-Host
    throw 'OAP container exited immediately after start'
}

try {
    $ready = $false
    for ($i = 1; $i -le 90; $i++) {
        if (Test-TcpPort '127.0.0.1' 11800) {
            Write-Host "OAP TCP 11800 open after $i attempt(s); warm-up 20s..."
            Start-Sleep -Seconds 20
            $ready = $true
            break
        }
        Start-Sleep -Seconds 2
    }
    if (-not $ready) {
        Write-Host 'OAP logs:' -ForegroundColor Red
        docker.exe logs $OapContainer 2>&1 | Write-Host
        throw 'OAP gRPC 11800 not reachable within 180s'
    }

    Write-Host 'dart pub get --no-example' -ForegroundColor DarkGray
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $dart.Source pub get --no-example 2>&1 | Out-Host
    $ErrorActionPreference = $prevEap
    if ($LASTEXITCODE -ne 0) { throw "pub get failed ($LASTEXITCODE)" }

    $maxAttempts = 2
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        Write-Host "verify_native attempt $attempt/$maxAttempts..."
        $code = Invoke-VerifyNativeQuick -DartExe $dart.Source
        if ([int]$code -eq 0) {
            Write-Host '=== [smoke-oap] passed ===' -ForegroundColor Green
            exit 0
        }
        if ($code -ne 0) { Write-Host "verify_native exit $code" -ForegroundColor Yellow }
        if ($attempt -lt $maxAttempts) {
            Write-Host 'retry in 10s...'
            Start-Sleep -Seconds 10
        }
    }

    Write-Host 'OAP logs:' -ForegroundColor Red
    docker.exe logs $OapContainer 2>&1 | Write-Host
    Write-Host '=== [smoke-oap] FAILED ===' -ForegroundColor Red
    exit 1
}
finally {
    Invoke-DockerQuiet @('rm', '-f', $OapContainer) | Out-Null
}
