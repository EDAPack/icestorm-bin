#!/usr/bin/env pwsh
# Build icestorm for Windows using MSVC + Ninja via CMake.
# Run from a Visual Studio Developer Command Prompt, or CI uses
# ilammy/msvc-dev-cmd to set up the environment first.
#
# Usage: .\scripts\build-windows.ps1 [-IcestormVersion <ver>]
param(
    [string]$IcestormVersion = ""
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot | Split-Path -Parent

# Version string
if (-not $IcestormVersion) {
    $buildNum = $env:BUILD_NUM
    if ($buildNum) {
        $IcestormVersion = "1.1.$buildNum"
    } else {
        $IcestormVersion = "1.1"
    }
}
$rlsPlat = "windows-x64"
Write-Host "Version:  $IcestormVersion"
Write-Host "Platform: $rlsPlat"

# ── Clone icestorm ────────────────────────────────────────────────────────────
$icestormDir = "$root\icestorm"
if (-not (Test-Path $icestormDir)) {
    git clone https://github.com/YosysHQ/icestorm $icestormDir
    if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
}
git config --global --add safe.directory $icestormDir.Replace('\','/')

# ── Place our CMakeLists and compat headers ───────────────────────────────────
Copy-Item "$root\cmake\CMakeLists.txt" "$icestormDir\CMakeLists.txt" -Force

# Copy compat directory into the icestorm source tree
$compatDest = "$icestormDir\compat"
if (Test-Path $compatDest) { Remove-Item $compatDest -Recurse -Force }
Copy-Item "$root\compat" $compatDest -Recurse

# ── Configure + build ─────────────────────────────────────────────────────────
$installDir = "$root\release\icestorm"
$buildDir   = "$root\build-windows"

if (Test-Path $buildDir) { Remove-Item $buildDir -Recurse -Force }
New-Item -ItemType Directory $buildDir | Out-Null

$genTimingsScript = "$root\cmake\gen_timings.cmake".Replace('\','/')
$compatDirFwd     = $compatDest.Replace('\','/')

cmake -S $icestormDir -B $buildDir `
    -G Ninja `
    -DCMAKE_BUILD_TYPE=Release `
    -DCMAKE_INSTALL_PREFIX="$installDir" `
    "-DCOMPAT_DIR=$compatDirFwd" `
    "-DGEN_TIMINGS_SCRIPT=$genTimingsScript"
if ($LASTEXITCODE -ne 0) { throw "cmake configure failed" }

cmake --build $buildDir --parallel
if ($LASTEXITCODE -ne 0) { throw "cmake build failed" }

cmake --install $buildDir
if ($LASTEXITCODE -ne 0) { throw "cmake install failed" }

# Copy export.envrc for ivpm
Copy-Item "$root\scripts\export.envrc" "$installDir\" -Force

# ── Package ───────────────────────────────────────────────────────────────────
$releaseDir = "$root\release"
if (-not (Test-Path $releaseDir)) { New-Item -ItemType Directory $releaseDir | Out-Null }

$archive = "$releaseDir\icestorm-$rlsPlat-$IcestormVersion.zip"
if (Test-Path $archive) { Remove-Item $archive }
Compress-Archive -Path "$installDir\*" -DestinationPath $archive

Write-Host "Build complete: $archive"
