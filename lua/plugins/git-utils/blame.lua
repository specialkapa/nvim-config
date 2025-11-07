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
local float_highlight_ns = vim.api.nvim_create_namespace 'GitBlameFloatLineHL'

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
  local line_highlights = opts.line_highlights or {}

  local lines = {}
  for _, line in ipairs(content) do
    table.insert(lines, line)
  end

  local help_line_index
  if help_text then
    table.insert(lines, '')
    table.insert(lines, help_text)
    help_line_index = #lines - 1
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
  vim.api.nvim_win_set_option(win, 'cursorline', false)
  vim.api.nvim_win_set_option(win, 'cursorcolumn', false)

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
      vim.hl.range(buf, url_highlight_ns, region.group or 'GitBlameURL', { region.line, region.col_start }, { region.line, region.col_end }, {})
    end
  end

  if #line_highlights > 0 then
    for _, hl in ipairs(line_highlights) do
      if hl.group and vim.fn.hlexists(hl.group) == 1 then
        local line_text = content[hl.line + 1] or ''
        local start_col = hl.col_start or 0
        local end_col = hl.col_end

        if not end_col or end_col < 0 then
          end_col = #line_text
        end

        -- vim.hl.range expects end_col to be exclusive, so use the raw length.
        vim.hl.range(buf, float_highlight_ns, hl.group, { hl.line, start_col }, { hl.line, end_col }, {})
      end
    end
  end

  if help_line_index and opts.help_highlight and vim.fn.hlexists(opts.help_highlight) == 1 then
    vim.hl.range(buf, float_highlight_ns, opts.help_highlight, { help_line_index, 0 }, { help_line_index, #help_text }, {})
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

  local commit_stat_cmd = string.format('git show --stat %s', commit_hash)
  local commit_stat = vim.fn.system(commit_stat_cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify('Failed to get commit stats', vim.log.levels.ERROR)
    return
  end

  local commit_info_cmd = string.format('git show --no-patch --format="%%an|%%ae|%%ad|%%s" --date=format:"%%Y-%%m-%%d %%H:%%M:%%S" %s', commit_hash)
  local commit_info = vim.fn.system(commit_info_cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify('Failed to get commit details', vim.log.levels.ERROR)
    return
  end

  local author, email, date, message = commit_info:match '^([^|]+)|([^|]+)|([^|]+)|(.+)'
  local files_changed, insertions, deletions
  local full_files, full_insertions, full_deletions = commit_stat:match '(%d+) files? changed[, ]+(%d+) insertions?%(%+%)?,?[, ]*(%d+) deletions?%(-%)?'
  if full_files then
    files_changed, insertions, deletions = full_files, full_insertions, full_deletions
  else
    local files_insert_only, insert_only_count = commit_stat:match '(%d+) files? changed[, ]+(%d+) insertions?%(%+%)?'
    if files_insert_only then
      files_changed, insertions = files_insert_only, insert_only_count
    else
      local files_delete_only, delete_only_count = commit_stat:match '(%d+) files? changed[, ]*(%d+) deletions?%(-%)?'
      if files_delete_only then
        files_changed, deletions = files_delete_only, delete_only_count
      end
    end
  end

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

  local content = {}
  local line_highlights = {}

  local function append_line(value, highlight)
    table.insert(content, value)
    local line_index = #content - 1
    if highlight then
      table.insert(line_highlights, {
        line = line_index,
        group = highlight,
      })
    end
    return line_index
  end

  append_line(string.format('  %s <%s> on %s', author, email, date), 'GitBlameFloatAuthor')
  append_line('', nil)
  append_line('   ' .. message:gsub('\n', ''), 'GitBlameFloatMessage')
  append_line('', nil)
  local commit_hash_display = commit_hash:sub(1, 8)
  local hash_url_line = string.format('  %s', commit_hash_display)
  if web_url ~= '' then
    hash_url_line = hash_url_line .. string.format(' |   %s', web_url)
  end

  local highlights = {}
  local hash_line_index = append_line(hash_url_line, nil)

  local hash_display_start = hash_url_line:find(commit_hash_display, 1, true)
  if hash_display_start then
    table.insert(line_highlights, {
      line = hash_line_index,
      group = 'GitBlameFloatHash',
      col_start = hash_display_start - 1,
      col_end = (hash_display_start - 1) + #commit_hash_display,
    })
  end
  append_line('', nil)

  if files_changed then
    local stats_segments = {}
    table.insert(stats_segments, {
      text = ' ' .. string.format('%s files changed', files_changed),
      group = 'GitBlameFloatStatsFilesChanged',
    })

    if insertions then
      table.insert(stats_segments, {
        text = string.format(', +%s insertions', insertions),
        group = 'GitBlameFloatStatsInsertions',
      })
    end

    if deletions then
      table.insert(stats_segments, {
        text = string.format(', -%s deletions', deletions),
        group = 'GitBlameFloatStatsDeletions',
      })
    end

    local stats_line = ''
    for _, segment in ipairs(stats_segments) do
      stats_line = stats_line .. segment.text
    end

    local stats_line_index = append_line(stats_line, nil)

    local col = 0
    for _, segment in ipairs(stats_segments) do
      local segment_length = #segment.text
      table.insert(line_highlights, {
        line = stats_line_index,
        group = segment.group,
        col_start = col,
        col_end = col + segment_length,
      })
      col = col + segment_length
    end
  end

  if web_url ~= '' then
    local url_start = hash_url_line:find(web_url, 1, true)
    if url_start then
      table.insert(highlights, {
        line = hash_line_index,
        col_start = url_start - 1,
        col_end = (url_start - 1) + #web_url,
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
    line_highlights = line_highlights,
    help_highlight = 'GitBlameFloatHelp',
  })
end

return M
