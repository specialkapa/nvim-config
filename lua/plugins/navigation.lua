return {
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    ---@type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash' },
      { 'S', mode = { 'n', 'x', 'o' }, function() require('flash').treesitter() end, desc = 'Flash Treesitter' },
      { 'r', mode = 'o', function() require('flash').remote() end, desc = 'Remote Flash' },
      { 'R', mode = { 'o', 'x' }, function() require('flash').treesitter_search() end, desc = 'Treesitter Search' },
      { '<c-s>', mode = { 'c' }, function() require('flash').toggle() end, desc = 'Toggle Flash Search' },
    },
  },
  {
    'LintaoAmons/bookmarks.nvim',
    -- pin the plugin at specific version for stability
    -- backup your bookmark sqlite db when there are breaking changes (major version change)
    tag = '3.2.0',
    dependencies = {
      { 'kkharji/sqlite.lua' },
      { 'nvim-telescope/telescope.nvim' },
    },
    config = function()
      local palettes_ok, palettes = pcall(require, 'catppuccin.palettes')
      local mocha = palettes_ok and palettes.get_palette 'mocha' or nil
      local bookmark_colors = {
        icon = mocha and mocha.pink or '#FF69B4',
        line_bg = '#572626',
        tree_bg = mocha and mocha.surface0 or '#2C323C',
        tree_fg = mocha and mocha.yellow or '#ffffff',
      }
      local bookmarks = require 'bookmarks'
      local opts = {
        signs = {
          mark = {
            icon = ' ',
            color = bookmark_colors.icon,
            line_bg = bookmark_colors.line_bg,
          },
          desc_format = function(bookmark)
            ---@cast bookmark Bookmarks.Node
            return ''
          end,
        },

        treeview = {
          ---@type fun(node: Bookmarks.Node): string | nil
          render_bookmark = nil,
          highlights = {
            active_list = {
              bg = bookmark_colors.tree_bg,
              fg = bookmark_colors.tree_fg,
              bold = true,
            },
          },
          active_list_icon = ' ',
          keymap = {
            ['q'] = {
              action = 'quit',
              desc = 'Close the tree view window',
            },
            ['<ESC>'] = {
              action = 'quit',
              desc = 'Close the tree view window',
            },
            ['R'] = {
              action = 'refresh',
              desc = 'Reload and redraw the tree view',
            },
            ['a'] = {
              action = 'create_list',
              desc = 'Create a new list under the current node',
            },
            ['u'] = {
              action = 'level_up',
              desc = 'Navigate up one level in the tree hierarchy',
            },
            ['.'] = {
              action = 'set_root',
              desc = 'Set current list as root of the tree view, also set as active list',
            },
            ['m'] = {
              action = 'set_active',
              desc = 'Set current list as the active list for bookmarks',
            },
            ['o'] = {
              action = 'toggle',
              desc = 'Toggle list expansion or go to bookmark location',
            },
            ['<localleader>k'] = {
              action = 'move_up',
              desc = 'Move current node up in the list',
            },
            ['<localleader>j'] = {
              action = 'move_down',
              desc = 'Move current node down in the list',
            },
            ['D'] = {
              action = 'delete',
              desc = 'Delete current node',
            },
            ['r'] = {
              action = 'rename',
              desc = 'Rename current node',
            },
            ['g'] = {
              action = 'goto',
              desc = 'Go to bookmark location in previous window',
            },
            ['x'] = {
              action = 'cut',
              desc = 'Cut node',
            },
            ['c'] = {
              action = 'copy',
              desc = 'Copy node',
            },
            ['p'] = {
              action = 'paste',
              desc = 'Paste node',
            },
            ['i'] = {
              action = 'show_info',
              desc = 'Show node info',
            },
            ['t'] = {
              action = 'reverse',
              desc = 'Reverse the order of nodes in the tree view',
            },
            ['P'] = {
              action = 'preview',
              desc = 'Preview bookmark content',
            },
            ['+'] = {
              action = 'add_to_aider',
              desc = 'Add to Aider',
            },
            ['='] = {
              action = 'add_to_aider_read_only',
              desc = 'Add to Aider as read-only',
            },
            ['-'] = {
              action = 'drop_from_aider',
              desc = 'Drop from Aider',
            },
            ['?'] = {
              action = 'show_help',
              desc = 'Show help panel with available keymaps',
            },
            ['<C-o>'] = {
              ---@type Bookmarks.KeymapCustomAction
              action = function(node, info)
                if info.type == 'bookmark' then
                  vim.system({ 'open', info.dirname }, { text = true })
                end
              end,
              desc = 'Open the current node with system default software',
            },
          },
          -- Dimension of the window spawned for Treeview
          window_split_dimension = 30,
        },
      } -- check the "./lua/bookmarks/default-config.lua" file for all the options
      bookmarks.setup(opts) -- you must call setup to init sqlite db
      vim.keymap.set('n', '<leader>bm', '<cmd>BookmarksMark<cr>', { desc = 'Place [B]ook [M]ark' })

      -- Always focus the BookmarksTree window after opening it so it is ready for interaction
      vim.api.nvim_create_user_command('BookmarksTree', function()
        bookmarks.toggle_treeview()
        vim.schedule(function()
          local ctx = vim.g.bookmark_tree_view_ctx
          if ctx and vim.api.nvim_win_is_valid(ctx.win) then
            vim.api.nvim_set_current_win(ctx.win)
          end
        end)
      end, { desc = 'browse bookmarks in tree view', force = true })

      local group = vim.api.nvim_create_augroup('BookmarksTreeHideStatusColumn', { clear = true })
      vim.api.nvim_create_autocmd('BufWinEnter', {
        group = group,
        callback = function(args)
          if vim.bo[args.buf].filetype ~= 'BookmarksTree' then
            return
          end

          local win = vim.api.nvim_get_current_win()
          if not vim.api.nvim_win_is_valid(win) then
            return
          end

          vim.api.nvim_set_option_value('statuscolumn', '', { win = win })
          vim.api.nvim_set_option_value('number', false, { win = win })
          vim.api.nvim_set_option_value('relativenumber', false, { win = win })
          vim.api.nvim_set_option_value('spell', false, { win = win })
        end,
      })
    end,
  },
  {
    'hedyhli/outline.nvim',
    lazy = true,
    cmd = { 'Outline', 'OutlineOpen' },
    keys = { -- Example mapping to toggle outline
      { '<leader>u', '<cmd>Outline<CR>', desc = 'Toggle outline' },
    },
    opts = {
      outline_window = {
        position = 'right',
        split_command = nil,
        width = 25,
        relative_width = true,
        auto_close = false,
        auto_jump = false,
        jump_highlight_duration = 300,
        center_on_jump = true,
        show_numbers = false,
        show_relative_numbers = false,
        wrap = false,
        show_cursorline = true,
        hide_cursor = false,
        focus_on_open = true,
        winhl = '',
        no_provider_message = 'No supported provider...',
      },
      outline_items = {
        show_symbol_details = true,
        show_symbol_lineno = false,
        highlight_hovered_item = true,
        auto_set_cursor = true,
        auto_update_events = {
          follow = { 'CursorMoved' },
          items = { 'InsertLeave', 'WinEnter', 'BufEnter', 'BufWinEnter', 'TabEnter', 'BufWritePost' },
        },
      },
      guides = {
        enabled = true,
        markers = {
          bottom = '└',
          middle = '├',
          vertical = '│',
        },
      },

      symbol_folding = {
        autofold_depth = 1,
        auto_unfold = {
          hovered = true,
          only = true,
        },
        markers = { '', '' },
      },
      preview_window = {
        auto_preview = false,
        open_hover_on_preview = false,
        width = 50,
        min_width = 50,
        relative_width = true,
        height = 50,
        min_height = 10,
        relative_height = true,
        border = 'single',
        winhl = 'NormalFloat:',
        winblend = 0,
        live = false,
      },

      keymaps = {
        show_help = '?',
        close = { '<Esc>', 'q' },
        goto_location = '<Cr>',
        peek_location = 'o',
        goto_and_close = '<S-Cr>',
        restore_location = '<C-g>',
        hover_symbol = '<C-space>',
        toggle_preview = 'K',
        rename_symbol = 'r',
        code_actions = 'a',
        unfold = 'l',
        fold_toggle = '<Tab>',
        fold_toggle_all = '<S-Tab>',
        fold_all = 'W',
        unfold_all = 'E',
        fold_reset = 'R',
        down_and_jump = '<C-j>',
        up_and_jump = '<C-k>',
      },

      providers = {
        priority = { 'lsp', 'coc', 'markdown', 'norg', 'man' },
        lsp = {
          blacklist_clients = {},
        },
        markdown = {
          filetypes = { 'markdown', 'vimwiki' },
        },
      },

      symbols = {
        filter = nil,
        ---@param kind string Key of the icons table below
        ---@param bufnr integer Code buffer
        ---@param symbol outline.Symbol The current symbol object
        ---@returns string|boolean The icon string to display, such as "f", or `false`
        ---                        to fallback to `icon_source`.
        icon_fetcher = nil,
        icon_source = nil,
        icons = {
          File = { icon = '󰈔', hl = 'Identifier' },
          Module = { icon = '󰆧', hl = 'Include' },
          Namespace = { icon = '󰅪', hl = 'Include' },
          Package = { icon = '󰏗', hl = 'Include' },
          Class = { icon = '𝓒', hl = 'Type' },
          Method = { icon = 'ƒ', hl = 'Function' },
          Property = { icon = '', hl = 'Identifier' },
          Field = { icon = '󰆨', hl = 'Identifier' },
          Constructor = { icon = '', hl = 'Special' },
          Enum = { icon = 'ℰ', hl = 'Type' },
          Interface = { icon = '󰜰', hl = 'Type' },
          Function = { icon = '', hl = 'Function' },
          Variable = { icon = '', hl = 'Constant' },
          Constant = { icon = '', hl = 'Constant' },
          String = { icon = '𝓐', hl = 'String' },
          Number = { icon = '#', hl = 'Number' },
          Boolean = { icon = '⊨', hl = 'Boolean' },
          Array = { icon = '󰅪', hl = 'Constant' },
          Object = { icon = '⦿', hl = 'Type' },
          Key = { icon = '🔐', hl = 'Type' },
          Null = { icon = 'NULL', hl = 'Type' },
          EnumMember = { icon = '', hl = 'Identifier' },
          Struct = { icon = '𝓢', hl = 'Structure' },
          Event = { icon = '🗲', hl = 'Type' },
          Operator = { icon = '+', hl = 'Identifier' },
          TypeParameter = { icon = '𝙏', hl = 'Identifier' },
          Component = { icon = '󰅴', hl = 'Function' },
          Fragment = { icon = '󰅴', hl = 'Constant' },
          TypeAlias = { icon = ' ', hl = 'Type' },
          Parameter = { icon = ' ', hl = 'Identifier' },
          StaticMethod = { icon = ' ', hl = 'Function' },
          Macro = { icon = ' ', hl = 'Function' },
        },
      },
    },
  },
}
