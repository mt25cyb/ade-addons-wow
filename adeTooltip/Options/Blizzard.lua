-- adeTooltip — 入口聚合（P1：重置确认弹窗；暴雪设置面板入口待后续阶段评估）。
local ADT = _G.adeTooltip
if not ADT then return end
local L = ADT.L or {}

-- 只添加自己的弹窗条目，不重赋值 Blizzard 的 StaticPopupDialogs。
function ADT:RegisterPopups()
    if type(_G.StaticPopupDialogs) == "table" and not _G.StaticPopupDialogs["ADETOOLTIP_RESET"] then
        _G.StaticPopupDialogs["ADETOOLTIP_RESET"] = {
            text = L.RESET_CONFIRM,
            button1 = _G.YES or "Yes",
            button2 = _G.NO or "No",
            OnAccept = function() ADT:ResetProfile() end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
    end
end
