#!/usr/bin/env bash
# Run through Setup-HomeVpn.ps1, or as root on an Ubuntu/Debian home host.
set -euo pipefail
if [[ ${EUID} -ne 0 ]]; then echo "Run this script as root." >&2; exit 1; fi
if [[ ${1:-} == --prepare-systemd ]]; then
  python3 - <<'PY'
import configparser
from pathlib import Path
p = Path('/etc/wsl.conf')
c = configparser.ConfigParser(interpolation=None)
if p.exists(): c.read(p)
if not c.has_section('boot'): c.add_section('boot')
c.set('boot', 'systemd', 'true')
with p.open('w') as f: c.write(f)
PY
  echo "WSL systemd enabled. Restart WSL before installing the VPN server."
  exit 0
fi
endpoint=${1:?Supply your DNS-only VPN hostname, for example workshop-vpn.apocalipse.cloud}
port=${2:-51820}
[[ "$endpoint" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ && "$port" =~ ^[0-9]{1,5}$ ]] || exit 1
(( port >= 1 && port <= 65535 )) || exit 1
[[ $(ps -p 1 -o comm=) == systemd ]] || { echo "Enable systemd and restart WSL first." >&2; exit 1; }
apt-get update
apt-get install --no-install-recommends -y wireguard-tools iptables curl python3
umask 077
install -d -m 700 /etc/wireguard/workshop-keys
for role in server client; do
  if [[ ! -s "/etc/wireguard/workshop-keys/$role.key" ]]; then
    wg genkey > "/etc/wireguard/workshop-keys/$role.key"
  fi
  wg pubkey < "/etc/wireguard/workshop-keys/$role.key" > "/etc/wireguard/workshop-keys/$role.pub"
done
[[ -s /etc/wireguard/workshop-keys/psk ]] || wg genpsk > /etc/wireguard/workshop-keys/psk
public_ip=$(curl -4 --fail --silent --show-error --max-time 20 https://api.ipify.org)
python3 - "$public_ip" <<'PY'
import ipaddress, sys
ip = ipaddress.IPv4Address(sys.argv[1])
if not ip.is_global: raise SystemExit('A public IPv4 is required; check ISP/CGNAT.')
PY
outbound=$(ip -j route show default | python3 -c 'import json,sys; r=json.load(sys.stdin); assert len(r)==1; print(r[0]["dev"])')
[[ "$outbound" =~ ^[A-Za-z0-9_.:-]+$ ]] || exit 1
echo "Home public IPv4: $public_ip"
echo "Outbound interface: $outbound"
printf 'net.ipv4.ip_forward=1\n' > /etc/sysctl.d/90-workshop-wireguard.conf
sysctl -p /etc/sysctl.d/90-workshop-wireguard.conf >/dev/null
# Own only wg-workshop and its named firewall chain; leave other VPNs/rules alone.
if systemctl is-active --quiet wg-quick@wg-workshop; then systemctl stop wg-quick@wg-workshop; fi
cat > /etc/wireguard/workshop-firewall <<'SH'
#!/usr/bin/env bash
set -euo pipefail
action=$1; tunnel=$2; outbound=$3; port=$4
if [[ "$action" == up ]]; then
  iptables -N PZ-WORKSHOP-VPN
  for range in 0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4; do
    iptables -A PZ-WORKSHOP-VPN -d "$range" -j DROP
  done
  iptables -A PZ-WORKSHOP-VPN -s 10.77.0.2/32 -o "$outbound" -j ACCEPT
  iptables -A PZ-WORKSHOP-VPN -j DROP
  iptables -I FORWARD 1 -i "$tunnel" -j PZ-WORKSHOP-VPN
  iptables -I FORWARD 1 -o "$tunnel" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -I INPUT 1 -i "$tunnel" -j DROP
  iptables -I INPUT 1 -i "$outbound" -p udp --dport "$port" -j ACCEPT
  iptables -t nat -A POSTROUTING -s 10.77.0.2/32 -o "$outbound" -j MASQUERADE
else
  iptables -D FORWARD -i "$tunnel" -j PZ-WORKSHOP-VPN || true
  iptables -D FORWARD -o "$tunnel" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT || true
  iptables -D INPUT -i "$tunnel" -j DROP || true
  iptables -D INPUT -i "$outbound" -p udp --dport "$port" -j ACCEPT || true
  iptables -t nat -D POSTROUTING -s 10.77.0.2/32 -o "$outbound" -j MASQUERADE || true
  iptables -F PZ-WORKSHOP-VPN || true
  iptables -X PZ-WORKSHOP-VPN || true
fi
SH
chmod 700 /etc/wireguard/workshop-firewall
cat > /etc/wireguard/wg-workshop.conf <<EOF
[Interface]
Address = 10.77.0.1/24
ListenPort = $port
PrivateKey = $(cat /etc/wireguard/workshop-keys/server.key)
MTU = 1380
PostUp = /etc/wireguard/workshop-firewall up %i $outbound $port
PostDown = /etc/wireguard/workshop-firewall down %i $outbound $port

[Peer]
PublicKey = $(cat /etc/wireguard/workshop-keys/client.pub)
PresharedKey = $(cat /etc/wireguard/workshop-keys/psk)
AllowedIPs = 10.77.0.2/32
EOF
cat > /etc/wireguard/workshop-client.conf <<EOF
[Interface]
Address = 10.77.0.2/32
PrivateKey = $(cat /etc/wireguard/workshop-keys/client.key)
MTU = 1380

[Peer]
PublicKey = $(cat /etc/wireguard/workshop-keys/server.pub)
PresharedKey = $(cat /etc/wireguard/workshop-keys/psk)
Endpoint = $endpoint:$port
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
base64 -w 0 /etc/wireguard/workshop-client.conf > /etc/wireguard/workshop-client.base64
chmod 600 /etc/wireguard/wg-workshop.conf /etc/wireguard/workshop-client.conf /etc/wireguard/workshop-client.base64
systemctl enable --now wg-quick@wg-workshop
echo "WireGuard started. Forward router UDP $port to this Windows machine's reserved LAN IPv4."
echo "Store /etc/wireguard/workshop-client.base64 as WORKSHOP_WIREGUARD_CONFIG; do not commit it."
echo "Configure local pzmanager DDNS_ADDITIONAL_SUBDOMAINS=workshop-vpn (or your chosen hostname label)."
python3 - "$endpoint" "$public_ip" <<'PY'
import socket, sys
try:
    ips = {a[4][0] for a in socket.getaddrinfo(sys.argv[1], None, socket.AF_INET)}
except OSError: ips = set()
print('DNS matches home IP.' if ips == {sys.argv[2]} else 'DNS is not current yet; start local DDNS and wait for DNS propagation before publishing.')
PY
