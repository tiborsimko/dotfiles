# Tibor's qutebrowser configuration.

# Start when we left off
c.auto_save.session = True

# Bind some shortcuts
config.bind('<ctrl+n>', 'tab-next')
config.bind('<ctrl+p>', 'tab-prev')
config.bind('<ctrl+s>', 'tab-focus last')

# Configure tab bar position
c.tabs.position = 'top'

# Configure tab width
c.tabs.max_width = 200

# Show/hide tabs
config.bind(',t', 'config-cycle tabs.show never always')

# Show/hide statusbar
config.bind(',s', 'config-cycle statusbar.show never always')

# Gruvbox dark colours
gruvbox_bg0_hard = "#1d2021"
gruvbox_bg0 = "#282828"
gruvbox_bg1 = "#3c3836"
gruvbox_bg2 = "#504945"
gruvbox_bg3 = "#665c54"
gruvbox_fg3 = "#bdae93"
gruvbox_fg2 = "#d5c4a1"
gruvbox_fg1 = "#ebdbb2"
gruvbox_fg0 = "#fbf1c7"
gruvbox_grey = "#928374"
gruvbox_red = "#fb4934"
gruvbox_orange = "#fe8019"
gruvbox_yellow = "#fabd2f"
gruvbox_green = "#b8bb26"
gruvbox_aqua = "#8ec07c"
gruvbox_blue = "#83a598"
gruvbox_purple = "#d3869b"
gruvbox_orange_dark = "#d65d0e"

# Qutebrowser in gentle gruvbox dark colours
c.colors.completion.category.bg = gruvbox_bg0_hard
c.colors.completion.category.border.bottom = gruvbox_bg0_hard
c.colors.completion.category.border.top = gruvbox_bg0_hard
c.colors.completion.category.fg = gruvbox_grey
c.colors.completion.even.bg = gruvbox_bg0_hard
c.colors.completion.fg = gruvbox_fg3
c.colors.completion.item.selected.bg = gruvbox_bg1
c.colors.completion.item.selected.border.bottom = gruvbox_bg1
c.colors.completion.item.selected.border.top = gruvbox_bg1
c.colors.completion.item.selected.fg = gruvbox_fg0
c.colors.completion.item.selected.match.fg = gruvbox_blue
c.colors.completion.match.fg = gruvbox_blue
c.colors.completion.odd.bg = gruvbox_bg0_hard
c.colors.completion.scrollbar.bg = gruvbox_bg0_hard
c.colors.completion.scrollbar.fg = gruvbox_grey
c.colors.downloads.bar.bg = gruvbox_bg0_hard
c.colors.downloads.error.fg = gruvbox_red
c.colors.downloads.start.bg = gruvbox_grey
c.colors.downloads.start.fg = gruvbox_bg0_hard
c.colors.downloads.stop.bg = gruvbox_green
c.colors.downloads.stop.fg = gruvbox_bg0_hard
c.colors.hints.fg = gruvbox_bg0_hard
c.colors.hints.match.fg = gruvbox_fg1
c.colors.keyhint.bg = gruvbox_bg0_hard
c.colors.keyhint.fg = gruvbox_fg1
c.colors.keyhint.suffix.fg = gruvbox_grey
c.colors.messages.error.bg = gruvbox_red
c.colors.messages.error.border = gruvbox_red
c.colors.messages.error.fg = gruvbox_bg0_hard
c.colors.messages.info.bg = gruvbox_bg0_hard
c.colors.messages.info.border = gruvbox_bg0_hard
c.colors.messages.info.fg = gruvbox_grey
c.colors.messages.warning.bg = gruvbox_orange
c.colors.messages.warning.border = gruvbox_orange
c.colors.messages.warning.fg = gruvbox_bg0_hard
c.colors.prompts.bg = gruvbox_bg0_hard
c.colors.prompts.border = gruvbox_bg0_hard
c.colors.prompts.fg = gruvbox_grey
c.colors.prompts.selected.bg = gruvbox_bg0_hard
c.colors.statusbar.caret.bg = gruvbox_fg1
c.colors.statusbar.caret.fg = gruvbox_bg0_hard
c.colors.statusbar.caret.selection.bg = gruvbox_fg1
c.colors.statusbar.caret.selection.fg = gruvbox_bg0_hard
c.colors.statusbar.command.bg = gruvbox_bg0_hard
c.colors.statusbar.command.fg = gruvbox_fg1
c.colors.statusbar.command.private.bg = gruvbox_grey
c.colors.statusbar.command.private.fg = gruvbox_bg0_hard
c.colors.statusbar.insert.bg = gruvbox_bg0_hard
c.colors.statusbar.insert.fg = gruvbox_yellow
c.colors.statusbar.normal.bg = gruvbox_bg0_hard
c.colors.statusbar.normal.fg = gruvbox_grey
c.colors.statusbar.passthrough.bg = gruvbox_blue
c.colors.statusbar.passthrough.fg = gruvbox_bg0_hard
c.colors.statusbar.private.bg = gruvbox_grey
c.colors.statusbar.private.fg = gruvbox_bg0_hard
c.colors.statusbar.progress.bg = gruvbox_green
c.colors.statusbar.url.error.fg = gruvbox_red
c.colors.statusbar.url.fg = gruvbox_grey
c.colors.statusbar.url.hover.fg = gruvbox_blue
c.colors.statusbar.url.success.http.fg = gruvbox_grey
c.colors.statusbar.url.success.https.fg = gruvbox_grey
c.colors.statusbar.url.warn.fg = gruvbox_orange
c.colors.tabs.bar.bg = gruvbox_bg0_hard
c.colors.tabs.even.bg = gruvbox_bg0_hard
c.colors.tabs.even.fg = gruvbox_grey
c.colors.tabs.indicator.error = gruvbox_red
c.colors.tabs.indicator.start = gruvbox_bg0
c.colors.tabs.indicator.stop = gruvbox_bg0
c.colors.tabs.odd.bg = gruvbox_bg0_hard
c.colors.tabs.odd.fg = gruvbox_grey
c.colors.tabs.pinned.even.bg = gruvbox_bg0_hard
c.colors.tabs.pinned.even.fg = gruvbox_grey
c.colors.tabs.pinned.odd.bg = gruvbox_bg0_hard
c.colors.tabs.pinned.odd.fg = gruvbox_grey
c.colors.tabs.pinned.selected.even.bg = gruvbox_bg0_hard
c.colors.tabs.pinned.selected.even.fg = gruvbox_fg1
c.colors.tabs.pinned.selected.odd.bg = gruvbox_bg0_hard
c.colors.tabs.pinned.selected.odd.fg = gruvbox_fg1
c.colors.tabs.selected.even.bg = gruvbox_bg0
c.colors.tabs.selected.even.fg = gruvbox_fg1
c.colors.tabs.selected.odd.bg = gruvbox_bg0
c.colors.tabs.selected.odd.fg = gruvbox_fg1

