-- === Vim Motions Practice Timer ===
-- Drop this in your init.lua or lua/vim_practice_timer.lua
-- Then run :StartPractice <minutes>

local timer = nil
local start_time = 0
local duration = 0
local bar_length = 20

local function notify(msg)
  vim.notify('󱫐 ' .. msg, vim.log.levels.INFO, { title = 'Vim Practice Timer' })
end

local function stop_timer()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

local function on_tick()
  local elapsed = (vim.loop.hrtime() - start_time) / 1e9
  local remaining = math.max(0, duration - elapsed)
  local mins = math.floor(remaining / 60)
  local secs = math.floor(remaining % 60)
  local ratio = duration > 0 and math.min(1, elapsed / duration) or 0
  local filled = math.floor(ratio * bar_length + 0.5)
  local bar = string.rep('█', filled) .. string.rep('░', bar_length - filled)

  if remaining > 0 then
    local msg = string.format('%s %02d:%02d remaining', bar, mins, secs)
    vim.api.nvim_echo({ { msg, 'ModeMsg' } }, false, {})
    return
  end

  vim.api.nvim_echo({}, false, {})
  notify "󱫌  Time's up! Practice round complete."
  stop_timer()
end

local function start_progress()
  if timer then
    vim.schedule(on_tick)
  end
end

vim.api.nvim_create_user_command('StartPractice', function(opts)
  stop_timer()
  local minutes = tonumber(opts.args)
  if not minutes or minutes <= 0 then
    notify 'Please provide a duration in minutes, e.g. :StartPractice 5'
    return
  end
  duration = minutes * 60
  start_time = vim.loop.hrtime()
  timer = vim.loop.new_timer()
  timer:start(1000, 1000, vim.schedule_wrap(on_tick))
  start_progress()
  notify('Started ' .. opts.args .. ' minute timer. Good luck!')
end, { nargs = 1 })

vim.api.nvim_create_user_command('StopPractice', function()
  stop_timer()
  notify 'Timer stopped.'
end, {})
