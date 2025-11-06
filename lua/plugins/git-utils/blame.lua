local M = {}

local function trim(value)
  if not value then
    return ''
  end
  return (value:gsub('\r', '')):gsub('^%s+', ''):gsub('%s+$', '')
end

local function is_wsl()
  local uname = trim(vim.fn.system { 'uname', '-a' })
  return uname:match 'WSL2' ~= nil
end

local function open_url_in_browser(url)
  if not url or url == '' then
    return
  end

  local open_cmd
  if is_wsl() then
    open_cmd = { 'cmd.exe', '/C', 'start', '', url }
  elseif vim.fn.has 'mac' == 1 or vim.fn.has 'macunix' == 1 then
    open_cmd = { 'open', url }
  elseif vim.fn.has 'win32' == 1 or vim.fn.has 'win64' == 1 then
    open_cmd = { 'cmd.exe', '/C', 'start', '', url }
  else
    open_cmd = { 'xdg-open', url }
  end

  local job = vim.fn.jobstart(open_cmd, { detach = true })
  if job <= 0 then
    vim.notify('Failed to launch browser for commit URL', vim.log.levels.ERROR)
    return
  end

  vim.notify('Opening commit in browser...', vim.log.levels.INFO)
end

local url_highlight_ns = vim.api.nvim_create_namespace 'GitBlameFloatURL'

local function ensure_url_highlight_group()
  if vim.fn.hlexists 'GitBlameURL' == 0 then
    vim.api.nvim_set_hl(0, 'GitBlameURL', { fg = '#61afef', underline = true })
  end
end

local function open_float_window(content, opts)
  opts = opts or {}
  local web_url = opts.web_url or ''
  local help_text = opts.help_text
  local copy_text = opts.copy_text
  local close_keys = opts.close_keys or { 'q', '<Esc>', '<CR>' }
  local highlight_regions = opts.highlights or {}

  local lines = {}
  for _, line in ipairs(content) do
    table.insert(lines, line)
  end

  if help_text then
    table.insert(lines, '')
    table.insert(lines, help_text)
  end

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, #line)
  end
  width = width
  local height = #lines

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local border_chars = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' }

  local base_opts = {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = 'minimal',
    border = border_chars,
    focusable = true,
  }

  local win = vim.api.nvim_open_win(buf, true, opts.win_opts and vim.tbl_extend('force', base_opts, opts.win_opts) or base_opts)

  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')

  for _, key in ipairs(close_keys) do
    vim.api.nvim_buf_set_keymap(buf, 'n', key, '', {
      noremap = true,
      silent = true,
      callback = function()
        vim.api.nvim_win_close(win, true)
      end,
    })
  end

  if web_url ~= '' then
    vim.api.nvim_buf_set_keymap(buf, 'n', 'o', '', {
      noremap = true,
      silent = true,
      callback = function()
        open_url_in_browser(web_url)
      end,
    })
  end

  if copy_text and copy_text ~= '' then
    vim.api.nvim_buf_set_keymap(buf, 'n', 'c', '', {
      noremap = true,
      silent = true,
      callback = function()
        vim.fn.setreg('"', copy_text)
        pcall(vim.fn.setreg, '+', copy_text)
        pcall(vim.fn.setreg, '*', copy_text)
        vim.notify('Commit hash copied to clipboard', vim.log.levels.INFO)
      end,
    })
  end

  local hl_exists = vim.fn.hlexists 'GitBlameFloat' == 1
  if hl_exists then
    vim.api.nvim_win_set_option(win, 'winhl', 'Normal:GitBlameFloat,FloatBorder:GitBlameFloatBorder')
  else
    vim.api.nvim_win_set_option(win, 'winhl', 'Normal:NormalFloat,FloatBorder:FloatBorder')
  end

  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  if #highlight_regions > 0 then
    ensure_url_highlight_group()
    for _, region in ipairs(highlight_regions) do
      vim.api.nvim_buf_add_highlight(buf, url_highlight_ns, region.group or 'GitBlameURL', region.line, region.col_start, region.col_end)
    end
  end
end

function M.show_git_blame_float()
  local current_line = vim.fn.line '.'
  local file_path = vim.fn.expand '%:p'

  local blame_cmd = string.format('git blame -L %d,%d --porcelain %s', current_line, current_line, file_path)
  local blame_output = vim.fn.system(blame_cmd)

  if vim.v.shell_error ~= 0 then
    if blame_output:match 'fatal: no such path' then
      local help_text = "Press 'q' or <Esc> to close"
      open_float_window({ string.format(' %s is still cooking!', file_path) }, { help_text = help_text })
      return
    end

    vim.notify('Failed to get git blame info', vim.log.levels.ERROR)
    return
  end

  local lines = vim.split(blame_output, '\n')
  local commit_hash = lines[1]:match '^(%x+)'

  if not commit_hash or commit_hash == '0000000000000000000000000000000000000000' then
    vim.notify('No commit info for this line', vim.log.levels.WARN)
    return
  end

  local commit_info_cmd = string.format('git show --no-patch --format="%%an|%%ae|%%ad|%%s" --date=format:"%%Y-%%m-%%d %%H:%%M:%%S" %s', commit_hash)
  local commit_info = vim.fn.system(commit_info_cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify('Failed to get commit details', vim.log.levels.ERROR)
    return
  end

  local author, email, date, message = commit_info:match '^([^|]+)|([^|]+)|([^|]+)|(.+)'

  local remote_url_cmd = 'git config --get remote.origin.url'
  local remote_url = vim.fn.system(remote_url_cmd):gsub('\n', '')

  local web_url = ''
  if remote_url:match 'github.com' then
    local repo_path = remote_url:match 'github.com[:/](.+)%.git$' or remote_url:match 'github.com[:/](.+)$'
    if repo_path then
      web_url = string.format('https://github.com/%s/commit/%s', repo_path, commit_hash)
    end
  elseif remote_url:match 'gitlab.com' then
    local repo_path = remote_url:match 'gitlab.com[:/](.+)%.git$' or remote_url:match 'gitlab.com[:/](.+)$'
    if repo_path then
      web_url = string.format('https://gitlab.com/%s/-/commit/%s', repo_path, commit_hash)
    end
  end

  local content = {
    string.format('  %s <%s> on %s', author, email, date),
    '',
    '   ' .. message:gsub('\n', ''),
    '',
  }
  local hash_url_line = string.format('  %s', commit_hash:sub(1, 8))
  if web_url ~= '' then
    hash_url_line = hash_url_line .. string.format(' |   %s', web_url)
  end

  local highlights = {}
  local hash_line_index = #content + 1
  table.insert(content, hash_url_line)

  if web_url ~= '' then
    local url_start = hash_url_line:find(web_url, 1, true)
    if url_start then
      table.insert(highlights, {
        line = hash_line_index - 1,
        col_start = url_start - 1,
        col_end = url_start - 1 + #web_url,
        group = 'GitBlameURL',
      })
    end
  end

  local help_text
  if web_url ~= '' then
    help_text = " Press 'o' to open URL, 'c' to copy hash, 'q' or <Esc> to close"
  else
    help_text = " Press 'c' to copy hash, 'q' or <Esc> to close"
  end

  open_float_window(content, {
    web_url = web_url,
    help_text = help_text,
    copy_text = commit_hash,
    highlights = highlights,
  })
end

return M
