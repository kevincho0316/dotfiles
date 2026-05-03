vim.filetype.add({
  extension = { ino = "arduino" },
})

return {
  "stevearc/vim-arduino",
  ft = { "arduino" },
  config = function()
    vim.g.arduino_dir = "/usr/share/arduino"
    vim.g.arduino_home_dir = vim.fn.expand("~/.arduino15")
    vim.g.arduino_args = "--verbose-upload"
    vim.g.arduino_board = "arduino:avr:leonardo"

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "arduino",
      callback = function()
        local map = function(key, cmd)
          vim.keymap.set("n", key, cmd, { buffer = true, silent = true })
        end
        map("<leader>ab", "<cmd>ArduinoChooseBoard<CR>")
        map("<leader>ap", "<cmd>ArduinoChoosePort<CR>")
        map("<leader>am", "<cmd>ArduinoVerify<CR>")
        map("<leader>au", "<cmd>ArduinoUpload<CR>")
        map("<leader>as", "<cmd>ArduinoSerial<CR>")
      end,
    })
  end,
}
