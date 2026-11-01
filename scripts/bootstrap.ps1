# ForgeNvim one-line installer for Windows:
#   irm https://raw.githubusercontent.com/anilkumara9/forgenvim/main/scripts/bootstrap.ps1 | iex
# With preview: set $env:FORGE_PREVIEW=1 before running.
param([switch]$Preview)
$ErrorActionPreference = "Stop"
$Repo = if ($env:FORGE_REPO) { $env:FORGE_REPO } else { "https://github.com/anilkumara9/forgenvim.git" }
$HomeDir = if ($env:FORGE_HOME) { $env:FORGE_HOME } else { Join-Path $env:LOCALAPPDATA "forgenvim-src" }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Host "git is required: winget install Git.Git"; exit 1 }
if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
  Write-Host "Installing Neovim via winget..."
  if (Get-Command winget -ErrorAction SilentlyContinue) { winget install --id Neovim.Neovim -e --silent } else { Write-Host "Install Neovim 0.11+ from https://github.com/neovim/neovim/releases"; exit 1 }
}
# Optional but recommended tools (search, JS tooling, native builds)
foreach ($Pkg in @("BurntSushi.ripgrep.MSVC","sharkdp.fd","OpenJS.NodeJS.LTS","Microsoft.VisualStudio.2022.BuildTools")) {
  if (Get-Command winget -ErrorAction SilentlyContinue) { winget install --id $Pkg -e --silent 2>$null | Out-Null }
}
if (Test-Path (Join-Path $HomeDir ".git")) { git -C $HomeDir pull --ff-only } else { git clone --depth 1 $Repo $HomeDir }
$Installer = Join-Path $HomeDir "scripts\install.ps1"
if ($Preview -or $env:FORGE_PREVIEW -eq "1") { & $Installer -Preview; Write-Host "Preview: `$env:NVIM_APPNAME='nvim-preview'; nvim ." } else { & $Installer }
Write-Host "Done. Run: nvim ."
