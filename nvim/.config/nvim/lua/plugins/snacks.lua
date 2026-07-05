return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    dashboard = { enabled = false },
    animate = { enabled = false },
    scroll = { enabled = false },
    picker = {
      sources = {
        -- Each source has built-in defaults setting `hidden = false`, and
        -- they are merged after the global picker config, so hidden files
        -- must be enabled per source
        files = { hidden = true },
        grep = { hidden = true },
        grep_word = { hidden = true },
        todo_comments = { hidden = true },
      },
    },
  },
}
