return{
  'numToStr/Comment.nvim',
  config = function()
    require('Comment').setup()

    local api = require('Comment.api')

    -- Normal 모드: 현재 줄 주석 토글
    vim.keymap.set('n', '<C-_>', api.toggle.linewise.current)

    -- Visual 모드: 선택한 줄들 주석 토글
    vim.keymap.set('v', '<C-_>', function()
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'nx', false
      )
      api.toggle.linewise(vim.fn.visualmode())
    end)
  end
}
