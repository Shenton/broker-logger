-- ********************************************************************************
-- Broker Logger (Broker_Logger)
-- Automaticaly enable combat logging when zoning into instances.
-- By: Shenton
--
-- Core.lua
-- ********************************************************************************

local LibStub = LibStub;

-- Ace libs (<3)
local A = LibStub("AceAddon-3.0"):NewAddon("Broker_Logger", "AceEvent-3.0", "AceHook-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("Broker_Logger");

-- ********************************************************************************
-- Variables
-- ********************************************************************************

-- Globals to locals
-- LUA
local pairs = pairs;
local ipairs = ipairs;
local tostring = tostring;
-- WoW
local LoggingCombat = LoggingCombat;
local PlaySound = PlaySound;
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME;
local StaticPopup_Show = StaticPopup_Show;
local IsInInstance = IsInInstance;
local GetInstanceInfo = GetInstanceInfo;
local YES = YES;
local NO = NO;
--local GetDifficultyInfo = GetDifficultyInfo -- 5.2 = use ##########################


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

-- Instance types table
A.instanceTypesTable = -- 5.2 = delete ###########################################################
{
    [1] = L["5 Player & Scenario"],
    [2] = L["5 Player (Heroic)"],
    [3] = L["10 Player"],
    [4] = L["25 Player"],
    [5] = L["10 Player (Heroic)"],
    [6] = L["25 Player (Heroic)"],
    [7] = L["Raid Finder"],
    [8] = L["Challenge Mode"],
    [9] = L["40 Player"],
};

-- Icons
A.iconEnabled = "Interface\\ICONS\\INV_Inscription_ParchmentVar02";
A.iconDisabled = "Interface\\ICONS\\INV_Inscription_ParchmentVar01";

-- Static popup
StaticPopupDialogs["BrokerLoggerNewInstance"] = {
    text = L["You have entered:\n\n\n|cff00ff96Instance: %s|r\n\n|cffc79c6eDifficulty: %s|r\n\n\nEnable logging for this area?"],
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

-- Database revision number
A.databaseRevision = 2;

-- ********************************************************************************
-- Functions
-- ********************************************************************************

function A:Message(text, color, silent)
    if ( color ) then
        color = A.color["RED"];
    else
        color = A.color["GREEN"]
    end

    if ( not silent ) then
        PlaySound("TellMessage");
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
    if ( var == 1 ) then return 1; end
    return nil;
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

--- Callback for event PLAYER_ENTERING_WORLD
function A:PLAYER_ENTERING_WORLD()
    A.isLogging = LoggingCombat();
    A:Update();
    A:UnregisterEvent("PLAYER_ENTERING_WORLD");
    if ( A.db.profile.auto ) then A:RegisterEvent("ZONE_CHANGED_NEW_AREA"); end
end

--- Callback for hook LoggingCombat()
function A:LoggingCombat(state)
    if ( state == nil ) then return; end
    A.isLogging = state;
    A:Update();
end

--- Callback for event ZONE_CHANGED_NEW_AREA
function A:ZONE_CHANGED_NEW_AREA()
    if ( A:IsLoggingNeeded() ) then
        LoggingCombat(true);
    else
        LoggingCombat(false);
    end

    A:Update();
end

-- ********************************************************************************
-- Configuration
-- ********************************************************************************

--- Default configation table
local defaultDB =
{
    profile =
    {
        auto = 1,
        instanceType =
        {
            [1] = 1, -- 5 Player & Scenario
            [2] = 1, -- 5 Player (Heroic)
            [3] = 1, -- 10 Player
            [4] = 1, -- 25 Player
            [5] = 1, -- 10 Player (Heroic)
            [6] = 1, -- 25 Player (Heroic)
            [7] = 1, -- Raid Finder
            [8] = 1, -- Challenge Mode
            [9] = 1, -- 40 Player
        },
        enabledMapID =
        {
            [1] = {}, -- 5 Player & Scenario
            [2] = {}, -- 5 Player (Heroic)
            [3] = {}, -- 10 Player
            [4] = {}, -- 25 Player
            [5] = {}, -- 10 Player (Heroic)
            [6] = {}, -- 25 Player (Heroic)
            [7] = {}, -- Raid Finder
            [8] = {}, -- Challenge Mode
            [9] = {}, -- 40 Player
        },
    },
    global =
    {
        databaseRevision = 0,
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

                                    if ( A.db.profile.auto ) then
                                        A:RegisterEvent("ZONE_CHANGED_NEW_AREA");
                                    else
                                        A:UnregisterEvent("ZONE_CHANGED_NEW_AREA");
                                    end
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
    for i=1,9 do
        --local difficultyName = GetDifficultyInfo(i); -- 5.2 = use #######################################
        local difficultyName = A.instanceTypesTable[i]; -- 5.2 = delete ############################################

        panel.args.options.args.instanceType.args[difficultyName] =
        {
            order = order,
            name = difficultyName,
            desc = L["With this options enabled it will ask if you want to enable logging when zoning to a new %s instance."]:format(difficultyName),
            type = "toggle",
            set = function() A.db.profile.instanceType[i] = not A.db.profile.instanceType[i]; end,
            get = function() return A.db.profile.instanceType[i]; end
        };

        order = order + 1;
    end

    order = 0;
    local order2 = 0;
    for k,v in pairs(A.db.profile.enabledMapID) do
        --local difficultyName = GetDifficultyInfo(k); -- 5.2 = use #####################################
        local difficultyName = A.instanceTypesTable[k]; -- 5.2 = delete ############################################

        panel.args.enabledInstance.args[difficultyName] =
        {
            order = order,
            name = difficultyName,
            type = "group",
            inline = true,
            args = {},
        };

        for kk,vv in pairs(v) do
            panel.args.enabledInstance.args[difficultyName].args[A.db.global.instanceNameByID[kk] or tostring(kk)] =
            {
                order = order2,
                name = A.db.global.instanceNameByID[kk] or tostring(kk),
                desc = L["Enable auto logging for %s (%s)."]:format(A.db.global.instanceNameByID[kk] or tostring(kk), difficultyName),
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

-- ********************************************************************************
-- Database revision handling
-- ********************************************************************************

-- Is an update needed?
function A:CheckDatabaseRevision()
    if ( A.db.global.databaseRevision < A.databaseRevision ) then
        if ( A.db.global.databaseRevision < 2 ) then
            A:CheckDatabaseRevision2();
        end
    end
end

-- 5.2
-- GetInstanceDifficulty() removed, using GetInstanceInfo() instead, offset by 1 the instance difficulty
-- Using instance map IDs instead of global map IDs, this need a wipe of db
function A:CheckDatabaseRevision2()
    for k,v in ipairs(A.db:GetProfiles()) do
        if ( A.db.profiles[v] ) then
            if ( A.db.profiles[v].instanceType ) then -- this can be saved, offset by 1
                for i=1,9 do
                    A.db.profiles[v].instanceType[i] = A.db.profiles[v].instanceType[i+1];
                end

                A.db.profiles[v].instanceType[10] = nil;
            end

            if ( A.db.profiles[v].enabledMapID ) then -- this can not be saved, wipe
                for i=1,10 do
                    A.db.profiles[v].enabledMapID[i] = nil;
                end
            end
        end
    end

    A.db.global.databaseRevision = 2;
end

-- ********************************************************************************
-- Main
-- ********************************************************************************

--- AceAddon callback
-- Called after the addon is fully loaded
function A:OnInitialize()
    A.db = LibStub("AceDB-3.0"):New("BrokerLoggerDB", defaultDB);

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

    -- Is update needed?
    A:CheckDatabaseRevision();

    -- Configuration panel
    LibStub("AceConfig-3.0"):RegisterOptionsTable("BrokerLoggerConfig", A.ConfigurationPanel);
    LibStub("AceConfigDialog-3.0"):SetDefaultSize("BrokerLoggerConfig", 800, 500);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BrokerLoggerConfig", "Broker Logger");
end
