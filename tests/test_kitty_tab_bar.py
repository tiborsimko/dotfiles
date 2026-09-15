"""Run with kitty +runpy: use Kitty's actual screen and tab-width allocation."""

import importlib.util
import json
import sys
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from kitty.config import load_config
from kitty.fast_data_types import DECAWM, set_options, wcswidth

from kitty import tab_bar as native

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    "dotfiles_tab_bar", ROOT / "kitty/.config/kitty/tab_bar.py"
)
labels = importlib.util.module_from_spec(spec)
spec.loader.exec_module(labels)


class Tab(SimpleNamespace):
    def __iter__(self):
        return iter((self.active_window,))


class Manager(list):
    def tab_for_id(self, tab_id):
        return next((tab for tab in self if tab.id == tab_id), None)


def tab(tab_id, directory, argv, session="reana", name=""):
    return Tab(
        id=tab_id,
        name=name,
        os_window_id=1,
        created_in_session_name=session,
        active_window=SimpleNamespace(
            needs_attention=False,
            child=SimpleNamespace(
                foreground_processes=[
                    {"pid": 31, "cwd": directory, "cmdline": ["caffeinate"]},
                    {"pid": 20, "cwd": directory, "cmdline": argv},
                ]
            ),
        ),
    )


def boss_for(tabs):
    manager = Manager(tabs)
    manager.active_tab = manager[0]
    manager.active_tab_history = [item.id for item in manager]
    return SimpleNamespace(
        os_window_map={1: manager},
        tab_for_id=manager.tab_for_id,
        mappings=SimpleNamespace(current_keyboard_mode_name=""),
    )


def test_names_and_labels():
    cases = json.loads((ROOT / "tests/kitty-process-cases.json").read_text())
    for case in cases:
        assert labels.process_identity(case["argv"]) == (
            case["name"],
            case["idle"],
        ), case

    format_title = labels.format_tab_title
    assert format_title("reana", "zsh", True, ["reana"]) == "reana"
    assert format_title("journal", "nvim", False, ["journal"] * 2) == "@nvim"
    assert (
        format_title("reana-server", "nvim", False, ["reana", "reana-server"])
        == "@nvim/reana-server"
    )
    assert (
        format_title("reana-demo", "zsh", True, ["reana", "reana-demo"]) == "reana-demo"
    )
    assert (
        format_title("my-reana-server", "nvim", False, ["reana"])
        == "@nvim/my-reana-server"
    )
    siblings = ["reana-server", "server"]
    for directory in siblings:
        assert format_title(directory, "nvim", False, siblings) == f"@nvim/{directory}"
        assert format_title(directory, "zsh", True, siblings) == directory
    assert labels.directory_leaf("/") == "/"
    assert labels.shorten_title("界界界", 4) == "界…"

    # Other sessions and unassigned tabs must not change a session's labels.
    tabs = [
        tab(1, "/projects/reana-server", ["nvim"]),
        tab(2, "/projects/reana-server", ["-zsh", "--login"]),
        tab(3, "/other", ["nvim"], session="other"),
        tab(4, "/unassigned", ["nvim"], session=""),
    ]
    boss = boss_for(tabs)
    with patch.object(labels, "get_boss", return_value=boss):
        assert labels.compact_tab_title(1) == "@nvim"
        assert labels.compact_tab_title(2) == "reana-server"
        assert labels.compact_tab_title(4) == "@nvim"
        boss.os_window_map[1].append(tab(5, "/projects/reana", ["zsh"]))
        assert labels.compact_tab_title(1) == "@nvim/reana-server"
        tabs[0].name = "my explicit name"
        assert labels.compact_tab_title(1) == "my explicit name"
    with patch.object(labels, "get_boss", None):
        assert labels.draw_title({"tab_id": 1, "title": "fallback"}) == "fallback"


def render(tabs, width, active_index):
    boss = boss_for(tabs)
    manager = boss.os_window_map[1]
    previous_index = (active_index + 1) % len(tabs)
    manager.active_tab = tabs[active_index]
    manager.active_tab_history = [tabs[previous_index].id, tabs[active_index].id]
    data = [
        native.TabBarData(
            title="filename-that-does-not-belong-in-the-tab-bar.py",
            tab_id=item.id,
            os_window_id=1,
            is_active=i == active_index,
            needs_attention=i == previous_index,
            session_name="reana",
            active_session_name="reana",
            layout_name="stack" if i == 2 else "splits",
            num_window_groups=2 if i == 2 else 1,
        )
        for i, item in enumerate(tabs)
    ]
    bar = native.TabBar(1)
    bar.laid_out_once = True
    bar.screen.resize(1, width)
    bar.screen.reset_mode(DECAWM)
    bar.draw_func = labels.draw_tab
    # No OS window exists in this test. Only the edge-colour update is skipped;
    # native TabBar.update, width allocation and separator rendering all run.
    bar._update_edge_defaults = lambda _: False
    with (
        patch.object(labels, "get_boss", return_value=boss),
        patch.object(native, "get_boss", return_value=boss),
        patch.object(native, "load_custom_draw_title", return_value=""),
    ):
        bar.update(data)
    row = str(bar.screen.line(0)).rstrip()
    assert len(bar.tab_extents) == len(tabs), row
    assert wcswidth(row) <= width, row
    for i, extent in enumerate(bar.tab_extents):
        segment = row[extent.x.start : extent.x.end].rstrip()
        assert f"{i + 1}:" in segment, (i, row)
        markers = "*" if i == active_index else "-!" if i == previous_index else ""
        if i == 2:
            markers += "Z"
        assert segment.endswith(markers), (i, markers, segment)
        if i >= 2:
            assert "@nvim" in segment, (i, row)
    return row


