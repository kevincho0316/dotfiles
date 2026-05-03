return 
  {
    "nvim-treesitter/nvim-treesitter",
     build = ":TSUpdate",
     config = function () 
     local configs = require("nvim-treesitter")
     configs.setup({
     ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "javascript", "typescript", "c_sharp" },
     highlight = { enable = true },
    indent = { enable = true },
    })
  end
  }
 
