return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    -- Keep ``` fences visible: treesitter's markdown query conceals
    -- fenced_code_block_delimiter / info_string when conceallevel >= 2,
    -- so don't bump conceallevel for rendered buffers.
    win_options = {
      conceallevel = { default = 0, rendered = 0 },
    },
    code = {
      conceal_delimiters = false,
      style = "normal",
    },
    heading = {
      -- Remove backgrounds in headings
      backgrounds = {
        "",
        "",
        "",
        "",
        "",
        "",
      },
    },
  },
}
