"""Render a Tmux-like tab bar with OS focus and a session name at the left edge.

Cross-session alerts and focus history require undocumented Kitty internals.
If those change after an upgrade, draw_tab falls back to the standard renderer.
"""

import os
from contextlib import suppress

from kitty.fast_data_types import (
    Screen,
    get_options,
    truncate_point_for_length,
    wcswidth,
)
from kitty.rgb import color_as_int
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
    draw_tab_with_separator,
)

try:
    from kitty.fast_data_types import current_focused_os_window_id, get_boss
except ImportError:  # Keep the standard tab bar usable after a Kitty API change.
    current_focused_os_window_id = None
    get_boss = None

# The following space lets Kitty render the larger glyph across two cells.
FOCUS_CIRCLE = "⬤ "


def foreground_process_group_leader(tab):
    """Return the active pane's foreground process-group leader, if present."""
    window = tab.active_window
    processes = window.child.foreground_processes if window is not None else ()
    for process in processes:
        pid = process["pid"]
        with suppress(OSError):
            if os.getpgid(pid) == pid:
                return process
    return processes[0] if processes else None


def process_identity(command_line) -> tuple[str, bool]:
    """Return a program name and whether argv describes a plain shell.

    Keep shell-script naming in step with session-picker.sh. Classify before
    renaming: a script named zsh is running, as is a shell executing -c.
    """
    if not command_line:
        return "", False
    command = os.path.basename(command_line[0]).lstrip("-")
    if command not in {"zsh", "bash", "sh", "dash", "fish"}:
        return command, False
    arguments = command_line[1:]
    if arguments and arguments[0] and not arguments[0].startswith("-"):
        return os.path.basename(arguments[0]), False
    return command, all(arg in {"--login", "-l", "-i"} for arg in arguments)


def directory_leaf(cwd: str) -> str:
    """Keep the root directory recognisable and missing directories empty."""
    return (os.path.basename(cwd.rstrip("/")) or "/") if cwd else ""


def format_tab_title(directory, command, idle, sibling_directories):
    """Keep activity visible, adding a directory when the session needs it."""
    if idle:
        return directory
    if not command:
        return ""
    if not directory or all(other == directory for other in sibling_directories):
        return f"@{command}"
    return f"@{command}/{directory}"


def compact_tab_title(tab_id: int) -> str:
    """Describe the active pane in the context of tabs from the same session."""
    if get_boss is None:
        raise RuntimeError("Kitty internals are unavailable")
    tab = get_boss().tab_for_id(tab_id)
    if tab is None:
        return ""
    if tab.name:
        return tab.name

    process = foreground_process_group_leader(tab)
    if process is None:
        return ""
    command, idle = process_identity(process["cmdline"] or ())
    directory = directory_leaf(process["cwd"] or "")
    session = tab.created_in_session_name
    tab_manager = get_boss().os_window_map[tab.os_window_id]
    sibling_directories = []
    for candidate in tab_manager:
        # Unassigned tabs remain visible, but form their own comparison group.
        if candidate.created_in_session_name == session:
            sibling = foreground_process_group_leader(candidate)
            sibling_directories.append(directory_leaf((sibling or {}).get("cwd") or ""))
    return format_tab_title(directory, command, idle, sibling_directories)


def draw_title(data: dict[str, object]) -> str:
    """Resolve a compact label, falling back to Kitty's title on API changes."""
    fallback = str(data["title"])
    try:
        return compact_tab_title(int(data["tab_id"])) or fallback
    except Exception:  # noqa: BLE001 - preserve the original title on API changes.
        return fallback


def shorten_title(title: str, width: int) -> str:
    """Shorten by terminal cells, preserving space for the index and markers."""
    if width <= 0:
        return ""
    if wcswidth(title) <= width:
        return title
    return title[: truncate_point_for_length(title, width - 1)] + "…"


