import importlib.machinery
import importlib.util
import pathlib
import unittest
from unittest.mock import patch

path = pathlib.Path(__file__).resolve().parents[1] / 'lumina-shell/files/lumina-controls'
loader = importlib.machinery.SourceFileLoader('controls', str(path))
spec = importlib.util.spec_from_loader(loader.name, loader)
controls = importlib.util.module_from_spec(spec)
loader.exec_module(controls)

class ControlsTest(unittest.TestCase):
    def test_unavailable_devices_are_not_reported_as_enabled(self):
        with patch.object(controls, 'run', return_value=(1, '', 'unavailable')):
            s = controls.status()
        self.assertFalse(s['wifiAvailable'])
        self.assertFalse(s['wifiEnabled'])
        self.assertIsNone(s['brightness'])
        self.assertEqual(s['powerProfile'], '')

    def test_network_name_with_colons_and_backlight_percentage(self):
        def fake(args):
            if args == ['nmcli', 'radio', 'wifi']: return 0, 'enabled', ''
            if args[0] == 'nmcli': return 0, 'wlan0:wifi:connected:Office:5GHz\nlo:loopback:connected (externally):lo', ''
            if args[0] == 'brightnessctl': return 0, 'intel_backlight,backlight,450,45%,1000', ''
            return 0, 'balanced', ''
        with patch.object(controls, 'run', side_effect=fake): s = controls.status()
        self.assertTrue(s['wifiAvailable']); self.assertTrue(s['wifiEnabled'])
        self.assertEqual(s['connection'], 'Office:5GHz'); self.assertEqual(s['brightness'], 45)

    def test_action_allowlist_and_bounds(self):
        for args in [['wifi', 'on; reboot'], ['brightness', '0'], ['brightness', '101'], ['profile', 'arbitrary'], ['execute', 'sh'], ['wifi']]:
            with self.subTest(args=args), patch.object(controls, 'run') as run:
                with self.assertRaises(ValueError): controls.command(args)
                run.assert_not_called()

    def test_failed_action_returns_error_and_refreshed_state(self):
        with patch.object(controls, 'run', return_value=(1, '', 'Permission denied')) as run, patch.object(controls, 'status', return_value={'wifiEnabled': True}):
            result = controls.command(['wifi', 'off'])
        self.assertFalse(result['ok']); self.assertEqual(result['error'], 'Permission denied')
        self.assertTrue(result['state']['wifiEnabled'])
        run.assert_called_once_with(['nmcli', 'radio', 'wifi', 'off'])

if __name__ == '__main__': unittest.main()
