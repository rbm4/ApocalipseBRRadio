import importlib.util
import io
import json
from pathlib import Path
import unittest
from unittest.mock import patch, MagicMock
from contextlib import redirect_stdout

spec = importlib.util.spec_from_file_location(
    "request_restart", Path(__file__).resolve().parents[1] / "scripts/workshop/request_restart.py")
restart = importlib.util.module_from_spec(spec)
spec.loader.exec_module(restart)


class RestartIntegrationTests(unittest.TestCase):
    def test_accepts_started_and_duplicate_responses(self):
        for code, status in [(202, "accepted"), (200, "already_in_progress")]:
            opener = MagicMock()
            response = opener.open.return_value.__enter__.return_value
            response.status = code
            response.read.return_value = json.dumps({"status": status}).encode()
            with patch.object(restart.urllib.request, "build_opener", return_value=opener):
                restart.request_restart("https://example.test/api/server/mod-update/restart", "test-token")
            request = opener.open.call_args.args[0]
            self.assertEqual(request.get_method(), "POST")
            self.assertEqual(json.loads(request.data)["message"], "Restart para update de mods")
            self.assertEqual(request.get_header("X-api-key"), "test-token")

    def test_configuration_requires_https_token_and_exact_endpoint(self):
        for url, token in [("http://example.test/api/server/mod-update/restart", "token"),
                           ("https://example.test/api/server/restart", "token"),
                           ("https://example.test/api/server/mod-update/restart", "")]:
            with patch.dict(restart.os.environ, {"PZMANAGER_RESTART_URL": url,
                                                "PZMANAGER_MOD_UPDATE_TOKEN": token}):
                with self.assertRaises(ValueError):
                    restart.configuration()

    def test_failures_hide_credentials_and_validate_only_never_calls_api(self):
        env = {"PZMANAGER_RESTART_URL": "https://example.test/api/server/mod-update/restart",
               "PZMANAGER_MOD_UPDATE_TOKEN": "private-test-token"}
        with patch.dict(restart.os.environ, env), patch.object(restart.sys, "argv", ["script", "--validate-only"]), \
                patch.object(restart, "request_restart") as call, redirect_stdout(io.StringIO()):
            self.assertEqual(restart.main(), 0)
            call.assert_not_called()
        output = io.StringIO()
        with patch.dict(restart.os.environ, env), patch.object(restart.sys, "argv", ["script"]), \
                patch.object(restart, "request_restart", side_effect=ValueError("private-test-token")), redirect_stdout(output):
            self.assertEqual(restart.main(), 1)
        self.assertNotIn("private-test-token", output.getvalue())

    def test_redirects_are_not_followed(self):
        self.assertIsNone(restart.NoRedirect().redirect_request(None, None, 302, "", {}, "https://other.test"))