def test_rendering():
    tabs = [
        tab(1, "/projects/reana", ["-zsh", "--login"]),
        tab(2, "/projects/reana-demo-root6-roofit", ["-zsh", "--login"]),
        tab(3, "/projects/reana-job-controller", ["nvim"]),
        tab(4, "/projects/reana-server", ["nvim"]),
    ]
    # Exercise narrow windows at every active position: Kitty preferentially
    # allocates spare width to the active tab.
    for active in range(4):
        row = render(tabs, 90, active)
    print("Four tabs:", row)
    wide_row = render(tabs, 160, 3)
    for directory in (
        "reana-demo-root6-roofit",
        "reana-job-controller",
        "reana-server",
    ):
        assert directory in wide_row, wide_row
    assert "…" not in wide_row, wide_row
    tabs.append(tab(5, "/projects/reana-workflow-controller", ["nvim"]))
    for active in range(5):
        row = render(tabs, 90, active)
    print("Five tabs:", row)


def test_session_prefix_width():
    for alerts, mode, prefix in (
        ((), "", "[reana] "),
        (("mail", "task"), "", "[reana mail! task!] "),
        ((), "resize", "[reana] RESIZE-MODE "),
        (("mail",), "resize", "[reana mail!] RESIZE-MODE "),
    ):
        tabs = [tab(1, "/projects/reana", ["nvim"], name="long title " * 10)]
        for tab_id, session in enumerate(alerts, 2):
            alert = tab(tab_id, "/other", ["zsh"], session=session)
            alert.active_window.needs_attention = True
            tabs.append(alert)
        boss = boss_for(tabs)
        boss.mappings.current_keyboard_mode_name = mode
        bar = native.TabBar(1)
        bar.screen.resize(1, 93)
        bar.screen.reset_mode(DECAWM)
        data = native.TabBarData(
            title="fallback",
            tab_id=1,
            os_window_id=1,
            is_active=True,
            active_session_name="reana",
        )
        with (
            patch.object(labels, "get_boss", return_value=boss),
            patch.object(native, "get_boss", return_value=boss),
            patch.object(native, "load_custom_draw_title", return_value=""),
            patch.object(
                labels, "draw_tab_with_separator", wraps=native.draw_tab_with_separator
            ) as renderer,
        ):
            end = labels.draw_tab(
                bar.draw_data, bar.screen, data, 0, 80, 1, True, native.ExtraData()
            )
        assert renderer.call_count == 1
        # The starting cursor is measured after drawing the prefix; the width
        # passed to Kitty was predicted before drawing. Compare the production
        # values directly, without duplicating the prefix-width formula here.
        actual_prefix_width, remaining_width = renderer.call_args.args[3:5]
        assert actual_prefix_width + remaining_width == 80, (alerts, mode)
        row = str(bar.screen.line(0)).rstrip()
        assert row.startswith(prefix), row
        assert end == 80 and row.endswith("…*"), row


def test_renderer_fallback():
    boss = boss_for([tab(1, "/projects/reana", ["nvim"], name="long title " * 10)])
    # Fail both early and late in preparation, including the shortening path.
    # Each case must leave an intact standard title with no partial prefix.
    for owner, attribute in (
        (labels, "get_boss"),
        (labels, "wcswidth"),
        (labels, "truncate_point_for_length"),
        (native.TabBarData, "_replace"),
        (native.DrawData, "_replace"),
    ):
        bar = native.TabBar(1)
        bar.screen.resize(1, 40)
        data = native.TabBarData(
            title="fallback", tab_id=1, os_window_id=1, active_session_name="reana"
        )
        with (
            patch.object(labels, "get_boss", return_value=boss),
            patch.object(native, "get_boss", return_value=boss),
            patch.object(native, "load_custom_draw_title", return_value=""),
            patch.object(
                owner, attribute, side_effect=AttributeError("simulated API change")
            ) as broken,
        ):
            labels.draw_tab(
                bar.draw_data, bar.screen, data, 0, 40, 1, True, native.ExtraData()
            )
        assert broken.called, attribute
        assert str(bar.screen.line(0)).rstrip() == "1:fallback", attribute


if __name__ == "__main__" and not __debug__:
    # Kitty's bundled Python disables assertions; run this test with them enabled.
    code = compile(Path(__file__).read_text(), __file__, "exec", optimize=0)
    exec(code)  # noqa: S102
elif __name__ == "__main__":
    set_options(load_config(str(ROOT / "kitty/.config/kitty/kitty.conf")))
    # The helper deliberately precedes the leader in every foreground group.
    with patch.object(labels.os, "getpgid", side_effect=lambda pid: 20):
        test_names_and_labels()
        test_rendering()
        test_session_prefix_width()
        test_renderer_fallback()
    print("Kitty tab labels and rendering: OK")
