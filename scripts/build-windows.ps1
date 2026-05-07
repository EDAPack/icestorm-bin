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

# ── Build libusb (pre-built binaries) ────────────────────────────────────────
$LIBUSB_VERSION = "1.0.27"
$libusbArchive = "$root\libusb-$LIBUSB_VERSION.7z"
$libusbDir     = "$root\libusb-$LIBUSB_VERSION"

if (-not (Test-Path $libusbDir)) {
    Write-Host "Downloading libusb $LIBUSB_VERSION..."
    Invoke-WebRequest "https://github.com/libusb/libusb/releases/download/v$LIBUSB_VERSION/libusb-$LIBUSB_VERSION.7z" `
        -OutFile $libusbArchive
    # 7-Zip is available on GitHub Actions runners and most Windows dev machines
    7z x $libusbArchive "-o$libusbDir" -y | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "libusb extraction failed" }
}

# Robustly locate the extracted files (archive structure varies by release)
Write-Host "libusb extracted structure:"
Get-ChildItem $libusbDir -Recurse -File | Select-Object -ExpandProperty FullName | Select-Object -First 30

$libusbInclude = (Get-ChildItem $libusbDir -Recurse -Filter "libusb.h" |
                  Select-Object -First 1).DirectoryName
# Prefer the import .lib next to a .dll (dll/ subdir), for x64
$libusbLib = (Get-ChildItem $libusbDir -Recurse -Filter "libusb-1.0.lib" |
              Where-Object { $_.DirectoryName -match 'dll' -and $_.DirectoryName -match '64' } |
              Select-Object -First 1).FullName
if (-not $libusbLib) {
    # Fallback: any .lib for x64
    $libusbLib = (Get-ChildItem $libusbDir -Recurse -Filter "libusb-1.0.lib" |
                  Where-Object { $_.DirectoryName -match '64' } |
                  Select-Object -First 1).FullName
}
$libusbDll = (Get-ChildItem $libusbDir -Recurse -Filter "libusb-1.0.dll" |
              Where-Object { $_.DirectoryName -match '64' } |
              Select-Object -First 1).FullName

if (-not $libusbInclude) { throw "libusb.h not found in extracted archive" }
if (-not $libusbLib)     { throw "libusb-1.0.lib not found in extracted archive" }
if (-not $libusbDll)     { throw "libusb-1.0.dll not found in extracted archive" }
Write-Host "libusb include: $libusbInclude"
Write-Host "libusb lib:     $libusbLib"
Write-Host "libusb dll:     $libusbDll"

# ── Build libftdi from source ─────────────────────────────────────────────────
$LIBFTDI_VERSION = "1.5"
$libftdiArchive = "$root\libftdi1-$LIBFTDI_VERSION.tar.bz2"
$libftdiSrc     = "$root\libftdi1-$LIBFTDI_VERSION"
$libftdiStaging = "$root\staging-libftdi"
$libftdiBuildDir = "$root\build-libftdi"

if (-not (Test-Path $libftdiSrc)) {
    Write-Host "Downloading libftdi $LIBFTDI_VERSION..."
    Invoke-WebRequest "https://www.intra2net.com/en/developer/libftdi/download/libftdi1-$LIBFTDI_VERSION.tar.bz2" `
        -OutFile $libftdiArchive
    Push-Location $root
    cmake -E tar xjf $libftdiArchive
    if ($LASTEXITCODE -ne 0) { throw "libftdi extraction failed" }
    Pop-Location
}

# Patch ftdi_stream.c: the sys/time.h include is guarded by #ifndef _WIN32
# but gettimeofday() is still called unconditionally. Add an #else branch
# providing a Windows implementation via GetSystemTimeAsFileTime().
$ftdiStreamPath = "$libftdiSrc\src\ftdi_stream.c"
$content = Get-Content $ftdiStreamPath -Raw
$compat = @'
#ifndef _WIN32
#include <sys/time.h>
#else
#include <winsock2.h>
#include <windows.h>
static int gettimeofday(struct timeval *tv, void *tz) {
    FILETIME ft; unsigned long long tmp;
    GetSystemTimeAsFileTime(&ft);
    tmp  = (unsigned long long)ft.dwHighDateTime << 32;
    tmp |= ft.dwLowDateTime;
    tmp -= 116444736000000000ULL;
    tmp /= 10;
    tv->tv_sec  = (long)(tmp / 1000000UL);
    tv->tv_usec = (long)(tmp % 1000000UL);
    (void)tz; return 0;
}
#endif
'@
# Match the existing #ifndef _WIN32 / #include <sys/time.h> / #endif block
$content = $content -replace '(?s)#ifndef _WIN32\s*\r?\n#include <sys/time\.h>\s*\r?\n#endif', $compat.Trim()
Set-Content $ftdiStreamPath $content -NoNewline

