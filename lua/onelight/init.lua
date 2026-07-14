local engine = require("engine")

local onelight = {}

function onelight.setup(cfg)
    cfg = cfg or {}
    cfg.style = "light"
    engine.setup(cfg)
end

function onelight.get_colors(cfg)
    cfg = cfg or {}
    cfg.style = "light"
    cfg.colors_name = "onelight"
    return engine.get_colors(cfg)
end

return onelight
