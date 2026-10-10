"""Configure a fail-closed WireGuard namespace, verify home egress, then drop root."""
import base64
import configparser
import ipaddress
import json
import os
from pathlib import Path
import re
import socket
import subprocess
import sys
import time
import urllib.request


def key(value):
    if len(base64.b64decode(value, validate=True)) != 32:
        raise ValueError("Invalid WireGuard key")
    return value


def configuration(encoded):
    text = base64.b64decode(encoded.strip(), validate=True).decode("utf-8")
    if len(text) > 8192:
        raise ValueError("Oversized VPN config")
    parser = configparser.ConfigParser(interpolation=None, strict=True)
    parser.optionxform = str
    parser.read_string(text)
    if parser.defaults() or parser.sections() != ["Interface", "Peer"]:
        raise ValueError("Exactly one interface and peer required")
    interface, peer = parser["Interface"], parser["Peer"]
    if set(interface) - {"PrivateKey", "Address", "MTU"} or set(peer) - {
            "PublicKey", "PresharedKey", "Endpoint", "AllowedIPs", "PersistentKeepalive"}:
        raise ValueError("Unsupported fields; hooks and DNS overrides are forbidden")
    key(interface["PrivateKey"])
    key(peer["PublicKey"])
    if "PresharedKey" in peer:
        key(peer["PresharedKey"])
    address = ipaddress.ip_interface(interface["Address"])
    if address.version != 4 or address.network.prefixlen != 32:
        raise ValueError("Client requires one IPv4 /32 address")
    if peer["AllowedIPs"].strip() != "0.0.0.0/0":
        raise ValueError("Full IPv4 tunnel required")
    endpoint = peer["Endpoint"].strip()
    match = re.fullmatch(r"([A-Za-z0-9.-]+):([0-9]{1,5})", endpoint)
    if not match or not 1 <= int(match[2]) <= 65535:
        raise ValueError("Endpoint requires hostname:UDP-port")
    addresses = {entry[4][0] for entry in socket.getaddrinfo(match[1], int(match[2]), socket.AF_INET, socket.SOCK_DGRAM)}
    if len(addresses) != 1:
        raise ValueError("Endpoint must resolve to exactly one IPv4 address")
    public_ip = addresses.pop()
    if not ipaddress.ip_address(public_ip).is_global:
        raise ValueError("Endpoint requires a routable public IPv4")
    mtu = int(interface.get("MTU", "1380"))
    keepalive = int(peer.get("PersistentKeepalive", "25"))
    if not 1280 <= mtu <= 1420 or not 0 <= keepalive <= 65535:
        raise ValueError("Invalid MTU or keepalive")
    # No secret config is passed to a shell or wg-quick hooks.
    lines = ["[Interface]", "PrivateKey = " + interface["PrivateKey"], "[Peer]",
             "PublicKey = " + peer["PublicKey"], "Endpoint = " + public_ip + ":" + match[2],
             "AllowedIPs = 0.0.0.0/0", "PersistentKeepalive = " + str(keepalive)]
    if "PresharedKey" in peer:
        lines.append("PresharedKey = " + peer["PresharedKey"])
    return str(address), mtu, public_ip, match[2], "\n".join(lines) + "\n"


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True, timeout=20).stdout


def setup(encoded):
    print("VPN: validating client configuration and resolving the home endpoint.", flush=True)
    address, mtu, endpoint, port, contents = configuration(encoded)
    defaults = json.loads(run("ip", "-j", "route", "show", "default"))
    if len(defaults) != 1 or "gateway" not in defaults[0]:
        raise ValueError("One bridged default gateway required")
    gateway, device = defaults[0]["gateway"], defaults[0]["dev"]
    print("VPN: applying outbound firewall and WireGuard routes.", flush=True)
    # Drop traffic before changing routes. Only encrypted UDP may use the bridge.
    run("iptables", "-P", "OUTPUT", "DROP")
    run("ip6tables", "-P", "OUTPUT", "DROP")
    run("iptables", "-A", "OUTPUT", "-o", "lo", "-j", "ACCEPT")
    run("iptables", "-A", "OUTPUT", "-o", "wg0", "-j", "ACCEPT")
    run("iptables", "-A", "OUTPUT", "-o", device, "-d", endpoint, "-p", "udp", "--dport", port, "-j", "ACCEPT")
    run("ip", "link", "add", "wg0", "type", "wireguard")
    file = Path("/etc/wireguard/workshop.conf")
    file.parent.mkdir(parents=True, exist_ok=True)
    file.write_text(contents, encoding="utf-8")
    file.chmod(0o600)
    try:
        run("wg", "setconf", "wg0", str(file))
    finally:
        file.unlink(missing_ok=True)
    run("ip", "address", "add", address, "dev", "wg0")
    run("ip", "link", "set", "wg0", "mtu", str(mtu), "up")
    run("ip", "route", "replace", endpoint + "/32", "via", gateway, "dev", device)
    run("ip", "route", "replace", "default", "dev", "wg0")
    # Avoid Docker's host-side DNS forwarder; DNS must cross the tunnel too.
    Path("/etc/resolv.conf").write_text("nameserver 1.1.1.1\noptions timeout:2 attempts:2\n")
    # Explicitly disable proxy discovery for this in-container check, so it tests
    # this namespace's egress rather than a proxy. Runner networking is untouched.
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    print("VPN: waiting for tunnel egress to match the home public IPv4.", flush=True)
    for attempt in range(6):
        try:
            with opener.open("https://api.ipify.org", timeout=10) as response:
                observed = response.read(64).decode().strip()
            if str(ipaddress.IPv4Address(observed)) != endpoint:
                raise ValueError("VPN exit IP does not match the endpoint's public IPv4")
            print("VPN connected: public IPv4 matches the home DNS endpoint. IPv6 and direct egress are blocked.", flush=True)
            return
        except (OSError, TimeoutError):
            if attempt == 5:
                raise
            time.sleep(2)


def main():
    try:
        setup(os.environ.get("WORKSHOP_WIREGUARD_CONFIG", ""))
        os.environ.pop("WORKSHOP_WIREGUARD_CONFIG", None)
        os.execvp("gosu", ["gosu", "steam", "python3", "/opt/publish.py", *sys.argv[1:]])
    except Exception:
        print("::error::Home VPN setup or public-IP verification failed. Check DNS, UDP forwarding, WSL/firewall, "
              "WireGuard keys and NET_ADMIN. Steam login was not attempted; VPN credentials remain hidden.", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
