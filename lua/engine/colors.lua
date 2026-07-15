local util = require('engine.util')

local colors = {}

---@type table<string, od.ColorPalette>

---Load a palette from lua/colorschemes/, falling back to the
---built-in engine default if it's missing or fails to load.
---Cached per name so repeated calls (e.g. switching back and forth)
---don't re-require the same file.
local palette_cache = {}

---@param name string
---@return od.ColorPalette
local function load_palette(name)
    if palette_cache[name] then
        return palette_cache[name]
    end
    local ok, palette = pcall(require, name .. '.' .. name)
    local resolved = ok and palette or require('engine.fallback_palette.edpt_onedark')
    util.validate_palette(name, resolved)
    palette_cache[name] = resolved
    palette_cache[name] = ok and palette or require('engine.fallback_palette.edpt_onedark')
    return palette_cache[name]
end

---@type table<string, od.ColorPalette>
---@param cfg od.ConfigSchema
---@return od.ColorPalette
colors.setup = function(cfg)
    cfg = cfg or require('engine.config').schema

    local base = load_palette(cfg.colors_name or 'onedark')

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
