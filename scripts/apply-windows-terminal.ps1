# Windows Terminal: give ForgeNvim the frosted-glass look.
# ForgeNvim's editor is transparent by design (Settings > Terminal
# transparency, on by default), so whatever the terminal draws behind the
# text is the editor's background. On macOS that is Warp's blur; on
# Windows the equal is Windows Terminal acrylic. This script merges the
# three profile-default values into your Windows Terminal settings
# (after a timestamped backup) - font face with the icon fonts as the
# system fallback, acrylic material, 85% opacity.
$ErrorActionPreference = "Stop"
$Candidates = @(
  (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
  (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"),
  (Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json")
)
$SettingsPath = $Candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $SettingsPath) {
  Write-Host "Windows Terminal settings.json not found. Install Windows Terminal, run it once, then re-run this script."
  Write-Host "Manual values for profiles.defaults: font.face = 'JetBrainsMono Nerd Font', opacity = 85, useAcrylic = true."
  exit 1
}
$Stamp = Get-Date -Format "yyyyMMddHHmmss"
Copy-Item $SettingsPath "$SettingsPath.forgenvim-bak-$Stamp"
Write-Host "Backed up settings to $SettingsPath.forgenvim-bak-$Stamp"
$Raw = Get-Content $SettingsPath -Raw
try { $Json = $Raw | ConvertFrom-Json }
catch {
  # Windows Terminal settings are JSONC: comments and trailing commas are
  # common and ConvertFrom-Json rejects both. Strip comments with a
  # string-aware pass, drop trailing commas, and parse again.
  $Clean = [regex]::Replace($Raw, '(?s)("(?:\\.|[^"\\])*")|//[^\r\n]*|/\*.*?\*/', { param($m) if ($m.Groups[1].Success) { $m.Groups[1].Value } else { "" } })
  $Clean = [regex]::Replace($Clean, ',(\s*[}\]])', '$1')
  try { $Json = $Clean | ConvertFrom-Json }
  catch { Write-Host "Could not parse settings.json even after JSONC cleanup. Edit it manually: profiles.defaults -> font.face 'JetBrainsMono Nerd Font', opacity 85, useAcrylic true."; exit 1 }
}
if (-not $Json.profiles) { $Json | Add-Member -NotePropertyName profiles -NotePropertyValue ([PSCustomObject]@{}) }
if (-not $Json.profiles.defaults) { $Json.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([PSCustomObject]@{}) }
$Defaults = $Json.profiles.defaults
function Set-Prop($Obj, $Name, $Value) {
  if ($Obj.PSObject.Properties.Name -contains $Name) { $Obj.$Name = $Value }
  else { $Obj | Add-Member -NotePropertyName $Name -NotePropertyValue $Value }
}
if (-not $Defaults.font) { Set-Prop $Defaults "font" ([PSCustomObject]@{}) }
Set-Prop $Defaults.font "face" "JetBrainsMono Nerd Font"
Set-Prop $Defaults "opacity" 85
Set-Prop $Defaults "useAcrylic" $true
$Json | ConvertTo-Json -Depth 32 | Set-Content $SettingsPath -Encoding UTF8
Write-Host "Windows Terminal defaults updated: JetBrainsMono Nerd Font, acrylic on, opacity 85."
Write-Host "Restart Windows Terminal to see the glass look. Raise opacity toward 100 if text contrast feels low."
