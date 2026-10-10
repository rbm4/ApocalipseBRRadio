# Publish through your home connection

The GitHub-hosted worker builds the package normally. Its SteamCMD Docker container
connects to a home WireGuard server before attempting login. The endpoint's DNS
A record supplies the current home IPv4, and the container checks HTTPS ipify
through the tunnel against that address. A missing tunnel, stale DNS or different
exit IP stops publication before Steam credentials are used. Its outbound firewall
permits only the encrypted endpoint UDP outside WireGuard; IPv6 is blocked.
Steam Guard can still request mobile approval: this changes the network origin,
not Steam's device or account authentication rules.

## Windows 11 with Ubuntu WSL2

Use Windows 11 22H2+ with updated WSL2 (`wsl --update`). Clone this repository onto
the Windows machine so the PowerShell and Bash scripts remain together. The setup
uses systemd and mirrored networking, backs up `.wslconfig`, preserves its other
settings, and adds specific inbound UDP Windows and WSL Hyper-V firewall rules.
It does not allow every Hyper-V inbound connection or change router configuration.

Run in **Administrator PowerShell**, from the repository directory:

```powershell
.\scripts\workshop\Setup-HomeVpn.ps1
# Save any open WSL work first: this stops all running WSL distributions.
wsl --shutdown
.\scripts\workshop\Setup-HomeVpn.ps1 -InstallLinux
```

Use `-Distribution Ubuntu-24.04` if that is your installed distribution name
(`wsl -l -v` lists them). Both phases accept `-VpnHostname` and `-Port` overrides;
use the same values for each phase. The Linux phase installs packages, enables
IPv4 forwarding, generates persistent server/client keys and a preshared key,
starts `wg-quick@wg-workshop`, and checks the current public IPv4 and DNS.
Existing keys are reused on subsequent runs. Keep `/etc/wireguard` private.
The client can access the public internet but firewall rules deny access to
private/home networks and the VPN server itself.

On your router, reserve the Windows machine's LAN IPv4 and forward **UDP 51820**
to that address (or your chosen port). Compare the router WAN IPv4 with the
script's public IPv4; inbound forwarding requires a public IPv4 assigned to your
router, not CGNAT. Keep Windows awake and WSL running during publication.
After a Windows reboot, start Ubuntu; systemd starts the enabled VPN service.

## Dynamic DNS through pzmanager

Use a dedicated DNS-only A record, default **workshop-vpn.apocalipse.cloud**.
Do not configure an HTTPS proxy or load balancer for it. The new pzmanager
configuration extends its existing Hostinger updater:

```powershell
$env:DDNS_ADDITIONAL_SUBDOMAINS = 'workshop-vpn'
# Start your usual local pzmanager process in this environment, with profile local.
```

Keep the existing `HOSTINGER_API_KEY` configured **on the home machine** and the
local backend running to refresh DNS every five minutes. Hostinger must be the
authoritative DNS provider for `hostinger.base-domain`. The existing `develop`
record is retained alongside the new record. Additional records persist when
pzmanager stops; it updates them again when restarted. Merge/deploy the companion
backend change before relying on this setting. The production backend or a hosted
worker would observe its own IP, so must not run the home DNS updater.

The workflow needs no DNS API credential or separate public-IP secret. It resolves
the hostname once, pins its UDP endpoint to that IPv4 for the run and compares its
actual exit IP with that value. Wait for DNS propagation after an ISP IP change.

## Organization secret

Copy the generated base64 client configuration without printing its contents:

```powershell
wsl -d Ubuntu -u root -- cat /etc/wireguard/workshop-client.base64 | Set-Clipboard
```

Add **WORKSHOP_WIREGUARD_CONFIG** at
https://github.com/organizations/ApocalipseBr/settings/secrets/actions and grant
this repository access. Paste the clipboard contents, then clear your clipboard.
This contains private keys; never commit it, attach it to artifacts or log it.
Keep all existing Steam and restart secrets as documented in
[Workshop publishing](workshop-publishing.md). The reusable workflow caller must
explicitly map `WORKSHOP_WIREGUARD_CONFIG`, too.

The container starts as root with only the extra `NET_ADMIN` capability to configure
its own bridge namespace, then drops to `steam` before launching the publisher.
It uses neither privileged mode nor the runner's host network. Session export,
secret refresh and the pzmanager restart request retain their existing behavior.
PR checks build/test without VPN or Steam secrets. Interactive local bootstrap
explicitly overrides the entrypoint and runs as `steam`, using your local connection.

This setup provisions **one client peer**. GitHub concurrency only serializes runs
within a repository. Do not share this client secret across repositories that
publish concurrently: WireGuard peers roam between endpoints. Use a centralized
publishing workflow, or provision distinct peers/addresses and per-repository
secrets before expanding to simultaneous publishers.

## Diagnose without publishing

On the home machine, inspect service and peer status:

```powershell
wsl -d Ubuntu -u root -- systemctl status wg-quick@wg-workshop
wsl -d Ubuntu -u root -- wg show wg-workshop
Resolve-DnsName workshop-vpn.apocalipse.cloud -Type A
```

No handshake in a publishing run points to DNS, router forwarding, Windows/Hyper-V
firewall, WSL availability or mismatched keys. An exit-IP mismatch means DNS and
actual egress disagree (including another VPN on the home host). The workflow
fails closed; it never retries Steam directly through the GitHub IP. If setup was
interrupted, inspect the service and its named `PZ-WORKSHOP-VPN` chain before
rerunning; do not flush unrelated firewall rules.

Offline policy and authentication tests run in CI. Windows firewall changes,
router forwarding and a real WireGuard handshake require validation on your
machine; no setup script or Steam publishing was executed during implementation.

References: [Microsoft WSL networking](https://learn.microsoft.com/windows/wsl/networking),
[Hyper-V firewall](https://learn.microsoft.com/windows/security/operating-system-security/network-security/windows-firewall/hyper-v-firewall),
[WireGuard quick start](https://www.wireguard.com/quickstart/),
[container network namespaces](https://www.wireguard.com/netns/).
