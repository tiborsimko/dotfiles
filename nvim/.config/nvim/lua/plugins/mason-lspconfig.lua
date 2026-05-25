return {
  {
    "mason-org/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "bashls",
          "cucumber_language_server",
          "dockerls",
          "docker_compose_language_service",
          "golangci_lint_ls",
          "gopls",
          "helm_ls",
          "html",
          "jsonls",
          "lua_ls",
          "marksman",
          "pyright",
          "texlab",
          "yamlls",
        },
      })
    end,
  },
}
