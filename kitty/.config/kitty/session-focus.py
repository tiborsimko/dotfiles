"""Work around Kitty losing the active session while its tab is closing."""

from kitty.boss import Boss


def active_session(self):
    tab = self.active_tab
    if tab is None:
        return ""
    window = tab.active_window
    if window is not None:
        return window.created_in_session_name or tab.created_in_session_name
    return tab.created_in_session_name


def on_load(boss, data):
    Boss.active_session = property(active_session)
