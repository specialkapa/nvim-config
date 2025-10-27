return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'theHamsta/nvim-dap-virtual-text',
    'LiadOz/nvim-dap-repl-highlights',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
    'mfussenegger/nvim-dap-python',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_setup = true,
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        -- 'delve',
        'python',
        'debugpy',
      },
    }
    require('nvim-dap-virtual-text').setup {
      commented = true,
    }
    require('nvim-dap-repl-highlights').setup()

    vim.fn.sign_define('DapBreakpoint', {
      text = '',
      texthl = 'DiagnosticSignError',
      linehl = '',
      numhl = '',
    })

    vim.fn.sign_define('DapBreakpointCondition', {
      text = '',
      texthl = 'DapBreakpointCondition',
      linehl = '',
      numhl = '',
    })

    vim.fn.sign_define('DapBreakpointRejected', {
      text = '',
      texthl = 'DiagnosticSignError',
      linehl = '',
      numhl = '',
    })

    vim.fn.sign_define('DapStopped', {
      text = '', -- or "→"
      texthl = 'DiagnosticSignWarn',
      linehl = 'Visual',
      numhl = 'DiagnosticSignWarn',
    })

    dap.configurations = {
      python = {
        {
          -- The first three options are required by nvim-dap
          type = 'python', -- the type here established the link to the adapter definition: `dap.adapters.python`
          request = 'launch',
          name = 'Launch file',

          -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

          program = '${file}', -- This configuration will launch the current file if used.
          pythonPath = function()
            -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
            -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
            -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
            local cwd = vim.fn.getcwd()
            if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
              return cwd .. '/venv/bin/python'
            elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
              return cwd .. '/.venv/bin/python'
            else
              return '/usr/bin/python'
            end
          end,
        },
      },
    }

    local function ensure_dap_repl_visible()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.bo[buf].filetype
        if ft == 'dapui_repl' or ft == 'dap-repl' then
          return
        end
      end

      local ok, dapui_module = pcall(require, 'dapui')
      if ok then
        dapui_module.open { reset = false }
      else
        dap.repl.open()
      end
    end

    -- Basic debugging keymaps, feel free to change to your liking!
    vim.keymap.set('n', '<leader>rb', dap.clear_breakpoints, { desc = '[R]emove all [B]reakpoints' })
    vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<C-F5>', dap.run_last, { desc = 'Debug: Restart' })
    vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F10>', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Toggle [B]reakpoint' })

    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Breakpoint' })

    vim.keymap.set('n', '<space>?', function()
      require('dapui').eval(nil, { enter = true })
    end, { desc = 'Debug: show value in floating box' })

    vim.keymap.set('x', '<leader>ss', function()
      local lines = vim.fn.getregion(vim.fn.getpos '.', vim.fn.getpos 'v')
      ensure_dap_repl_visible()
      dap.repl.execute(table.concat(lines, '\n'))
    end, { desc = 'Debug: [S]end [S]election to REPL' })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '󰏤',
          play = '▶',
          step_into = '',
          step_over = '',
          step_out = '',
          step_back = '',
          run_last = '',
          terminate = '',
          disconnect = '⏏',
        },
      },
      layouts = {
        {
          elements = {
            { id = 'scopes', size = 0.25 },
            'breakpoints',
            'stacks',
            'watches',
          },
          size = 40,
          position = 'left',
        },
        {
          elements = {
            { id = 'repl', size = 0.5 },
          },
          size = 40,
          position = 'right',
        },
      },
    }

    -- Remove line numbers from DAP UI windows. Some panes re-enable them, so guard on multiple events.
    local function strip_dapui_numbers(win)
      pcall(vim.api.nvim_win_set_option, win, 'statuscolumn', '')
      pcall(vim.api.nvim_win_set_option, win, 'number', false)
      pcall(vim.api.nvim_win_set_option, win, 'relativenumber', false)
    end
    local dapui_filetypes = {
      dapui_scopes = true,
      dapui_breakpoints = true,
      dapui_stacks = true,
      dapui_watches = true,
      dapui_console = true,
      dapui_repl = true,
      ['dap-repl'] = true,
      dapui_hover = true,
    }

    vim.api.nvim_create_autocmd({ 'FileType', 'BufWinEnter', 'WinEnter', 'TermEnter' }, {
      callback = function(args)
        local ft = vim.bo[args.buf].filetype
        if not dapui_filetypes[ft] then
          return
        end
        strip_dapui_numbers(args.win or vim.api.nvim_get_current_win())
      end,
    })

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Install golang specific config
    -- require('dap-go').setup()
    require('dap-python').setup 'uv'
    require('dap-python').test_runner = 'pytest'
  end,
}
