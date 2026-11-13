-- 关于页：套用库范本 AF.Options.AboutPage，文本全部走 ABOUT_* 三语键。
local _, DEMO = ...
local AF, L = DEMO.AF, DEMO.L
if not AF then return end

function DEMO.BuildAbout(parent)
    local version = C_AddOns and C_AddOns.GetAddOnMetadata
        and C_AddOns.GetAddOnMetadata("ade_Demo", "Version") or ""
    return AF.Options.AboutPage.Build(parent, {
        L = L,
        addonName = "ade_Demo",
        version = version,
        description = { "ABOUT_DESC_1", "ABOUT_DESC_2", "ABOUT_DESC_3" },
        features = {
            { label = "ABOUT_FEATURE_1_LABEL", text = "ABOUT_FEATURE_1" },
            { label = "ABOUT_FEATURE_2_LABEL", text = "ABOUT_FEATURE_2" },
            { label = "ABOUT_FEATURE_3_LABEL", text = "ABOUT_FEATURE_3" },
            { label = "ABOUT_FEATURE_4_LABEL", text = "ABOUT_FEATURE_4" },
            { label = "ABOUT_FEATURE_5_LABEL", text = "ABOUT_FEATURE_5" },
        },
        commands = "ABOUT_COMMANDS",
        author = "ABOUT_AUTHOR",
        creditsTitle = "ABOUT_CREDITS_TITLE",
        credits = { "ABOUT_CREDITS", "ABOUT_LICENSE" },
        notes = { "ABOUT_NOTES" },
    })
end
