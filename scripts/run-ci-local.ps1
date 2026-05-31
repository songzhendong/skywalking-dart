# Mirror .github/workflows/ci.yml on Windows (test job + optional OAP smoke).
param(
    [switch] $SkipSmoke
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host '=== CI: pub get (package only, skip example/) ===' -ForegroundColor Cyan
dart pub get --no-example

Write-Host '=== CI: analyze ===' -ForegroundColor Cyan
dart analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '=== CI: test ===' -ForegroundColor Cyan
dart test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($SkipSmoke) {
    Write-Host 'Skipped smoke-oap (-SkipSmoke)' -ForegroundColor Yellow
    exit 0
}

$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
    Write-Host 'Docker not found; skip smoke-oap (install Docker or use -SkipSmoke)' -ForegroundColor Yellow
    exit 0
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

Write-Host '=== CI: smoke-oap (Docker OAP 10.2.0) ===' -ForegroundColor Cyan
$container = 'skywalking-dart-ci-oap'
Invoke-DockerQuiet @('rm', '-f', $container) | Out-Null
$runCode = Invoke-DockerQuiet @(
    'run', '-d', '--name', $container,
    '-p', '11800:11800',
    '-e', 'SW_STORAGE=h2',
    '-e', 'SW_HEALTH_CHECKER=default',
    'apache/skywalking-oap-server:10.2.0'
)
if ($runCode -ne 0) { throw "docker run failed (exit $runCode)" }

try {
    $ready = $false
    for ($i = 1; $i -le 60; $i++) {
        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $client.Connect('127.0.0.1', 11800)
            Write-Host "OAP gRPC ready after ${i}s"
            $ready = $true
            break
        } catch {
            Start-Sleep -Seconds 2
        } finally {
            $client.Dispose()
        }
    }
    if (-not $ready) {
        throw 'OAP gRPC 11800 not reachable within 120s'
    }

    $env:SW_AGENT_COLLECTOR_BACKEND_SERVICES = '127.0.0.1:11800'
    $env:SKYWALKING_SERVICE_NAME = 'ci-smoke-my-app'
    dart run bin/verify_native.dart --quick
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Invoke-DockerQuiet @('stop', '-t', '3', $container) | Out-Null
}

Write-Host '=== CI: all passed ===' -ForegroundColor Green
