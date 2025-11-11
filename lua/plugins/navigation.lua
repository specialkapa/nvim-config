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
      local opts = {
        signs = {
          mark = {
            icon = ' ',
            color = '#FF69B4',
            line_bg = '#572626',
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
              bg = '#2C323C',
              fg = '#ffffff',
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
      require('bookmarks').setup(opts) -- you must call setup to init sqlite db
      vim.keymap.set('n', '<leader>bm', '<cmd>BookmarksMark<cr>', { desc = 'Place [B]ook [M]ark' })

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
        end,
      })
    end,
  },
}
