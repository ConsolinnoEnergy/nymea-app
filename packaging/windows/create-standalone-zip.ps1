param(
    [string]$Workspace = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

$workspacePath = (Resolve-Path -LiteralPath $Workspace).Path

$installer = Get-ChildItem -LiteralPath $workspacePath -Filter "*-win-installer-*.exe" -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $installer) {
    throw "No Windows installer EXE matching '*-win-installer-*.exe' found in '$workspacePath'."
}

$packageDataDirs = Get-ChildItem -LiteralPath $workspacePath -Directory -Recurse -Filter data |
    Where-Object { $_.FullName -match "\\packaging\\windows\\packages\\[^\\]+\\data$" } |
    ForEach-Object {
        $applicationExe = Get-ChildItem -LiteralPath $_.FullName -Filter "*.exe" -File |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($applicationExe) {
            [PSCustomObject]@{
                DataDirectory = $_
                ApplicationExe = $applicationExe
            }
        }
    }

$packageData = $packageDataDirs |
    Sort-Object { $_.ApplicationExe.LastWriteTime } -Descending |
    Select-Object -First 1

if (-not $packageData) {
    throw "No Windows package data directory containing an application EXE found below '$workspacePath'."
}

$zipDestination = Join-Path $workspacePath ($installer.BaseName + "-standalone.zip")

Write-Host ("Using package data directory: " + $packageData.DataDirectory.FullName)
Write-Host ("Using packaged application: " + $packageData.ApplicationExe.FullName)
Write-Host ("Creating standalone ZIP: " + $zipDestination)

Compress-Archive -Path (Join-Path $packageData.DataDirectory.FullName "*") -DestinationPath $zipDestination -Force
