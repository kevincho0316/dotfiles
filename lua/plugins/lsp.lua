return {
  -- Mason
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    config = function()
      require("mason").setup({
        registries = {
          "github:mason-org/mason-registry",
          "github:Crashdummyy/mason-registry",
        },
      })
    end,
  },
  -- Bridge mason <-> lspconfig (v2 auto-enables every installed server)
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = true,
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "marksman", "lua_ls", "ts_ls", "pyright", "ruff", "clangd", "glsl_analyzer" },
      })
    end,
  },
  -- Formatters / linters installed through mason
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "stylua", "clang-format", "prettierd" },
    },
  },
  -- lazydev.nvim
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  -- LSP progress (clangd indexing etc.)
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {},
  },
  -- LSP config
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "folke/lazydev.nvim",
    },
    config = function()
      vim.diagnostic.config({
        severity_sort = true,
        update_in_insert = false,
        virtual_text = { spacing = 4, prefix = "●" },
        float = { border = "rounded", source = "if_many" },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "󰌵",
          },
        },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          local tb = require("telescope.builtin")
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = bufnr, silent = true, desc = desc })
          end
          map("gd",         tb.lsp_definitions,                "Go to definition")
          map("gD",         vim.lsp.buf.declaration,           "Go to declaration")
          map("gR",         tb.lsp_references,                 "References")
          map("gI",         tb.lsp_implementations,            "Implementation")
          map("gy",         tb.lsp_type_definitions,           "Type definition")
          map("K",          vim.lsp.buf.hover,                 "Hover docs")
          map("<leader>rn", vim.lsp.buf.rename,                "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action,           "Code action")
          map("<leader>ds", tb.lsp_document_symbols,           "Document symbols")
          map("<leader>ws", tb.lsp_dynamic_workspace_symbols,  "Workspace symbols")
          map("<leader>e",  vim.diagnostic.open_float,         "Line diagnostics")
          map("<leader>dl", tb.diagnostics,                    "All diagnostics")
          map("<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
          end, "Toggle inlay hints")

          if not client then return end

          if client.name == "clangd" then
            map("<leader>h", "<cmd>LspClangdSwitchSourceHeader<CR>", "Switch header/source")
          end

          -- Highlight other references of the symbol under the cursor
          if client:supports_method("textDocument/documentHighlight") then
            local group = vim.api.nvim_create_augroup("lsp_highlight_" .. bufnr, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              group = group, buffer = bufnr, callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              group = group, buffer = bufnr, callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      vim.lsp.config("clangd", {
          cmd = {
              "clangd",
              "--query-driver=/usr/bin/arm-none-eabi-*,/usr/bin/clang*",
              "--background-index",
              "--clang-tidy",
              "--header-insertion=iwyu",
          },
      })

      -- glsl_analyzer LSP doesn't emit diagnostics and only does syntax. Bridge glslangValidator
      -- (semantic checks: undefined symbols, type mismatch, stage rules) into vim.diagnostic.
      local stage_by_ext = {
        vert = "vert", vs = "vert",
        frag = "frag", fs = "frag",
        geom = "geom", comp = "comp",
        tesc = "tesc", tese = "tese",
      }
      local glsl_ns = vim.api.nvim_create_namespace("glslang_diag")
      local function glsl_diagnose(bufnr)
        if not vim.api.nvim_buf_is_valid(bufnr) then return end
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if fname == "" then return end
        local ext = vim.fn.fnamemodify(fname, ":e")
        local stage = stage_by_ext[ext]
        if not stage then return end
        local exe = vim.fn.exepath("glslangValidator")
        if exe == "" then return end
        local tmp = vim.fn.tempname() .. "." .. ext
        vim.fn.writefile(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), tmp)
        -- -I keeps #include paths relative to the real file working
        local include = "-I" .. vim.fn.fnamemodify(fname, ":p:h")
        vim.system({ exe, include, "-S", stage, tmp }, { text = true }, function(out)
          local diags = {}
          for line in ((out.stdout or "") .. (out.stderr or "")):gmatch("[^\r\n]+") do
            local sev, lnum, msg = line:match("^(ERROR):%s*%d+:(%d+):%s*(.+)$")
            if not sev then sev, lnum, msg = line:match("^(WARNING):%s*%d+:(%d+):%s*(.+)$") end
            if sev then
              table.insert(diags, {
                lnum = tonumber(lnum) - 1,
                col = 0,
                message = msg,
                severity = sev == "ERROR" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
                source = "glslangValidator",
              })
            end
          end
          vim.schedule(function()
            vim.fn.delete(tmp)
            if vim.api.nvim_buf_is_valid(bufnr) then
              vim.diagnostic.set(glsl_ns, bufnr, diags)
            end
          end)
        end)
      end

      -- Debounce so rapid edits don't spawn a validator process each time
      local glsl_timers = {}
      local function glsl_diagnose_debounced(bufnr)
        if glsl_timers[bufnr] then glsl_timers[bufnr]:stop() end
        glsl_timers[bufnr] = vim.defer_fn(function()
          glsl_timers[bufnr] = nil
          glsl_diagnose(bufnr)
        end, 300)
      end

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave", "TextChanged" }, {
        pattern = { "*.vert", "*.frag", "*.geom", "*.comp", "*.tesc", "*.tese", "*.vs", "*.fs" },
        callback = function(args) glsl_diagnose_debounced(args.buf) end,
      })
  end,
  },
  -- Formatting
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, desc = "Format buffer" },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        javascript = { "prettierd" },
        typescript = { "prettierd" },
        markdown = { "prettierd" },
      },
      format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
    },
  },
  -- Completion
  {
    "saghen/blink.cmp",
    version = "*",
    opts = {
      keymap = { preset = "super-tab" },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        menu = { border = "rounded" },
      },
      signature = { enabled = true },
      fuzzy = { implementation = "prefer_rust_with_warning" },
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
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },
    },
  },
}
