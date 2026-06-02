-- Move lines: disable default shortcurts
vim.keymap.del({ "n", "i", "v" }, "<A-j>")
vim.keymap.del({ "n", "i", "v" }, "<A-k>")

-- Increment/decrement: disable to avoid accidental edits from Ctrl-A muscle memory. Use `g<C-a>` / `g<C-x>` when the increment/decrement feature is actually wanted.
vim.keymap.set({ "n", "v" }, "<C-a>", "<Nop>")
vim.keymap.set({ "n", "v" }, "<C-x>", "<Nop>")

-- Notes: helper that returns the current month's journal file path
local function journal_path()
  return vim.fn.expand("~/private/journal/journal-") .. os.date("%Y-%m") .. ".md"
end

-- Journal: open current month's journal
vim.keymap.set("n", "<leader>jj", function()
  vim.cmd("e " .. journal_path())
  vim.cmd("normal! Gzz")
end, { desc = "Open current month's journal" })

-- Journal: append a new timestamped entry at the end of the current month's journal
vim.keymap.set("n", "<leader>jc", function()
  vim.cmd("e " .. journal_path())
  vim.cmd("normal! G")
  vim.api.nvim_put({ "", os.date("## %Y-%m-%d %H:%M:%S #") }, "l", true, true)
  vim.cmd("normal! zz")
  vim.cmd("startinsert!")
end, { desc = "Append new entry to current month's journal" })
