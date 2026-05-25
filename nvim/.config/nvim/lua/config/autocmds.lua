-- Restore cursor to beam on exit
vim.api.nvim_create_autocmd("VimLeave", {
  callback = function()
    vim.opt.guicursor = "a:ver25"
  end,
})

-- Dim inactive splits to match tmux's inactive pane background.
-- Re-applied on every colorscheme load so live theme switches (x1-theme) work.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "gruvbox",
  callback = function()
    local bg = vim.o.background == "dark" and "#26282b" or "#e8e4d8"
    vim.api.nvim_set_hl(0, "NormalNC", { bg = bg })
  end,
})

-- Show cursor line only in active window
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
  callback = function()
    local ok, cl = pcall(vim.api.nvim_win_get_var, 0, "auto-cursorline")
    if ok and cl then
      vim.wo.cursorline = true
      vim.api.nvim_win_del_var(0, "auto-cursorline")
    end
  end,
})
vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
  callback = function()
    local cl = vim.wo.cursorline
    if cl then
      vim.api.nvim_win_set_var(0, "auto-cursorline", cl)
      vim.wo.cursorline = false
    end
  end,
})

-- Enable spelling in mail messages, and wrap for RFC 3676 format=flowed
-- (neomutt sets the header; `formatoptions+=w` makes Vim end soft-wrapped
-- lines with a trailing space so phones can re-flow them to screen width)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "mail",
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.textwidth = 72
    vim.opt_local.formatoptions:append("w")
  end,
})

-- Update CERN copyright statement in source code files
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    if not vim.bo.modified then
      return
    end

    -- Search for Copyright line with CERN
    local found_line = vim.fn.search("Copyright.*[0-9]\\{4\\}\\sCERN", "nw")
    if found_line == 0 then
      return
    end

    -- Save cursor position
    local cursor_pos = vim.api.nvim_win_get_cursor(0)

    -- Get current year
    local current_year = os.date("%Y")

    -- Update copyright lines in the buffer
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local modified = false

    for i, line in ipairs(lines) do
      -- Match "Copyright ... YYYY CERN" where YYYY is not the current year
      local new_line = line:gsub("(Copyright.-)(%d%d%d%d)(%s+CERN)", function(prefix, year, suffix)
        -- Only update if the current year isn't already present
        if not line:match(current_year .. "%s+CERN") then
          return prefix .. year .. ", " .. current_year .. suffix
        end
        return nil -- no change
      end)

      if new_line ~= line then
        lines[i] = new_line
        modified = true
      end
    end

    if modified then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    end

    -- Restore cursor position
    vim.api.nvim_win_set_cursor(0, cursor_pos)
  end,
})

-- Ansible: detect *.ansible files and use yaml.jinja2 syntax
vim.filetype.add({
  extension = {
    ansible = "yaml.ansible",
  },
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "yaml.ansible",
  callback = function()
    vim.schedule(function()
      vim.treesitter.stop()
      vim.bo.syntax = "yaml.jinja2"
    end)
  end,
})

-- Support vim myfile.py:123:78 file opening syntax
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  callback = function()
    local file = vim.fn.expand("<afile>")
    local line, col = file:match(":(%d+):?(%d*)$")

    if line then
      local actual_file = file:gsub(":(%d+):?(%d*)$", "")

      if vim.fn.filereadable(actual_file) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(actual_file))
        vim.cmd("normal! " .. line .. "G")

        if col and col ~= "" then
          vim.cmd("normal! " .. col .. "|")
        end
      end
    end
  end,
})
