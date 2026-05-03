return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      size = 15,
      open_mapping = [[<C-\>]],
      direction = "horizontal",
      shade_terminals = true,
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      local Terminal = require("toggleterm.terminal").Terminal

      local function make_term(cmd_fn)
        return function()
          local cmd = cmd_fn()
          if not cmd then return end
          Terminal:new({ cmd = cmd, close_on_exit = false, direction = "horizontal" }):toggle()
        end
      end

      -- Build: runs cmake --build in the nearest build/ dir
      local build = make_term(function()
        local root = vim.fn.finddir("build", vim.fn.getcwd() .. ";")
        if root == "" then
          vim.notify("No build/ dir found. Run cmake first.", vim.log.levels.WARN)
          return nil
        end
        return "cmake --build " .. vim.fn.getcwd() .. "/build 2>&1"
      end)

      -- Flash via OpenOCD (STM32H7, ST-Link)
      local flash = make_term(function()
        local elf = vim.fn.glob(vim.fn.getcwd() .. "/build/**/*.elf", true, true)[1]
        if not elf then
          vim.notify("No .elf found in build/. Build first.", vim.log.levels.WARN)
          return nil
        end
        return string.format(
          "openocd -f interface/stlink.cfg -f target/stm32h7x.cfg "
          .. "-c 'program %s verify reset exit'",
          elf
        )
      end)

      -- Serial monitor via picocom
      local monitor = make_term(function()
        local port = vim.fn.glob("/dev/ttyACM*", false, true)[1]
            or vim.fn.glob("/dev/ttyUSB*", false, true)[1]
        if not port then
          vim.notify("No serial port found.", vim.log.levels.WARN)
          return nil
        end
        return "picocom " .. port .. " -b 115200"
      end)

      -- CMake configure (generates compile_commands.json for clangd)
      local cmake_configure = make_term(function()
        return "cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON "
          .. "-DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi.cmake 2>&1"
      end)

      local map = function(key, fn, desc)
        vim.keymap.set("n", key, fn, { silent = true, desc = desc })
      end

      map("<leader>eb", build,             "Embedded: build")
      map("<leader>ef", flash,             "Embedded: flash (OpenOCD)")
      map("<leader>em", monitor,           "Embedded: serial monitor")
      map("<leader>ec", cmake_configure,   "Embedded: cmake configure")
    end,
  },
}
