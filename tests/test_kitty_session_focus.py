"""Run with kitty +runpy: check session lookup while a tab is closing."""

import runpy
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from kitty.boss import Boss
from kitty.config import load_config

KITTY_DIR = Path(__file__).resolve().parents[1] / "kitty/.config/kitty"
workaround = runpy.run_path(str(KITTY_DIR / "session-focus.py"))


class EmptyTab(SimpleNamespace):
    def __len__(self):
        return 0


class SessionFocusTest(unittest.TestCase):
    def test_config_loads_watcher(self):
        self.assertIn(
            "session-focus.py", load_config(str(KITTY_DIR / "kitty.conf")).watcher
        )

    def test_session_lookup(self):
        empty = EmptyTab(active_window=None, created_in_session_name="tab-session")
        window = SimpleNamespace(created_in_session_name="window-session")
        occupied = SimpleNamespace(
            active_window=window, created_in_session_name="tab-session"
        )
        original = Boss.active_session
        with patch.object(Boss, "active_session", original):
            workaround["on_load"](None, {})
            lookup = Boss.active_session.fget
            self.assertEqual(
                lookup(SimpleNamespace(active_tab=empty)), empty.created_in_session_name
            )
            for tab in (None, occupied):
                boss = SimpleNamespace(active_tab=tab)
                self.assertEqual(lookup(boss), original.fget(boss))
            window.created_in_session_name = ""
            self.assertEqual(
                lookup(SimpleNamespace(active_tab=occupied)), "tab-session"
            )
            empty.created_in_session_name = ""
            self.assertEqual(lookup(SimpleNamespace(active_tab=empty)), "")


if __name__ == "__main__":
    # unittest assertions also run under Kitty's optimized Python.
    unittest.main(argv=[__file__])
