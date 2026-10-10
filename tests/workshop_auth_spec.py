"""Offline login/fallback tests; never authenticate a real Steam account."""
import base64
import contextlib
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "steam_auth_publisher", Path(__file__).resolve().parents[1] / "docker/workshop/publish.py")
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


def result(code=0, output="Logon state: Logged On"):
    return subprocess.CompletedProcess([], code, output)


class SteamAuthenticationTests(unittest.TestCase):
    def test_cached_login_does_not_resend_password(self):
        with patch.object(publisher, "login_attempt", return_value=result()) as login, contextlib.redirect_stdout(io.StringIO()):
            self.assertTrue(publisher.authenticate("steamcmd", "account", "private-password"))
        login.assert_called_once_with("steamcmd", "account")

    def test_failed_cache_uses_password_and_prompts_for_mobile_approval(self):
        output = io.StringIO()
        with patch.object(publisher, "login_attempt", side_effect=[result(5, "Cached credentials not found."), result()]) as login, \
                contextlib.redirect_stdout(output):
            self.assertTrue(publisher.authenticate("steamcmd", "account", "private-password"))
        self.assertEqual(2, login.call_count)
        self.assertEqual(("steamcmd", "account", "private-password"), login.call_args.args)
        self.assertIn("Steam mobile app", output.getvalue())
        self.assertNotIn("private-password", output.getvalue())

    def test_exit_zero_without_confirmed_login_cannot_authenticate(self):
        with patch.object(publisher, "login_attempt", return_value=result(0, "Logon state: Logged Off")), \
                contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertFalse(publisher.authenticate("steamcmd", "account", "password"))

    def test_missing_password_and_approval_timeout_fail_cleanly(self):
        with patch.object(publisher, "login_attempt", return_value=result(5, "no cache")) as login, \
                contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertFalse(publisher.authenticate("steamcmd", "account", ""))
            self.assertEqual(1, login.call_count)
        with patch.object(publisher, "login_attempt", side_effect=[result(5, "no cache"), subprocess.TimeoutExpired("steamcmd", 300)]), \
                contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertFalse(publisher.authenticate("steamcmd", "account", "password"))

    def test_password_is_in_private_script_not_process_arguments(self):
        files = []

        def run(args, **kwargs):
            self.assertNotIn("private-password", str(args))
            file = Path(args[-1])
            files.append(file)
            self.assertEqual(0o600, file.stat().st_mode & 0o777)
            self.assertIn('login "account" "private-password"', file.read_text())
            self.assertIn("info\nquit", file.read_text())
            self.assertEqual(300, kwargs["timeout"])
            self.assertEqual(subprocess.DEVNULL, kwargs["stdin"])
            return result()

        with patch.object(publisher.subprocess, "run", side_effect=run):
            self.assertTrue(publisher.logged_on(publisher.login_attempt("steamcmd", "account", "private-password")))
        self.assertTrue(all(not file.exists() for file in files))

    def test_failed_authentication_cannot_publish_or_leave_refresh_marker(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            runtime = home / "steamcmd"
            runtime.mkdir()
            marker = runtime / "authenticated"
            marker.write_text("stale")
            env = {"STEAM_USERNAME": "account", "STEAM_PASSWORD": "password",
                   "STEAM_CONFIG_VDF": base64.b64encode(b"fixture").decode()}
            previous = Path.cwd()
            try:
                with patch.object(publisher.Path, "home", return_value=home), patch.dict(os.environ, env), \
                        patch.object(publisher.sys, "argv", ["publisher"]), \
                        patch.object(publisher, "authenticate", return_value=False), patch.object(publisher, "publish") as publish:
                    self.assertEqual(1, publisher.main())
                    publish.assert_not_called()
                    self.assertFalse(marker.exists())
            finally:
                os.chdir(previous)
