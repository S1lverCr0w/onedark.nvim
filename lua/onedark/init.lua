local engine = require('engine')

local onedark = {}

---@param user_config od.ConfigSchema|nil
onedark.setup = function(user_config)
  engine.setup(user_config)
end

---@param cfg od.ConfigSchema|nil
---@return od.ColorPalette
onedark.get_colors = function(cfg)
  return engine.get_colors(cfg)
end

return onedark
