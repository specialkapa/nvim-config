---@return table
local function layout()
  ---@param sc string
  ---@param txt string
  ---@param keybind string?
  ---@param keybind_opts table?
  ---@param opts table?
  ---@return table
  local function button(sc, txt, keybind, keybind_opts, opts)
    local def_opts = {
      cursor = 3,
      align_shortcut = 'right',
      hl_shortcut = 'AlphaButtonShortcut',
      hl = 'AlphaButton',
      width = 35,
      position = 'center',
    }
    opts = opts and vim.tbl_extend('force', def_opts, opts) or def_opts
    opts.shortcut = sc
    local sc_ = sc:gsub('%s', ''):gsub('SPC', '<Leader>')
    local on_press = function()
      local key = vim.api.nvim_replace_termcodes(keybind or sc_ .. '<Ignore>', true, false, true)
      vim.api.nvim_feedkeys(key, 't', false)
    end
    if keybind then
      keybind_opts = vim.F.if_nil(keybind_opts, { noremap = true, silent = true, nowait = true })
      opts.keymap = { 'n', sc_, keybind, keybind_opts }
    end
    return { type = 'button', val = txt, on_press = on_press, opts = opts }
  end

  math.randomseed(os.time())
  local header_color = 'AlphaCol' .. math.random(11)

  local header_lines = {
    [[                                                                       ]],
    [[                                                                     ]],
    [[       ████ ██████           █████      ██                     ]],
    [[      ███████████             █████                             ]],
    [[      █████████ ███████████████████ ███   ███████████   ]],
    [[     █████████  ███    █████████████ █████ ██████████████   ]],
    [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
    [[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
    [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
    [[                                                                       ]],
  }

  -- https://github.com/goolord/alpha-nvim/issues/105
  local lazycache = setmetatable({}, {
    __newindex = function(table, index, fn)
      assert(type(fn) == 'function')
      getmetatable(table)[index] = fn
    end,
    __call = function(table, index)
      return function()
        return table[index]
      end
    end,
    __index = function(table, index)
      local fn = getmetatable(table)[index]
      if fn then
        local value = fn()
        rawset(table, index, value)
        return value
      end
    end,
  })

  ---@return table
  lazycache.info = function()
    local stats = require('lazy').stats()
    local total = stats.count or 0
    local loaded = stats.loaded or 0
    local progress = total > 0 and (loaded / total) or 0
    local bar_length = 20
    local filled = math.floor(progress * bar_length + 0.5)
    filled = math.max(0, math.min(filled, bar_length))
    local bar = string.format('%s%s', string.rep('█', filled), string.rep('░', bar_length - filled))
    local v = vim.version()
    local datetime = os.date ' %d-%m-%Y   %H:%M:%S'
    local platform = vim.fn.has 'win32' == 1 and '' or ''
    local top_line = string.format('%s Neovim %d.%d.%d  %s', platform, v.major, v.minor, v.patch, datetime)
    local progress_line = string.format('%s  %d/%d plugins loaded', bar, loaded, total)
    local progress_hl = loaded == total and 'AlphaProgressLoaded' or 'AlphaProgressPending'
    return {
      {
        type = 'text',
        val = top_line,
        opts = { hl = header_color, position = 'center' },
      },
      {
        type = 'text',
        val = progress_line,
        opts = { hl = progress_hl, position = 'center' },
      },
    }
  end

  ---@return table
  lazycache.menu = function()
    return {
      button('space s.', '   Find recent files'),
      button('space sf', '   Find file'),
      button('space sg', '   Find reference'),
      button('space e', '    Toggle file tree'),
      button('n', '    New file', '<Cmd>ene<CR>'),
      button('p', '    Plugins', '<Cmd>Lazy<CR>'),
      button('q', '    Quit', '<Cmd>qa<CR>'),
    }
  end

  ---@return table
  lazycache.mru = function()
    local result = {}
    for _, filename in ipairs(vim.v.oldfiles) do
      if vim.loop.fs_stat(filename) ~= nil then
        local icon, hl = require('nvim-web-devicons').get_icon(filename, vim.fn.fnamemodify(filename, ':e'))
        icon = icon or ''
        hl = hl or 'Normal'
        local filename_short = string.sub(vim.fn.fnamemodify(filename, ':t'), 1, 30)
        table.insert(
          result,
          button(
            tostring(#result + 1),
            string.format('%s  %s', icon, filename_short),
            string.format('<Cmd>e %s<CR>', filename),
            nil,
            { hl = { { hl, 0, 3 }, { 'Normal', 5, #filename_short + 5 } } }
          )
        )
        if #result == 9 then
          break
        end
      end
    end
    return result
  end

  ---@return table
  lazycache.fortune = function()
    return require 'alpha.fortune'()
  end

  return {
    { type = 'padding', val = 1 },
    {
      type = 'text',
      val = header_lines,
      opts = { hl = header_color, position = 'center' },
    },
    { type = 'padding', val = 1 },
    {
      type = 'group',
      val = lazycache 'info',
      opts = { spacing = 1 },
    },
    { type = 'padding', val = 2 },
    {
      type = 'group',
      val = lazycache 'menu',
      opts = { spacing = 0 },
    },
    { type = 'padding', val = 1 },
    {
      type = 'group',
      val = lazycache 'mru',
      opts = { spacing = 0 },
    },
    { type = 'padding', val = 1 },
    {
      type = 'text',
      val = lazycache 'fortune',
      opts = { hl = 'AlphaQuote', position = 'center' },
    },
  }
end

return {
  'goolord/alpha-nvim',
  event = 'VimEnter',
  config = function()
    vim.api.nvim_set_hl(0, 'AlphaProgressLoaded', { fg = '#98c379' })
    vim.api.nvim_set_hl(0, 'AlphaProgressPending', { fg = '#e06c75' })
    require('alpha').setup {
      layout = layout(),
      opts = {
        setup = function()
          vim.api.nvim_create_autocmd('User', {
            pattern = 'AlphaReady',
            desc = 'Disable status and tabline for alpha',
            callback = function()
              vim.go.laststatus = 0
              vim.opt.showtabline = 0
            end,
          })
          vim.api.nvim_create_autocmd('BufUnload', {
            buffer = 0,
            desc = 'Enable status and tabline after alpha',
            callback = function()
              vim.go.laststatus = 3
              vim.opt.showtabline = 2
            end,
          })
        end,
        margin = 5,
      },
    }
  end,
}
