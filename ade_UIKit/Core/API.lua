------------------------------------------------------------
-- 快速创建门面：对外 API v6 → v6.5 不变（RegisterTab / CreateWindow 别名）。
-- v6.5 从 KAF 复刻后，行/网格均由 RegisterTab 的 elements 契约驱动，
-- 旧的 StandaloneRow/Grid/List、MarkChanged、RichDescription 门面已随自造模块删除。
------------------------------------------------------------
local lib = ResolveBOFNamespace("ade_UIKit")
if not lib then return end

lib.CreateWindow = lib.RegisterTab
