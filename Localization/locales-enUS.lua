-- ********************************************************************************
-- Broker Logger (Broker_Logger)
-- Automaticaly enable combat logging when zoning into instances.
-- By: Shenton
--
-- Locales-enUS.lua
-- ********************************************************************************

local L = LibStub("AceLocale-3.0"):NewLocale("Broker_Logger", "enUS", true);

if L then
L["Enabled"] = true;
L["Disabled"] = true;
L["Options"] = true;
L["Auto Enable"] = true;
L["Enable"] = true;
L["With this options enabled it will automatically turn on combat logging when zoning to an enabled instance."] = true;
L["Ask for logging when entering"] = true;
L["With this options enabled it will ask if you want to enable logging when zoning to a new %s instance."] = true;
L["Enabled Instances"] = true;
L["You have entered:\n\n\n|cff00ff96Instance: |r%s\n\n|cffc79c6eDifficulty: |r%s\n\n\nEnable logging for this area?"] = true;
L["Enable auto logging for %s (%s)."] = true;
L["Instance type is unknown to the addon, an uptade might be available."] = true;
L["|cFFC79C6ELeft-Click:|cFF33FF99 Toggle logging\n|cFFC79C6ERight-Click:|cFF33FF99 Display the configuration panel"] = true;
end
