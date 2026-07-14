local onedark = require('onedark')

---@class od.OneLight
local onelight = {}

---@param user_config od.ConfigSchema|nil
onelight.setup = function(user_config)
  user_config = user_config or {}
  user_config.style = 'light'
  onedark.setup(user_config)
end

---@param cfg od.ConfigSchema|nil
---@return od.ColorPalette
onelight.get_colors = function(cfg)
  cfg = cfg or {}
  cfg.style = 'light'
  return onedark.get_colors(cfg)
end

return onelight
