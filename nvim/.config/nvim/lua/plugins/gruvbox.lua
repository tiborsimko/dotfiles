local function current_background()
  local file = io.open(vim.fn.expand("~/.config/theme-toggle/current"), "r")
  if not file then
    return "light"
  end

  local background = file:read("*l")
  file:close()

  return background == "dark" and "dark" or "light"
end

return {
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      contrast = "hard",
      transparent_mode = true,
    },
    config = function(_, opts)
      vim.o.background = current_background()
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
