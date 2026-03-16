return    {{
    'nvim-telescope/telescope.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
    end
  },
  {
'nvim-telescope/telescope-ui-select.nvim',
config = function ()
  -- This is your opts table
  require("telescope").setup {
    defaults = {
      -- but usually handles directories correctly if trailing slash isn't forced
      file_ignore_patterns = { "%.metadata", ".cs.metadata" },
    },
    extensions = {
      ["ui-select"] = {
        require("telescope.themes").get_dropdown {
          -- even more opts
        }

      }
    }
  }
  -- To get ui-select loaded and working with telescope, you need to call
  -- load_extension, somewhere after setup function:
  require("telescope").load_extension("ui-select")

end }
}
