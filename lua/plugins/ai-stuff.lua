return {
  {
    'rhart92/codex.nvim', -- depends on codex CLI. Make sure it is installed
    config = function()
      require('codex').setup {
        split = 'vertical',
        size = 0.3,
        float = {
          width = 1,
          height = 0.6,
          border = 'rounded',
          row = nil,
          col = nil,
          title = 'codex',
        },
        codex_cmd = { 'codex' },
        focus_after_send = true,
        log_level = 'debug',
        autostart = false,
      }

      vim.keymap.set('v', '<leader>cs', function()
        require('codex').actions.send_selection()
      end, { desc = 'Codex: Send selection' })

      vim.keymap.set('n', '<leader>cc', function()
        require('codex').toggle()
      end, { desc = 'Codex: Toggle' })
    end,
  },
  {
    'github/copilot.vim', -- depends on node.js. Make sure it is installed
  },
}
