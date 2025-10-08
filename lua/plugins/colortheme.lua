return {
  'shaunsingh/nord.nvim',
  lazy = false,
  priority = 1000,

  config = function()
    vim.g.nord_contrast = true
    vim.g.nord_borders = false
    vim.g.nord_disable_background = true
    vim.g.nord_italic = false
    vim.g.nord_uniform_diff_background = true
    vim.g.nord_bold = false
    vim.g.nord_cursorline_transparent = false

    local transparent_groups = {
      'Normal',
      'NormalNC',
      'NormalFloat',
      'FloatBorder',
      'WinSeparator',
      'SignColumn',
      'StatusLine',
      'StatusLineNC',
      'CursorLine',
      'CursorLineNr',
      'TelescopeNormal',
      'TelescopeBorder',
      'TelescopePromptNormal',
      'TelescopePromptBorder',
      'TroubleNormal',
      'TroubleNormalNC',
      'DiagnosticFloatingError',
      'DiagnosticFloatingWarn',
      'DiagnosticFloatingInfo',
      'DiagnosticFloatingHint',
      'LazyNormal',
      'WhichKeyFloat',
      'NoicePopup',
    }

    local function apply_transparent_background()
      if not vim.g.nord_disable_background then
        return
      end

      for _, group in ipairs(transparent_groups) do
        vim.api.nvim_set_hl(0, group, { bg = 'none', ctermbg = 'none' })
      end
    end

    local transparency_augroup = vim.api.nvim_create_augroup('NordTransparentBackground', { clear = true })
    vim.api.nvim_create_autocmd('ColorScheme', {
      group = transparency_augroup,
      pattern = 'nord',
      callback = apply_transparent_background,
    })

    require('nord').set()
    apply_transparent_background()

    -- Toggle background transparency
    local bg_transparent = true

    local toggle_transparency = function()
      bg_transparent = not bg_transparent
      vim.g.nord_disable_background = bg_transparent
      vim.cmd [[colorscheme nord]]
      apply_transparent_background()
    end

    vim.keymap.set('n', '<leader>bg', toggle_transparency, { noremap = true, silent = true })
  end,
}
