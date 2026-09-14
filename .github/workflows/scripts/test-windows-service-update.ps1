# Run only on an isolated, elevated Windows CI runner.
$ErrorActionPreference = 'Stop'
$installDir = Join-Path $env:ProgramData 'Jackett'
$console = Join-Path $installDir 'JackettConsole.exe'
$testRoot = Join-Path $env:RUNNER_TEMP 'jackett-service-update-test'
$dashboard = 'http://127.0.0.1:9117/UI/Dashboard'

function Wait-Dashboard {
    $deadline = (Get-Date).AddSeconds(60)
    do {
        try {
            $response = Invoke-WebRequest $dashboard -TimeoutSec 3
            if ($response.StatusCode -eq 200) { return }
        }
        catch { }
        Start-Sleep -Seconds 1
    } while ((Get-Date) -lt $deadline)
    throw 'The Jackett dashboard did not become available within 60 seconds.'
}

function Assert-Service {
    $service = Get-CimInstance Win32_Service -Filter "Name='Jackett'"
    if ($null -eq $service -or $service.StartMode -ne 'Auto' -or $service.State -ne 'Running') {
        throw "Jackett service is not running with automatic startup: $($service | ConvertTo-Json -Compress)"
    }
    Wait-Dashboard
}

if (Get-Service Jackett -ErrorAction SilentlyContinue) {
    throw 'Refusing to run this CI test over an existing Jackett service.'
}

try {
    New-Item -ItemType Directory -Force $testRoot | Out-Null
    $installer = (Resolve-Path 'build/Jackett.Installer.Windows.exe').Path
    $setup = Start-Process $installer -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-' -PassThru
    if (-not $setup.WaitForExit(120000)) { throw 'Installer timed out.' }
    if ($setup.ExitCode -ne 0) { throw "Installer exited with $($setup.ExitCode)." }
    Assert-Service
    Write-Host 'PASS: installer starts the automatic Windows service and dashboard.'

    # Exercise service stop/start separately from the installer.
    Stop-Service Jackett
    (Get-Service Jackett).WaitForStatus('Stopped', [TimeSpan]::FromSeconds(60))
    & $console --Start
    if ($LASTEXITCODE -ne 0) { throw 'The --Start command failed.' }
    Assert-Service
    Write-Host 'PASS: the installed Windows service restarts.'

    # The Web UI downloads this ZIP and launches its updater from a temporary folder.
    Expand-Archive 'build/Jackett.Binaries.Windows.zip' -DestinationPath $testRoot -Force
    $sourceDir = Join-Path $testRoot 'Jackett'
    $updaterExe = Join-Path $sourceDir 'JackettUpdater.exe'
    $installedConsole = @(Get-CimInstance Win32_Process -Filter "Name='JackettConsole.exe'" |
        Where-Object { $_.ExecutablePath -eq $console })
    if ($installedConsole.Count -ne 1) { throw 'Expected exactly one service-owned Jackett console.' }
    $consolePid = $installedConsole[0].ProcessId
    $updaterLog = Join-Path $installDir 'updater.txt'
    Remove-Item $updaterLog -Force -ErrorAction SilentlyContinue
    New-Item -ItemType File -Force (Join-Path $installDir '.lock') | Out-Null

    $arguments = '--Path "{0}" --Type WindowsService --KillPids "{1}"' -f $installDir, $consolePid
    $updater = Start-Process $updaterExe -ArgumentList $arguments -WorkingDirectory $sourceDir -PassThru
    if (-not $updater.WaitForExit(180000)) { throw 'The updater timed out.' }
    if ($updater.ExitCode -ne 0) { throw "Updater exited with $($updater.ExitCode)." }
    Assert-Service
    if (Test-Path (Join-Path $installDir '.lock')) { throw 'The update failure marker remains.' }
    if (Select-String -Path $updaterLog -Pattern '\s(ERROR|FATAL)\s' -Quiet) {
        throw 'The updater logged an error.'
    }
    foreach ($file in Get-ChildItem $sourceDir -Recurse -File) {
        $relative = [IO.Path]::GetRelativePath($sourceDir, $file.FullName)
        $installed = Join-Path $installDir $relative
        if (!(Test-Path $installed) -or (Get-FileHash $file.FullName).Hash -ne (Get-FileHash $installed).Hash) {
            throw "Installed file does not match the update package: $relative"
        }
    }
    Write-Host 'PASS: ZIP update replaces all files and restores the service and dashboard.'
}
finally {
    foreach ($name in @('log.txt', 'updater.txt', 'ServiceLog.txt')) {
        $path = Join-Path $installDir $name
        if (Test-Path $path) {
            Write-Host "Last lines of $name"
            Get-Content $path -Tail 100
        }
    }
    $service = Get-Service Jackett -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.Status -ne 'Stopped') {
            Stop-Service Jackett -ErrorAction Continue
            $service.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(60))
        }
        & sc.exe delete Jackett
    }
}
