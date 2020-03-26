# Tibor's qutebrowser configuration.

# workaroung for Intel GPU troubles
c.qt.force_software_rendering = 'software-opengl'

# start when we left off
c.auto_save.session = True

# unbind some shortcuts
config.bind('<ctrl+n>', 'tab-next')
config.bind('<ctrl+p>', 'tab-prev')

# show tabs only when I ask
c.tabs.show = 'never'
config.bind(',t', 'config-cycle tabs.show never always')

# show tabs on top
c.tabs.position = 'bottom'

# tmux-like gruvbox-like colours
c.colors.statusbar.insert.bg = "#3a3a3a"
c.colors.statusbar.insert.fg = "#a8a8a8"
c.colors.statusbar.normal.bg = "#3a3a3a"
c.colors.statusbar.normal.fg = "#a8a8a8"
c.colors.tabs.even.bg = "#3a3a3a"
c.colors.tabs.even.fg = "#a8a8a8"
c.colors.tabs.odd.bg = "#3a3a3a"
c.colors.tabs.odd.fg = "#a8a8a8"
c.colors.tabs.pinned.even.bg = "#3a3a3a"
c.colors.tabs.pinned.even.fg = "#a8a8a8"
c.colors.tabs.pinned.odd.bg = "#3a3a3a"
c.colors.tabs.pinned.odd.fg = "#a8a8a8"
c.colors.tabs.pinned.selected.even.bg = "#4e4e4e"
c.colors.tabs.pinned.selected.even.fg = "#ffaf00"
c.colors.tabs.pinned.selected.odd.bg = "#4e4e4e"
c.colors.tabs.pinned.selected.odd.fg = "#ffaf00"
c.colors.tabs.selected.even.bg = "#4e4e4e"
c.colors.tabs.selected.even.fg = "#ffaf00"
c.colors.tabs.selected.odd.bg = "#4e4e4e"
c.colors.tabs.selected.odd.fg = "#ffaf00"

# show statusbar only when I need
c.statusbar.hide = True
config.bind(',b', 'config-cycle statusbar.hide', mode='normal')

# spell check languages
c.spellcheck.languages = ['en-GB']

# numbers for hints
c.hints.chars = '1234567890'

# fonts
c.fonts.default_family = 'monospace'

# password manager
config.bind('<z><l>', 'spawn --userscript qute-pass --dmenu-invocation dmenu')
config.bind('<z><u><l>', 'spawn --userscript qute-pass --dmenu-invocation dmenu --username-only')
config.bind('<z><p><l>', 'spawn --userscript qute-pass --dmenu-invocation dmenu --password-only')

# edit text areas in vim
c.editor.command = ['st', '-e', 'vim', '{file}']

# create task for the current web page
config.bind(',T', 'spawn --userscript taskadd')

# use mpv for videos
config.bind(',m', 'spawn --userscript view_in_mpv')

# open URL in Chromium
config.bind(',c', 'spawn -d chromium {url}')

# search engines
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
