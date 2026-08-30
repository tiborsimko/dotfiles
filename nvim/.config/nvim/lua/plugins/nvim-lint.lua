return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      dockerfile = { "hadolint" },
      go = { "golangcilint" },
      markdown = { "markdownlint-cli2" },
      sh = { "shellcheck" },
      yaml = { "yamllint" },
    },
  },
}
