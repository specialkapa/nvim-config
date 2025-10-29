return {
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true }, -- Optional
  },
  cmd = {
    'DBUI',
    'DBUIToggle',
    'DBUIAddConnection',
    'DBUIFindBuffer',
  },
  init = function()
    vim.g.db_ui_use_nerd_fonts = 1
  end,
  config = function()
    -- Disable line numbers and sign column in DBUI windows
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'dbui', 'dbout', 'sql' },
      callback = function(args)
        local bufnr = args.buf
        local bufname = vim.api.nvim_buf_get_name(bufnr)

        -- Check if this is a DBUI-related buffer
        if
          vim.bo[bufnr].filetype == 'dbui'
          or vim.bo[bufnr].filetype == 'dbout'
          or (vim.bo[bufnr].filetype == 'sql' and vim.bo[bufnr].buftype == 'nofile')
          or bufname:match 'dbui://'
          or bufname:match '%.dbout$'
        then
          -- Find all windows displaying this buffer
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == bufnr then
              vim.wo[win].number = false
              vim.wo[win].relativenumber = false
              vim.wo[win].signcolumn = 'no'
              vim.wo[win].statuscolumn = ' '
              -- Disable neominimap for this window
              vim.b[bufnr].neominimap_disable = true
              -- Also try to disable via command if available
              pcall(function()
                vim.api.nvim_buf_call(bufnr, function()
                  vim.cmd('Neominimap BufDisable')
                end)
              end)
            end
          end
        end
      end,
    })

    -- Also handle when windows are created or entered
    vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local winnr = vim.api.nvim_get_current_win()
        local bufname = vim.api.nvim_buf_get_name(bufnr)

        if
          vim.bo[bufnr].filetype == 'dbui'
          or vim.bo[bufnr].filetype == 'dbout'
          or (vim.bo[bufnr].filetype == 'sql' and vim.bo[bufnr].buftype == 'nofile')
          or bufname:match 'dbui://'
          or bufname:match '%.dbout$'
        then
          vim.wo[winnr].number = false
          vim.wo[winnr].relativenumber = false
          vim.wo[winnr].signcolumn = 'no'
          vim.wo[winnr].statuscolumn = ' '
          -- Disable neominimap for this buffer
          vim.b[bufnr].neominimap_disable = true
          -- Also try to disable via command if available
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_win_is_valid(winnr) then
              pcall(vim.cmd, 'Neominimap BufDisable')
            end
          end)
        end
      end,
    })
  end,
}
