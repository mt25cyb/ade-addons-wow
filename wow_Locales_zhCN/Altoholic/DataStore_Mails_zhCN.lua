-- DataStore_Mails 2026.10.14 (zhCN 汉化 / Ade)
local addonName = ...
local L = AddonFactory:SetLocale(addonName, "zhCN")
if not L then return end

L["EXPIRY_CHECK_LABEL"] = "邮件过期警告"
L["SCAN_MAIL_BODY_LABEL"] = "扫描邮件正文（标记为已读）"
L["Warn when mail expires in less days than this value"] = "当邮件在此天数内过期时发出警告"


-- [ADE] 补全缺失 key
L["EXPIRED_EMAILS_WARNING"] = "%s (%s) 有已过期（或即将过期）的邮件"
L["EXPIRY_ALL_ACCOUNTS_DISABLED"] = "仅考虑当前账号；导入的账号将被忽略。"
L["EXPIRY_ALL_ACCOUNTS_ENABLED"] = "过期检查例程会查找所有已知账号上的过期邮件。"
L["EXPIRY_ALL_ACCOUNTS_LABEL"] = "检查所有已知账号的邮件过期"
L["EXPIRY_ALL_ACCOUNTS_TITLE"] = "检查所有账号"
L["EXPIRY_ALL_REALMS_DISABLED"] = "仅考虑当前服务器；其他服务器将被忽略。"
L["EXPIRY_ALL_REALMS_ENABLED"] = "过期检查例程会查找所有已知服务器上的过期邮件。"
L["EXPIRY_ALL_REALMS_LABEL"] = "检查所有已知服务器的邮件过期"
L["EXPIRY_ALL_REALMS_TITLE"] = "检查所有服务器"
L["EXPIRY_CHECK_DISABLED"] = "不执行任何过期检查。"
L["EXPIRY_CHECK_ENABLED"] = "登录 5 秒后检查邮件过期。若发现至少一封过期邮件，客户端插件会收到通知。"
L["EXPIRY_CHECK_TITLE"] = "检查邮件过期"
L["REPORT_EXPIRED_MAILS_DISABLED"] = "聊天框中不显示任何内容。"
L["REPORT_EXPIRED_MAILS_ENABLED"] = "邮件过期检查期间，过期邮件的角色列表也会显示在聊天框中。"
L["REPORT_EXPIRED_MAILS_LABEL"] = "邮件过期警告（聊天框）"
L["REPORT_EXPIRED_MAILS_TITLE"] = "邮件过期警告（聊天框）"
L["SCAN_MAIL_BODY_DISABLED"] = "仅读取邮件附件。邮件会保持未读状态。"
L["SCAN_MAIL_BODY_ENABLED"] = "扫描邮箱时会读取每封邮件的正文。所有邮件都会被标记为已读。"
L["SCAN_MAIL_BODY_TITLE"] = "扫描邮件正文"
