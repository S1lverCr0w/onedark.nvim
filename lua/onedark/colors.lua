local util = require('onedark.util')

local colors = {}

---@type table<string, od.ColorPalette>
local palettes = {
  dark = {
    none = 'NONE',
    bg0 = '#1b1d22',
    bg1 = '#16181d',
    bg_highlight = '#2c313a',
    bg_visual = '#393f4a',
    black0 = '#20232A',
    blue0 = '#61afef',
    blue1 = '#528bff',
    cyan0 = '#56b6c2',
    fg0 = '#abb2bf',
    fg_dark = '#798294',
    fg_gutter = '#5c6370',
    fg_light = '#adbac7',
    green0 = '#98c379',
    orange0 = '#e59b4e',
    orange1 = '#d19a66',
    purple0 = '#c678dd',
    red0 = '#e06c75',
    red1 = '#e86671',
    red2 = '#f65866',
    yellow0 = '#ebd09c',
    yellow1 = '#e5c07b',
    dev_icons = {
      blue = '#519aba',
      green0 = '#8dc149',
      yellow = '#cbcb41',
      orange = '#e37933',
      red = '#cc3e44',
      purple = '#a074c4',
      pink = '#f55385',
      gray = '#4d5a5e',
    },
  },

  light = {
    none = 'NONE',
    bg0 = '#fafafa',
    bg1 = '#f0f0f1',
    bg_highlight = '#e5e5e6',
    bg_visual = '#d9d9db',
    black0 = '#383a42',
    blue0 = '#4078f2',
    blue1 = '#3b5bdb',
    cyan0 = '#0184bc',
    fg0 = '#383a42',
    fg_dark = '#696c77',
    fg_gutter = '#a0a1a7',
    fg_light = '#4f525e',
    green0 = '#50a14f',
    orange0 = '#a05a00',
    orange1 = '#986801',
    purple0 = '#a626a4',
    red0 = '#e45649',
    red1 = '#ca1243',
    red2 = '#d0021b',
    yellow0 = '#f0c674',
    yellow1 = '#c18401',
    dev_icons = {
      blue = '#519aba',
      green0 = '#8dc149',
      yellow = '#986801',
      orange = '#a05a00',
      red = '#cc3e44',
      purple = '#a074c4',
      pink = '#d0507a',
      gray = '#a0a1a7',
    },
  },
}

---@param cfg od.ConfigSchema
---@return od.ColorPalette
colors.setup = function(cfg)
  cfg = cfg or require('onedark.config').schema

  local style = cfg.style or 'dark'
  local base = palettes[style] or palettes.dark

  ---@type od.ColorPalette
  local c = vim.deepcopy(base)

  -- useful for 'util.darken()' and 'util.lighten()'
  util.bg = c.bg0
  util.fg = c.fg0

  --
  -- NOTE: These colors are also configurable
  --

  c.git = {
    change = '#e0af68',
    add = '#109868',
    delete = '#9a353d',
    conflict = '#bb7a61',
    ignore = c.fg_gutter,
  }
  c.diff = {
    add = util.darken(c.git.add, 0.09),
    delete = util.darken(c.git.delete, 0.09),
    change = util.darken(c.git.change, 0.09),
    text = util.darken(c.git.change, 0.3),
  }
  c.git_signs = {
    add = util.brighten(c.git.add, 0.2),
    change = util.brighten(c.git.change, 0.2),
    delete = util.brighten(c.git.delete, 0.2),
  }

  -- Sidebar and Floats
  c.bg_sidebar = (cfg.transparent_sidebar and c.none) or cfg.dark_sidebar and c.bg1 or c.bg0
  c.bg_float = cfg.dark_float and c.bg1 or c.bg0

  -- EndOfBuffer
  c.sidebar_eob = cfg.dark_sidebar and c.bg1 or c.bg0
  c.sidebar_eob = cfg.hide_end_of_buffer and c.sidebar_eob or c.fg_gutter
  c.eob = cfg.hide_end_of_buffer and c.bg0 or c.fg_gutter

  -- LineNumber
  c.bg_linenumber = cfg.highlight_linenumber and c.bg1 or c.bg0

  -- Search
  c.bg_search = c.yellow0
  c.fg_search = c.bg1

  -- Diagnostic
  c.error = c.red1
  c.warning = c.yellow1
  c.info = c.blue0
  c.hint = c.cyan0

  c = util.color_overrides(c, cfg.colors)
  return c
end

return colors