def alerting_session_names(tab: TabBarData) -> tuple[str, ...]:
    """Return other sessions with an alert, in their tab creation order."""
    if get_boss is None:
        raise RuntimeError("Kitty internals are unavailable")
    tab_manager = get_boss().os_window_map.get(tab.os_window_id)
    if tab_manager is None:
        return ()

    session_order: list[str] = []
    alerting_sessions: set[str] = set()
    for candidate in tab_manager:
        session_name = candidate.created_in_session_name
        if session_name and session_name not in session_order:
            session_order.append(session_name)
        if session_name and any(window.needs_attention for window in candidate):
            alerting_sessions.add(session_name)

    return tuple(
        session_name
        for session_name in session_order
        if session_name != tab.active_session_name and session_name in alerting_sessions
    )


def draw_session_status(
    screen: Screen,
    active_session: str,
    alerting_sessions: tuple[str, ...],
    keyboard_mode: str,
    mode_foreground: int,
    alert_background: int,
) -> None:
    """Draw the active session, keyboard mode, and reverse-colour alerts."""
    screen.draw(f"[{active_session}")
    foreground, background = screen.cursor.fg, screen.cursor.bg
    for session_name in alerting_sessions:
        screen.draw(" ")
        screen.cursor.fg, screen.cursor.bg = background, alert_background
        try:
            screen.draw(f"{session_name}!")
        finally:
            screen.cursor.fg, screen.cursor.bg = foreground, background
    screen.draw("]")
    if keyboard_mode:
        foreground = screen.cursor.fg
        screen.cursor.fg = mode_foreground
        try:
            screen.draw(f" {keyboard_mode.upper()}-MODE")
        finally:
            screen.cursor.fg = foreground
    screen.draw(" ")


def current_keyboard_mode_name() -> str:
    """Return the active user-visible keyboard mode, if any."""
    if get_boss is None:
        raise RuntimeError("Kitty internals are unavailable")
    mode_name = get_boss().mappings.current_keyboard_mode_name or ""
    return "" if mode_name.startswith("__") else mode_name


def window_has_focus(os_window_id: int) -> bool:
    """Use actual OS focus, which can be absent while a tab remains active.

    Kitty's Boss.on_focus already marks the affected tab bar dirty, so the
    indicator updates even when nothing is happening in the terminal.
    """
    if current_focused_os_window_id is None:
        raise RuntimeError("Kitty focus state is unavailable")
    return current_focused_os_window_id() == os_window_id


