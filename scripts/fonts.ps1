# Windows: install the icon fonts ForgeNvim needs, per user (no admin).
# - Symbols Nerd Font / Symbols Nerd Font Mono: every Devicon and powerline
#   glyph the UI draws, as a fallback face next to the coding font.
# - Monocraft Nerd Font: the pixel-style face the reference setup pairs
#   with Warp on macOS; optional on Windows, offered for the same look.
# - JetBrainsMono Nerd Font via winget: the recommended coding face.
$ErrorActionPreference = "Continue"
$FontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
$RegKey = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
New-Item -ItemType Directory -Force -Path $FontDir | Out-Null

function Install-UserFont($DisplayName, $FileName, $Url, $ZipMember) {
  $Target = Join-Path $FontDir $FileName
  if (Test-Path $Target) { Write-Host "$DisplayName already installed."; return }
  try {
    $Tmp = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Force -Path $Tmp | Out-Null
    $Dl = Join-Path $Tmp "download.bin"
    Invoke-WebRequest -Uri $Url -OutFile $Dl -UseBasicParsing
    if ($ZipMember) {
      Expand-Archive -Path $Dl -DestinationPath $Tmp -Force
      $SrcFile = Join-Path $Tmp $ZipMember
    } else { $SrcFile = $Dl }
    Copy-Item $SrcFile $Target -Force
    New-ItemProperty -Path $RegKey -Name "$DisplayName (TrueType)" -Value $FileName -PropertyType String -Force | Out-Null
    Write-Host "Installed $DisplayName."
  } catch { Write-Host "Could not install $DisplayName ($($_.Exception.Message)). Install it manually from $Url" }
}

Install-UserFont "Symbols Nerd Font Mono" "SymbolsNerdFontMono-Regular.ttf" `
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/NerdFontsSymbolsOnly.zip" "SymbolsNerdFontMono-Regular.ttf"
Install-UserFont "Symbols Nerd Font" "SymbolsNerdFont-Regular.ttf" `
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/NerdFontsSymbolsOnly.zip" "SymbolsNerdFont-Regular.ttf"
Install-UserFont "Monocraft Nerd Font" "Monocraft-nerd-fonts-patched.ttc" `
  "https://github.com/idreesinc/Monocraft/releases/download/v4.2.1/Monocraft-nerd-fonts-patched.ttc" $null

if (Get-Command winget -ErrorAction SilentlyContinue) {
  winget install --id DEVCOM.JetBrainsMonoNerdFont -e --accept-source-agreements --accept-package-agreements
} else { Write-Host "winget not found: install JetBrainsMono Nerd Font from https://www.nerdfonts.com/font-downloads" }
Write-Host "Icon fonts installed (Symbols Nerd Font, Monocraft Nerd Font, JetBrainsMono Nerd Font). Restart your terminal to load them."
