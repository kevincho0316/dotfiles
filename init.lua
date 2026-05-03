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

vim.filetype.add({
  extension = {
    vert = 'glsl',
    frag = 'glsl',
    geom = 'glsl',
    comp = 'glsl',
  },
})

-- 4. 기타 단축키
vim.keymap.set('n', '<C-b>', ':Neotree reveal left<CR>')


