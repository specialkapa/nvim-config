require 'core.options'
require 'core.keymaps'

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }

  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

local rtp = vim.opt.rtp
rtp:prepend(lazypath)

require('lazy').setup {
  require 'plugins.nvim-tree',
  require 'plugins.colortheme',
  require 'plugins.barbar',
  require 'plugins.lualine',
  require 'plugins.treesitter',
  require 'plugins.telescope',
  require 'plugins.lsp',
  require 'plugins.autocompletion',
  require 'plugins.none-ls',
  require 'plugins.gitsigns',
  require 'plugins.welcome-dashboard',
  require 'plugins.indent-blankline',
  require 'plugins.misc',
  require 'plugins.lazygit',
  require 'plugins.lazydocker',
  require 'plugins.toggleterm',
  require 'plugins.comment',
  require 'plugins.neotest',
  require 'plugins.debug',
  require 'plugins.neominimap',
  require 'plugins.ai-stuff',
  require 'plugins.trouble',
}
