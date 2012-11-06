-- ********************************************************************************
-- Broker Logger (Broker_Logger)
-- Automaticaly enable combat logging when zoning into instances.
-- By: Shenton
--
-- Core.lua
-- ********************************************************************************

-- Ace libs (<3)
local A = LibStub("AceAddon-3.0"):NewAddon("Broker_Logger", "AceEvent-3.0", "AceHook-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("Broker_Logger");

-- ********************************************************************************
-- Variables
-- ********************************************************************************

--- LUA globals to locals
local math, string, pairs, format = math, string, pairs, format;

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
A.instanceTypesTable =
{
    [2] = L["5 Player & Scenario"],
    [3] = L["5 Player (Heroic)"],
    [4] = L["10 Player"],
    [5] = L["25 Player"],
    [6] = L["10 Player (Heroic)"],
    [7] = L["25 Player (Heroic)"],
    [8] = L["Raid Finder"],
    [9] = L["Challenge Mode"],
    [10] = L["40 Player"],
};

-- Icons
A.iconEnabled = "Interface\\ICONS\\INV_Inscription_ParchmentVar02";
A.iconDisabled = "Interface\\ICONS\\INV_Inscription_ParchmentVar01";

-- Static popup
StaticPopupDialogs["BrokerLoggerNewInstance"] = {
	text = L["You have entered:\n\n|cff00ff96%s|r\n|cffc79c6e%s|r\n\nEnable logging for this area?"],
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
        A.db.profile.enabledMapID[self.data.instanceType][self.data.mapID] = 1;
        LoggingCombat(true);
    end,
	OnCancel = function(self)
        A.db.profile.enabledMapID[self.data.instanceType][self.data.mapID] = 0;
	end,
	hideOnEscape = 1,
	timeout = 0,
};

-- ********************************************************************************
-- Functions
-- ********************************************************************************

--- Toggle combat logging
function A:ToggleLogging()
    if ( A.isLogging ) then
        LoggingCombat(false);
    else
        LoggingCombat(true);
    end
end

--- Ask the player if combat log should be enabled in this area
-- @param mapID The current area ID
function A:AskAreaLogging(mapID, instanceType)
    local name = GetMapNameByID(mapID);

    local data =
    {
        instanceType = instanceType,
        mapID = mapID,
    };

    StaticPopup_Show("BrokerLoggerNewInstance", name, A.instanceTypesTable[instanceType], data);
end

--- Get the current map id and return to the current one
function A:GetCurrentMapAreaID()
    local currentMapID = GetCurrentMapAreaID();

    SetMapToCurrentZone();

    local mapID = GetCurrentMapAreaID();

    SetMapByID(currentMapID);

    return mapID;
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

    local instanceType = GetInstanceDifficulty();

    if ( instanceType == 1 ) then return nil; end

    local mapID = A:GetCurrentMapAreaID();

    if ( A.db.profile.enabledMapID[instanceType][mapID] ) then
        if ( A:GetVarBool(A.db.profile.enabledMapID[instanceType][mapID]) ) then return 1; end
    else
        if ( A.db.profile.instanceType[instanceType] ) then A:AskAreaLogging(mapID, instanceType); end
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
            [2] = 1, -- 5 Player & Scenario
            [3] = 1, -- 5 Player (Heroic)
            [4] = 1, -- 10 Player
            [5] = 1, -- 25 Player
            [6] = 1, -- 10 Player (Heroic)
            [7] = 1, -- 25 Player (Heroic)
            [8] = 1, -- Raid Finder
            [9] = 1, -- Challenge Mode
            [10] = 1, -- 40 Player
        },
        enabledMapID =
        {
            [2] = {}, -- 5 Player & Scenario
            [3] = {}, -- 5 Player (Heroic)
            [4] = {}, -- 10 Player
            [5] = {}, -- 25 Player
            [6] = {}, -- 10 Player (Heroic)
            [7] = {}, -- 25 Player (Heroic)
            [8] = {}, -- Raid Finder
            [9] = {}, -- Challenge Mode
            [10] = {}, -- 40 Player
        },
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
                        name = L["instance Types"],
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
    for k,v in pairs(A.instanceTypesTable) do
        panel.args.options.args.instanceType.args[v] =
        {
            order = order,
            name = v,
            desc = L["With this options enabled it will ask if you want to enable logging when zoning to a new %s instance"]:format(v),
            type = "toggle",
            set = function() A.db.profile.instanceType[k] = not A.db.profile.instanceType[k]; end,
            get = function() return A.db.profile.instanceType[k]; end
        };

        order = order + 1;
    end

    order = 0;
    local order2 = 0;
    for k,v in pairs(A.db.profile.enabledMapID) do
        panel.args.enabledInstance.args[A.instanceTypesTable[k]] =
        {
            order = order,
            name = A.instanceTypesTable[k],
            type = "group",
            inline = true,
            args = {},
        };

        for kk,vv in pairs(v) do
            local name = GetMapNameByID(kk);

            panel.args.enabledInstance.args[A.instanceTypesTable[k]].args[name] =
            {
                order = order2,
                name = name,
                desc = L["Enable auto logging for %s (%s)."]:format(name, A.instanceTypesTable[k]),
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
-- Main
-- ********************************************************************************

--- AceAddon callback
-- Called after the addon is fully loaded
function A:OnInitialize()
    A.db = LibStub("AceDB-3.0"):New("BrokerLoggerDB", defaultDB);
end

--- AceAddon callback
-- Called during the PLAYER_LOGIN event
function A:OnEnable()
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
            tooltip:AddLine(L["|cFFC79C6ELeft-Click:|cFF33FF99 Toggle logging\n|cFFC79C6ERight-Click:|cFF33FF99 Display the configuration menu"]);
        end,
    });

    -- Events
    A:RegisterEvent("PLAYER_ENTERING_WORLD");

    -- Hooks
    A:SecureHook("LoggingCombat");

    -- Configuration panel
    LibStub("AceConfig-3.0"):RegisterOptionsTable("BrokerLoggerConfig", A.ConfigurationPanel);
    LibStub("AceConfigDialog-3.0"):SetDefaultSize("BrokerLoggerConfig", 800, 500);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BrokerLoggerConfig", "Broker Logger");
end