# Spell check languages
c.spellcheck.languages = ['en-GB']

# Numbers for hints
c.hints.chars = '1234567890'

# Fonts
c.fonts.default_family = 'monospace'
c.fonts.default_size = '10pt'

# Password manager
config.bind('<z><l>', 'spawn --userscript qute-pass --dmenu-invocation dmenu')
config.bind('<z><u><l>', 'spawn --userscript qute-pass --dmenu-invocation dmenu --username-only')
config.bind('<z><p><l>', 'spawn --userscript qute-pass --dmenu-invocation dmenu --password-only')

# Edit text areas in vim
c.editor.command = ['st', '-e', 'vim', '{file}']

# Create task for the current web page
config.bind(',T', 'spawn --userscript taskadd')

# Use mpv for videos
config.bind(',m', 'spawn --userscript view_in_mpv')

# Open URL in Chromium
config.bind(',c', 'spawn -d chromium {url}')

# Search engines
c.url.searchengines["a"] = "https://arxiv.org/search/?query={}&searchtype=all&source=header"
c.url.searchengines["aw"] = "https://wiki.archlinux.org/?search={}"
c.url.searchengines["az"] = "https://www.amazon.fr/s/?field-keywords={}"
c.url.searchengines["c"] = "https://cds.cern.ch/search?p={}"
c.url.searchengines["d"] = "https://duckduckgo.com/?q={}"
c.url.searchengines["g"] = "https://www.google.com/search?hl=en&q={}"
c.url.searchengines["i"] = "http://inspirehep.net/search?p={}"
c.url.searchengines["oi"] = "https://github.com/search?q=org%3Acernopendata+is%3Aopen+is%3Aissue+{}"
c.url.searchengines["oii"] = "https://github.com/search?q=org%3Acernopendata+is%3Aissue+{}"
c.url.searchengines["op"] = "https://github.com/search?q=org%3Acernopendata+is%3Aopen+is%3Apr+{}"
c.url.searchengines["opp"] = "https://github.com/search?q=org%3Acernopendata+is%3Apr+{}"
c.url.searchengines["r"] = "https://reddit.com/r/{}"
c.url.searchengines["ri"] = "https://github.com/search?q=org%3Areanahub+is%3Aopen+is%3Aissue+{}"
c.url.searchengines["rii"] = "https://github.com/search?q=org%3Areanahub+is%3Aissue+{}"
c.url.searchengines["rp"] = "https://github.com/search?q=org%3Areanahub+is%3Aopen+is%3Apr+{}"
c.url.searchengines["rpp"] = "https://github.com/search?q=org%3Areanahub+is%3Apr+{}"
c.url.searchengines["w"] = "en.wikipedia.org/?search={}"
c.url.searchengines["y"] = "https://youtube.com/results?search_query={}"
c.url.searchengines["DEFAULT"] = c.url.searchengines["g"]
