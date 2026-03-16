return {
  -- Mason
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        registries = {
          "github:mason-org/mason-registry",
          "github:Crashdummyy/mason-registry",
        },
      })
    end,
  },

  -- Bridge mason <-> lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "ts_ls", "pyright" },
        automatic_installation = true,
      })
    end,
  },

  -- lazydev.nvim
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  -- LSP config
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "folke/lazydev.nvim",
    },
    config = function()

      vim.diagnostic.config({
        virtual_text = {
          spacing = 4,
          prefix = '●',
          -- This filter is the "secret sauce" 
          -- It ensures only the highest severity diagnostic on the line is shown
          severity = { min = vim.diagnostic.severity.HINT },
          format = function(diagnostic)
            -- We find all diagnostics on the current line
            local line_diags = vim.diagnostic.get(diagnostic.bufnr, { lnum = diagnostic.lnum })
            -- Sort them so the most severe is at index 1
            table.sort(line_diags, function(a, b) return a.severity < b.severity end)

            -- If the current diagnostic isn't the most severe one, return nothing
            if diagnostic.code ~= line_diags[1].code or diagnostic.message ~= line_diags[1].message then
              return nil
            end

            return string.format("%s", diagnostic.message)
          end,
        },
        severity_sort = true,
        -- Keep the signs (left gutter) showing everything so you don't miss info
        signs = true,
        update_in_insert = false,
      })
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = bufnr, silent = true, desc = desc })
          end
          map("gd",         vim.lsp.buf.definition,  "Go to definition")
          map("K",          vim.lsp.buf.hover,        "Hover docs")
          map("gr",         vim.lsp.buf.references,   "References")
          map("<leader>rn", vim.lsp.buf.rename,       "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action,  "Code action")
          --map("<leader>d", vim.diagnostic.open_float)
        end,
      })

      vim.o.updatetime = 500

      -- Configure servers using the new vim.lsp.config API (Neovim 0.11+)
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
          },
        },
      })

      vim.lsp.enable({ "lua_ls", "ts_ls", "pyright" })
    end,
  },

  -- Completion
  {
    "saghen/blink.cmp",
    version = "*",
    opts = {
      -- 'super-tab' makes Tab select the next item and Enter confirm
      keymap = { preset = 'super-tab' },
      sources = {
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },
      -- This makes the completion menu look cleaner
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono'
      },
    },
  },
}
