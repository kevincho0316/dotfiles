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
        ensure_installed = { "lua_ls", "ts_ls", "pyright", "clangd" ,"glsl_analyzer"},
        automatic_installation = true,
      })
    end,
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
          prefix = "●",
          severity = { min = vim.diagnostic.severity.HINT },
          format = function(diagnostic)
            local line_diags = vim.diagnostic.get(diagnostic.bufnr, { lnum = diagnostic.lnum })

            -- Guard: list may be empty if LSP hasn't responded yet (e.g. on InsertLeave)
            if not line_diags or #line_diags == 0 then
              return string.format("%s", diagnostic.message)
            end

            -- Sort so the most severe is at index 1
            table.sort(line_diags, function(a, b) return a.severity < b.severity end)

            -- Only show virtual text for the most severe diagnostic on the line
            if diagnostic.severity ~= line_diags[1].severity or diagnostic.message ~= line_diags[1].message then
              return nil
            end

            return string.format("%s", diagnostic.message)
          end,
        },
        severity_sort = true,
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
        end,
      })

      vim.o.updatetime = 500

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
          },
        },
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

      vim.lsp.config("glsl_analyzer", {
          capabilities = vim.lsp.protocol.make_client_capabilities(),
      })

      vim.lsp.enable({ "lua_ls", "ts_ls", "pyright", "clangd","glsl_analyzer" })

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
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if fname == "" then return end
        local ext = vim.fn.fnamemodify(fname, ":e")
        local stage = stage_by_ext[ext]
        if not stage then return end
        local exe = vim.fn.exepath("glslangValidator")
        if exe == "" then return end
        local tmp = vim.fn.tempname() .. "." .. ext
        vim.fn.writefile(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), tmp)
        vim.system({ exe, "-S", stage, tmp }, { text = true }, function(out)
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

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave", "TextChanged" }, {
        pattern = { "*.vert", "*.frag", "*.geom", "*.comp", "*.tesc", "*.tese", "*.vs", "*.fs" },
        callback = function(args) glsl_diagnose(args.buf) end,
      })
  end,
  },
  -- Completion
  {
    "saghen/blink.cmp",
    version = "*",
    opts = {
      keymap = { preset = "super-tab" },
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
