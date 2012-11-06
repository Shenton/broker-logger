-- ********************************************************************************
-- Broker Logger (Broker_Logger)
-- Automaticaly enable combat logging when zoning into instances.
-- By: Shenton
--
-- Locales-enUS.lua
-- ********************************************************************************

local L = LibStub("AceLocale-3.0"):NewLocale("Broker_Logger", "enUS", true);

if L then
L["5 Player & Scenario"] = true;
L["5 Player (Heroic)"] = true;
L["10 Player"] = true;
L["25 Player"] = true;
L["10 Player (Heroic)"] = true;
L["25 Player (Heroic)"] = true;
L["Raid Finder"] = true;
L["Challenge Mode"] = true;
L["40 Player"] = true;
L["Enabled"] = true;
L["Disabled"] = true;
L["Options"] = true;
L["Auto Enable"] = true;
L["Enable"] = true;
L["With this options enabled it will automatically turn on combat logging when zoning to an enabled instance."] = true;
L["instance Types"] = true;
L["With this options enabled it will ask if you want to enable logging when zoning to a new %s instance"] = true;
L["Enabled Instances"] = true;
L["You have entered:\n\n|cff00ff96%s|r\n|cffc79c6e%s|r\n\nEnable logging for this area?"] = true;
L["Enable auto logging for %s (%s)."] = true;
L["|cFFC79C6ELeft-Click:|cFF33FF99 Toggle logging\n|cFFC79C6ERight-Click:|cFF33FF99 Display the configuration menu"] = true;
end
