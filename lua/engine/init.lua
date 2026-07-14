local config = require('engine.config')
local theme = require('engine.theme')
local util = require('engine.util')

local init = {}

---@param user_config od.ConfigSchema
init.setup = function(user_config)
  if user_config then
    config.apply_configuration(user_config)
  end
  util.load(theme.setup(config.schema))
end

---@param cfg od.ConfigSchema|nil
---@return od.ColorPalette
init.get_colors = function(cfg)
  return require('engine.colors').setup(cfg)
end

return init
