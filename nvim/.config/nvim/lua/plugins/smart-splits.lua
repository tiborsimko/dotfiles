return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  opts = {
    at_edge = "wrap",
    disable_multiplexer_nav_when_zoomed = false,
    ignored_buftypes = { "nofile" },
    ignored_filetypes = {
      "nofile",
      "quickfix",
      "qf",
      "prompt",
    },
  },
  keys = {
    {
      "<C-h>",
      function()
        require("smart-splits").move_cursor_left()
      end,
      desc = "Move to window left",
      mode = { "n", "i", "t", "v" },
    },
    {
      "<C-j>",
      function()
        require("smart-splits").move_cursor_down()
      end,
      desc = "Move to window down",
      mode = { "n", "i", "t", "v" },
    },
    {
      "<C-k>",
      function()
        require("smart-splits").move_cursor_up()
      end,
      desc = "Move to window up",
      mode = { "n", "i", "t", "v" },
    },
    {
      "<C-l>",
      function()
        require("smart-splits").move_cursor_right()
      end,
      desc = "Move to window right",
      mode = { "n", "i", "t", "v" },
    },
    {
      "<C-\\>",
      "<C-w>p",
      desc = "Move to previous window",
      mode = { "n", "v" },
    },
  },
}
