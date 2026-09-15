#!/usr/bin/env python3

"""Check Kitty configuration relationships that span multiple files."""

import re
from pathlib import Path

DOTFILES_DIR = Path(__file__).resolve().parents[1]
KITTY_DIR = DOTFILES_DIR / "kitty/.config/kitty"


def active_lines(path: Path) -> list[str]:
    return [
        line.strip()
        for line in path.read_text().splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]


def test_theme_keys() -> None:
    # Kitty loads light first, then overlays the current theme. A missing dark
    # setting would inherit its light value; neither palette's values are fixed.
    light = {
        line.split()[0] for line in active_lines(KITTY_DIR / "themes/theme-light.conf")
    }
    dark = {
        line.split()[0] for line in active_lines(KITTY_DIR / "themes/theme-dark.conf")
    }
    assert light == dark, (
        f"theme keys differ: light only={sorted(light - dark)}, "
        f"dark only={sorted(dark - light)}"
    )


def test_mail_role() -> None:
    # Task navigation and theme reloads must target the role supplied by the
    # mail session, even if the role's name changes.
    mail = KITTY_DIR / "sessions/mail.kitty-session"
    role = re.search(r"--var role=(\S+)", "\n".join(active_lines(mail)))
    assert role is not None, "mail session has no window role"
    match = f"session:^{mail.stem}$ and var:role={role[1]}"
    for consumer in (
        "taskwarrior/common/.config/task/task-jump-mail.sh",
        "theme/.local/bin/theme-toggle",
    ):
        text = "\n".join(active_lines(DOTFILES_DIR / consumer))
        assert re.search(rf"""['"]{re.escape(match)}['"]""", text), (
            f"{consumer}: selector does not match the mail session role"
        )


if __name__ == "__main__":
    test_theme_keys()
    test_mail_role()
    print("Kitty configuration consistency: OK")
