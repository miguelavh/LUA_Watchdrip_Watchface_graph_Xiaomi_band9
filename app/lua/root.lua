local lvgl = require("lvgl")

local globalWidth = lvgl.HOR_RES()
local globalHeight = lvgl.VER_RES()

function createRoot()
    local property = {
        w = globalWidth,
        h = globalHeight,
        bg_color = 0,
        bg_opa = lvgl.OPA(100),
        border_width = 0,
        pad_all = 0
    }

    local scr = lvgl.Object(nil, property)
    scr:clear_flag(lvgl.FLAG.SCROLLABLE)
    scr:add_flag(lvgl.FLAG.EVENT_BUBBLE)
    return scr
end

-- return {
--     createRoot = createRoot
-- }