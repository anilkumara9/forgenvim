# ForgeNvim doctor for Windows.
function Check($Name, $Note) {
  if (Get-Command $Name -ErrorAction SilentlyContinue) { Write-Host "ok      $Name" }
  else { Write-Host "missing $Name ($Note)" }
}
Write-Host "== Required =="; Check nvim "required"; Check git "required"
Write-Host "== Search / tools =="; Check rg "project search"; Check fd "file finding"; Check node "JS/TS LSP + debug"; Check npm "Mason JS tools"
Write-Host "== Languages (as needed) =="; Check python "Python"; Check go "Go"; Check cargo "Rust"; Check java "Java"
Write-Host "== Terminal =="; Check pwsh "PowerShell 7 preferred"; Check powershell "Windows PowerShell"; Check wt "Windows Terminal recommended"
Write-Host "== AI CLIs (optional) =="; Check codex "Codex"; Check agent "Cursor Agent"; Check gemini "Gemini"; Check claude "Claude"; Check opencode "OpenCode"; Check agy "Antigravity"; Check aider "Aider"
Write-Host "== Fonts =="; Write-Host "Install a Nerd Font and set it in Windows Terminal: winget install --id DEVCOM.JetBrainsMonoNerdFont -e"
if (Get-Command nvim -ErrorAction SilentlyContinue) { nvim --headless "+ForgeHealth" +qa }
