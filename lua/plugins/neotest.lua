return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',

    -- adapters
    'nvim-neotest/neotest-python',
    'nvim-neotest/neotest-plenary',
    'nvim-neotest/neotest-vim-test',
  },
  config = function()
    require('neotest').setup {
      floating = {
        border = 'rounded',
      },
      icons = {
        child_indent = '│',
        child_prefix = '├',
        collapsed = '─',
        expanded = '┐',
        failed = '',
        final_child_indent = ' ',
        final_child_prefix = '└',
        non_collapsible = '─',
        notify = '',
        passed = '󰄴',
        running = '',
        -- running_animated = { '', '', '', '', '', '' },
        running_animated = { '', '', '', '', '', '', '', '', '', '', '', '', '', '' },
        skipped = '',
        test = '',
        unknown = '󰄰',
        watching = '',
      },

      adapters = {
        require 'neotest-python' {
          dap = { justMyCode = false },
        },
        args = { '--log-level', 'DEBUG', '-vvv' },
        runner = 'pytest',
        python = '.venv/bin/python',

        require 'neotest-plenary',
        require 'neotest-vim-test' {
          ignore_file_types = { 'python', 'vim', 'lua' },
        },
      },
    }
  end,
}