if (Test-Path $libftdiBuildDir) { Remove-Item $libftdiBuildDir -Recurse -Force }
New-Item -ItemType Directory $libftdiBuildDir | Out-Null
New-Item -ItemType Directory -Force $libftdiStaging | Out-Null

cmake -S $libftdiSrc -B $libftdiBuildDir `
    -G Ninja `
    -DCMAKE_BUILD_TYPE=Release `
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 `
    "-DCMAKE_INSTALL_PREFIX=$libftdiStaging" `
    "-DLIBUSB_INCLUDE_DIR=$libusbInclude" `
    "-DLIBUSB_LIBRARIES=$libusbLib" `
    -DFTDIPP=OFF `
    -DPYTHON_BINDINGS=OFF `
    -DDOCUMENTATION=OFF `
    -DEXAMPLES=OFF `
    -DFTDI_EEPROM=OFF `
    -DSTATICLIBS=OFF
if ($LASTEXITCODE -ne 0) { throw "libftdi cmake configure failed" }

cmake --build $libftdiBuildDir --parallel
if ($LASTEXITCODE -ne 0) { throw "libftdi build failed" }

cmake --install $libftdiBuildDir
if ($LASTEXITCODE -ne 0) { throw "libftdi install failed" }

# libftdi cmake may not install the import lib (.lib) on Windows — copy it manually
New-Item -ItemType Directory -Force "$libftdiStaging\lib" | Out-Null
$builtImportLib = "$libftdiBuildDir\src\ftdi1.lib"
if (Test-Path $builtImportLib) {
    Copy-Item $builtImportLib "$libftdiStaging\lib\ftdi1.lib" -Force
    Write-Host "Copied import lib from build dir to $libftdiStaging\lib\ftdi1.lib"
} elseif (-not (Test-Path "$libftdiStaging\lib\ftdi1.lib")) {
    throw "ftdi1.lib not found in build dir ($builtImportLib) or staging dir"
}

# Locate the installed DLL (target name is ftdi1, so ftdi1.dll on Windows)
$libftdiInclude = "$libftdiStaging\include\libftdi1"
$libftdiLib     = "$libftdiStaging\lib\ftdi1.lib"
$libftdiDll     = (Get-ChildItem "$libftdiStaging\bin" -Filter "ftdi*.dll" |
                   Select-Object -First 1).FullName
if (-not $libftdiDll) { throw "libftdi DLL not found in $libftdiStaging\bin" }
Write-Host "libftdi DLL: $libftdiDll"

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

# ── Patch upstream sources for MSVC compatibility ────────────────────────────
# icepll.cc calls abs() on doubles; MSVC's <math.h> doesn't provide abs(double).
# Replace with fabs() which is unambiguous for floating-point.
$icepllPath = "$icestormDir\icepll\icepll.cc"
$content = Get-Content $icepllPath -Raw
$content = $content -replace 'if \(abs\(fout - f_pllout\) < abs\(best_fout - f_pllout\)\)',
                              'if (fabs(fout - f_pllout) < fabs(best_fout - f_pllout))'
Set-Content $icepllPath $content -NoNewline

# iceutil.cc (non-MinGW branch): uses WCHAR for longpath but calls GetModuleFileName
# (which without UNICODE defined maps to GetModuleFileNameA, taking char*).
# Change WCHAR longpath to TCHAR longpath so both buffer types match the API.
$iceutilPath = "$icestormDir\icetime\iceutil.cc"
$content = Get-Content $iceutilPath -Raw
$content = $content -replace 'WCHAR longpath\[MAX_PATH \+ 1\];', 'TCHAR longpath[MAX_PATH + 1];'
Set-Content $iceutilPath $content -NoNewline

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
    "-DGEN_TIMINGS_SCRIPT=$genTimingsScript" `
    "-DLIBFTDI1_INCLUDE_DIR=$libftdiInclude" `
    "-DLIBFTDI1_LIBRARY=$libftdiLib" `
    "-DLIBFTDI1_DLL=$libftdiDll" `
    "-DLIBUSB1_DLL=$libusbDll"
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
