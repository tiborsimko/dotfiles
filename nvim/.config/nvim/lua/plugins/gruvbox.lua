return {
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      contrast = "hard",
      transparent_mode = true,
    },
    config = function(_, opts)
      vim.o.background = "light"
      require("gruvbox").setup(opts)
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
