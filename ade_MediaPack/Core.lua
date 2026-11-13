--[==[==========================================================================
    ade_MediaPack / ade_MediaPack.lua

    ADE 套件共享材质库主入口。职责：取 LibSharedMedia-3.0 实例，向 ns 暴露
    统一注册入口 ns.Register；素材注册分散在 MediaPack_<来源>.lua 中。

    目录约定：
      · 自有素材放 statusbar/ border/ background/ sound/ 顶层目录；
      · 第三方素材放 material_3rd-party/<来源>/<statusbar|border|background|sound>/；
      · RuriWigs 计时条描边纹理放 textures/，不注册进 LSM，由 StyleWigs/StyleDBM 直接引用。

    LSM 由本插件 libs\ 下的 LibStub / CallbackHandler-1.0 / LibSharedMedia-3.0
    按 TOC 顺序自行注册，不依赖任何外部插件；统一经全局 LibStub 取用。
    库缺失时本文件静默返回，后续来源文件检测 ns.Register 后同样跳过，不注册任何假数据。
==========================================================================]==]

local _, ns = ...

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
if not LSM then
    return
end

ns.LSM = LSM

--- 统一注册入口，供各来源注册文件经 ns.Register 调用。
---@param mediaType string
---@param name string
---@param path string 完整的 Interface\... 路径
---@return boolean?
function ns.Register(mediaType, name, path)
    return LSM:Register(mediaType, name, path)
end
