-- Do not yank things to system clipboard by default (use +y instead)
-- vim.opt.clipboard = ""

-- Publish the current buffer for Kitty's Cmd-G pane picker. Keep [No Name]
-- for unnamed buffers so Kitty replaces any previous filename; the picker
-- hides that placeholder. The tab bar derives its compact label separately.
vim.opt.title = true
vim.opt.titlestring = "%t"
