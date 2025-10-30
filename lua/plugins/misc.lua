-- Standalone plugins with less than 10 lines of config go here
return {
  {
    -- Detect tabstop and shiftwidth automatically
    'tpope/vim-sleuth',
  },
  {
    -- Hints keybinds
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      preset = 'helix',
      win = {
        title = '   keybinds ',
        title_pos = 'center',
      },
    },
  },
  {
    -- Autoclose parentheses, brackets, quotes, etc.
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = true,
    opts = {},
  },
  {
    -- High-performance color highlighter
    'norcalli/nvim-colorizer.lua',
    event = 'InsertEnter',
    config = function()
      require('colorizer').setup()
    end,
  },
  {
    'ya2s/nvim-cursorline',
    config = function()
      require('nvim-cursorline').setup {
        cursorline = {
          enable = false,
          timeout = 1000,
          number = true,
        },
        cursorword = {
          enable = true,
          min_length = 3,
          hl = { underline = true },
        },
      }
    end,
  },
  {
    'folke/persistence.nvim',
    event = 'BufReadPre', -- this will only start session saving when an actual file was opened
    opts = {
      -- add any custom options here
    },
  },
  {
    'wthollingsworth/pomodoro.nvim',
    dependencies = { 'MunifTanjim/nui.nvim' },
    config = function()
      require('pomodoro').setup {
        time_work = 20,
        time_break_short = 5,
        time_break_long = 10,
        timers_break_long = 3,
      }
    end,
  },
}
