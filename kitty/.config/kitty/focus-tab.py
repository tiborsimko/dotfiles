"""Focus an adjacent visible tab without wrapping at either end."""

from kittens.tui.handler import result_handler


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    manager = boss.active_tab_manager_with_dispatch
    if manager is None:
        return
    tabs = tuple(manager.tabs_to_be_shown_in_tab_bar)
    try:
        index = tabs.index(manager.active_tab)
    except ValueError:
        return
    target = index + int(args[1])
    if 0 <= target < len(tabs):
        manager.set_active_tab(tabs[target])
