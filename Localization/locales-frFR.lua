-- ********************************************************************************
-- Broker Logger (Broker_Logger)
-- Automaticaly enable combat logging when zoning into instances.
-- By: Shenton
--
-- Locales-enUS.lua
-- ********************************************************************************

local L = LibStub("AceLocale-3.0"):NewLocale("Broker_Logger", "frFR");

if L then
L["Enabled"] = "Activ\195\169e";
L["Disabled"] = "Desactiv\195\169e";
L["Options"] = "Options";
L["Auto Enable"] = "Activation automatique";
L["Enable"] = "Activer";
L["With this options enabled it will automatically turn on combat logging when zoning to an enabled instance."] = "Avec cette option activ\195\169e, la sauvegarde du journal de combat d\195\169marrera automatiquement en entrant dans une instance ou la sauvegarde est demand\195\169e.";
L["Ask for logging when entering"] = "Demander l'activation de la sauvegarde en entrant";
L["With this options enabled it will ask if you want to enable logging when zoning to a new %s instance."] = "Avec cette option activ\195\169e, il vous sera demand\195\169 si vous souhaitez activer la sauvegarde du journal de combat pour une instance de difficult\195\169e: %s.";
L["Enabled Instances"] = "Instances activ\195\169es";
L["You have entered:\n\n\n|cff00ff96Instance: |r%s\n\n|cffc79c6eDifficulty: |r%s\n\n\nEnable logging for this area?"] = "Vous venez d'entrer dans:\n\n\n|cff00ff96Instance: |r%s\n\n|cffc79c6eDifficult\195\169e: |r%s\n\n\nActiver la sauvegarde du journal de combat?";
L["Enable auto logging for %s (%s)."] = "Active la sauvegarde automatique du journal de combat pour %s (%s).";
L["Instance type is unknown to the addon, an uptade might be available."] = "L'addon ne connait ce type d'instance, une mise \195\160 jour est surement disponible."
L["|cFFC79C6ELeft-Click:|cFF33FF99 Toggle logging\n|cFFC79C6ERight-Click:|cFF33FF99 Display the configuration panel"] = "|cFFC79C6EClique-Gauche:|cFF33FF99 Active/D\195\169sactive la sauvegarde du journal de combat\n|cFFC79C6EClique-Droit:|cFF33FF99 Affiche la fen\195\170tre de configuration";
end
