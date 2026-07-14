---Factory for generating a theme entrypoint module.
---Every colorscheme's `init.lua` becomes a one-liner using this.
---@param name string  -- must match lua/<name>/<name>.lua and colors/<name>.vim
---@return table
return function(name)
  local m = {}

  ---@param cfg od.ConfigSchema|nil
  m.setup = function(cfg)
    cfg = cfg or {}
    cfg.colors_name = name
    require('engine').setup(cfg)
  end

  ---@param cfg od.ConfigSchema|nil
  ---@return od.ColorPalette
  m.get_colors = function(cfg)
    cfg = cfg or {}
    cfg.colors_name = name
    return require('engine').get_colors(cfg)
  end

  return m
end
