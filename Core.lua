--[[-----------------------------------------------------------------------------------------------
    Broker Logger (Broker_Logger)
    Automaticaly enable combat logging when zoning into instances.
    By: Shenton

    Core.lua
-------------------------------------------------------------------------------------------------]]

--[[-----------------------------------------------------------------------------------------------
    Upvalues
-------------------------------------------------------------------------------------------------]]

local pairs = pairs;
local ipairs = ipairs;
local tostring = tostring;

-- GLOBALS:  LoggingCombat, PlaySound, DEFAULT_CHAT_FRAME, IsInInstance, GetInstanceInfo
-- GLOBALS: StaticPopup_Show, GetDifficultyInfo

--[[-----------------------------------------------------------------------------------------------
    Ace3, libs, addon global
-------------------------------------------------------------------------------------------------]]

-- Ace libs (<3)
local A = LibStub("AceAddon-3.0"):NewAddon("Broker_Logger", "AceEvent-3.0", "AceHook-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("Broker_Logger");

_G["BrokerLoggerGlobal"] = A;

--[[-----------------------------------------------------------------------------------------------
    Variables
-------------------------------------------------------------------------------------------------]]

-- AddOn version
A.version = GetAddOnMetadata("Broker_Logger", "Version");

-- Text colors
A.color =
{
    ["RED"] = "|cffff3333",
    ["GREEN"] = "|cff33ff99",
    ["WHITE"] = "|cffffffff",
    ["RESET"] = "|r",
};

-- Icons
A.iconEnabled = "Interface\\ICONS\\INV_Inscription_ParchmentVar02";
A.iconDisabled = "Interface\\ICONS\\INV_Inscription_ParchmentVar01";

--[[-----------------------------------------------------------------------------------------------
    Static Popup
-------------------------------------------------------------------------------------------------]]

StaticPopupDialogs["BrokerLoggerNewInstance"] = {
    text = L["You have entered:\n\n\n|cff00ff96Instance: |r%s\n\n|cffc79c6eDifficulty: |r%s\n\n\nEnable logging for this area?"],
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        A.db.profile.enabledMapID[self.data.difficultyIndex][self.data.instanceMapID] = 1;
        LoggingCombat(true);
    end,
    OnCancel = function(self)
        A.db.profile.enabledMapID[self.data.difficultyIndex][self.data.instanceMapID] = 0;
    end,
    hideOnEscape = 1,
    timeout = 0,
    preferredIndex = 3,
};

--[[-----------------------------------------------------------------------------------------------
    Methods
-------------------------------------------------------------------------------------------------]]

function A:Message(text, color, silent)
    if ( color ) then
        color = A.color["RED"];
    else
        color = A.color["GREEN"]
    end

    if ( not silent ) then
        PlaySound(SOUNDKIT.TELL_MESSAGE);
    end

    DEFAULT_CHAT_FRAME:AddMessage(color.."Broker Logger"..": "..A.color["RESET"]..text);
end

--- Toggle combat logging
function A:ToggleLogging()
    if ( A.isLogging ) then
        LoggingCombat(false);
    else
        LoggingCombat(true);
    end
end

--- Return a bool value for enabled instance logging db
-- @param var The db value
function A:GetVarBool(var)
    if ( var == 1 ) then return true; end
    return false;
end

--- Check if logging is needed in this instance
function A:IsLoggingNeeded()
    if ( not IsInInstance() ) then return nil; end

    local instanceName, _, difficultyIndex, difficultyName, _, _, _, instanceMapID = GetInstanceInfo();

    if ( difficultyIndex == 0 ) then return nil; end

    -- Add instance name to database
    if ( not A.db.global.instanceNameByID[instanceMapID] ) then
        A.db.global.instanceNameByID[instanceMapID] = instanceName;
    end

    -- Instance type is unknown to the addon
    if ( not A.db.profile.enabledMapID[difficultyIndex] ) then
        A:Message(L["Instance type is unknown to the addon, an uptade might be available."], 1);
        return nil;
    end

    if ( A.db.profile.enabledMapID[difficultyIndex][instanceMapID] ) then -- Instance is known
        if ( A:GetVarBool(A.db.profile.enabledMapID[difficultyIndex][instanceMapID]) ) then return 1; end -- Log!
    else
        if ( A.db.profile.instanceType[difficultyIndex] ) then -- Asking for logging for that difficulty is enabled
            StaticPopup_Show("BrokerLoggerNewInstance", instanceName, difficultyName, {difficultyIndex = difficultyIndex, instanceMapID = instanceMapID});
        end
    end

    return nil;
end

--- Update broker object text
function A:Update()
    if ( A.isLogging ) then
        A.ldb.text = A.color["GREEN"]..L["Enabled"];
        A.ldb.icon = A.iconEnabled
    else
        A.ldb.text = A.color["RED"]..L["Disabled"];
        A.ldb.icon = A.iconDisabled
    end
end

--- Set auto log state
function A:SetAutoLoggingState()
    if ( A.db.profile.auto ) then
        A:RegisterEvent("ZONE_CHANGED_NEW_AREA", "IsLoggingNeededCallback");
        A:RegisterEvent("PLAYER_DIFFICULTY_CHANGED", "IsLoggingNeededCallback");
    else
        A:UnregisterEvent("ZONE_CHANGED_NEW_AREA");
        A:UnregisterEvent("PLAYER_DIFFICULTY_CHANGED");
    end
end

--[[-----------------------------------------------------------------------------------------------
    Events & callbacks
-------------------------------------------------------------------------------------------------]]

--- Callback for event PLAYER_ENTERING_WORLD
function A:PLAYER_ENTERING_WORLD()
    A.isLogging = LoggingCombat();
    A:Update();
    A:SetAutoLoggingState();
    A:UnregisterEvent("PLAYER_ENTERING_WORLD");

    -- Dev stuff this need to be commented out
    --A:PrintDifficultyInfos();
end

--- Callback for hook LoggingCombat()
function A:LoggingCombat(state)
    if ( state == nil ) then return; end
    A.isLogging = state;
    A:Update();
end

--- Callback for events
function A:IsLoggingNeededCallback()
    if ( A:IsLoggingNeeded() ) then
        LoggingCombat(true);
    else
        LoggingCombat(false);
    end

    A:Update();
end

--[[-----------------------------------------------------------------------------------------------
    Config
-------------------------------------------------------------------------------------------------]]

--      name                groupType   isHeroic    isChallengeMode displayHeroic   displayMythic   toggleDifficultyID  isLfr
-- 1    Normal              party       false       false           false           false           nil                 false
-- 2    Heroic              party       true        false           false           false           nil                 false
-- 3    10 Player           raid        false       false           false           false           5                   false
-- 4    25 Player           raid        false       false           false           false           6                   false
-- 5    10 Player (Heroic)  raid        true        false           false           false           3                   false
-- 6    25 Player (Heroic)  raid        true        false           false           false           4                   false
-- 7    Looking For Raid    raid        false       false           false           false           nil                 true
-- 8    Mythic Keystone     party       true        true            false           false           nil                 false
-- 9    40 Player           raid        false       false           false           false           nil                 false

-- 11   Heroic Scenario     scenario    true        false           false           false           nil                 false
-- 12   Normal Scenario     scenario    false       false           false           false           nil                 false

-- 14   Normal              raid        false       false           false           false           nil                 false
-- 15   Heroic              raid        false       false           true            false           nil                 false
-- 16   Mythic              raid        true        false           false           true            nil                 false
-- 17   Looking For Raid    raid        false       false           false           false           nil                 true
-- 18   Event               raid        false       false           false           false           nil                 false
-- 19   Event               party       false       false           false           false           nil                 false
-- 20   Event Scenario      scenario    false       false           false           false           nil                 false

-- 23   Mythic              party       true        false           false           true            nil                 false
-- 24   Timewalking         party       false       false           false           false           nil                 false
-- 25   World PvP Scenario  scenario    false       false           false           false           nil                 false

-- 29   PvEvP Scenario      pvp         false       false           false           false           nil                 false
-- 30   Event               scenario    false       false           false           false           nil                 false

-- 32   World PvP Scenario  scenario    false       false           false           false           nil                 false
-- 33   Timewalking         raid        false       false           false           false           nil                 false
-- 34   PvP                 pvp         false       false           false           false           nil                 false

-- 38   Normal              scenario    false       false           false           false           nil                 false
-- 39   Heroic              scenario    false       false           true            false           nil                 false
-- 40   Mythic              scenario    false       false           false           true            nil                 false

-- 45   PvP                 scenario    false       false           false           false           nil                 false


--- Default configation table
local defaultDB =
{
    profile =
    {
        auto = 1,
        instanceType =
        {
            [1] = 1, -- Normal
            [2] = 1, -- Heroic
            [3] = 1, -- 10 Player
            [4] = 1, -- 25 Player
            [5] = 1, -- 10 Player (Heroic)
            [6] = 1, -- 25 Player (Heroic)
            [7] = 1, -- Looking For Raid
            [8] = 1, -- Challenge Mode
            [9] = 1, -- 40 Player
            -- 10
            [11] = 1, -- Scenario (Heroic)
            [12] = 1, -- Scenario
            -- 13
            [14] = 1, -- Normal
            [15] = 1, -- Heroic
            [16] = 1, -- Mythic
            [17] = 1, -- Looking For Raid
            [18] = 1, -- Event (raid)
            [19] = 1, -- Event (dungeon)
            [20] = 1, -- Event Scenario
            -- 21-22
            [23] = 1, -- Mythic (party)
            [24] = 1, -- Timewalking
            [25] = 1, -- PvP Scenario
            -- 26-28
            [29] = 1, -- PvEvP Scenario
            [30] = 1, -- Event (scenario)
            -- 31
            [32] = 1, -- World PvP Scenario
            [33] = 1, -- Timewalking
            [34] = 1, -- PvP (pvp)
            -- 35-37
            [38] = 1, -- Normal
            [39] = 1, -- Heroic
            [40] = 1, -- Mythic
            -- 41-44
            [45] = 1, -- PvP (scenario)
        },
        enabledMapID =
        {
            [1] = {}, -- Normal
            [2] = {}, -- Heroic
            [3] = {}, -- 10 Player
            [4] = {}, -- 25 Player
            [5] = {}, -- 10 Player (Heroic)
            [6] = {}, -- 25 Player (Heroic)
            [7] = {}, -- Looking For Raid
            [8] = {}, -- Challenge Mode
            [9] = {}, -- 40 Player
            -- 10
            [11] = {}, -- Scenario (Heroic)
            [12] = {}, -- Scenario
            -- 13
            [14] = {}, -- Normal
            [15] = {}, -- Heroic
            [16] = {}, -- Mythic
            [17] = {}, -- Looking For Raid
            [18] = {}, -- Event (raid)
            [19] = {}, -- Event (dungeon)
            [20] = {}, -- Event Scenario
            -- 21-22
            [23] = {}, -- Mythic (party)
            [24] = {}, -- Timewalking
            [25] = {}, -- PvP Scenario
            [29] = {}, -- PvEvP Scenario
            [30] = {}, -- Event (scenario)
            -- 31
            [32] = {}, -- World PvP Scenario
            [33] = {}, -- Timewalking
            [34] = {}, -- PvP (pvp)
            -- 35-37
            [38] = {}, -- Normal
            [39] = {}, -- Heroic
            [40] = {}, -- Mythic
            -- 41-44
            [45] = {}, -- PvP (scenario)
        },
    },
    global =
    {
        instanceNameByID = {},
    },
};

--- Configuration panel
function A:ConfigurationPanel()
    local panel =
    {
        name = "Broker Logger",
        type = "group",
        childGroups = "tab",
        args =
        {
            options =
            {
                order = 0,
                name = L["Options"],
                type = "group",
                args =
                {
                    auto =
                    {
                        order = 1,
                        name = L["Auto Enable"],
                        type = "group",
                        inline = true,
                        args =
                        {
                            enable =
                            {
                                order = 0,
                                name = L["Enable"],
                                desc = L["With this options enabled it will automatically turn on combat logging when zoning to an enabled instance."],
                                type = "toggle",
                                set = function()
                                    A.db.profile.auto = not A.db.profile.auto;
                                    A:SetAutoLoggingState();
                                end,
                                get = function() return A.db.profile.auto; end
                            },
                        },
                    },
                    instanceType =
                    {
                        order = 10,
                        name = L["Ask for logging when entering"],
                        type = "group",
                        inline = true,
                        args = {},
                    },
                },
            },
            enabledInstance =
            {
                order = 10,
                name = L["Enabled Instances"],
                type = "group",
                args = {},
            },
        },
    };

    local order = 0;
    for i=1,20 do
        local difficultyName, groupType = GetDifficultyInfo(i);

        if ( difficultyName and groupType ) then
            panel.args.options.args.instanceType.args[difficultyName..groupType] =
            {
                order = order,
                name = difficultyName,
                desc = L["With this options enabled it will ask if you want to enable logging when zoning to a new %s instance."]:format(difficultyName.." ("..groupType..")"),
                type = "toggle",
                set = function() A.db.profile.instanceType[i] = not A.db.profile.instanceType[i]; end,
                get = function() return A.db.profile.instanceType[i]; end
            };

            order = order + 1;
        end
    end

    order = 0;
    local order2 = 0;
    for k,v in pairs(A.db.profile.enabledMapID) do
        local difficultyName, groupType = GetDifficultyInfo(k);

        panel.args.enabledInstance.args[difficultyName..groupType] =
        {
            order = order,
            name = difficultyName.." ("..groupType..")",
            type = "group",
            inline = true,
            args = {},
        };

        for kk,vv in pairs(v) do
            panel.args.enabledInstance.args[difficultyName..groupType].args[A.db.global.instanceNameByID[kk] or tostring(kk)] =
            {
                order = order2,
                name = A.db.global.instanceNameByID[kk] or tostring(kk),
                desc = L["Enable auto logging for %s (%s)."]:format(A.db.global.instanceNameByID[kk] or tostring(kk), difficultyName.." ("..groupType..")"),
                type = "toggle",
                set = function(info, val)
                    if ( val ) then
                        A.db.profile.enabledMapID[k][kk] = 1;
                    else
                        A.db.profile.enabledMapID[k][kk] = 0;
                    end
                end,
                get = function() return A:GetVarBool(A.db.profile.enabledMapID[k][kk]); end
            };
            order2 = order2 + 1;
        end

        order = order + 1;
    end

    -- Profiles
    panel.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(A.db);
    panel.args.profile.order = 1000;

    return panel;
end

--[[-----------------------------------------------------------------------------------------------
    Ace3 init
-------------------------------------------------------------------------------------------------]]

--- AceAddon callback
-- Called after the addon is fully loaded
function A:OnInitialize()
    A.db = LibStub("AceDB-3.0"):New("BrokerLoggerDB", defaultDB, true);

    -- LDB
    A.ldb = LibStub("LibDataBroker-1.1"):NewDataObject("Broker Logger",
    {
        type = "data source",
        text = "",
        label = "Logger",
        icon = A.iconDisabled,
        tocname = "Broker_Logger",
        OnClick = function(self, button)
            if ( button == "LeftButton" ) then
                A:ToggleLogging();
            elseif ( button == "RightButton" ) then
                LibStub("AceConfigDialog-3.0"):Open("BrokerLoggerConfig");
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddDoubleLine(A.color["WHITE"].."Broker Logger", A.color["GREEN"].." v"..A.version);
            tooltip:AddLine(" ");

            if ( A.isLogging ) then
                tooltip:AddLine(A.color["GREEN"]..L["Enabled"]);
            else
                tooltip:AddLine(A.color["RED"]..L["Disabled"]);
            end

            tooltip:AddLine(" ");
            tooltip:AddLine(L["|cFFC79C6ELeft-Click:|cFF33FF99 Toggle logging\n|cFFC79C6ERight-Click:|cFF33FF99 Display the configuration panel"]);
        end,
    });
end

--- AceAddon callback
-- Called during the PLAYER_LOGIN event
function A:OnEnable()
    -- Events
    A:RegisterEvent("PLAYER_ENTERING_WORLD");

    -- Hooks
    A:SecureHook("LoggingCombat");

    -- Configuration panel
    LibStub("AceConfig-3.0"):RegisterOptionsTable("BrokerLoggerConfig", A.ConfigurationPanel);
    LibStub("AceConfigDialog-3.0"):SetDefaultSize("BrokerLoggerConfig", 800, 500);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BrokerLoggerConfig", "Broker Logger");
end

--[[-----------------------------------------------------------------------------------------------
    Dev tools
-------------------------------------------------------------------------------------------------]]

-- function A:PrintDifficultyInfos()
    -- for i=1,100 do
        -- print(i, GetDifficultyInfo(i));
    -- end
-- end
