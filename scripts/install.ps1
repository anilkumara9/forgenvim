# ForgeNvim installer for Windows (PowerShell 5.1+ / PowerShell 7).
# Installs into $env:LOCALAPPDATA\<AppName> (nvim by default), backing up first.
param([switch]$Preview)
$ErrorActionPreference = "Stop"
$Src = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$AppName = if ($env:FORGE_APPNAME) { $env:FORGE_APPNAME } elseif ($Preview) { "nvim-preview" } else { "nvim" }
$Dest = Join-Path $env:LOCALAPPDATA $AppName
if ((Test-Path $Dest) -and -not (Test-Path (Join-Path $Dest ".forgenvim"))) {
  $Stamp = Get-Date -Format "yyyyMMddHHmmss"
  Write-Host "Backing up existing config to $Dest.bak-$Stamp"
  Copy-Item -Recurse $Dest "$Dest.bak-$Stamp"
}
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
foreach ($Item in @("init.lua","lua","scripts","docs","README.md","LICENSE","Makefile","VERSION")) {
  $From = Join-Path $Src $Item
  if (Test-Path $From) { Copy-Item -Recurse -Force $From $Dest }
}
New-Item -ItemType File -Force -Path (Join-Path $Dest ".forgenvim") | Out-Null
Write-Host "Installed ForgeNvim to $Dest"
# Icon fonts (Symbols Nerd Font, Monocraft Nerd Font, JetBrainsMono Nerd
# Font). A font hiccup must never fail the install, so this is guarded.
try { & (Join-Path $Src "scripts\fonts.ps1") } catch { Write-Host "Font step skipped: $($_.Exception.Message)" }
if (Get-Command nvim -ErrorAction SilentlyContinue) {
  $env:FORGE_MINIMAL = "1"; $env:NVIM_APPNAME = $AppName
  nvim --headless "+lua print('ForgeNvim core loads OK')" +qa
} else {
  Write-Host "Neovim not found. Install: winget install Neovim.Neovim"
}
Write-Host "First launch installs plugins via lazy.nvim (needs internet). Run: nvim ."
Write-Host "For the frosted-glass look in Windows Terminal, run: scripts\apply-windows-terminal.ps1"
