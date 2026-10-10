"""Offline VPN policy and pre-authentication failure regressions."""
import base64
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import MagicMock, patch

spec = importlib.util.spec_from_file_location('vpn', Path(__file__).parents[1] / 'docker/workshop/vpn.py')
vpn = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vpn)
KEY = base64.b64encode(bytes(range(32))).decode()
CONFIG = f'''[Interface]
PrivateKey = {KEY}
Address = 10.77.0.2/32
[Peer]
PublicKey = {KEY}
Endpoint = workshop-vpn.example.com:51820
AllowedIPs = 0.0.0.0/0
'''


def encoded(text=CONFIG):
    return base64.b64encode(text.encode()).decode()


class VpnTests(unittest.TestCase):
    def setUp(self):
        self.dns = patch.object(vpn.socket, 'getaddrinfo', return_value=[(2, 2, 17, '', ('8.8.8.8', 51820))])
        self.dns.start()
        self.addCleanup(self.dns.stop)

    def test_pins_hostname_to_one_public_ipv4(self):
        address, mtu, endpoint, port, config = vpn.configuration(encoded())
        self.assertEqual((address, mtu, endpoint, port), ('10.77.0.2/32', 1380, '8.8.8.8', '51820'))
        self.assertIn('Endpoint = 8.8.8.8:51820', config)
        self.assertNotIn('example.com', config)

    def test_rejects_hooks_defaults_partial_tunnels_and_invalid_keys(self):
        for text in [CONFIG.replace('Address =', 'PostUp = echo unsafe\nAddress ='),
                     '[DEFAULT]\nMTU = 1380\n' + CONFIG,
                     CONFIG.replace('0.0.0.0/0', '10.0.0.0/8'),
                     CONFIG.replace(KEY, 'bad'), CONFIG.replace('/32', '/24')]:
            with self.subTest(text=text), self.assertRaises((ValueError, KeyError)):
                vpn.configuration(encoded(text))

    def test_rejects_private_and_ambiguous_endpoints(self):
        for ips in [('192.168.0.1',), ('8.8.8.8', '1.1.1.1')]:
            with patch.object(vpn.socket, 'getaddrinfo', return_value=[(2, 2, 17, '', (ip, 51820)) for ip in ips]):
                with self.assertRaises(ValueError):
                    vpn.configuration(encoded())

    def exercise_setup(self, observed):
        commands = []
        def command(*args):
            commands.append(args)
            return '[{"gateway":"172.17.0.1","dev":"eth0"}]' if args[:3] == ('ip', '-j', 'route') else ''
        with tempfile.TemporaryDirectory() as directory:
            paths = lambda name: Path(directory) / Path(name).name
            opener = MagicMock()
            opener.open.return_value.__enter__.return_value.read.return_value = observed.encode()
            with patch.object(vpn, 'run', side_effect=command), patch.object(vpn, 'Path', side_effect=paths), patch.object(vpn.urllib.request, 'build_opener', return_value=opener):
                if observed != '8.8.8.8':
                    with self.assertRaises(ValueError):
                        vpn.setup(encoded())
                else:
                    vpn.setup(encoded())
                self.assertFalse((Path(directory) / 'workshop.conf').exists())
                self.assertIn('nameserver 1.1.1.1', (Path(directory) / 'resolv.conf').read_text())
        return commands

    def test_blocks_direct_egress_before_tunnel_and_pins_endpoint_route(self):
        commands = self.exercise_setup('8.8.8.8')
        self.assertLess(commands.index(('iptables', '-P', 'OUTPUT', 'DROP')), commands.index(('ip', 'link', 'add', 'wg0', 'type', 'wireguard')))
        self.assertIn(('ip6tables', '-P', 'OUTPUT', 'DROP'), commands)
        self.assertIn(('ip', 'route', 'replace', '8.8.8.8/32', 'via', '172.17.0.1', 'dev', 'eth0'), commands)
        bridge_rules = [c for c in commands if c[:6] == ('iptables', '-A', 'OUTPUT', '-o', 'eth0', '-d')]
        self.assertEqual(bridge_rules, [('iptables', '-A', 'OUTPUT', '-o', 'eth0', '-d', '8.8.8.8', '-p', 'udp', '--dport', '51820', '-j', 'ACCEPT')])

    def test_exit_ip_mismatch_fails_closed(self):
        self.exercise_setup('1.1.1.1')

    def test_vpn_failure_never_starts_steam_or_prints_secret(self):
        with patch.object(vpn, 'setup', side_effect=ValueError(KEY)), patch.object(vpn.os, 'execvp') as start, patch('sys.stderr') as stderr:
            self.assertEqual(vpn.main(), 1)
            start.assert_not_called()
            self.assertNotIn(KEY, ''.join(str(c) for c in stderr.write.call_args_list))


if __name__ == '__main__':
    unittest.main()