def last_focused_tab_id(tab: TabBarData) -> int | None:
    """Return the previous tab in the active session, ignoring other sessions."""
    if get_boss is None:
        raise RuntimeError("Kitty internals are unavailable")
    tab_manager = get_boss().os_window_map.get(tab.os_window_id)
    if tab_manager is None or tab_manager.active_tab is None:
        return None

    active_tab = tab_manager.active_tab
    session_name = active_tab.created_in_session_name
    for tab_id in reversed(tab_manager.active_tab_history):
        candidate = tab_manager.tab_for_id(tab_id)
        if (
            candidate is not None
            and candidate is not active_tab
            and candidate.created_in_session_name == session_name
        ):
            return candidate.id
    return None


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    """Draw the session once, followed by compact Tmux-style tab labels."""
    # Gather all internal state before drawing anything. On an incompatible
    # Kitty upgrade this avoids leaving half a custom prefix on screen.
    try:
        active_session_name = tab.active_session_name
        alerting_sessions = alerting_session_names(tab) if index == 1 else ()
        keyboard_mode = current_keyboard_mode_name() if index == 1 else ""
        focused = window_has_focus(tab.os_window_id)
        options = get_options()
        # Use macOS-like colours when focused and the theme's grey otherwise.
        colors = (
            (0xFF5F57, 0xFEBC2E, 0x28C840) if focused else (int(options.color8),) * 3
        )
        focus_colors = tuple(as_rgb(color) for color in colors) if index == 1 else ()
        default_fg = draw_data.inactive_fg
        foreground, background = (
            as_rgb(draw_data.tab_fg(tab)),
            as_rgb(draw_data.tab_bg(tab)),
        )
        alert_background = foreground
        mode_foreground = as_rgb(color_as_int(options.color9))
        if not focused:
            # Only the foreground changes, during existing redraws; no timer.
            default_fg = options.color8
            foreground = as_rgb(int(default_fg))
            mode_foreground = foreground
        previous_tab_id = last_focused_tab_id(tab)
        zoom_marker = (
            "Z" if tab.layout_name == "stack" and tab.num_window_groups > 1 else ""
        )
        label = draw_title({"title": tab.title, "tab_id": tab.tab_id})
        show_session = index == 1 and bool(active_session_name)
        prefix_width = (
            wcswidth(" " + FOCUS_CIRCLE * len(focus_colors)) if focus_colors else 0
        )
        if show_session:
            prefix_width += wcswidth(f"[{active_session_name}] ")
            prefix_width += sum(wcswidth(f" {name}!") for name in alerting_sessions)
            if keyboard_mode:
                prefix_width += wcswidth(f" {keyboard_mode.upper()}-MODE")
        render_max_tab_length = max(1, max_tab_length - prefix_width)

        if tab.is_active:
            marker = "*"
        elif tab.tab_id == previous_tab_id:
            marker = "-"
        else:
            marker = ""
        alert_marker = "!" if tab.needs_attention else ""
        markers = marker + alert_marker + zoom_marker
        # Keep the index and markers when the fixed prefix consumes most of
        # the first tab's allocation. Kitty handles overflow of later tabs.
        render_max_tab_length = max(
            render_max_tab_length,
            wcswidth(f"{index}:{markers}")
            + draw_data.leading_spaces
            + draw_data.trailing_spaces,
        )
        title_width = (
            render_max_tab_length
            - draw_data.leading_spaces
            - min(render_max_tab_length - 1, draw_data.trailing_spaces)
        )
        if draw_data.max_tab_title_length > 0:
            title_width = min(title_width, draw_data.max_tab_title_length)
        label_width = max(0, title_width - wcswidth(f"{index}:{markers}"))
        # Resolve and shorten only the label; Kitty's whole-title truncation
        # would otherwise discard the trailing focus, attention and zoom markers.
        render_tab = tab._replace(title=shorten_title(label, label_width))
        title_template = f"{{index}}:{{title}}{markers}"
        render_data = draw_data._replace(
            bell_on_tab="",
            tab_activity_symbol="",
            title_template=title_template,
            active_title_template=title_template,
        )
    except Exception:  # noqa: BLE001 - fall back after any incompatible API change.
        return draw_tab_with_separator(
            draw_data,
            screen,
            tab,
            before,
            max_tab_length,
            index,
            is_last,
            extra_data,
        )

    screen.cursor.fg, screen.cursor.bg = foreground, background
    if index == 1:
        # Keep default-coloured separators consistent with the tab text.
        if screen.color_profile.default_fg != default_fg:
            screen.color_profile.default_fg = default_fg
        tab_font_style = screen.cursor.bold, screen.cursor.italic
        screen.cursor.bold = screen.cursor.italic = False
        foreground = screen.cursor.fg
        screen.draw(" ")
        for color in focus_colors:
            screen.cursor.fg = color
            screen.draw(FOCUS_CIRCLE)
        screen.cursor.fg = foreground
        if show_session:
            draw_session_status(
                screen,
                active_session_name,
                alerting_sessions,
                keyboard_mode,
                mode_foreground,
                alert_background,
            )
        screen.cursor.bold, screen.cursor.italic = tab_font_style
        before = screen.cursor.x
    foreground, background = screen.cursor.fg, screen.cursor.bg
    if tab.needs_attention:
        screen.cursor.fg, screen.cursor.bg = background, alert_background
    try:
        return draw_tab_with_separator(
            render_data,
            screen,
            render_tab,
            before,
            render_max_tab_length,
            index,
            is_last,
            extra_data,
        )
    finally:
        screen.cursor.fg, screen.cursor.bg = foreground, background
