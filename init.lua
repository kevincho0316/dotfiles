vim.env.DOTNET_CLI_UI_LANGUAGE = "en-US"
vim.env.VSLANG = "1033"
vim.env.LANG = "en_US.UTF-8"
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("vim-options")
require("lazy").setup("plugins")
require("nvim-web-devicons").set_icon({
  fs = {
    icon = "",
    color = "#5586A0",
    cterm_color = "67",
    name = "Glsl",
  },
  vs = {
    icon = "",
    color = "#5586A0",
    cterm_color = "67",
    name = "Glsl",
  },
})
vim.filetype.add({
  extension = {
    vs = "glsl",
    fs = "glsl",
    vert = "glsl",
    frag = "glsl",
  },
})
-- 4. 기타 단축키
vim.keymap.set('n', '<C-b>', ':Neotree reveal left<CR>')


