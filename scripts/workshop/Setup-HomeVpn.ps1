[CmdletBinding()]
param(
    [string]$Distribution = "Ubuntu",
    [string]$VpnHostname = "workshop-vpn.apocalipse.cloud",
    [ValidateRange(1,65535)][int]$Port = 51820,
    [switch]$InstallLinux
)
$ErrorActionPreference = "Stop"
if ([int](Get-CimInstance Win32_OperatingSystem).BuildNumber -lt 22621) {
    throw "This setup requires Windows 11 22H2+ and current WSL2 mirrored networking."
}
$kernel = (& wsl.exe --distribution $Distribution -- uname -r) -join ""
if ($LASTEXITCODE -ne 0 -or $kernel -notmatch "WSL2") { throw "Select a WSL2 Linux distribution." }
$linuxScript = (& wsl.exe --distribution $Distribution -- wslpath -a -u (Join-Path $PSScriptRoot "setup-home-wireguard.sh")) -join ""
if ($LASTEXITCODE -ne 0) { throw "Cannot locate Linux setup script." }
if ($InstallLinux) {
    & wsl.exe --distribution $Distribution --user root -- bash $linuxScript.Trim() $VpnHostname $Port
    if ($LASTEXITCODE -ne 0) { throw "Linux WireGuard setup failed; inspect the preceding error." }
    return
}
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run the Windows configuration phase in an elevated PowerShell window."
}
# Preserve other settings and back up the user's WSL configuration.
$config = Join-Path $env:USERPROFILE ".wslconfig"
$lines = [Collections.Generic.List[string]]::new()
if (Test-Path $config) {
    Copy-Item $config "$config.workshop-backup-$(Get-Date -Format yyyyMMddHHmmss)"
    foreach ($line in Get-Content $config) { $lines.Add($line) }
}
$section = -1
for ($i=0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*\[wsl2\]\s*$') { $section=$i; break } }
if ($section -lt 0) { $lines.Add("[wsl2]"); $lines.Add("networkingMode=mirrored") }
else {
    $end=$section+1
    while ($end -lt $lines.Count -and $lines[$end] -notmatch '^\s*\[') { $end++ }
    $found=$false
    for ($i=$section+1; $i -lt $end; $i++) {
        if ($lines[$i] -match '^\s*networkingMode\s*=') { $lines[$i]="networkingMode=mirrored"; $found=$true }
    }
    if (!$found) { $lines.Insert($end,"networkingMode=mirrored") }
}
[IO.File]::WriteAllLines($config, $lines, [Text.UTF8Encoding]::new($false))
$ruleName = "PZ-Workshop-WireGuard-$Port"
if (!(Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name $ruleName -DisplayName "Workshop WireGuard UDP $Port" `
        -Direction Inbound -Action Allow -Protocol UDP -LocalPort $Port -Profile Any | Out-Null
}
if (!(Get-Command New-NetFirewallHyperVRule -ErrorAction SilentlyContinue)) {
    throw "Hyper-V firewall cmdlets unavailable. Update Windows and WSL before continuing."
}
if (!(Get-NetFirewallHyperVRule -Name $ruleName -ErrorAction SilentlyContinue)) {
    New-NetFirewallHyperVRule -Name $ruleName -DisplayName "WSL Workshop WireGuard UDP $Port" `
        -Direction Inbound -Action Allow -VMCreatorId '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' `
        -Protocol UDP -LocalPorts $Port | Out-Null
}
& wsl.exe --distribution $Distribution --user root -- bash $linuxScript.Trim() --prepare-systemd
if ($LASTEXITCODE -ne 0) { throw "Could not enable WSL systemd." }
Write-Host "Windows firewall and WSL config prepared. Save your WSL work, run wsl --shutdown, then rerun this script with -InstallLinux."
Write-Host "Router: forward UDP $Port to this Windows machine's reserved LAN IPv4. Windows must remain awake while publishing."
