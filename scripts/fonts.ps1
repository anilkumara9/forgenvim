# Windows: install a Nerd Font via winget (covers Devicons in Windows Terminal).
if (Get-Command winget -ErrorAction SilentlyContinue) {
  winget install --id DEVCOM.JetBrainsMonoNerdFont -e
  Write-Host "Set JetBrainsMono Nerd Font as your Windows Terminal font."
} else { Write-Host "Install a Nerd Font from https://www.nerdfonts.com/font-downloads" }
