-- ********************************************************
-- **              Mizus RaidTracker - Core              **
-- **               <http://cosmocanyon.de>              **
-- ********************************************************
--
-- This addon is written and copyrighted by:
--    * Mîzukichan @ EU-Antonidas (2010-2019)
--
-- Contributors:
--    * Kevin (HTML-Export) (2010)
--    * Knoxa (various MoP fixes) (2013)
--    * Kravval (various MoP fixes, enhancements to boss kill detection) (2013)
--
--    This file is part of Mizus RaidTracker.
--
--    Mizus RaidTracker is free software: you can redistribute it and/or
--    modify it under the terms of the GNU General Public License as
--    published by the Free Software Foundation, either version 3 of the
--    License, or (at your option) any later version.
--
--    Mizus RaidTracker is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with Mizus RaidTracker.
--    If not, see <http://www.gnu.org/licenses/>.


-- Check for addon table
if (not ClassicRaidTracker) then ClassicRaidTracker = {}; end
local _L = ClassicRaidTracker._L

-------------------------------
--  Globals/Default Options  --
-------------------------------
MRT_ADDON_TITLE = GetAddOnMetadata("ClassicRaidTracker_Stormforged", "Title");
MRT_ADDON_VERSION = GetAddOnMetadata("ClassicRaidTracker_Stormforged", "Version");
MRT_NumOfCurrentRaid = nil;
MRT_NumOfLastBoss = nil;
MRT_Options = {};
MRT_RaidLog = {};
MRT_PlayerDB = {};
MRT_LastPRImport = nil;
MRT_SFExport = {};
MRT_ArrayBossID = {};
MRT_ArrayBosslast = nil;
MRT_Msg_ID = 1;
MRT_ChannelMsgStore = nil;
MRT_ChannelMsgRequestStore = nil;
MRT_ReadOnly = false;
MRT_ROPlayerPR = {};
MRT_Msg_Request_ID = 1;
MRT_LootBidding = false;
MRT_TopBidders = {
    ["PR"] = nil,
    ["Players"] = {},
    ["Type"] = nil,
    ["History"] = {},
    ["Loot"] = nil,
    ["Lootnum"] = nil,
}
MRT_BagFreeSlots = 0;
MRT_TradeInitiated = false;
MRT_TradeItemsList = {};
MRT_TradePartner = ""; 

MsgEvents = {
    [1] = "Create Raid",
    [2] = "New Loot",
    [3] = "Loot updated",
    [4] = "PR Imported"
};
MRT_MasterLooter = nil;
MRT_RecMsg_Raid = {};

local MRT_Defaults = {
    ["Options"] = {
        ["DB_Version"] = 2,
        ["General_MasterEnable"] = true,                                            -- AddonEnable: true / nil
        ["General_OptionsVersion"] = 13,                                            -- OptionsVersion - Counter, which increases after a new option has been added - if new option is added, then increase counter and add to update options function
        ["General_DebugEnabled"] = false,                                           --
        ["General_SlashCmdHandler"] = "storm",                                      --
        ["General_PrunnRaidLog"] = true,                                           -- Prunning - shall old be deleted after a certain amount of time
        ["General_PrunningTime"] = 90,                                              -- Prunning time, after log shall be deleted (days)
        ["General_ShowMinimapIcon"] = true,                                        --
        ["Attendance_GuildAttendanceCheckEnabled"] = false,                         --
        ["Attendance_GuildAttendanceCheckNoAuto"] = true,                           --
        ["Attendance_GuildAttendanceCheckUseTrigger"] = false,
        ["Attendance_GuildAttendanceCheckTrigger"] = "!triggerexample",
        ["Attendance_GuildAttendanceCheckDuration"] = 3,                            -- in minutes - 0..5
        ["Attendance_GuildAttendanceUseCustomText"] = false,
        ["Attendance_GuildAttendanceCustomText"] = MRT_GA_TEXT_CHARNAME_BOSS,
        ["Attendance_GroupRestriction"] = false,                                    -- if true, track only first 2/5 groups in 10/25 player raids
        ["Attendance_TrackOffline"] = true,                                         -- if true, track offline players
        ["Tracking_Log10MenRaids"] = true,                                          -- Track 10 player raids: true / nil (pre WoD-Raids)
        ["Tracking_Log25MenRaids"] = true,                                          -- Track 25 player raids: true / nil (pre WoD-Raids)
        ["Tracking_LogLFRRaids"] = true,                                            -- Track LFR raids: true / nil (any)
        ["Tracking_LogNormalRaids"] = true,                                         -- Track Normal raids (WoD+)
        ["Tracking_LogHeroicRaids"] = true,                                         -- Track Heroic raids (WoD+)
        ["Tracking_LogMythicRaids"] = true,                                         -- Track Mythic raids (WoD+)
        ["Tracking_LogAVRaids"] = false,                                            -- Track PvP raids: true / nil
        ["Tracking_LogClassicRaids"] = true,                                       -- Track classic raids: true / nil
        ["Tracking_LogBCRaids"] = false,                                            -- Track BC raid true / nil
        ["Tracking_LogWotLKRaids"] = false,                                         -- Track WotLK raid: true / nil
        ["Tracking_LogCataclysmRaids"] = false,                                     -- Track Catacylsm raid: true / nil
        ["Tracking_LogMoPRaids"] = false,                                           -- Track MoP raid: true / nil
        ["Tracking_LogWarlordsRaids"] = false,                                      -- Track Warlords of Draenor raid: true / nil
        ["Tracking_LogLootModePersonal"] = true,
        ["Tracking_AskForDKPValue"] = false,                                         --
        ["Tracking_AskForDKPValuePersonal"] = false,                                 -- ask for points cost when in personal loot mode true/nil - not used when generic option is off
        ["Tracking_MinItemQualityToLog"] = 4,                                       -- 0:poor, 1:common, 2:uncommon, 3:rare, 4:epic, 5:legendary, 6:artifact
        ["Tracking_MinItemQualityToGetDKPValue"] = 4,                               -- 0:poor, 1:common, 2:uncommon, 3:rare, 4:epic, 5:legendary, 6:artifact
        ["Tracking_AskCostAutoFocus"] = 2,                                          -- 1: always AutoFocus, 2: when not in combat, 3: never
        ["Tracking_CreateNewRaidOnNewZone"] = false,                                -- set default to false... bad things happen when true.
        ["Tracking_OnlyTrackItemsAboveILvl"] = 0,
        ["Tracking_UseServerTime"] = false,
        ["ItemTracking_IgnoreEnchantingMats"] = true,
        ["ItemTracking_IgnoreGems"] = true,
        ["ItemTracking_UseEPGPValues"] = true,
        ["ItemTracking_SyncWML"] = false,
        ["Export_ExportFormat"] = 2,                                                -- 1: CTRT compatible, 2: EQdkp-Plus XML, 3: MLdkp 1.5,  4: plain text, 5: BBCode, 6: BBCode with wowhead, 7: CSS based HTML
        ["Export_ExportEnglish"] = false,                                           -- If activated, zone and boss names will be exported in english
        ["Export_CTRT_AddPoorItem"] = false,                                        -- Add a poor item as loot to each boss - Fixes encounter detection for CTRT-Import for EQDKP: true / nil
        ["Export_CTRT_IgnorePerBossAttendance"] = false,                            -- This will create an export where each raid member has 100% attendance: true / nil
        ["Export_CTRT_RLIPerBossAttendanceFix"] = false,
        ["Export_EQDKP_RLIPerBossAttendanceFix"] = false,
        ["Export_DateTimeFormat"] = "%m/%d/%Y",                                     -- lua date syntax - http://www.lua.org/pil/22.1.html
        ["Export_Currency"] = "DKP",
        ["MiniMap_SV"] = {                                                          -- Saved Variables for LibDBIcon
            hide = true,
        },
    },
};

--------------
--  Locals  --
--------------
MRT_DELAY_FIRST_RAID_ENTRY_FOR_RLI_BOSSATTENDANCE_FIX_DATA = 60;

local deformat = LibStub("LibDeformat-3.0");
local LDB = LibStub("LibDataBroker-1.1");
local LDBIcon = LibStub("LibDBIcon-1.0");
local LDialog = LibStub("LibDialog-1.0");
local LBB = LibStub("LibBabble-Boss-3.0");
local LBBL = LBB:GetUnstrictLookupTable();
local LibGP = LibStub("LibGearPoints-1.2-MRT");
local LibSFGP = LibStub("LibSFGearPoints-1.0");
local ScrollingTable = LibStub("ScrollingTable");
local tinsert = tinsert;
local pairs = pairs;
local ipairs = ipairs;

local MRT_TimerFrame = CreateFrame("Frame");                -- Timer for Guild-Attendance-Checks
local MRT_LoginTimer = CreateFrame("Frame");                -- Timer for Login (Wait 10 secs after Login - then check Raidstatus)
local MRT_RaidRosterScanTimer = CreateFrame("Frame");       -- Timer for regular scanning for the raid roster (there is no event for disconnecting players)
local MRT_RIWTimer = CreateFrame("Frame");

local MRT_GuildRoster = {};
local MRT_GuildRosterInitialUpdateDone = nil;
local MRT_GuildRosterUpdating = nil;
local MRT_AskCostQueue = {};
local MRT_AskCostQueueRunning = nil;

local MRT_UnknownRelogStatus = true;


local _, _, _, uiVersion = GetBuildInfo();

-- Vars for API
local MRT_ExternalItemCostHandler = {
    func = nil,
    suppressDialog = nil,
    addonName = nil,
};
local MRT_ExternalLootNotifier = {};

-- Table definition for the drop down menu for the DKPFrame
local MRT_DKPFrame_DropDownTableColDef = {
    {["name"] = "", ["width"] = 100},
};

-- Table for boss yells
-- ToDo: Check if win encounter events in old instances (WotLK and others) are fixed and replace yells with encounter IDs
for k, v in pairs(_L.yells) do
    MRT_L.Bossyells[k] = {}
    for k2, v2 in pairs(v) do
        if (k2 == "Icecrown Gunship Battle Alliance") or (k2 == "Icecrown Gunship Battle Horde") then k2 = "Icecrown Gunship Battle"; end
        MRT_L.Bossyells[k][v2] = k2
    end
end

----------------------
--  RegisterEvents  --
----------------------
function MRT_MainFrame_OnLoad(frame)
    frame:RegisterEvent("ADDON_LOADED");
    frame:RegisterEvent("CHAT_MSG_LOOT");
    frame:RegisterEvent("CHAT_MSG_WHISPER");
    --frame:RegisterEvent("CHAT_MSG_MONSTER_YELL");
    --frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    frame:RegisterEvent("ENCOUNTER_END");
    frame:RegisterEvent("PARTY_INVITE_REQUEST");
    frame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED");
    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("PLAYER_REGEN_DISABLED");
    frame:RegisterEvent("RAID_INSTANCE_WELCOME");
    frame:RegisterEvent("RAID_ROSTER_UPDATE");
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA");
    frame:RegisterEvent("TRADE_SHOW");
    frame:RegisterEvent("TRADE_REQUEST_CANCEL");
    --frame:RegisterEvent("TRADE_CLOSED");
    frame:RegisterEvent("BAG_UPDATE");
    frame:RegisterEvent("MERCHANT_SHOW");
    frame:RegisterEvent("MERCHANT_UPDATE");
    frame:RegisterEvent("CHAT_MSG_ADDON");
    frame:RegisterEvent("CHAT_MSG_RAID");
    frame:RegisterEvent("CHAT_MSG_RAID_LEADER");
end

-------------------------
--  Handler functions  --
-------------------------
-- Event handler
function MRT_OnEvent(frame, event, ...)
    if (event == "ADDON_LOADED") then
        local addonName = ...;
        if (addonName == "ClassicRaidTracker_Stormforged") then
            MRT_Debug("Initializing MRT...");
            frame:UnregisterEvent("ADDON_LOADED");
            MRT_Initialize(frame);
        end

    elseif (event == "CHAT_MSG_LOOT") then
        if (MRT_NumOfCurrentRaid) then
            MRT_AutoAddLoot(...);
        end

    elseif (event == "CHAT_MSG_WHISPER") then
        --use this to handle latest PR request
        --[[ if (not MRT_TimerFrame.GARunning) then return false; end
        local msg, from = ...;
        if ( MRT_Options["Attendance_GuildAttendanceCheckUseTrigger"] and (MRT_Options["Attendance_GuildAttendanceCheckTrigger"] == msg) ) then
            MRT_GuildAttendanceWhisper(from, from);
        elseif (not MRT_Options["Attendance_GuildAttendanceCheckUseTrigger"]) then
            local player = MRT_GuildRoster[string.lower(msg)];
            if (not player) then return; end
            MRT_GuildAttendanceWhisper(player, from);
        end ]]
        --Check to see if there is an active raid.  if not, do nothing.
        ProcessWhisper(...);
    --elseif(event == "CHAT_MSG_RAID") or (event == "CHAT_MSG_RAID_LEADER") or (event == "CHAT_MSG_RAID_WARNING") then
    elseif (event == "CHAT_MSG_RAID") or (event == "CHAT_MSG_RAID_LEADER") then
        --handle raid chat
        --MRT_Debug("RaidMessage received!");
        --MRT_Debug("RaidMessage received: MRT_LootBidding: " ..tostring(MRT_LootBidding));
        local sText = ...;
        
        if MRT_LootBidding then
            local strIndex = strfind(sText, "New Highest");
            if not strIndex then
                if string.len(sText) < 6  then
                    processLootRaidChat(...)
                end
            end
        end

    elseif (event == "CHAT_MSG_MONSTER_YELL") then
        if (not MRT_Options["General_MasterEnable"]) then return end;
        if (not MRT_NumOfCurrentRaid) then return; end
        local monsteryell, sourceName = ...;
		-- local localInstanceInfoName, instanceInfoType, diffID, diffDesc, maxPlayers, _, _, areaID, iniGroupSize = MRT_GetInstanceInfo();
		-- local localInstanceInfoName, instanceInfoType, diffID, diffDesc, maxPlayers, _, _, areaID, iniGroupSize = MRT_GetInstanceInfo();
        local areaID = GetCurrentMapAreaID();
        if (not areaID) then return; end
        if (MRT_L.Bossyells[areaID] and MRT_L.Bossyells[areaID][monsteryell]) then
            MRT_Debug("NPC Yell from Bossyelllist detected. Source was "..sourceName);
            local bossName = LBBL[MRT_L.Bossyells[areaID][monsteryell]] or MRT_L.Bossyells[areaID][monsteryell];
            local NPCID = MRT_ReverseBossIDList[MRT_L.Bossyells[areaID][monsteryell]];
            MRT_AddBosskill(bossName, nil, NPCID);
        end

    elseif (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        if (not MRT_Options["General_MasterEnable"]) then return end;
        MRT_CombatLogHandler(...);

    elseif (event == "MERCHANT_SHOW") then
        ArghEasterEgg();

    elseif (event == "MERCHANT_UPDATE") then
        ArghEasterEgg();
        MRT_Debug("merchant update fired");

    elseif (event == "ENCOUNTER_END") then
        local encounterID, name, difficulty, size, success = ...
        MRT_Debug("ENCOUNTER_END fired! encounterID="..encounterID..", name="..name..", difficulty="..difficulty..", size="..size..", success="..success)
        if (not MRT_Options["General_MasterEnable"]) then return end;
        MRT_EncounterEndHandler(encounterID, name, difficulty, size, success);

    elseif (event == "GUILD_ROSTER_UPDATE") then
        MRT_GuildRosterUpdate(frame, event, ...);

    elseif (event == "PARTY_INVITE_REQUEST") then
        MRT_Debug("PARTY_INVITE_REQUEST fired!");
        if (MRT_UnknownRelogStatus) then
            MRT_UnknownRelogStatus = false;
            MRT_EndActiveRaid();
        end

    elseif (event == "CHAT_MSG_ADDON") then
        local prefix, messageFromAddon, chan, sender, target = ...;
        --MRT_Debug(prefix);
        if prefix == "SFRT" then
           --process message
           --MRT_Debug("SFRT: "..messageFromAddon);
            if MRT_ReadOnly or MRT_Options["ItemTracking_SyncWML"] then -- if readonly mode or syncing enabled handle the incoming message
                MRT_CHAT_MSG_ADDON_Handler(messageFromAddon, chan, sender, target);
            end
        end

    elseif (event == "PLAYER_ENTERING_WORLD") then
        frame:UnregisterEvent("PLAYER_ENTERING_WORLD");
        MRT_LoginTimer.loginTime = time();
        -- Delay data gathering a bit to make sure, that data is available after login
        -- aka: ugly Dalaran latency fix - this is the part, which needs rework
        MRT_LoginTimer:SetScript("OnUpdate", function (self)
            if ((time() - self.loginTime) > 5) then
                if (not MRT_GuildRosterInitialUpdateDone) then
                    MRT_GuildRosterUpdate(frame, nil, true);
                end
                MRT_GuildRosterInitialUpdateDone = true;
            end
            if ((time() - self.loginTime) > 15) then
                MRT_Debug("Relog Timer: 15 seconds threshold reached...");
                self:SetScript("OnUpdate", nil);
                if (MRT_UnknownRelogStatus) then MRT_CheckRaidStatusAfterLogin(); end
                MRT_UnknownRelogStatus = false;
            end
        end);

    elseif (event == "PARTY_LOOT_METHOD_CHANGED") then
        MRT_Debug("Event PARTY_LOOT_METHOD_CHANGED fired.");
        if (not MRT_Options["General_MasterEnable"]) then
            MRT_Debug("MRT seems to be disabled. Ignoring Event.");
            return;
        end;
        MRT_CheckZoneAndSizeStatus();
        --this is old logic, I think.  We don't blanketly set MRT_ReadOnly based on ML anymore.
        --[[  if isMasterLootSet() then
            --get master looter if masterlooter ~= player then set mode to readonly
            --MRT_ReadOnly = not isMasterLooter();
            if isMasterLooter() then
                MRT_ReadOnly = false;
            else
                MRT_ReadOnly = true;
            end
        else
            --if not ML mode, do nothing.
        end ]]
    elseif (event == "TRADE_SHOW") then
        MRT_Debug("Trade initiated");
        MRT_GUIFrame_BossLoot_Trade_Button:SetEnabled(true);
        encourageTrade();
        --MessWArgh();
    elseif (event == "TRADE_REQUEST_CANCEL") then
        if MRT_GUIFrame:IsShown() then
            MRT_Print("Trade Cancelled!")
            MRT_TradeInitiated = false;
        end
        --[[ MRT_Debug("Trade Closed");
        MRT_GUIFrame_BossLoot_Trade_Button:SetEnabled(false);
        local freeSlotsNow = GetBagFreeSlots();
        MRT_Debug("Trade Closed: freeSlotsNow: " ..tostring(freeSlotsNow));
        MRT_Debug("Trade Closed: MRT_BagFreeSlots: " ..tostring(MRT_BagFreeSlots));
        if freeSlotsNow == MRT_BagFreeSlots then
            MRT_Debug("Trade Closed: Free slots same or greater" );
            MRT_Print("Trade cancelled");
        else
            MRT_Debug("Trade Closed: Free slots is less update" );
            stopEncouragingTrade();
            MarkAsTraded();
        end ]]

    --elseif (event == "TRADE_ACCEPT_UPDATE") then
        --[[ MRT_Debug("Trade status changed");
        local playerTradeStatus, targetTradeStatus = ...
        if playerTradeStatus and targetTradeStatus then
          MRT_GUIFrame_BossLoot_Trade_Button:SetEnabled(false);
          stopEncouragingTrade();
          MarkAsTraded();
        end ]]
        
    elseif (event == "BAG_UPDATE") then
        if MRT_TradeInitiated then 
            local freeSlotsNow = GetBagFreeSlots();
            MRT_Debug("Bag_Update: freeSlotsNow: " ..tostring(freeSlotsNow));
            MRT_Debug("Bag_Update: MRT_BagFreeSlots: " ..tostring(MRT_BagFreeSlots));
            if freeSlotsNow > MRT_BagFreeSlots then
                MRT_Debug("Trade worked: Free slots is more update" );
                stopEncouragingTrade();
                MarkAsTraded();
            end
            MRT_TradeInitiated = false;
        end
        MRT_GUI_BossLootTableUpdate(nil, true);

    elseif (event == "RAID_ROSTER_UPDATE") then
        MRT_Debug("RAID_ROSTER_UPDATE fired!");
        if (MRT_UnknownRelogStatus) then
            MRT_UnknownRelogStatus = false;
            MRT_CheckRaidStatusAfterLogin();
        end
        MRT_RaidRosterUpdate(frame);

    elseif (event == "ZONE_CHANGED_NEW_AREA") then
        MRT_Debug("Event ZONE_CHANGED_NEW_AREA fired.");
        if (not MRT_Options["General_MasterEnable"]) then
            MRT_Debug("MRT seems to be disabled. Ignoring Event.");
            return;
        end;
        -- The WoW-Client randomly returns wrong zone information directly after a zone change for a relatively long period of time.
        -- Use the DBM approach: wait 10 seconds after RIW-Event and then check instanceInfo stuff. Hopefully this fixes the problem....
        -- A generic function to schedule functions would be nice! <- FIXME!
        MRT_Debug("Setting up instance check timer - raid status will be checked in 10 seconds.");
        MRT_RIWTimer.riwTime = time();
        MRT_RIWTimer:SetScript("OnUpdate", function (self)
            if ((time() - self.riwTime) > 10) then
                self:SetScript("OnUpdate", nil);
                MRT_CheckZoneAndSizeStatus();
            end
        end);
    elseif(event == "PLAYER_REGEN_DISABLED") then
        wipe(MRT_ArrayBossID)
        --MRT_Debug("Tabelle gelöscht");
    end
end

function processLootRaidChat(text, playerName)
    MRT_Debug("processLootRaidChat fired!");
    local msg = text
    local pName = stripRealmFromName(playerName);
    local lRaidNum
    local isABid, strBidType = isBid(msg)
    local blnNewTop = false;
    local playerPR = nil;

    if isABid then
        --MRT_Debug("processLootRaidChat: isabid");
        --calc bid
        --get raidnum to do modified PR
        --don't use current raid, only use currently selected raid.  This will prevent issues with bidding on a raid while another one is going on.
        --if (MRT_NumOfCurrentRaid) then 
            --lRaidNum = MRT_NumOfCurrentRaid
        --else
        local raid_select = MRT_GUI_RaidLogTable:GetSelection();
        if raid_select then 
            lRaidNum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
        else
            MRT_Print("No Raid selected")
            return
        end 
        --end 
        playerPR = tonumber(getModifiedPR(lRaidNum, pName));
        local Bid = {
            ["Player"] = pName,
            ["PR"] = playerPR,
            ["Type"] = strBidType,
        }
        local msgType;
        if Bid["Type"] == "ms" then
            msgType = "MainSpec"
        else
            msgType = "OffSpec"
        end
        if strBidType == "pass" then
            --remove the bid from history and recalc top bidder
            blnNewTop = UpdateBid(Bid, true)
        else 
            --if bid is os, but msonly then kick it out
            MRT_Debug("processLootRaidChat: checking if os and msonly" );
            if strBidType == "os" and LibSFGP:GetMSOnly(MRT_TopBidders["Loot"]) then 
                --can't bid os on msonly item, do some error message here and return
                SendChatMessage(Bid["Player"].. " bid "..msgType.. ".  OS bid is not allowed on this item.  Bid rejected"  , "Raid");
                return;
            else
                MRT_Debug("processLootRaidChat: not msonly" );
                --if bidder doesn't exist, add to the list, if exists, update bid.
                if isNewBidder(Bid) then
                    tinsert(MRT_TopBidders["History"], Bid)
                    blnNewTop = UpdateTopBidder(Bid)
                    
                else
                    MRT_Debug("processLootRaidChat: not new bidder: find and update" );
                    blnNewTop = UpdateBid(Bid)
                end
                if not blnNewTop then 
                    SendChatMessage(Bid["Player"].. " bid "..msgType.. " PR is "..tostring(Bid["PR"]..".") , "Raid");
                end
                selectPlayer(Bid["Player"], lRaidNum)
            end
        end 
        if blnNewTop then 
            AnnounceBidLeader();
        end
    end
end
function selectPlayer(name, raidnum)
    local PlayerList = MRT_GUI_RaidAttendeesTableUpdate(raidnum)
    local pName
    local lName = string.lower(name)
    if PlayerList then 
        for i = 1, #PlayerList do
            pName = cleanString(PlayerList[i][2]);
            MRT_Debug("selecPlayer: Comparing pName: " ..pName.." and name: " ..lName)
            if pName == lName then
                MRT_Debug("selecPlayer: Player, "..lName.. " found! i: " ..i)
                MRT_GUI_RaidAttendeesTable:SetSelection(i);
                return;
            end
        end
    end
end

function isNewBidder (bid)
    if not MRT_TopBidders["History"] then
        MRT_Debug("isNewBidder: isNewBidder: true" );
        return true;
    else
        for i,v in pairs(MRT_TopBidders["History"]) do
            if v["Player"] == bid["Player"] then
                MRT_Debug("isNewBidder: isNewBidder: false" );
                return false;
            end
        end 
        MRT_Debug("isNewBidder: isNewBidder: true" );
        return true;
    end
end

--Use this function to update the bids in history and update the top bidder
function UpdateBid(bid, remove)
    MRT_Debug("UpdateBid called!");
    local oldTopBid = {
        ["PR"] = MRT_TopBidders["PR"],
        ["Players"] = {},
        ["Type"] = MRT_TopBidders["Type"],
    }
    for i, v in pairs(MRT_TopBidders["Players"]) do
        tinsert(oldTopBid["Players"], v)
    end
    MRT_Debug("UpdateBid: #oldTopBid[Players]: " ..tostring(#oldTopBid["Players"]));
    if not remove then 
        for i,v in pairs(MRT_TopBidders["History"]) do
            if v["Player"] == bid["Player"] then
                v["Type"] = bid["Type"]
                MRT_Debug("UpdateBid: MRT_TopBidders[History][i]: " ..MRT_TopBidders["History"][i]["Type"]);
                --if bid changed, and topplayer is bidder, then remove the top player.
                if isPlayerTop(bid["Player"]) then
                    MRT_Debug("UpdateBid: player passing is top bidder, remove");
                    removePlayerTop(bid["Player"])
                    MRT_Debug("UpdateBid: after removePlayerTop: #oldTopBid[Players]: " ..tostring(#oldTopBid["Players"]));
                end 
            end
            
        end
    else
        --call if someone passes
        MRT_Debug("UpdateBid bidtype is pass");
        for i,v in pairs(MRT_TopBidders["History"]) do
            if v["Player"] == bid["Player"] then
                MRT_Debug("UpdateBid: v:[Player]: "..v["Player"].. ", bid[Player]: " ..bid["Player"]);
                MRT_Debug("UpdateBid: removing bid from history");
                tremove(MRT_TopBidders["History"], i)
                MRT_Debug("UpdateBid: #MRT_TopBidders[History]: " ..tostring(#MRT_TopBidders["History"]));
            end
        end 
        if isPlayerTop(bid["Player"]) then
            MRT_Debug("UpdateBid: player passing is top bidder, remove");
            removePlayerTop(bid["Player"])
            MRT_Debug("UpdateBid: after removePlayerTop: #oldTopBid[Players]: " ..tostring(#oldTopBid["Players"]));
        end
    end
    --now update TopBidder
    MRT_Debug("UpdateBid: updating TopBidder");
    MRT_Debug("UpdateBid: #MRT_TopBidders[History]: " ..tostring(#MRT_TopBidders["History"]));
    for i, v in pairs(MRT_TopBidders["History"]) do
        MRT_Debug("UpdateBid: v[Player]: " ..v["Player"]);
        local topbidderupdated = false
        topbidderupdated = UpdateTopBidder(v)
        MRT_Debug("UpdateBid: tobidderupdated: " ..tostring(topbidderupdated));
    end
    if (oldTopBid["PR"] == MRT_TopBidders["PR"]) and topBiddersMatch(oldTopBid["Players"], MRT_TopBidders["Players"]) and (oldTopBid["Type"] == MRT_TopBidders["Type"]) then
        MRT_Debug("UpdateBid: oldTopBid match current top");
        return false
    else 
        MRT_Debug("UpdateBid: oldTopBid doesn't match return true");
        return true
    end
end
--return if a player is in the top bidders list

function topBiddersMatch (old, new)
    MRT_Debug("TopBidderMatch Called!");
    MRT_Debug("TopBidderMatch: #old: " ..tostring(#old).. ", #new: " ..tostring(#new));
    if #old ~= #new then
        return false
    end
    for i,v in ipairs(old) do
        if old[i] ~= new[i] then
            return false;
        end
    end
    return true;
end 
function isPlayerTop(name)
    MRT_Debug("isPlayerTop: MRT_TopBidders[Players]: " ..tostring(#MRT_TopBidders["Players"]));
    
    for i,v in pairs(MRT_TopBidders["Players"]) do
        MRT_Debug("isPlayerTop: name: " ..name.. ", v: " ..v);
        if name == v then
            MRT_Debug("isPlayerTop: name matches in top player table");
            return true
        end
    end
    MRT_Debug("isPlayerTop: does not match top player, return false");
    return false
end

function removePlayerTop(name)
    MRT_Debug("removePlayerTop called!");
    for i,v in pairs(MRT_TopBidders["Players"]) do
        if name == v then
            MRT_Debug("removePlayerTop: name: " ..name.. ", v: " ..v);
            tremove(MRT_TopBidders["Players"], i);
            MRT_Debug("removePlayerTop: #MRT_TopBidders[Players]: " ..tostring(#MRT_TopBidders["Players"]));
            if #MRT_TopBidders["Players"] == 0 then 
                MRT_Debug("removePlayerTop: resetting type and PR ");
                MRT_TopBidders["Type"] = nil;
                MRT_TopBidders["PR"] = 0;
            end
        end
    end
end 

function UpdateTopBidder(bid)
    local strBidType, playerPR, pName = bid["Type"], bid["PR"], bid["Player"]
    MRT_Debug("UpdateTopBidder: strBidType: " ..strBidType.. ", playerPR: " ..tostring(playerPR)..", pName: " ..pName);
    local blnNewTop = false;
    --check if top bidder type is set
    if not MRT_TopBidders["Type"] then
        MRT_Debug("processLootRaidChat: setting BidType: " ..strBidType);
        MRT_TopBidders["Type"] = strBidType
        MRT_Debug("processLootRaidChat: MRT_TopBidders[Type]: " ..MRT_TopBidders["Type"]);
    else 
        --check if top bidder is ms
        if (MRT_TopBidders["Type"] == "ms") then
            MRT_Debug("UpdateTopBidder: TopBidders'type' == ms");
            if strBidType == "os" then 
                MRT_Debug("UpdateTopBidder: new bid is os");
                --stop and return if new bid is os, but top bidder is ms
                if isPlayerTop(pName) then 
                    --TODO there is a bug where if the person swaps from MS to OS it doesn't recheck the folks further
                    --check history... if ms exists, then new top bidder, if not, proceed.
                    MRT_Debug("UpdateTopBidder: old bid is ms, new bid is os, same player on top, so update.");
                    if MSinBidHistory() then 
                        blnNewTop = true;
                    else
                        MRT_TopBidders["Type"] = "os"
                        blnNewTop = true;    
                    end 
                else
                    --Added case where it's a OS bid of non 0 PR against a MS zero bid. New raiders never trump existing.
                    if (playerPR > 0) and (MRT_TopBidders["PR"] == 0) then
                       MRT_Debug("Non zero OS bid trumps 0 MS.");
                       MRT_TopBidders["Type"] = "os" 
                       blnNewTop = true;
                    else
                        return false
                    end
                end 
            end
        else 
            --MRT_TopBidders["Type"] == "os"
            --Top bid is os, check to see if new bid is ms
            if (strBidType == "ms") then
             --Added case where it's a MS bid of 0 PR against an OS non zero bid. New raiders never trump existing.
             if  playerPR > 0 then
                    MRT_TopBidders["Type"] = "ms"
                    blnNewTop = true;
                else
                    MRT_Debug("UpdateTopBidder: MS bid of zero doesn't beat non-zero OS bid.");
                    return false
                end
            end
        end 
    end
     
    if #MRT_TopBidders["Players"] == 0 then
        MRT_TopBidders["PR"] = playerPR
        tinsert(MRT_TopBidders["Players"], pName);
        blnNewTop = true
    else
        if blnNewTop then
            MRT_TopBidders["PR"] = playerPR;
            MRT_TopBidders["Players"] = {};
            tinsert(MRT_TopBidders["Players"], pName)
        else 
            MRT_Debug("UpdateTopBidder: bid['Type']: "..bid["Type"].. " MRT_TopBIdders['Type']: " ..MRT_TopBidders["Type"]);
            if bid["Type"] == "ms" and MRT_TopBidders["Type"] == "os" then
                MRT_Debug("UpdateTopBidder: Special case called!");
                MRT_TopBidders["PR"] = playerPR;
                MRT_TopBidders["Players"] = {};
                tinsert(MRT_TopBidders["Players"], pName)
                blnNewTop = true
            else 
                if playerPR > MRT_TopBidders["PR"] then
                    MRT_TopBidders["PR"] = playerPR;
                    MRT_TopBidders["Players"] = {};
                    tinsert(MRT_TopBidders["Players"], pName);
                    blnNewTop = true
                elseif playerPR == MRT_TopBidders["PR"] then
                    if isPlayerTop(pName) then 
                        blnNewTop = false
                    else
                        tinsert(MRT_TopBidders["Players"], pName);
                        blnNewTop = true
                    end 
                else
                    blnNewTop = false
                end
            end
        end
    end
    return blnNewTop;
end 
function MSinBidHistory()
    local found = false
    for i,v in pairs(MRT_TopBidders["History"]) do
        if v["Type"] == "ms" then
            MRT_Debug("MSinBidHistory: ms bid found" );
            found = true;
        end
    end 
    return found;
end
function AnnounceBidLeader()
    local messageType = "Raid"
    local rwMessage
    local strBidType 
    
    if MRT_TopBidders["Type"] == "os" then 
        strBidType = "OffSpec"
    else
        strBidType = "MainSpec"
    end
    if MRT_TopBidders["Type"] then 
        if #MRT_TopBidders["Players"] == 1 then 
            rwMessage = string.format(MRT_L.GUI["BidLeaderMessage"], MRT_TopBidders["Players"][1], MRT_TopBidders["PR"], strBidType);
        else
            local sPlayers = ""
            for i, v in ipairs(MRT_TopBidders["Players"]) do
                if sPlayers == "" then 
                    sPlayers = v
                else
                    sPlayers = sPlayers.. ", "..v;
                end 
            end
            rwMessage = string.format(MRT_L.GUI["BidLeaderMessage"], sPlayers, MRT_TopBidders["PR"], strBidType);        
        end
    else
        rwMessage = "There is currently no bid leader."
    end
    SendChatMessage(rwMessage, messageType);
end 

function isBid(text)
    local bid = string.lower(text);
    --if bid == os or ms do a thing
    local intMSIndex = strfind(bid, "ms");
    local intOSIndex = strfind(bid, "os");
    local intPass = strfind(bid, "pass")
    if intMSIndex and intOSIndex then
        return false;
    end
    if intMSIndex then
        return true, "ms"
    elseif intOSIndex then
        return true, "os"
    elseif intPass then
        return true, "pass"
    else
        return false
    end

end

function MarkAsTraded()

    MRT_Debug("Checking for items to mark traded")

    --Get name of player with an open trade window
    --local tradePartnerName = UnitName("NPC");
    --local itemsToTrade = {};

    -- check if a raid is selected
    local raidnum = GetSelectedRaid();
    if not raidnum then
        return
    end

    --check for all the items that are being traded
    --for j=1, 7 do
        --local tradedItemName, texture, quantity, quality, isUsable, enchant =  GetTradePlayerItemInfo(j);
    for i2, v2 in pairs(MRT_TradeItemsList) do
        --if tradedItemName then
          --MRT_Debug("Checking if this item should be marked traded: "..tradedItemName
        --end
        --iterate through all the items in the raid log to see if it's an item that dropped being traded to it's new owner.
        for i, v in ipairs(MRT_RaidLog[raidnum]["Loot"]) do
            if v["Looter"] == MRT_TradePartner then
                if v2 == v["ItemName"] then
                 MRT_Debug(MRT_TradePartner.. " has been traded "..v2);
                  v["Traded"] = true;
                end
            end
        end
    end

    --Refresh the Loot UI
    MRT_TradePartner = "";
    MRT_TradeItemsList = {};
end
function MRT_CHAT_MSG_ADDON_Handler(msg, channel, sender, target)
    --if debugging, change ML in getMasterLooter()
    local strML = getMasterLooter();
    MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: MasterLooter is " ..strML)
    MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: got message from " ..channel.. " from "..sender)
    MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: msg: " .. msg)
    local sName = stripRealmFromName(sender)
    if sName == UnitName("player") then 
        MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: got a message from me do nothing!") 
        return
    end
    if (string.lower(sName) ~= string.lower(strML)) and (channel == "RAID") then 
         -- if message is sent to RAID channel and is not ML, ignore
         MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: not ML or RAID")
    else
        local tbMsg = deserializeAddonMessage(msg);
        MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: tbMsg RaidID = "..tbMsg["RaidID"].. " ID: " ..tbMsg["ID"].. " Time: " ..tbMsg["Time"].. " Data: " .. tbMsg["Data"].. " EventID: " ..tbMsg["EventID"])
        --We need to validate which raid this message belongs to.
        --Scenarios we need to consider...
        --1. Client has created a new raid, match ML's raid to this one.
        --2. Client doesn't have an active raid, message recieved from ML, create new raid and map new messages to this raid
        if channel == "RAID" then
            MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: Inside raid message check")
            if not (MRT_ChannelMsgStore) then
                MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: channel store needs to be updated.")
                MRT_ChannelMsgStore = {};
                MRT_ChannelMsgStore[tbMsg["RaidID"]] = {};
            end
            MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: Adding msg to the channel store.")
            addChannelMessageToStore(tbMsg);
            --Event 3 is the new loot message
            if tbMsg["EventID"] == "3" then
                MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: EventID = 3")
                local playerName, strData = getToken(tbMsg["Data"], ";");
                local itemLink, itemCount = getToken(strData, ";");
                MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: playerName: "..playerName.. " itemLink: "..itemLink)
                MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: playerName: itemCount: " ..itemCount)
                GetItemInfo(itemLink); --cache iteminfo
                MRT_AutoAddLootItem(playerName, itemLink, itemCount);
                MRT_GUI_BossDetailsTableUpdate();
            end
            --Event 4 is loot modified message
            if tbMsg["EventID"] == "4" then
                MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: EventID = 4")
                --create channel message data here.  bossnum;lootnum;itemLink;Looter;cost;lootNote;offspec, eventid=4
                local bossnum, strData = getToken(tbMsg["Data"], ";");
                local lootnum, strData = getToken(strData, ";");
                local raid_select = MRT_GUI_RaidLogTable:GetSelection();
                if raid_select then 
                    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
                end
                if not MRT_NumOfCurrentRaid then
                    strRaidNum = raidnum
                else
                    strRaidNum = MRT_NumOfCurrentRaid
                end
                MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: bossnum: "..bossnum.. " lootnum: "..lootnum)
                MRT_GUI_LootModifyAccept(strRaidNum, tonumber(bossnum), tonumber(lootnum), strData);
            end
            --Event 5 is PR imported
            if tbMsg["EventID"] == "5" then
                MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: EventID = 5")
                local strData = tbMsg["Data"];
                local strRaidNum;
                ProcessROPlayerPR(strData);
                --testing use get current raid.
                local raid_select = MRT_GUI_RaidLogTable:GetSelection();
                if raid_select then 
                    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
                end
                if not MRT_NumOfCurrentRaid then
                    strRaidNum = raidnum
                else
                    strRaidNum = MRT_NumOfCurrentRaid
                end
                MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: EventID = 5: strRaidNum: "..strRaidNum) ;
                MRT_GUI_RaidAttendeesTableUpdate(strRaidNum);
            end
            --process messages here
        elseif channel == "WHISPER" then
            --Handle Whisper request
            if tbMsg["EventID"] == "1" then
                MRT_Debug("MRT_CHAT_MSG_ADDON_Handler:WHISPER: EventID = 1")
                --testing use get current raid.
                if not(MRT_NumOfCurrentRaid) then
                    raid_select = MRT_GUI_RaidLogTable:GetSelection();
                    if not raid_select then
                        MRT_GUI_RaidLogTable:SetSelection(1)
                        raid_select = MRT_GUI_RaidLogTable:GetSelection();
                        MRT_GUI_RaidLogTable:ClearSelection()
                    end
                    --MRT_Debug("doPRReply: raid_select: " .. raid_select);
                    strRaidNum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
                else
                    strRaidNum = MRT_NumOfCurrentRaid
                end
                MRT_Debug("MRT_CHAT_MSG_ADDON_Handler:WHISPER: EventID = 1: strRaidNum: "..strRaidNum);
                local RaidAttendees = MRT_GUI_RaidAttendeesTableUpdate(strRaidNum);
                --create data
                if isMasterLooter() then 
                    MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: MasterLooter send message");
                    SendPRMsg(RaidAttendees, channel, sender);
                    -- send message to addon channel with new loot message
                else
                    MRT_Debug("MRT_CHAT_MSG_ADDON_Handler:WHISPER: EventID = 1")
                    local strData = tbMsg["Data"];
                    local strRaidNum;
                    ProcessROPlayerPR(strData);
                    --testing use get current raid.
                    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
                    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
                    if not MRT_NumOfCurrentRaid then
                        strRaidNum = raidnum
                    else
                        strRaidNum = MRT_NumOfCurrentRaid
                    end
                    MRT_Debug("MRT_CHAT_MSG_ADDON_Handler: EventID = 1: strRaidNum: "..strRaidNum) ;
                    MRT_GUI_RaidAttendeesTableUpdate(strRaidNum);
                end
            end
        end
    end
    -- check other message here, like WHISPER
end

function stripRealmFromName(playerName)
    return getToken(playerName, "-")
end

function addChannelMessageToStore(msg)
    if not MRT_ChannelMsgStore[msg["RaidID"]] then
        MRT_ChannelMsgStore[msg["RaidID"]] = {};
    end
    if not isAddOnMessageInStore(msg) then
        tinsert(MRT_ChannelMsgStore[msg["RaidID"]], msg);
    end
end

function isAddOnMessageInStore(msg)
    if MRT_ChannelMsgStore[msg["RaidID"]] then 
        for i,v in pairs(MRT_ChannelMsgStore[msg["RaidID"]]) do
            if v["ID"] == msg["ID"] then
                return true
            end
        end 
    end
    return false
end

function deserializeAddonMessage(msg)
    local strList = msg;
    local strTruncList
    local tblMsg = {};
    -- msg["RaidID"]..","..msg["ID"]..","..msg["Time"]..","..msg["Data"]..",",msg["EventID"]
    tblMsg["RaidID"], strTruncList = getToken(strList, ",");
    tblMsg["ID"], strTruncList = getToken(strTruncList, ",");
    tblMsg["Time"], strTruncList = getToken(strTruncList, ",");
    tblMsg["Data"], strTruncList = getToken(strTruncList, ",")
    tblMsg["EventID"] = strTruncList;
    return tblMsg;
end

function getToken(strList, strDelim)
    local index = substr(strList, strDelim);
    if not index then
        return strList, ""
    end
    local truncList = strsub(strList, index + 1);
    local sTok = strsub(strList, 1, index - 1);
    return sTok, truncList;
end

function ArghEasterEgg()
    if not (UnitName("player")=="Arghkettnaad") then
      return;
    end
    --MRT_Debug("Merchant Window Opened: "..UnitName("player"));
    --MRT_Debug("Free Slots: ".. countEmptyBagSlots());

    local merchantSellsHammers = checkIfMerchantSellsHammers();
    if (merchantSellsHammers == -1) then 
        MRT_Debug("The merchant doesn't sell hammers");
        return;  -- no hammers
    end

    if countEmptyBagSlots() > 0 then
        BuyMerchantItem(merchantSellsHammers);
    end
end

function countEmptyBagSlots()

    local freeSlots =0;
    for bagID=0, 5 do
        local singleBagFreeSlots, BagType = GetContainerNumFreeSlots(bagID);
        freeSlots = freeSlots + singleBagFreeSlots;
    end

    return freeSlots;
end

function checkIfMerchantSellsHammers()

    local merchantInventoryCount = GetMerchantNumItems();

    for inventoryIndex=0, merchantInventoryCount do
        local merchantItemName = GetMerchantItemInfo(inventoryIndex)
        if (merchantItemName == "Blacksmith Hammer") then
            return inventoryIndex
        end
    end
    return -1;
end


local SupressMsg = {}
function ProcessWhisper(text, playerName)
    --if text:gsub("^%s*(.-)%s*$", "%1") == AutoInviteSettings.AutoInviteKeyword then
    local stext = text:gsub("^%s*(.-)%s*$", "%1")
    --MRT_Debug("Process Whisper: stext: " ..stext);
    local prefix = strsub(stext, 1, 5)
    local nopunc
    local numstripped = 0;
    nopunc, numstripped = string.gsub(prefix,"%p", "")
    --MRT_Debug("Process Whisper: numstripped: " ..numstripped);
    local sCom = strsub(nopunc,1,4);
    local sParams = strsub(stext,6 + numstripped)
    --MRT_Debug("Process Whisper: sCom: " ..sCom);
    --MRT_Debug("Process Whisper: sParams: " ..sParams);
    if string.lower(sCom) == string.lower ("epgp") then
        --SendChatMessage("What!?", "WHISPER",nil ,playerName);
        if sParams == "?" then
            local sendMsg = "usage: epgp (return your PR)"
            tinsert(SupressMsg, sendMsg);
            SendChatMessage(sendMsg, "WHISPER", nil, playerName);
            --[[ sendMsg = "usage: epgp healers (or melee/casters)"
            SendChatMessage(sendMsg, "WHISPER", nil, playerName);
            tinsert(SupressMsg, sendMsg);
            sendMsg = "usage: epgp druids (or warriors/hunters, etc...)"
            SendChatMessage(sendMsg, "WHISPER", nil, playerName);
            tinsert(SupressMsg, sendMsg);
            sendMsg = "usage: epgp scrapper (or hokie/moncholyg, etc...)"
            SendChatMessage(sendMsg, "WHISPER", nil, playerName);
            tinsert(SupressMsg, sendMsg);
            sendMsg = "usage: epgp all (this might be throttled)"
            SendChatMessage(sendMsg, "WHISPER",nil , playerName);
            tinsert(SupressMsg, sendMsg); ]]
        else
            doPRReply(playerName, sParams);
        end
	end
end
function doPRReply(playerName, sParams)
    local RaidAttendees = nil;
    local raid_select = nil;
    local filter = nil;
    local raidnum;
    --MRT_Debug("Process Whisper: MRT_NumOfCurrentRaid: " ..MRT_NumOfCurrentRaid);
    if not(MRT_NumOfCurrentRaid) then
        raid_select = MRT_GUI_RaidLogTable:GetSelection();
        if not raid_select then
            MRT_GUI_RaidLogTable:SetSelection(1)
            raid_select = MRT_GUI_RaidLogTable:GetSelection();
            MRT_GUI_RaidLogTable:ClearSelection()
        end
        --MRT_Debug("doPRReply: raid_select: " .. raid_select);
        raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    else
        raidnum = MRT_NumOfCurrentRaid
    end
    --MRT_Debug("doPRReply: raidnum " ..raidnum);
    --local allIndex = substr(sParams, "all")
    
    --if (allIndex) then
        --strip out all, it's special for whisper
        --MRT_Debug("doPRReply: stripping :all sParams: " ..sParams);
      --  local allGone = strsub(sParams,1,allIndex-1)..strsub(sParams,allIndex+4);
      --  filter = applyFilterSyntax(allGone)
        --[[ if not filter then
            MRT_Debug("doPRReply: stripping :filter: nil");
        else     
            MRT_Debug("doPRReply: stripping :filter: " ..filter);
            MRT_Debug("doPRReply: stripping :len (filter): " ..strlen(filter));
        end ]]
    --else
        --MRT_Debug("doPRReply: default path");
        --TODOif we see a class name or class group, add a ":"

        --filter = applyFilterSyntax(sParams)
    --end
    --if not(sParams) or sParams == "" then
        --MRT_Debug("doPRReply: no sParam");
        --strip off realmname from player
        local realmIndex = substr(playerName, "-");
        if realmIndex then
            filter = strsub(playerName, 1, realmIndex - 1);
        else 
            filter = playerName
        end
        --MRT_Debug("doPRReply: filter: "  ..filter.. " strlen(filter): " ..strlen(filter));
    --end
    --MRT_Debug("doPRReply: raid_select: " ..raid_select);
    --MRT_Debug("doPRReply: raidnum: " ..raidnum);
    
    if (raidnum) then 
        RaidAttendees = MRT_GUI_RaidAttendeesTableUpdate(raidnum, filter, true)
        --MRT_Debug("doPRReply: raidnum valid");
        --[[ if (RaidAttendees) then
            MRT_Debug("doPRReply: RaidAttendees returned");
        end ]]
        table.sort(RaidAttendees, function (a, b)
            if a[3] > b[3] then
                    return true;
            else
                    return false;
            end
        end)
    end
    
    if (RaidAttendees) and table.maxn(RaidAttendees) > 0 then 
        --MRT_Debug("doPRReply: RaidAttendee returned and count > 0");
        --SendChatMessage("Player Name PR", "WHISPER", _, playerName);
        local msgTable = {};
        --build table
        tinsert(msgTable, "Player PR");
        for i, v in ipairs(RaidAttendees) do
            tinsert(msgTable, cleanString(v[2], true).." "..cleanPR(v[3]));
        end
        local largestLen = getLargestStrLen(msgTable);
        --send tell
        for i, v in ipairs(msgTable) do
            local strMessage
            MRT_Debug("doPRReply: i: " ..i);
            MRT_Debug("doPRReply: v: "..v);
            strMessage = format2Table(v, largestLen);
            SendChatMessage(strMessage, "WHISPER", nil, playerName);
            --MRT_ChatHandler.MsgToBlock = strMessage;
            tinsert(SupressMsg, strMessage);
            strMessage = "";
        end
    else
        strMessage = "PR info not available or you don't have PR info in Master Looter's raid.  epgp ? for help";
        tinsert(SupressMsg, strMessage);
        SendChatMessage(strMessage, "WHISPER", nil, playerName);
    end
end
function cleanPR (PR)
    if PR == "0.00" then
        return "0"
    else 
        return PR
    end 

end 
function applyFilterSyntax(sText)
    local filtertype = {
        ["warrior"] = ":warrior",
        ["warriors"] = ":warrior",
        ["priest"] = ":priest",
        ["priests"] = ":priest",
        ["warlock"] = ":warlock",
        ["warlocks"] = ":warlock",
        ["druid"] = ":druid",
        ["druids"] = ":druid",
        ["hunter"] = ":hunter",
        ["hunters"] = ":hunter",
        ["rogue"] = ":rogue",
        ["rogues"] = ":rogue",
        ["paladin"] = ":paladin",
        ["paladins"] = ":paladin",
        ["mage"] = ":mage",
        ["mages"] = ":mage",
        ["shaman"] = ":shaman",
        ["shamans"] = ":shaman",
        ["healer"] = ":healer",
        ["healers"] = ":healers",
        ["caster"] = ":caster",
        ["casters"] = ":casters",
        ["ranged"] = ":ranged",
        ["melee"] = ":melee",
    }
    local retVal;
    retVal = filtertype[string.lower(sText)];
    if retVal then
        return retVal;
    else
        return sText;
    end
end

function getLargestStrLen(msgTable)
    --MRT_Debug("getLargestStrLen: Called!");
    --return the largetst string length
    local largestLength = 0
    for i, v in ipairs(msgTable) do
        --MRT_Debug("getLargestStrLen: i: " ..i);
        --MRT_Debug("getLargestStrLen: v: "..v);
        if strlen(v) > largestLength then
            largestLength = strlen(v);
        end
    end
    --MRT_Debug("getLargestStrLen: largestLength: " ..largestLength);
    return largestLength;
end
function format2Table(message, largeLength)
    local indexOfSpace = strfind(message," ");
    local newString
    local endString = strsub(message,indexOfSpace+1);
    --start PR at largestLength
    newString = strsub(message,1,indexOfSpace);
    --local newlength = ((largeLength* 3.14) - (strlen(message)*.85)) *.75
    local dotlen = largeLength - strlen(endString) - strlen(newString)

    
    --[[ for i = 1, (newlength - indexOfSpace) do
        newString = newString.."."
    end ]]
    dotlen = dotlen + (countLetters(newString, "i")*4) + (countLetters(newString, "l") *5) + countLetters(newString, "t") + countLetters(newString, "r") - (countLetters(newString, "W")*2) - countLetters(newString, "w") - (countLetters(newString, "M")*2) - (countLetters(newString, "m")*2)
    
    if dotlen < 0 then
        dotlen = 2
    end
    for i = 1, dotlen do
        newString = newString..".";
    end
    newString = newString..endString;
    --MRT_Debug("format2Table: newString: " ..newString .. " len(newString) : " ..strlen(newString));
    --MRT_Debug("format2Table: dotlen : " ..dotlen);
    return newString
end 

function countLetters(base, pattern)
    return select(2, string.gsub(base, pattern, ""))
end
function MRT_PrintGR()
    local concatTable = "";
    for key, val in pairs(MRT_GuildRoster) do
        concatTable = concatTable..val..", ";
    end
    --MRT_Debug(concatTable);
end

-- Combatlog handler
function MRT_CombatLogHandler(...)
    local _, combatEvent, _, _, _, _, _, destGUID, destName, _, _, spellID = ...;
    if (not MRT_NumOfCurrentRaid) then return; end
    if (combatEvent == "UNIT_DIED") then
        local englishBossName;
        local localBossName = destName;
        local NPCID = MRT_GetNPCID(destGUID);
        --MRT_Debug("localBossName: "..localBossName.." - NPCID: "..NPCID);
        if (MRT_BossIDList[NPCID]) then
            MRT_Debug("Valid NPCID found... - Match on "..MRT_BossIDList[NPCID]);
            localBossName = LBBL[MRT_BossIDList[NPCID]] or MRT_BossIDList[NPCID];
            if(MRT_ArrayBossIDList[MRT_BossIDList[NPCID]]) then
                local count = 0;
                local bosses = getn(MRT_ArrayBossIDList[MRT_BossIDList[NPCID]]);
                MRT_ArrayBossID[NPCID] = NPCID;
                MRT_Debug("Tabelle erweitert um "..NPCID);
                for key, val in pairs(MRT_ArrayBossID) do
                    if(tContains(MRT_ArrayBossIDList[MRT_BossIDList[NPCID]], val)) then
                        count = count +1;
                    end
                end
                if (bosses == count) then
                    if (MRT_ArrayBosslast ~= localBossName) then
                        MRT_AddBosskill(localBossName, nil, NPCID);
                    end
                end
            else
                MRT_AddBosskill(localBossName, nil, NPCID);
            end
        end
    end
    if (combatEvent == "SPELL_CAST_SUCCESS") then
        -- MRT_Debug("SPELL_CAST_SUCCESS event found - SpellID is " .. spellID);
    end
    if (combatEvent == "SPELL_CAST_SUCCESS" and MRT_BossSpellIDTriggerList[spellID]) then
        MRT_Debug("Matching SpellID in trigger list found - Processing...");
        -- Get NPCID provided by the constants file
        local NPCID = MRT_BossSpellIDTriggerList[spellID][2]
        -- Get localized boss name, if available - else use english one supplied in the constants file
        local localBossName = LBBL[MRT_BossSpellIDTriggerList[spellID][1]] or MRT_BossSpellIDTriggerList[spellID][1];
        MRT_AddBosskill(localBossName, nil, NPCID);
    end
end

function MRT_EncounterEndHandler(encounterID, name, difficulty, size, success)
    if (not MRT_NumOfCurrentRaid) then return; end
    if ((success == 1) and (MRT_EncounterIDList[encounterID])) then
        MRT_Debug("Valid encounterID found... - Match on "..MRT_EncounterIDList[encounterID]);
        MRT_AddBosskill(name, nil, MRT_EncounterIDList[encounterID]);
    end
end

-- Slashcommand handler
function MRT_SlashCmdHandler(msg)
    local msg_lower = string.lower(msg);
    if (msg_lower == 'options' or msg_lower == 'o') then
        InterfaceOptionsFrame_OpenToCategory("Classic RaidTracker_Stormforged");
        return;
    elseif (msg_lower == 'dkpcheck') then
        MRT_AddBosskill(MRT_L.Core["GuildAttendanceBossEntry"]);
        MRT_StartGuildAttendanceCheck("_attendancecheck_");
        return;
    elseif (msg_lower == 'deleteall now') then
        MRT_DeleteRaidLog();
        return;
    elseif (msg_lower == 'snapshot') then
        MRT_TakeSnapshot();
        return;
    elseif (msg_lower == '') then
        MRT_GUI_Toggle();
        return;
    elseif (msg_lower == 'dkpframe') then
        if (MRT_GetDKPValueFrame:IsShown()) then
            MRT_GetDKPValueFrame:Hide();
        else
            MRT_GetDKPValueFrame:Show();
        end
        return;
    elseif (string.match(msg, 'additem')) then
        local itemLink, looter, cost = string.match(msg, 'additem%s+(|c.+|r)%s+(%a+)%s+(%d*)');
        if (not itemLink) then
            itemLink, looter = string.match(msg, 'additem%s+(|c.+|r)%s+(%a+)');
            cost = 0;
            traded = false; 
        end
        if (itemLink) then
            MRT_ManualAddLoot(itemLink, looter, cost, traded);
            return;
        end
    end
    local slashCmd = '/'..MRT_Options.General_SlashCmdHandler;
    MRT_Print("Slash commands:");
    MRT_Print("'"..slashCmd.."' opens the raid log broser.");
    MRT_Print("'"..slashCmd.." options' opens the options menu.");
    MRT_Print("'"..slashCmd.." dkpcheck' creates a new boss entry and starts an attendance check.");
    MRT_Print("'"..slashCmd.." additem <ItemLink> <Looter> [<Costs>]' adds an item to the last boss kill.");
    MRT_Print("Example: "..slashCmd.." additem \124cffffffff\124Hitem:6948:0:0:0:0:0:0:0:0\124h[Hearthstone]\124h\124r Mizukichan 10");
    MRT_Print("'"..slashCmd.." snapshot' creates a snapshot of the current raid composition.");
    MRT_Print("'"..slashCmd.." deleteall now' deletes the complete raid log. USE WITH CAUTION!");
end

function MRT_SlashCmdHandlerRO(msg)
    MRT_Debug("MRT_SlashCmdHandlerRO")
    MRT_ReadOnly = true;
    MRT_GUI_Toggle(true);
end

-- Chat handler
local MRT_ChatHandler = {};
function MRT_ChatHandler:CHAT_MSG_WHISPER_Filter(event, msg, from, ...)
    --keeping next line to test
    local nopunc, numstripped = string.gsub(msg,"%p", "")
    local sCom = strsub(nopunc,1,4);
    --local sCom = strsub(msg,1,4);
    --MRT_Debug("Message MSG_Whisper_filtered... ");
    --if (not MRT_TimerFrame.GARunning) then return false; end

    if string.lower(sCom) == "epgp" then
        MRT_Debug("Message filtered... - Msg was '"..msg.."' from '"..from.."'");
        return true
    else
        return false
    end
    if ( MRT_Options["Attendance_GuildAttendanceCheckUseTrigger"] and (MRT_Options["Attendance_GuildAttendanceCheckTrigger"] == msg) ) then
        MRT_Debug("Message filtered... - Msg was '"..msg.."' from '"..from.."'");
        return true;
    elseif (not MRT_Options["Attendance_GuildAttendanceCheckUseTrigger"]) then
        local player = MRT_GuildRoster[string.lower(msg)];
        if (not player) then return false; end
        MRT_Debug("Message filtered... - Msg was '"..msg.."' from '"..from.."'");
        return true;
    end
    return false;
end

function MRT_ChatHandler:CHAT_MSG_WHISPER_INFORM_FILTER(event, msg, from, ...)
    --MRT_Debug("Message MSG_Whisper_INFORM_Filter... ");
    --if (not MRT_TimerFrame.GARunning) then return false; end
    --if (msg == MRT_ChatHandler.MsgToBlock) then
    --if (msg == blockmsg) then
    for i, v in ipairs(SupressMsg) do
        if msg == v then
            MRT_Debug("Message filtered... - Msg was '"..msg.."' from '"..from.."'" .."blocked Msg: "..v);
            return true;
        end
    end
    return false;
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", MRT_ChatHandler.CHAT_MSG_WHISPER_Filter);
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", MRT_ChatHandler.CHAT_MSG_WHISPER_INFORM_FILTER);

------------------
--  Initialize  --
------------------
function MRT_Initialize(frame)
    -- Update settings and DB
    MRT_UpdateSavedOptions();
    MRT_VersionUpdate();
    -- Maintenance
    MRT_PeriodicMaintenance();
    -- Parse localization
    MRT_Options_ParseValues();
    MRT_GUI_ParseValues();
    MRT_Core_Frames_ParseLocal();
    -- set up slash command
    if (MRT_Options["General_SlashCmdHandler"] and MRT_Options["General_SlashCmdHandler"] ~= "") then
        SLASH_MIZUSRAIDTRACKER1 = "/"..MRT_Options["General_SlashCmdHandler"];
        SlashCmdList["MIZUSRAIDTRACKER"] = function(msg) MRT_SlashCmdHandler(msg); end
        SLASH_SFREADONLY1 = "/epgp";
        SlashCmdList["SFREADONLY"] = function(msg) MRT_SlashCmdHandlerRO(msg); end
    end
    -- set up LDB data source
    MRT_LDB_DS = LDB:NewDataObject("Classic RaidTracker_Stormforged", {
        icon = "Interface\\AddOns\\ClassicRaidTracker_Stormforged\\icons\\icon_disabled",
        label = MRT_ADDON_TITLE,
        text = "Storm",
        type = "data source",
        OnClick = function(self, button)
            if (button == "LeftButton") then
                MRT_GUI_Toggle();
            elseif (button == "RightButton") then
                InterfaceOptionsFrame_OpenToCategory("Classic RaidTracker_Stormforged");
                InterfaceOptionsFrame_OpenToCategory("Classic RaidTracker_Stormforged");
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(MRT_ADDON_TITLE);
            tooltip:AddLine(" ");
            tooltip:AddLine(MRT_L.Core["LDB Left-click to toggle the raidlog browser"]);
            tooltip:AddLine(MRT_L.Core["LDB Right-click to open the options menu"]);
        end,
    });
    -- set up minimap icon
    LDBIcon:Register("Classic RaidTracker_Stormforged", MRT_LDB_DS, MRT_Options["MiniMap_SV"]);
    -- set up drop down menu for the DKPFrame
    MRT_DKPFrame_DropDownTable = ScrollingTable:CreateST(MRT_DKPFrame_DropDownTableColDef, 9, nil, nil, MRT_GetDKPValueFrame);
    MRT_DKPFrame_DropDownTable.head:SetHeight(1);
    MRT_DKPFrame_DropDownTable.frame:SetFrameLevel(3);
    MRT_DKPFrame_DropDownTable.frame:Hide();
    MRT_DKPFrame_DropDownTable:EnableSelection(false);
    MRT_DKPFrame_DropDownTable:RegisterEvents({
        ["OnClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
            if (not realrow) then return true; end
            local playerName = MRT_DKPFrame_DropDownTable:GetCell(realrow, column);
            if (playerName) then
                MRT_GetDKPValueFrame.Looter = playerName;
                MRT_GetDKPValueFrame_TextThirdLine:SetText(string.format(MRT_L.Core.DKP_Frame_LootetBy, playerName));
                MRT_GetDKPValueFrame_DropDownList_Toggle();
            end
            return true;
        end
    });
    MRT_DKPFrame_DropDownTable.head:SetHeight(1);
    -- check for open raids
    if (not MRT_NumOfCurrentRaid) then
        MRT_UnknownRelogStatus = false;
    end
    -- update version number in saved vars
    MRT_Options["General_Version"] = MRT_ADDON_VERSION;
    MRT_Options["General_ClientLocale"] = GetLocale();


    C_ChatInfo.RegisterAddonMessagePrefix("SFRT")

   HookToolTips();

    -- Finish
    MRT_Debug("Addon loaded.");

end

----------------------
--  Apply Defaults  --
----------------------
-- Check variables - if missing, load defaults
function MRT_UpdateSavedOptions()
    if not MRT_Options["General_OptionsVersion"] then
        MRT_Debug("Setting Options to default values...");
        for key, value in pairs(MRT_Defaults["Options"]) do
            if (MRT_Options[key] == nil) then
                MRT_Options[key] = value;
            end
        end
    end
    if MRT_Options["General_OptionsVersion"] == 1 then
        MRT_Options["Tracking_CreateNewRaidOnNewZone"] = false;
        MRT_Options["General_OptionsVersion"] = 2;
    end
    if MRT_Options["General_OptionsVersion"] == 2 then
        if (MRT_Options["Export_ExportFormat"] > 1) then
            MRT_Options["Export_ExportFormat"] = MRT_Options["Export_ExportFormat"] + 1;
        end
        MRT_Options["General_OptionsVersion"] = 3;
    end
    if MRT_Options["General_OptionsVersion"] == 3 then
        if (MRT_Options["Export_ExportFormat"] > 2) then
            MRT_Options["Export_ExportFormat"] = MRT_Options["Export_ExportFormat"] + 1;
        end
        MRT_Options["General_OptionsVersion"] = 4;
    end
    if MRT_Options["General_OptionsVersion"] == 4 then
        MRT_Options["Tracking_OnlyTrackItemsAboveILvl"] = 0;
        MRT_Options["General_OptionsVersion"] = 5;
    end
    if MRT_Options["General_OptionsVersion"] == 5 then
        MRT_Options["Attendance_GuildAttendanceCheckUseTrigger"] = false;
        MRT_Options["Attendance_GuildAttendanceCheckTrigger"] = "!triggerexample";
        MRT_Options["General_OptionsVersion"] = 6;
    end
    if MRT_Options["General_OptionsVersion"] == 6 then
        MRT_Options["General_PrunnRaidLog"] = false;
        MRT_Options["General_PrunningTime"] = 90;
        MRT_Options["Tracking_AskCostAutoFocus"] = 1;
        MRT_Options["Export_ExportEnglish"] = false;
        MRT_Options["General_OptionsVersion"] = 7;
    end
    if MRT_Options["General_OptionsVersion"] == 7 then
        MRT_Options["General_ShowMinimapIcon"] = false;
        MRT_Options["MiniMap_SV"] = {
            hide = true,
        };
        MRT_Options["General_OptionsVersion"] = 8;
    end
    if MRT_Options["General_OptionsVersion"] == 8 then
        if (MRT_Options["Export_ExportFormat"] > 3) then
            MRT_Options["Export_ExportFormat"] = MRT_Options["Export_ExportFormat"] + 1;
        end
        MRT_Options["General_OptionsVersion"] = 9;
    end
    if MRT_Options["General_OptionsVersion"] == 9 then
        MRT_Options["Attendance_GuildAttendanceUseCustomText"] = false;
        MRT_Options["Attendance_GuildAttendanceCustomText"] = MRT_GA_TEXT_CHARNAME_BOSS;
        MRT_Options["General_OptionsVersion"] = 10;
    end
    if MRT_Options["General_OptionsVersion"] == 10 then
        MRT_Options["ItemTracking_IgnoreEnchantingMats"] = true;
        MRT_Options["ItemTracking_IgnoreGems"] = true;
        MRT_Options["General_OptionsVersion"] = 11;
    end
    if MRT_Options["General_OptionsVersion"] == 11 then
        MRT_Options["Tracking_LogWotLKRaids"] = false;
        MRT_Options["General_OptionsVersion"] = 12;
    end
    if MRT_Options["General_OptionsVersion"] == 12 then
        --MRT_Options["ItemTracking_UseEPGPValues"] = false;
        MRT_Options["ItemTracking_UseEPGPValues"] = true; -- setting to true always for SF
        MRT_Options["General_OptionsVersion"] = 13;
    end
    if MRT_Options["General_OptionsVersion"] == 13 then
        MRT_Options["Tracking_LogLFRRaids"] = true;
        MRT_Options["General_OptionsVersion"] = 14;
    end
    if MRT_Options["General_OptionsVersion"] == 14 then
        MRT_Options["Tracking_LogCataclysmRaids"] = false;
        MRT_Options["Tracking_LogMoPRaids"] = true;
        MRT_Options["Tracking_LogLootModePersonal"] = true;
        MRT_Options["General_OptionsVersion"] = 15;
    end
    if MRT_Options["General_OptionsVersion"] == 15 then
        MRT_Options["Tracking_Log25MenRaids"] = true;
        MRT_Options["Tracking_LogNormalRaids"] = true;
        MRT_Options["Tracking_LogHeroicRaids"] = true;
        MRT_Options["Tracking_LogMythicRaids"] = true;
        MRT_Options["General_OptionsVersion"] = 16;
    end
    if MRT_Options["General_OptionsVersion"] == 16 then
        MRT_Options["Tracking_AskForDKPValuePersonal"] = true;
        MRT_Options["General_OptionsVersion"] = 17;
    end
    if MRT_Options["General_OptionsVersion"] == 17 then
        MRT_Options["Tracking_LogWarlordsRaids"] = true;
        MRT_Options["General_OptionsVersion"] = 18;
    end
    if MRT_Options["General_OptionsVersion"] == 18 then
        -- BfA transition - reset logging of personal loot to true - it is the only loot mode available now
        MRT_Options["Tracking_LogLootModePersonal"] = true;
        MRT_Options["General_OptionsVersion"] = 19;
    end
    if MRT_Options["General_OptionsVersion"] == 19 then
        -- BfA transition - reset logging of personal loot to true - it is the only loot mode available now
        MRT_Options["ItemTracking_SyncWML"] = false;
        MRT_Options["General_OptionsVersion"] = 20;
    end
end

-----------------------------------------------
--  Make configuration changes if necessary  --
-----------------------------------------------
function MRT_VersionUpdate()
    -- DB changes from v.nil to v.1: Move extended player information in extra database
    if (MRT_Options["DB_Version"] == nil) then
        if (#MRT_RaidLog > 0) then
            local currentrealm = GetRealmName();
            for i, raidInfoTable in ipairs(MRT_RaidLog) do
                local realm;
                if (raidInfoTable["Realm"]) then
                    realm = raidInfoTable["Realm"];
                else
                    realm = currentrealm;
                    raidInfoTable["Realm"] = realm;
                end
                if (MRT_PlayerDB[realm] == nil) then
                    MRT_PlayerDB[realm] = {};
                end
                for j, playerInfo in pairs(raidInfoTable["Players"]) do
                    local name = playerInfo["Name"];
                    if (MRT_PlayerDB[realm][name] == nil) then
                        MRT_PlayerDB[realm][name] = {};
                        MRT_PlayerDB[realm][name]["Name"] = name;
                    end
                    if (playerInfo["Race"]) then
                        MRT_PlayerDB[realm][name]["Race"] = playerInfo["Race"];
                        playerInfo["Race"] = nil;
                    end
                    if (playerInfo["RaceL"]) then
                        MRT_PlayerDB[realm][name]["Race"] = playerInfo["RaceL"];
                        playerInfo["RaceL"] = nil;
                    end
                    if (playerInfo["Class"]) then
                        MRT_PlayerDB[realm][name]["Class"] = playerInfo["Class"];
                        playerInfo["Class"] = nil;
                    end
                    if (playerInfo["ClassL"]) then
                        MRT_PlayerDB[realm][name]["ClassL"] = playerInfo["ClassL"];
                        playerInfo["ClassL"] = nil;
                    end
                    if (playerInfo["Level"]) then
                        MRT_PlayerDB[realm][name]["Level"] = playerInfo["Level"];
                        playerInfo["Level"] = nil;
                    end
                    if (playerInfo["Sex"]) then
                        MRT_PlayerDB[realm][name]["Sex"] = playerInfo["Sex"];
                        playerInfo["Sex"] = nil;
                    end
                end
            end
        end
        MRT_Options["DB_Version"] = 1;
    end
    -- DB changes from v.1 to v.2: Add missing StopTime to each raid entry
    if (MRT_Options["DB_Version"] == 1) then
        if (#MRT_RaidLog > 0) then
            for i, raidInfoTable in ipairs(MRT_RaidLog) do
                local latestTimestamp = 1;
                for j, playerInfo in pairs(raidInfoTable["Players"]) do
                    if (playerInfo["Leave"] > latestTimestamp) then
                        latestTimestamp = playerInfo["Leave"];
                    end
                end
                raidInfoTable["StopTime"] = latestTimestamp;
            end
        end
        MRT_Options["DB_Version"] = 2;
    end
    -- DB changes from v.2 to v.3:
    -- * Update from 3.4 difficulty IDs to 6.0 difficulty IDs
    -- * Add raid difficulty IDs to raid entries
    -- * Fix LFR (ID 17) entries
    if (MRT_Options["DB_Version"] == 2) then
        if (#MRT_RaidLog > 0) then
            for i, raidInfoTable in ipairs(MRT_RaidLog) do
                if (raidInfoTable["RaidSize"] == 10) then
                    raidInfoTable["DiffID"] = 3;
                elseif (raidInfoTable["RaidSize"] == 25) then
                    raidInfoTable["DiffID"] = 4;
                end
                for j, bossInfo in ipairs(raidInfoTable["Bosskills"]) do
                    if (not bossInfo["Difficulty"]) then
                        raidInfoTable["DiffID"] = 17;
                        bossInfo["Difficulty"] = 17;
                    elseif (bossInfo["Difficulty"] == 1) then
                        bossInfo["Difficulty"] = 3;
                    elseif (bossInfo["Difficulty"] == 2) then
                        bossInfo["Difficulty"] = 4;
                    elseif (bossInfo["Difficulty"] == 3) then
                        bossInfo["Difficulty"] = 5;
                    elseif (bossInfo["Difficulty"] == 4) then
                        bossInfo["Difficulty"] = 6;
                    end
                end
            end
        end
        MRT_Options["DB_Version"] = 3;
    end
    if (MRT_Options["DB_Version"] == 3) then
        if (#MRT_RaidLog > 0) then
            local currentrealm = GetRealmName();
            for i, raidInfoTable in ipairs(MRT_RaidLog) do
                local realm;
                if (raidInfoTable["Realm"]) then
                    realm = raidInfoTable["Realm"];
                else
                    realm = currentrealm;
                    raidInfoTable["Realm"] = realm;
                end
                if (MRT_PlayerDB[realm] == nil) then
                    MRT_PlayerDB[realm] = {};
                end
                for j, playerInfo in pairs(raidInfoTable["Players"]) do
                    local name = playerInfo["Name"];
                    if (playerInfo["PR"]) then
                        MRT_PlayerDB[realm][name]["PR"] = playerInfo["PR"];
                        playerInfo["PR"] = "0.00";
                    end
                end
            end
        end
        MRT_Options["DB_Version"] = 4;
    end
    
end

----------------------------
--  Periodic maintenance  --
----------------------------
-- delete unused PlayerDB-Entries and prun raidlog
function MRT_PeriodicMaintenance()
    if (#MRT_RaidLog == 0) then return; end
    local startTime = time();
    -- process prunning - smaller raidIndex is older raid
    if (MRT_Options["General_PrunnRaidLog"]) then
        -- prunningTime in seconds
        local prunningTime = MRT_Options["General_PrunningTime"] * 24 * 60 * 60;
        local lastRaidOverPrunningTreshhold = nil;
        for i, raidInfo in ipairs(MRT_RaidLog) do
            if ( (startTime - raidInfo["StartTime"]) > prunningTime and i ~= MRT_NumOfCurrentRaid ) then
                lastRaidOverPrunningTreshhold = i;
            end
        end
        if (lastRaidOverPrunningTreshhold) then
            -- if MRT_NumOfCurrentRaid not nil, then reduce it by the number of deleted raids
            if (MRT_NumOfCurrentRaid) then
                MRT_NumOfCurrentRaid = MRT_NumOfCurrentRaid - lastRaidOverPrunningTreshhold
                if (MRT_NumOfCurrentRaid < 1) then MRT_NumOfCurrentRaid = nil; end
            end
            -- delete raid entries, that are too old
            for i = lastRaidOverPrunningTreshhold, 1, -1 do
                tremove(MRT_RaidLog, i);
            end
        end
    end
    -- process playerDB
    local deletedEntries = 0;
    local usedPlayerList = {};
    for i, raidInfoTable in ipairs(MRT_RaidLog) do
        local name;
        local realm = raidInfoTable["Realm"];
        if (not usedPlayerList[realm]) then usedPlayerList[realm] = {}; end
        for j, playerInfo in pairs(raidInfoTable["Players"]) do
            name = playerInfo.Name;
            usedPlayerList[realm][name] = true;
        end
        for j, bossInfo in ipairs(raidInfoTable["Bosskills"]) do
            for k, playerName in ipairs(bossInfo["Players"]) do
                usedPlayerList[realm][playerName] = true;
            end
        end
    end
    for realm, playerInfoList in pairs(MRT_PlayerDB) do
        for player, playerInfo in pairs(MRT_PlayerDB[realm]) do
            -- realm-check is neccessary, because there may be PlayerDB-entries for realms, whose corresponding raids are deleted
            if (not usedPlayerList[realm] or not usedPlayerList[realm][player]) then
                MRT_PlayerDB[realm][player] = nil;
                deletedEntries = deletedEntries + 1;
            end
        end
    end
    MRT_Debug("Maintenance finished in "..tostring(time() - startTime).." seconds. Deleted "..tostring(deletedEntries).." player entries.");
end

-----------------
--  API-Stuff  --
-----------------
function MRT_RegisterItemCostHandlerCore(functionToCall, addonName)
    if (functionToCall == nil or addonName == nil) then
        return false;
    end
    if (not MRT_ExternalItemCostHandler.func) then
        MRT_ExternalItemCostHandler.func = functionToCall;
        MRT_ExternalItemCostHandler.addonName = addonName;
        MRT_Print("Note: The addon '"..addonName.."' has registered itself to handle item tracking.");
        return true;
    else
        return false;
    end
end

function MRT_UnregisterItemCostHandlerCore(functionCalled)
    if (functionCalled == nil) then
        return false;
    end
    if (MRT_ExternalItemCostHandler.func == functionCalled) then
        MRT_ExternalItemCostHandler.func = nil;
        MRT_ExternalItemCostHandler.addonName = nil;
        return true;
    else
        return false;
    end
end

function MRT_RegisterLootNotifyCore(functionToCall)
    local isRegistered = nil;
    for i, val in ipairs(MRT_ExternalLootNotifier) do
        if (val == functionToCall) then
            isRegistered = true;
        end
    end
    if (isRegistered) then
        return false;
    else
        tinsert(MRT_ExternalLootNotifier, functionToCall);
        return true;
    end
end

function MRT_UnregisterLootNotifyCore(functionCalled)
    local isRegistered = nil;
    for i, val in ipairs(MRT_ExternalLootNotifier) do
        if (val == functionCalled) then
            isRegistered = i;
        end
    end
    if (isRegistered) then
        tremove(MRT_ExternalLootNotifier, isRegistered);
        return true;
    else
        return false;
    end
end

-------------------------------------
--  basic raid tracking functions  --
-------------------------------------
function MRT_CheckRaidStatusAfterLogin()
    if (not MRT_IsInRaid()) then
        MRT_EndActiveRaid();
        MRT_LDB_DS.icon = "Interface\\AddOns\\ClassicRaidTracker_Stormforged\\icons\\icon_disabled";
        return;
    end
    if (MRT_NumOfCurrentRaid) then
        -- set up timer for regular raid roster scanning
        MRT_RaidRosterScanTimer.lastCheck = time()
        MRT_RaidRosterScanTimer:SetScript("OnUpdate", function (self)
            if ((time() - self.lastCheck) > 5) then
                self.lastCheck = time();
                MRT_RaidRosterUpdate();
            end
        end);
        -- update LDB text and icon
        MRT_LDB_DS.icon = "Interface\\AddOns\\ClassicRaidTracker_Stormforged\\icons\\icon_enabled";
    end
end

function MRT_CheckZoneAndSizeStatus()
    -- Use GetInstanceInfo() for informations about the zone! / Track bossdifficulty at bosskill (important for ICC)
    local localInstanceInfoName, instanceInfoType, diffID, diffDesc, maxPlayers, _, _, areaID, iniGroupSize = MRT_GetInstanceInfo();
    if (not diffID) then return; end
    if (not areaID) then return; end
    -- local localInstanceInfoName = GetMapNameByID(areaID);
    if (not localInstanceInfoName) then return; end
    MRT_Debug("MRT_CheckZoneAndSizeStatus called - data: Name="..localInstanceInfoName.." / areaID=" ..areaID.." / Type="..instanceInfoType.." / diffDesc="..diffDesc.." / diffID="..diffID);
    -- For legacy 10 N/H and 25 N/H raids, difficulty is tracked at boss killtime, as those difficulties have a shared ID
    -- Thus, handle diffID 5 as 3 and 6 as 2
    if (diffID == 5) then diffID = 3; end
    if (diffID == 6) then diffID = 4; end
    if (MRT_RaidZones[areaID]) then
        -- Check if the current raidZone is a zone which should be tracked
        if (MRT_LegacyRaidZonesClassic[areaID] and not MRT_Options["Tracking_LogClassicRaids"]) then
            MRT_Debug("This instance is a Classic-Raid and tracking of those is disabled.");
            if (MRT_NumOfCurrentRaid) then MRT_EndActiveRaid(); end
            return;
        end
        -- Check if the current loot mode should be tracked
        if (select(1, GetLootMethod()) == "personalloot" and not MRT_Options["Tracking_LogLootModePersonal"]) then
            MRT_Debug("Loot method is personal loot and tracking of this loot method is disabled.");
            if (MRT_NumOfCurrentRaid) then MRT_EndActiveRaid(); end
            return;
        end
        -- Check if current raid size should be tracked
        if (diffID == 3 and not MRT_Options["Tracking_Log10MenRaids"]) then
            MRT_Debug("This instance is a 10 player legacy raid and tracking of those is disabled.");
            if (MRT_NumOfCurrentRaid) then MRT_EndActiveRaid(); end
            return;
        end
        if (diffID == 4 and not MRT_Options["Tracking_Log25MenRaids"]) then
            MRT_Debug("This instance is a 25 player legacy raid and tracking of those is disabled.");
            if (MRT_NumOfCurrentRaid) then MRT_EndActiveRaid(); end
            return;
        end
        if ((diffID == 7 or diffID == 17) and not MRT_Options["Tracking_LogLFRRaids"]) then
            MRT_Debug("This instance is a LFR-Raid and tracking of those is disabled.");
            if (MRT_NumOfCurrentRaid) then MRT_EndActiveRaid(); end
            return;
        end
        if (diffID == 14 and not MRT_Options["Tracking_LogNormalRaids"]) then
            MRT_Debug("This instance is a WoD or later normal mode raid and tracking of those is disabled.");
            if (MRT_NumOfCurrentRaid) then MRT_EndActiveRaid(); end
            return;
        end
        if (diffID == 15 and not MRT_Options["Tracking_LogHeroicRaids"]) then
            MRT_Debug("This instance is a WoD or later heroic mode raid and tracking of those is disabled.");
            if (MRT_NumOfCurrentRaid) then MRT_EndActiveRaid(); end
            return;
        end
        if (diffID == 16 and not MRT_Options["Tracking_LogMythicRaids"]) then
            MRT_Debug("This instance is a WoD or later mythic mode raid and tracking of those is disabled.");
            if (MRT_NumOfCurrentRaid) then MRT_EndActiveRaid(); end
            return;
        end
        MRT_Debug("MRT_CheckZoneAndSizeStatus: At this point, we should have something that should be tracked");
        -- At this point, we should have something that should be tracked.
        -- If there is no active raid, just start one
        if (not MRT_NumOfCurrentRaid) then
            MRT_Debug("MRT_CheckZoneAndSizeStatus:no current raid, create one");
            MRT_Debug("Start tracking a new instance - Name="..localInstanceInfoName.." / maxPlayers="..maxPlayers.." / diffID="..diffID);
            --SF: Use Short Name if it's Classic
            if not MRT_LegacyRaidZonesClassic[areaID] then
                MRT_CreateNewRaid(localInstanceInfoName, maxPlayers, diffID);
            else
                MRT_CreateNewRaid(MRT_LegacyRaidShortName[areaID], maxPlayers, diffID);
            end
            return;
        end
        -- There is an active raid, check if diffID changed, if yes, start a new raid
        MRT_Debug("MRT_CheckZoneAndSizeStatus: Active Raid, check diffID");
        if (MRT_RaidLog[MRT_NumOfCurrentRaid]["DiffID"] ~= diffID) then
            MRT_Debug("MRT_CheckZoneAndSizeStatus: Start tracking a new instance - Name="..localInstanceInfoName.." / maxPlayers="..maxPlayers.." / diffID="..diffID);
            --SF: Use Short Name if it's Classic
            if not MRT_LegacyRaidZonesClassic[areaID] then
                MRT_CreateNewRaid(localInstanceInfoName, maxPlayers, diffID);
            else
                MRT_CreateNewRaid(MRT_LegacyRaidShortName[areaID], maxPlayers, diffID);
            end
            return;
        else
            MRT_Debug("MRT_CheckZoneAndSizeStatus: diffIDs are equal, we should not create a new raid if one is active - Name="..localInstanceInfoName.." / maxPlayers="..maxPlayers.." / diffID="..diffID);
        end
        -- If instance changed, check to see if it's the same zone name.  If not, create.  If so do nothing.
        MRT_Debug("MRT_CheckZoneAndSizeStatus: Active Raid, RaidZone check if same zone, do nothing otherwise create a new raid");
        if (MRT_RaidLog[MRT_NumOfCurrentRaid]["RaidZone"] ~= MRT_LegacyRaidShortName[areaID]) then
            MRT_Debug("Start tracking a new instance - Name="..localInstanceInfoName.." / maxPlayers="..maxPlayers.." / diffID="..diffID);
            --SF: Use Short Name if it's Classic
            if not MRT_LegacyRaidZonesClassic[areaID] then
                MRT_CreateNewRaid(localInstanceInfoName, maxPlayers, diffID);
            else
                MRT_CreateNewRaid(MRT_LegacyRaidShortName[areaID], maxPlayers, diffID);
            end
            return;
        else
            MRT_Debug("MRT_CheckZoneAndSizeStatus: Zone matches, we should do nothing. Name="..MRT_LegacyRaidShortName[areaID].. " MRT_RaidLog[MRT_NumOfCurrentRaid][RaidZone]: " ..MRT_RaidLog[MRT_NumOfCurrentRaid]["RaidZone"]);
        end
        -- diffID not changed. If instance changed, check if auto create on new instance is on.
        -- need to no do this 
        --if ((MRT_RaidLog[MRT_NumOfCurrentRaid]["RaidZone"] ~= localInstanceInfoName) and MRT_Options["Tracking_CreateNewRaidOnNewZone"]) then
        --we should never do this.. commenting out all the code.
 --[[        if ((MRT_RaidLog[MRT_NumOfCurrentRaid]["RaidZone"] ~= localInstanceInfoName) and false) then
            MRT_Debug("Start tracking a new instance - Name="..localInstanceInfoName.." / maxPlayers="..maxPlayers.." / diffID="..diffID);
            --SF: Use Short Name if it's Classic
            if not MRT_LegacyRaidZonesClassic[areaID] then
                MRT_CreateNewRaid(localInstanceInfoName, maxPlayers, diffID);
            else
                MRT_CreateNewRaid(MRT_LegacyRaidShortName[areaID], maxPlayers, diffID);
            end
            return;
        end ]]
    else
        MRT_Debug("This instance is not on the tracking list.");
    end
end

function MRT_CreateNewRaid(zoneName, raidSize, diffID)
    assert(zoneName, "Invalid argument: zoneName is nil.")
    assert(raidSize, "Invalid argument: raidSize is nil.")
    assert(diffID, "Invalid argument: diffID is nil.")
    --don't create new raid if one exists
    --oldcode: if (MRT_NumOfCurrentRaid) then MRT_EndActiveRaid(); end
    if (MRT_NumOfCurrentRaid) then 
        MRT_Debug("MRT_CreateNewRaid: Trying to create a new raid when one is already running.");
        assert(diffID, "Active raid, please end current raid to create a new one.")
        return;
    end
    local numRaidMembers = MRT_GetNumRaidMembers();
    local realm = GetRealmName();
    if (numRaidMembers == 0) then return; end
    MRT_Debug("Creating new raid... - RaidZone is "..zoneName..", RaidSize is "..tostring(raidSize).. " and diffID is "..tostring(diffID));
    local currentTime = MRT_GetCurrentTime();
    local MRT_RaidInfo = {["Players"] = {}, ["Bosskills"] = {}, ["Loot"] = {}, ["DiffID"] = diffID, ["RaidZone"] = zoneName, ["RaidSize"] = raidSize, ["Realm"] = GetRealmName(), ["StartTime"] = currentTime};
    MRT_Debug(tostring(numRaidMembers).." raidmembers found. Processing RaidRoster...");
    --why?
--[[     if isMasterLootSet() then
        if isMasterLooter() then
            MRT_ReadOnly = false
        else
            MRT_ReadOnly = true
        end
    end ]]
    for i = 1, numRaidMembers do
        local playerName, _, playerSubGroup, playerLvl, playerClassL, playerClass, _, playerOnline = GetRaidRosterInfo(i);
        local UnitID = "raid"..tostring(i);
        local playerRaceL, playerRace = UnitRace(UnitID);
        local playerSex = UnitSex(UnitID);
        local playerGuild = GetGuildInfo(UnitID);
        local playerPR = getPlayerPR(playerName);  -- write a function that returns player PR from website export
        --MRT_Debug("CreateNewRaid: playerPR: " ..playerPR);
        local playerInfo = {
            ["Name"] = playerName,
            ["Join"] = currentTime,
            ["Leave"] = nil,
            ["PR"] = playerPR,
        };
        local playerDBEntry = {
            ["Name"] = playerName,
            ["Race"] = playerRace,
            ["RaceL"] = playerRaceL,
            ["Class"] = playerClass,
            ["ClassL"] = playerClassL,
            ["Level"] = playerLvl,
            ["Sex"] = playerSex,
            ["Guild"] = playerGuild,
            ["PR"] = playerPR,
        };
        if ((playerOnline or MRT_Options["Attendance_TrackOffline"]) and (not MRT_Options["Attendance_GroupRestriction"] or (playerSubGroup <= (raidSize / 5)))) then
            tinsert(MRT_RaidInfo["Players"], playerInfo);
        end
        if (MRT_PlayerDB[realm] == nil) then
            MRT_PlayerDB[realm] = {};
        end
        MRT_PlayerDB[realm][playerName] = playerDBEntry;
    end
    tinsert(MRT_RaidLog, MRT_RaidInfo);
    MRT_NumOfCurrentRaid = #MRT_RaidLog;
    -- set up timer for regular raid roster scanning
    MRT_RaidRosterScanTimer.lastCheck = time()
    MRT_RaidRosterScanTimer:SetScript("OnUpdate", function (self)
        if ((time() - self.lastCheck) > 5) then
            self.lastCheck = time();
            MRT_RaidRosterUpdate();
        end
    end);
    -- update LDB text and icon
    MRT_LDB_DS.icon = "Interface\\AddOns\\ClassicRaidTracker_Stormforged\\icons\\icon_enabled";

    --send message to chatchannel with new raid info serialize MRT_RaidInfo
end

function getMasterLooter()
    -- for debug testing, we can set Main to someone other than the ML.
    -- uncomment next line for testing to assign ML  replace <playername> with ML tester... this should be the one that is the "server"
    --return "<playername>"
    --local strML = "Hokei"
    local _, _, MasterLootRaidIndex = GetLootMethod();
    if (MasterLootRaidIndex) then
        local MLName = GetRaidRosterInfo(MasterLootRaidIndex);
        return MLName;
        --return strML;
    else
        --we should do something if the master looter is not set.
        return "Hokei";
    end
end	


function MRT_ResumeLastRaid()
    -- if there is a running raid, then there is nothing to resume
    if (MRT_NumOfCurrentRaid) then return false; end
    -- if the player is not in a raid, then there is no reason to resume
    local numRaidMembers = MRT_GetNumRaidMembers();
    local currentTime = MRT_GetCurrentTime();

    if (numRaidMembers == 0) then return false; end
    -- sanity checks: Is there a last raid? Was the last raid on the same realm as this raid?
    local numOfLastRaid = #MRT_RaidLog;
    if (not numOfLastRaid or numOfLastRaid == 0) then return false; end
    local realm = GetRealmName();
    if (MRT_RaidLog[numOfLastRaid]["Realm"] ~= realm) then return false; end
    local raidSize = MRT_RaidLog[numOfLastRaid]["RaidSize"];
    -- scan RaidRoster and create a list with current valid attendees (valid in the sense should be tracked according to the current setting (check subgroup and onlinestatus))
    -- also, update PlayerDB
    local currentAttendeesList = {};
    for i = 1, numRaidMembers do
        local playerName, _, playerSubGroup, playerLvl, playerClassL, playerClass, _, playerOnline = GetRaidRosterInfo(i);
        local UnitID = "raid"..tostring(i);
        local playerRaceL, playerRace = UnitRace(UnitID);
        local playerSex = UnitSex(UnitID);
        local playerGuild = GetGuildInfo(UnitID);
        local playerPR = "0.00";  -- write a function that returns player PR from website export
        local playerInfo = {
            ["Name"] = playerName,
            ["Join"] = currentTime,
            ["Leave"] = nil,
            ["PR"] = playerPR,
        }
        local playerDBEntry = {
            ["Name"] = playerName,
            ["Race"] = playerRace,
            ["RaceL"] = playerRaceL,
            ["Class"] = playerClass,
            ["ClassL"] = playerClassL,
            ["Level"] = playerLvl,
            ["Sex"] = playerSex,
            ["Guild"] = playerGuild,
            ["PR"] = playerPR,
        };
        if (MRT_PlayerDB[realm] == nil) then
            MRT_PlayerDB[realm] = {};
        end
        MRT_PlayerDB[realm][playerName] = playerDBEntry;
        -- is this a valid attendee?
        if ((playerOnline or MRT_Options["Attendance_TrackOffline"]) and (not MRT_Options["Attendance_GroupRestriction"] or (playerSubGroup <= (raidSize / 5)))) then
            currentAttendeesList[playerName] = true;
        end
    end
    -- next step: check raid roster of last raid - if there is an entry of an valid raid member with leaveTime == end of last raid, then just resume this entry (-> set leave-time to nil)
    local endOfLastRaid = MRT_RaidLog[numOfLastRaid]["StopTime"];
    for i, attendeeDataSet in ipairs(MRT_RaidLog[numOfLastRaid]["Players"]) do
        if (attendeeDataSet.Leave and attendeeDataSet.Leave == endOfLastRaid and currentAttendeesList[attendeeDataSet.Name]) then
            attendeeDataSet.Leave = nil;
            currentAttendeesList[attendeeDataSet.Name] = nil;
        end
    end
    -- at this point, currentAttendeesList should only contain players, which were not in the last raid when tracking of the last raid ended. Add new raid attendee entries for these players
    local now = MRT_GetCurrentTime();
    for playerName, val in pairs(currentAttendeesList) do
        local playerInfo = {
            ["Name"] = playerName,
            ["Join"] = now,
            ["Leave"] = nil,
            ["PR"] = playerPR,
        };
        tinsert(MRT_RaidLog[numOfLastRaid]["Players"], playerInfo);
    end
    -- set up timer for regular raid roster scanning
    MRT_RaidRosterScanTimer.lastCheck = time()
    MRT_RaidRosterScanTimer:SetScript("OnUpdate", function (self)
        if ((time() - self.lastCheck) > 5) then
            self.lastCheck = time();
            MRT_RaidRosterUpdate();
        end
    end);
    -- update LDB text and icon
    MRT_LDB_DS.icon = "Interface\\AddOns\\ClassicRaidTracker_Stormforged\\icons\\icon_enabled";
    -- update status variables
    MRT_NumOfCurrentRaid = numOfLastRaid;
    if (#MRT_RaidLog[MRT_NumOfCurrentRaid]["Bosskills"] > 0) then
        MRT_NumOfLastBoss = #MRT_RaidLog[MRT_NumOfCurrentRaid]["Bosskills"];
    end
    -- done - last raid is resumed and tracking is enabled
    return true;
end

function MRT_RaidRosterUpdate(frame)
    if (not MRT_NumOfCurrentRaid) then return; end
    if (not MRT_IsInRaid()) then
        MRT_Debug("MRT_RaidRosterUpdate: Not in Raid ending active raid");
        MRT_EndActiveRaid();
        return;
    end
    local numRaidMembers = MRT_GetNumRaidMembers();
    local realm = GetRealmName();
    local raidSize = MRT_RaidLog[MRT_NumOfCurrentRaid]["RaidSize"];
    local activePlayerList = {};
    --MRT_Debug("RaidRosterUpdate: Processing RaidRoster");
    --MRT_Debug(tostring(numRaidMembers).." raidmembers found.");
    for i = 1, numRaidMembers do
        local playerName, _, playerSubGroup, playerLvl, playerClassL, playerClass, _, playerOnline = GetRaidRosterInfo(i);
        -- seems like there is a slight possibility, that playerName is not available - so check it
        if playerName then
            if (playerOnline or MRT_Options["Attendance_TrackOffline"]) and (not MRT_Options["Attendance_GroupRestriction"] or (playerSubGroup <= (raidSize / 5))) then
                tinsert(activePlayerList, playerName);
            end
            local playerInRaid = nil;
            for key, val in pairs(MRT_RaidLog[MRT_NumOfCurrentRaid]["Players"]) do
                if (val["Name"] == playerName) then
                    if(val["Leave"] == nil) then playerInRaid = true; end
                end
            end
            if ((playerInRaid == nil) and (playerOnline or MRT_Options["Attendance_TrackOffline"]) and (not MRT_Options["Attendance_GroupRestriction"] or (playerSubGroup <= (raidSize / 5)))) then
                MRT_Debug("New player found: "..playerName);
                local UnitID = "raid"..tostring(i);
                local playerRaceL, playerRace = UnitRace(UnitID);
                local playerSex = UnitSex(UnitID);
                local playerPR = getPlayerPR(playerName);  -- write a function that returns player PR from website export
                local playerInfo = {
                    ["Name"] = playerName,
                    ["Join"] = MRT_GetCurrentTime(),
                    ["Leave"] = nil,
                    ["PR"] = playerPR
                };
                tinsert(MRT_RaidLog[MRT_NumOfCurrentRaid]["Players"], playerInfo);
            end
            -- PlayerDB is being renewed when creating a new raid, so only update unknown players here
            if (not MRT_PlayerDB[realm][playerName]) then
                local UnitID = "raid"..tostring(i);
                local playerRaceL, playerRace = UnitRace(UnitID);
                local playerSex = UnitSex(UnitID);
                local playerGuild = GetGuildInfo(UnitID);
                local playerPR = getPlayerPR(playerName);  -- write a function that returns player PR from website export
                local playerDBEntry = {
                    ["Name"] = playerName,
                    ["Race"] = playerRace,
                    ["RaceL"] = playerRaceL,
                    ["Class"] = playerClass,
                    ["ClassL"] = playerClassL,
                    ["Level"] = playerLvl,
                    ["Sex"] = playerSex,
                    ["Guild"] = playerGuild,
                    ["PR"] = playerPR,
                };
                MRT_PlayerDB[realm][playerName] = playerDBEntry;
            end
        end
    end
    -- MRT_Debug("RaidRosterUpdate: Checking for leaving players...");
    for key, val in pairs(MRT_RaidLog[MRT_NumOfCurrentRaid]["Players"]) do
        local matchFound = nil;
        for index, activePlayer in ipairs (activePlayerList) do
            if (val["Name"] == activePlayer) then
                matchFound = true;
            end
        end
        if (not matchFound) then
            if (not MRT_RaidLog[MRT_NumOfCurrentRaid]["Players"][key]["Leave"]) then
                MRT_Debug("Leaving player found: "..val["Name"]);
                MRT_RaidLog[MRT_NumOfCurrentRaid]["Players"][key]["Leave"] = MRT_GetCurrentTime();
            end
        end
    end
end

function getPlayerClass(PlayerName)
    --[[ if not MRT_SFExport["info"] then
        return "Unknown";
    else
      --  MRT_Debug("getPlayerClass: about to start loop");        
        local playerCount = MRT_SFExport["info"]["total_players"];
        for key, value in pairs(MRT_SFExport["players"]) do
            if strcomp(value["name"], PlayerName) then
           --    MRT_Debug("getPlayerClass: Found player"); 
                local retval = value["class_name"];
                if not retval then
                    return "Unknown";
                else
                    return retval;
                end
            end
        end
        return "Unknown";
    end ]]
    --take care of special assignments
    
    if (PlayerName == "bank") or (PlayerName == "disenchanted") then
   --     MRT_Debug("getPlayerClass: bank or disenchanted player = " ..PlayerName);
        return PlayerName;
    end
    local realm = GetRealmName();
    local nilcheckname = MRT_PlayerDB[realm][PlayerName]
    local cName;
    --MRT_Debug("getPlayerClass, player = " ..PlayerName);
    --check if player is in our playerdb
    if not nilcheckname then 
     --   MRT_Debug("getPlayerClass, not in playerDB");
        return getPlayerClassFromGuildRoster(PlayerName);
    else
        --seen this person before, pull this from the PlayerDB
        cName = MRT_PlayerDB[realm][PlayerName]["ClassL"];
    end 
    if not cName then
        return "Uknown";
    else 
        return cName;
    end
end

function getPlayerClassFromGuildRoster(PlayerName)
    local retClassName;
    local gPlayerName;
    for i = 1, GetNumGuildMembers() do
        gPlayerName, _, _, _, retClassName = GetGuildRosterInfo(i);
        if getPlayerPR == PlayerName then
            return retClassName;
        end
    end
    return "Unknown"
end 

-- GetPlayerPR  There are potentially 3 ways to get a PR.  PlayerDB, MRT_SFExport (imported from website), or adjusted PR based on selected Raid.
-- Current implementation is only from MRT_SFExport (PlayerDB is updated on new raid, but that data is not currently being used.)
function getPlayerPR(PlayerName)
    local currentrealm = GetRealmName();
    MRT_Debug("getPlayerPR called!")
    if not MRT_ReadOnly then 
        return getSFData(PlayerName);
    else
        local retVal = MRT_ROPlayerPR[PlayerName]
        if not retVal then
            MRT_Debug("getPlayerPR: MRT_ROPlayerPR is blank, checking MRT_PlayerDB")
            MRT_Debug("getPlayerPR: currentrealm: " ..currentrealm.. " PlayerName: ".. PlayerName)
            --look for playing playerDB
            --need to special case if PR doesn't exist.
            local playerExists = MRT_PlayerDB[currentrealm][PlayerName]
            if playerExists then 
                retVal = MRT_PlayerDB[currentrealm][PlayerName]["PR"]
            else 
                return "0.00"
            end
            if not retVal then
                return "0.00"
            else 
                return retVal
            end
        else
            return retVal
        end
    end
end

function ProcessROPlayerPR(data)
    local strName = ""
    local strPR = ""
    local strList = data;
    while strList ~= "" do
        strName, strList = getToken(strList,";")
        MRT_ROPlayerPR[strName], strList = getToken(strList,";");
    end
end

--getSFEPGP gets the EP and GP for a given player
function getSFEPGP(PlayerName)
    --MRT_Debug("getSFEPGP: Called!");        
    --MRT_Debug("getSFEPGP: PlayerName: "..PlayerName);
    return getSFData(PlayerName);
end
function getSFData(PlayerName)
    MRT_Debug("getSFData: Called!: " ..PlayerName);
    if not MRT_SFExport["info"] then
        return "0.00";
    else
        MRT_Debug("getSFEPGP: about to start loop");        
        local playerCount = MRT_SFExport["info"]["total_players"];
        for key, value in pairs(MRT_SFExport["players"]) do
            local tblName = stripRealm(value["name"])
            --MRT_Debug("getSFEPGP: tblName: "..tblName);        
            if strcomp(tblName,PlayerName) then
                MRT_Debug("getSFEPGP: Found player"); 
                MRT_Debug("getSFEPGP: value[name]: "..tblName);        
                for k, v in pairs(value["points"]) do
                    MRT_Debug("getSFEPGP: v[points_current]: "..v["points_current"]);
                    if v["multidkp_id"]  == "2" then 
                        return (v["points_current"]), (v["points_earned"]), (v["points_spent"]); --don't forget actual points spent is points_spent + base GP (TBC Phase 2 is 5000)
                    end 
                end
            end
        end
        --MRT_Debug("getSFEPGP: didn't find name returning zeros");  
        return "0.00", "0.00", "0.00";
    end
end

--use this function to remove realm suffix from the string
function stripRealm(strName)
    local sText = strName;
    local intFound = strfind(sText, "-")
    if not intFound then
        return sText;
    else
        return string.sub(sText, 1, intFound-1);
    end
end

function strcomp(str1, str2)
    local s1 = string.lower(str1);
    local s2 = string.lower(str2);
    return (s1==s2);
end
-- @param man_diff: used by GUI when a bosskill was added manually
--                  valid values: "H", "N", nil
function MRT_AddBosskill(bossname, man_diff, bossID, raidnum)
    local lRaidNum
    if (MRT_NumOfCurrentRaid) or (raidnum) then 
        if not MRT_NumOfCurrentRaid then
            lRaidNum = raidnum
        else
            lRaidNum = MRT_NumOfCurrentRaid
        end
    else 
        MRT_Debug("MRT_AddBosskill: boss: "..bossname.. " no current raid and raidnum not passed in.");
        return; 
    end
    MRT_Debug("Adding bosskill to RaidLog[] - tracked boss: "..bossname);
    local maxPlayers = MRT_RaidLog[lRaidNum]["RaidSize"];
    local _, _, diffID = MRT_GetInstanceInfo();
    if (man_diff) then
        diffID = MRT_RaidLog[lRaidNum]["DiffID"];
        if (man_diff == "H" and (diffID == 3 or diffID == 4)) then
            diffID = diffID + 2;
        end
    end
    local trackedPlayers = {};
    local numRaidMembers = MRT_GetNumRaidMembers();
    for i = 1, numRaidMembers do
        local playerName, _, playerSubGroup, _, _, _, _, playerOnline = GetRaidRosterInfo(i);
        -- check group number and group related tracking options
        if (not MRT_Options["Attendance_GroupRestriction"] or (playerSubGroup <= (maxPlayers / 5))) then
            -- check online status and online status related tracking options
            if (MRT_Options["Attendance_TrackOffline"] or playerOnline == 1) then
                tinsert(trackedPlayers, playerName);
            end
        end
    end
    local MRT_BossKillInfo = {
        ["Players"] = trackedPlayers,
        ["Name"] = bossname,
        ["Date"] = MRT_GetCurrentTime(),
        ["Difficulty"] = diffID,
        ["BossId"] = bossID,
    }
    tinsert(MRT_RaidLog[lRaidNum]["Bosskills"], MRT_BossKillInfo);
    MRT_NumOfLastBoss = #MRT_RaidLog[lRaidNum]["Bosskills"];
    if (bossname ~= MRT_L.Core["GuildAttendanceBossEntry"] and MRT_Options["Attendance_GuildAttendanceCheckEnabled"]) then
        if (MRT_Options["Attendance_GuildAttendanceCheckNoAuto"]) then
            StaticPopupDialogs["MRT_GA_MSGBOX"] = {
                preferredIndex = 3,
                text = string.format("MRT: "..MRT_L.Core["GuildAttendanceMsgBox"], bossname),
                button1 = MRT_L.Core["MB_Yes"],
                button2 = MRT_L.Core["MB_No"],
                OnAccept = function() MRT_StartGuildAttendanceCheck(bossname); end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = false,
            }
            local msgbox = StaticPopup_Show("MRT_GA_MSGBOX");
            msgbox.bossname = bossname;
        else
            MRT_StartGuildAttendanceCheck(bossname);
        end
    end
    MRT_ArrayBosslast = bossname;
    wipe(MRT_ArrayBossID);
end

function MRT_EndActiveRaid()
    if (not MRT_NumOfCurrentRaid) then return; end
    MRT_Debug("Ending active raid...");
    -- disable RaidRosterScanTimer
    MRT_RaidRosterScanTimer:SetScript("OnUpdate", nil);
    -- update DB
    local currentTime = MRT_GetCurrentTime();
    for key, value in pairs (MRT_RaidLog[MRT_NumOfCurrentRaid]["Players"]) do
        if (not MRT_RaidLog[MRT_NumOfCurrentRaid]["Players"][key]["Leave"]) then
            MRT_RaidLog[MRT_NumOfCurrentRaid]["Players"][key]["Leave"] = currentTime;
        end
    end
    MRT_RaidLog[MRT_NumOfCurrentRaid]["StopTime"] = currentTime;
    MRT_NumOfCurrentRaid = nil;
    MRT_NumOfLastBoss = nil;
    -- update LDB text and icon
    MRT_LDB_DS.icon = "Interface\\AddOns\\ClassicRaidTracker_Stormforged\\icons\\icon_disabled";
end

function MRT_TakeSnapshot()
    if (MRT_NumOfCurrentRaid) then
        MRT_Print(MRT_L.Core["TakeSnapshot_CurrentRaidError"]);
        return false;
    end
    if (not MRT_IsInRaid()) then
        MRT_Print(MRT_L.Core["TakeSnapshot_NotInRaidError"]);
        return false;
    end
    MRT_CreateNewRaid("Snapshot", 40, 0);
    MRT_EndActiveRaid();
    MRT_Print(MRT_L.Core["TakeSnapshot_Done"]);
    return true;
end


-------------------------------
--  loot tracking functions  --
-------------------------------
-- track loot based on chatmessage recognized by event CHAT_MSG_LOOT
MRT_LastLooter = "";
MRT_LastLootitem = "";
MRT_LastLootTime = "";
function MRT_AutoAddLoot(chatmsg)
    MRT_Debug("Loot event received. Processing...");
    -- patterns LOOT_ITEM / LOOT_ITEM_SELF are also valid for LOOT_ITEM_MULTIPLE / LOOT_ITEM_SELF_MULTIPLE - but not the other way around - try these first
    -- first try: somebody else received multiple loot (most parameters)
    local playerName, itemLink, itemCount = deformat(chatmsg, LOOT_ITEM_MULTIPLE);
    -- next try: somebody else received single loot
    if (playerName == nil) then
        itemCount = 1;
        playerName, itemLink = deformat(chatmsg, LOOT_ITEM);
    end
    -- if player == nil, then next try: player received multiple loot
    if (playerName == nil) then
        playerName = UnitName("player");
        itemLink, itemCount = deformat(chatmsg, LOOT_ITEM_SELF_MULTIPLE);
    end
    -- if itemLink == nil, then last try: player received single loot
    if (itemLink == nil) then
        itemCount = 1;
        itemLink = deformat(chatmsg, LOOT_ITEM_SELF);
    end
    -- if itemLink == nil, then there was neither a LOOT_ITEM, nor a LOOT_ITEM_SELF message
    if (itemLink == nil) then
        -- MRT_Debug("No valid loot event received.");
        return;
    end
    -- if code reaches this point, we should have a valid looter and a valid itemLink
    -- SF: hack to assign to disenchanted playerName = "disenchanted";
    MRT_Debug("Item looted - Looter is "..playerName.." and loot is "..itemLink);
    --cache the item
    local itemName, _, itemId, itemString, itemRarity, itemColor, itemLevel, _, itemType, itemSubType, _, _, _, _, itemClassID, itemSubClassID = MRT_GetDetailedItemInformation(itemLink);
    if not MRT_MasterLooter then
        MRT_MasterLooter = getMasterLooter();
    end

    if MRT_ReadOnly or isMasterLootSet() then
        MRT_Debug("MRT_AutoAddLoot: readonly mode or MasterLoot set");
        --if readonly or ML set, wait for channel message
        --should set an option here to sync with channel or proximity
        
        if isMasterLooter() then --if you're the ML, process it.
            MRT_Debug("MRT_AutoAddLoot: You are the ML process it!");
            MRT_AutoAddLootItem(playerName, itemLink, itemCount);

        elseif not MRT_ReadOnly then  --you are not the masterlooter and not Readonly then check if sync to master is on.
            --if not readonly and sync is not on, process it
            MRT_Debug("MRT_AutoAddLoot: You are not ML and not readonly");
            if not MRT_Options["ItemTracking_SyncWML"] then
                MRT_Debug("MRT_AutoAddLoot: Syncing is not set, process it!");
                MRT_AutoAddLootItem(playerName, itemLink, itemCount);
            end
        elseif not isMasterLootSet() then
            MRT_Debug("MRT_AutoAddLoot: readonly and ML not set, process it!");
            MRT_AutoAddLootItem(playerName, itemLink, itemCount);
        end
        MRT_Debug("MRT_AutoAddLoot: waiting for loot message from ML");    
    else
        --If normal mode and masterlooter is not set process it.
        MRT_Debug("MRT_AutoAddLoot: not readonly mode and ML not set, process it!");
        MRT_AutoAddLootItem(playerName, itemLink, itemCount);
        --I don't think this is needed...
        --MRT_LastLooter = playerName
        --MRT_LastLootitem = itemLink
    end
end

function isMasterLootSet()
    local strLootMethod = GetLootMethod();
    return strLootMethod == "master";
end

function isMasterLooter()
    -- return true if master looter and player is the same
    -- only use this for determining whether or not to send comms messages, don't use this for anything else.
    MRT_Debug("IsMasterLooter called")
    local ML = getMasterLooter();
    MRT_Debug("IsMasterLooter: ML = " ..ML)

    local PN = UnitName("player");
    MRT_Debug("IsMasterLooter: PN = " ..PN)
    return ML == PN;
end

function MRT_SendAddonMessage(msg, channel, target)
    local strMsg = serializeAddonMessage(msg);
    --add message to the message log
    if channel == "RAID" then
        MRT_Debug("MRT_SendAddonMessage: Sending message to RAID")
        if not MRT_ChannelMsgStore then
            --add first entry.
            MRT_ChannelMsgStore = {};
            MRT_ChannelMsgStore[msg["RaidID"]] = {};
        end
        if not MRT_ChannelMsgStore[msg["RaidID"]] then
            MRT_ChannelMsgStore[msg["RaidID"]] = {};
        end
        tinsert(MRT_ChannelMsgStore[msg["RaidID"]], msg)

        C_ChatInfo.SendAddonMessage("SFRT", strMsg, channel);
        MRT_Debug("sending strMsg: " ..strMsg)
        --increment message ID
        MRT_Msg_ID = MRT_Msg_ID + 1;
    elseif channel == "WHISPER" then
        MRT_Debug("MRT_SendAddonMessage: Sending message to WHISPER")
        if not MRT_ChannelMsgRequestStore then
            --add first entry.
            MRT_ChannelMsgRequestStore = {};
            MRT_ChannelMsgRequestStore[msg["RaidID"]] = {};
        end
        tinsert(MRT_ChannelMsgRequestStore[msg["RaidID"]], msg);
        local strTarget
        if not target then 
            strTarget = getMasterLooter();
        else
            strTarget = target
        end
        C_ChatInfo.SendAddonMessage("SFRT", strMsg, channel, strTarget);
        MRT_Debug("sending strMsg: " ..strMsg)
        MRT_Msg_Request_ID = MRT_Msg_Request_ID + 1;
    end
end

function serializeAddonMessage(msg)
    local retVal = msg["RaidID"]..","..msg["ID"]..","..msg["Time"]..","..msg["Data"]..","..msg["EventID"];
    return retVal;
end	

function autoAssign (itemName)
    local SF_AUTOASSIGN_ITEM_LIST = {
        ["Elementium Ore"] = "bank";
        ["Sulfuron Ingot"] = "bank";
        --["Felheart Bracers"] = "bank";
        --["Belt of Might"] = "bank";
        --["Giantstalker's Bracers"] = "bank";
        --["Giantstalker's Belt"] = "bank";
        --["Bracers of Might"] = "bank";
        --["Felheart Belt"] = "bank";
        --["Nightslayer Belt"] = "bank";
        ["Stringy Wolf Meat"] = "bank";
    }
    local retval = SF_AUTOASSIGN_ITEM_LIST[itemName];
    return retval;
end


-- track loot for a given player and item
function MRT_AutoAddLootItem(playerName, itemLink, itemCount)
	if (not playerName) then return; end
	if (not itemLink) then return; end
	if (not itemCount) then return; end
	--MRT_Debug("MRT_AutoAddLootItem called - playerName: "..playerName.." - itemLink: "..itemLink.." - itemCount: "..itemCount);
    -- example itemLink: |cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0|h[Broken Fang]|h|r (outdated!)
    local itemName, _, itemId, itemString, itemRarity, itemColor, itemLevel, _, itemType, itemSubType, _, _, _, _, itemClassID, itemSubClassID = MRT_GetDetailedItemInformation(itemLink);
    if (not itemName == nil) then MRT_Debug("Panic! Item information lookup failed horribly. Source: MRT_AutoAddLootItem()"); return; end
    -- check options, if this item should be tracked
    if (MRT_Options["Tracking_MinItemQualityToLog"] > itemRarity) then MRT_Debug("Item not tracked - quality is too low."); return; end
    if (MRT_Options["Tracking_OnlyTrackItemsAboveILvl"] > itemLevel) then MRT_Debug("Item not tracked - iLvl is too low."); return; end
    -- itemClassID 3 = "Gem", itemSubClassID 11 = "Artifact Relic"; itemClassID 7 = "Tradeskill", itemSubClassID 4 = "Jewelcrafting", 12 = Enchanting
    if (MRT_Options["ItemTracking_IgnoreGems"] and itemClassID == 3 and itemSubClassID ~= 11) then MRT_Debug("Item not tracked - it is a gem and the corresponding ignore option is on."); return; end
    if (MRT_Options["ItemTracking_IgnoreGems"] and itemClassID == 7 and itemSubClassID == 4) then MRT_Debug("Item not tracked - it is a gem and the corresponding ignore option is on."); return; end
    if (MRT_Options["ItemTracking_IgnoreEnchantingMats"] and itemClassID == 7 and itemSubClassID == 12) then MRT_Debug("Item not tracked - it is a enchanting material and the corresponding ignore option is on."); return; end
    if (MRT_IgnoredItemIDList[itemId]) then MRT_Debug("Item not tracked - ItemID is listed on the ignore list"); return; end
    local dkpValue = 0;
    local lootAction = nil;
    local itemNote = nil;
    local offspec = false;
    local supressCostDialog = nil;
    local gp1 = nil;
    -- if EPGP GP system is enabled, get GP values
    -- SF: Old Code here.
    --if (MRT_Options["ItemTracking_UseEPGPValues"]) then
    --    gp1, gp2 = LibGP:GetValue(itemLink);
    --   if (not gp1) then
    --        dkpValue = 0
    --    elseif (not gp2) then
    --        dkpValue = gp1
    --    else
    --        dkpValue = gp1
    --        itemNote = string.format("%d or %d", gp1, gp2)
    --    end
    --end
    
    -- SF: use this setting to get Stormforged GP values
    -- SF: ep/gp code here.

    if (MRT_Options["ItemTracking_UseEPGPValues"]) then
        MRT_Debug("MRT_AutoAddLootItem called - pregetvalue");
        gp1 = LibSFGP:GetValue(itemLink);
        MRT_Debug("MRT_AutoAddLootItem called - postgetvalue");
        if (not gp1) then
            MRT_Debug("MRT_AutoAddLootItem called - gp1 =nil");
            dkpValue = 0
        else
            MRT_Debug("MRT_AutoAddLootItem called - gp1 !=nil = "..gp1);
            dkpValue = gp1
            --itemNote = string.format("%d", gp1);
        end
    end

    -- if an external function handles item data, notify it
    if (MRT_ExternalItemCostHandler.func) then
        local notifierInfo = {
            ["ItemLink"] = itemLink,
            ["ItemString"] = itemString,
            ["ItemId"] = itemId,
            ["ItemName"] = itemName,
            ["ItemColor"] = itemColor,
            ["ItemCount"] = itemCount,
            ["Looter"] = playerName,
            ["Traded"] = false,
            ["DKPValue"] = dkpValue,
            ["Time"] = MRT_GetCurrentTime(),
        };
        local retOK, dkpValue_tmp, playerName_tmp, itemNote_tmp, lootAction_tmp, supressCostDialog_tmp = pcall(MRT_ExternalItemCostHandler.func, notifierInfo);
        if (retOK) then
            dkpValue = dkpValue_tmp;
            playerName = playerName_tmp;
            itemNote = itemNote_tmp;
            lootAction = lootAction_tmp;
            supressCostDialog = supressCostDialog_tmp;
        end
        if (lootAction == MRT_LOOTACTION_BANK) then
            playerName = "bank";
        elseif (lootAction == MRT_LOOTACTION_DISENCHANT) then
            playerName = "disenchanted";
        elseif (lootAction == MRT_LOOTACTION_DELETE) then
            playerName = "_deleted_";
        end
    end
    -- Quick&Dirty for trash drops before first boss kill
    if (MRT_NumOfLastBoss == nil) then
        MRT_Debug("MRT_AutoAddLootItem: MRT_NumOfLastBoss: nil");
        MRT_AddBosskill(MRT_L.Core["Trash Mob"], "N");
    end
    -- SF: set default values for looter.
    local dLooter = nil;
    dLooter = autoAssign(itemName);
    if not dLooter then
        dLooter = "unassigned";
    end
    -- SF: add a note to who it was looted to.
    local dNote;
    if not itemNote then
        dNote = "looted to: "..playerName;
    else
        dNote = itemNote.."looted to: "..playerName;
    end
    -- if code reach this point, we should have valid item information, an active raid and at least one boss kill entry - make a table!
    local MRT_LootInfo = {
        ["ItemLink"] = itemLink,
        ["ItemString"] = itemString,
        ["ItemId"] = itemId,
        ["ItemName"] = itemName,
        ["ItemColor"] = itemColor,
        ["ItemCount"] = itemCount,
        ["Looter"] = dLooter, -- playerName
        ["Traded"] = false,
        ["DKPValue"] = dkpValue,
        ["BossNumber"] = MRT_NumOfLastBoss,
        ["Time"] = MRT_GetCurrentTime(),
        ["Note"] = dNote, -- itemNote
        ["OffSpec"] = offspec, --OffSpec costing
    };
    MRT_Debug("MRT_AutoAddLootItem: adding to table");
    tinsert(MRT_RaidLog[MRT_NumOfCurrentRaid]["Loot"], MRT_LootInfo);
    MRT_Debug("MRT_AutoAddLootItem: MRT_NumOfCurrentRaid: " ..MRT_NumOfCurrentRaid);
    MRT_GUI_RaidAttendeesTableUpdate(MRT_NumOfCurrentRaid);
    MRT_GUI_RaidDetailsTableUpdate(MRT_NumOfCurrentRaid);
    if isMasterLooter() then 
        MRT_Debug("MRT_AutoAddLootItem: MasterLooter send message");
        -- send message to addon channel with new loot message
        local msg = {
            ["RaidID"] = MRT_NumOfCurrentRaid,
            ["ID"] = MRT_Msg_ID,
            ["Time"] = MRT_MakeEQDKP_TimeShort(MRT_GetCurrentTime()),
            ["Data"] = playerName..";"..itemLink..";"..itemCount,
            ["EventID"] = "3",
        }
        MRT_SendAddonMessage(msg, "RAID");
    end
    -- get current loot mode
    local isPersonal = select(1, GetLootMethod()) == "personalloot"
    -- check if we should ask the player for item cost
    if (supressCostDialog or (not MRT_Options["Tracking_AskForDKPValue"]) or (isPersonal and not MRT_Options["Tracking_AskForDKPValuePersonal"])) then
        -- notify registered, external functions
        local itemNum = #MRT_RaidLog[MRT_NumOfCurrentRaid]["Loot"];
        if (#MRT_ExternalLootNotifier > 0) then
            local itemInfo = {};
            for key, val in pairs(MRT_RaidLog[MRT_NumOfCurrentRaid]["Loot"][itemNum]) do
                itemInfo[key] = val;
            end
            if (itemInfo.Looter == "bank") then
                itemInfo.Action = MRT_LOOTACTION_BANK;
            elseif (itemInfo.Looter == "disenchanted") then
                itemInfo.Action = MRT_LOOTACTION_DISENCHANT;
            elseif (itemInfo.Looter == "_deleted_") then
                itemInfo.Action = MRT_LOOTACTION_DELETE;
            else
                itemInfo.Action = MRT_LOOTACTION_NORMAL;
            end
            for i, val in ipairs(MRT_ExternalLootNotifier) do
                pcall(val, itemInfo, MRT_NOTIFYSOURCE_ADD_SILENT, MRT_NumOfCurrentRaid, itemNum);
            end
        end
        return;
    end
    if (MRT_Options["Tracking_MinItemQualityToGetDKPValue"] > MRT_ItemColorValues[itemColor]) then return; end
    -- ask the player for item cost
    MRT_DKPFrame_AddToItemCostQueue(MRT_NumOfCurrentRaid, #MRT_RaidLog[MRT_NumOfCurrentRaid]["Loot"]);
end

function MRT_ManualAddLoot(itemLink, looter, cost, traded)
    if (not MRT_NumOfCurrentRaid) then
        MRT_Print(MRT_L["GUI"]["No active raid"]);
        return;
    end
    if (not MRT_NumOfLastBoss) then MRT_AddBosskill(MRT_L.Core["Trash Mob"]); end
    local itemName, _, itemId, itemString, itemRarity, itemColor, itemLevel, _, itemType, itemSubType, _, _, _, _ = MRT_GetDetailedItemInformation(itemLink);
    local offspec = false;
    local traded = false;
    if (not itemName) then
        MRT_Debug("MRT_ManualAddLoot(): Failed horribly when trying to get item informations.");
        return;
    end
    if (MRT_NumOfLastBoss == nil) then
        MRT_AddBosskill(MRT_L.Core["Trash Mob"], "N");
    end
    local lootInfo = {
        ["ItemLink"] = itemLink,
        ["ItemString"] = itemString,
        ["ItemId"] = itemId,
        ["ItemName"] = itemName,
        ["ItemColor"] = itemColor,
        ["ItemCount"] = 1,
        ["Looter"] = looter,
        ["Traded"] = traded,
        ["DKPValue"] = cost,
        ["BossNumber"] = MRT_NumOfLastBoss,
        ["Time"] = MRT_GetCurrentTime(),
        ["OffSpec"] = offspec,
    };
    tinsert(MRT_RaidLog[MRT_NumOfCurrentRaid]["Loot"], lootInfo);
    local itemNum = #MRT_RaidLog[MRT_NumOfCurrentRaid]["Loot"];
    if (#MRT_ExternalLootNotifier > 0) then
        local itemInfo = {};
        for key, val in pairs(MRT_RaidLog[MRT_NumOfCurrentRaid]["Loot"][itemNum]) do
            itemInfo[key] = val;
        end
        if (itemInfo.Looter == "bank") then
            itemInfo.Action = MRT_LOOTACTION_BANK;
        elseif (itemInfo.Looter == "disenchanted") then
            itemInfo.Action = MRT_LOOTACTION_DISENCHANT;
        elseif (itemInfo.Looter == "_deleted_") then
            itemInfo.Action = MRT_LOOTACTION_DELETE;
        else
            itemInfo.Action = MRT_LOOTACTION_NORMAL;
        end
        for i, val in ipairs(MRT_ExternalLootNotifier) do
            pcall(val, itemInfo, MRT_NOTIFYSOURCE_ADD_GUI, MRT_NumOfCurrentRaid, itemNum);
        end
    end
    return;
end


---------------------------
--  loot cost functions  --
---------------------------
-- basic idea: add looted items to a little queue and ask cost for each item in the queue
--             this should avoid missing dialogs for fast looted items
-- note: standard dkpvalue is already 0 (unless EPGP-system-support enabled)
function MRT_DKPFrame_AddToItemCostQueue(raidnum, itemnum)
    local MRT_DKPCostQueueItem = {
        ["RaidNum"] = raidnum,
        ["ItemNum"] = itemnum,
    }
    tinsert(MRT_AskCostQueue, MRT_DKPCostQueueItem);
    if (MRT_AskCostQueueRunning) then return; end
    MRT_AskCostQueueRunning = true;
    MRT_DKPFrame_AskCost();
end

-- process first queue entry
function MRT_DKPFrame_AskCost()
    -- if there are no entries in the queue, then return
    if (#MRT_AskCostQueue == 0) then
        MRT_AskCostQueueRunning = nil;
        return;
    end
    -- else format text and show "Enter Cost" frame
    local raidNum = MRT_AskCostQueue[1]["RaidNum"];
    local itemNum = MRT_AskCostQueue[1]["ItemNum"];
    -- gather playerdata and fill drop down menu
    local playerData = {};
    for i, val in ipairs(MRT_RaidLog[raidNum]["Bosskills"][MRT_NumOfLastBoss]["Players"]) do
        playerData[i] = { val };
    end
    table.sort(playerData, function(a, b) return (a[1] < b[1]); end );
    MRT_DKPFrame_DropDownTable:SetData(playerData, true);
    if (#playerData < 8) then
        MRT_DKPFrame_DropDownTable:SetDisplayRows(#playerData, 15);
    else
        MRT_DKPFrame_DropDownTable:SetDisplayRows(8, 15);
    end
    MRT_DKPFrame_DropDownTable.frame:Hide();
    -- set up rest of the frame
    MRT_GetDKPValueFrame_TextFirstLine:SetText(MRT_L.Core["DKP_Frame_EnterCostFor"]);
    MRT_GetDKPValueFrame_TextSecondLine:SetText(MRT_RaidLog[raidNum]["Loot"][itemNum]["ItemLink"]);
    MRT_GetDKPValueFrame_TextThirdLine:SetText(string.format(MRT_L.Core.DKP_Frame_LootetBy, MRT_RaidLog[raidNum]["Loot"][itemNum]["Looter"]));
    MRT_GetDKPValueFrame_TTArea:SetWidth(MRT_GetDKPValueFrame_TextSecondLine:GetWidth());
    if (MRT_RaidLog[raidNum]["Loot"][itemNum]["DKPValue"] == 0) then
        MRT_GetDKPValueFrame_EB:SetText("");
    else
        MRT_GetDKPValueFrame_EB:SetText(tostring(MRT_RaidLog[raidNum]["Loot"][itemNum]["DKPValue"]));
    end
    if (MRT_RaidLog[raidNum]["Loot"][itemNum]["Note"]) then
        MRT_GetDKPValueFrame_EB2:SetText(MRT_RaidLog[raidNum]["Loot"][itemNum]["Note"]);
    else
        MRT_GetDKPValueFrame_EB2:SetText("");
    end
    MRT_GetDKPValueFrame.Looter = MRT_RaidLog[raidNum]["Loot"][itemNum]["Looter"];
    -- set autoFocus of EditBoxes
    if (MRT_Options["Tracking_AskCostAutoFocus"] == 3 or (MRT_Options["Tracking_AskCostAutoFocus"] == 2 and UnitAffectingCombat("player")) ) then
        MRT_GetDKPValueFrame_EB:SetAutoFocus(false);
    else
        MRT_GetDKPValueFrame_EB:SetAutoFocus(true);
    end
    -- show DKPValue Frame
    MRT_GetDKPValueFrame:Show();
end

-- Buttons: OK, Cancel, Delete, Bank, Disenchanted
function MRT_DKPFrame_Handler(button)
    MRT_Debug("DKPFrame: "..button.." pressed.");
    -- if OK was pressed, check input data
    local dkpValue = nil;
    local lootNote = MRT_GetDKPValueFrame_EB2:GetText();
    if (button == "OK") then
        if (MRT_GetDKPValueFrame_EB:GetText() == "") then
            dkpValue = 0;
        else
            dkpValue = tonumber(MRT_GetDKPValueFrame_EB:GetText(), 10);
        end
        if (dkpValue == nil) then return; end
    end
    if (lootNote == "" or lootNote == " ") then
        lootNote = nil;
    end
    -- hide frame
    MRT_GetDKPValueFrame:Hide();
    -- this line is solely for debug purposes
    -- if (button == "Cancel") then return; end
    -- process item
    local raidNum = MRT_AskCostQueue[1]["RaidNum"];
    local itemNum = MRT_AskCostQueue[1]["ItemNum"];
    local looter = MRT_GetDKPValueFrame.Looter;
    if (button == "OK") then
        MRT_RaidLog[raidNum]["Loot"][itemNum]["Looter"] = looter;
        MRT_RaidLog[raidNum]["Loot"][itemNum]["DKPValue"] = dkpValue;
        MRT_RaidLog[raidNum]["Loot"][itemNum]["Note"] = lootNote;
        MRT_RaidLog[raidNum]["Loot"][itemNum]["Traded"] = MRT_GUI_FourRowDialog_CBTraded:GetChecked(); 
    elseif (button == "Cancel") then
    elseif (button == "Delete") then
        MRT_RaidLog[raidNum]["Loot"][itemNum]["Looter"] = "_deleted_";
        MRT_RaidLog[raidNum]["Loot"][itemNum]["DKPValue"] = 0;
    elseif (button == "Bank") then
        MRT_RaidLog[raidNum]["Loot"][itemNum]["Looter"] = "bank";
        MRT_RaidLog[raidNum]["Loot"][itemNum]["Note"] = lootNote;
        MRT_RaidLog[raidNum]["Loot"][itemNum]["DKPValue"] = 0;
        MRT_RaidLog[raidNum]["Loot"][itemNum]["Traded"] = MRT_GUI_FourRowDialog_CBTraded:GetChecked(); 
    elseif (button == "Disenchanted") then
        MRT_RaidLog[raidNum]["Loot"][itemNum]["Looter"] = "disenchanted";
        MRT_RaidLog[raidNum]["Loot"][itemNum]["Note"] = lootNote;
        MRT_RaidLog[raidNum]["Loot"][itemNum]["DKPValue"] = 0;
        MRT_RaidLog[raidNum]["Loot"][itemNum]["Traded"] = MRT_GUI_FourRowDialog_CBTraded:GetChecked(); 
    end
    -- notify registered, external functions
    if (#MRT_ExternalLootNotifier > 0) then
        local itemInfo = {};
        for key, val in pairs(MRT_RaidLog[raidNum]["Loot"][itemNum]) do
            itemInfo[key] = val;
        end
        if (itemInfo.Looter == "bank") then
            itemInfo.Action = MRT_LOOTACTION_BANK;
        elseif (itemInfo.Looter == "disenchanted") then
            itemInfo.Action = MRT_LOOTACTION_DISENCHANT;
        elseif (itemInfo.Looter == "_deleted_") then
            itemInfo.Action = MRT_LOOTACTION_DELETE;
        else
            itemInfo.Action = MRT_LOOTACTION_NORMAL;
        end
        for i, val in ipairs(MRT_ExternalLootNotifier) do
            pcall(val, itemInfo, MRT_NOTIFYSOURCE_ADD_POPUP, raidNum, itemNum);
        end
    end
    -- done with handling item - proceed to next one
    table.remove(MRT_AskCostQueue, 1);
    if (#MRT_AskCostQueue == 0) then
        MRT_AskCostQueueRunning = nil;
        -- queue finished, delete itemes which were marked as deleted - FIXME!
    else
        MRT_DKPFrame_AskCost();
    end
end

function MRT_GetDKPValueFrame_DropDownList_Toggle()
    if (MRT_DKPFrame_DropDownTable.frame:IsShown()) then
        MRT_DKPFrame_DropDownTable.frame:Hide();
    else
        MRT_DKPFrame_DropDownTable.frame:Show();
        MRT_DKPFrame_DropDownTable.frame:SetPoint("TOPRIGHT", MRT_GetDKPValueFrame_DropDownButton, "BOTTOMRIGHT", 0, 0);
    end
end


----------------------------
--  attendance functions  --
----------------------------
-- Create a table with names of guild members
function MRT_GuildRosterUpdate(frame, event, ...)
    local GuildRosterChanged = ...;
    if (MRT_GuildRosterInitialUpdateDone and not GuildRosterChanged) then return end;
    if (MRT_GuildRosterUpdating) then return end;
    MRT_GuildRosterUpdating = true;
    MRT_Debug("Processing GuildRoster...");
    if (frame:IsEventRegistered("GUILD_ROSTER_UPDATE")) then
        frame:UnregisterEvent("GUILD_ROSTER_UPDATE");
    end
    local guildRosterOfflineFilter = GetGuildRosterShowOffline();
    local guildRosterSelection = GetGuildRosterSelection();
    SetGuildRosterShowOffline(true);
    local numGuildMembers = GetNumGuildMembers();
    local guildRoster = {};
    for i = 1, numGuildMembers do
        local charName = GetGuildRosterInfo(i);
        if (charName) then
            guildRoster[string.lower(charName)] = charName;
        end
    end
    MRT_GuildRoster = guildRoster;
    SetGuildRosterShowOffline(guildRosterOfflineFilter);
    SetGuildRosterSelection(guildRosterSelection);
    MRT_GuildRosterUpdating = nil;
    frame:RegisterEvent("GUILD_ROSTER_UPDATE");
end

-- start guild attendance announcement
function MRT_StartGuildAttendanceCheck(bosskilled)
    if (not MRT_NumOfCurrentRaid) then return end;
    if (MRT_TimerFrame.GARunning) then return end;
    MRT_TimerFrame.GARunning = true;
    MRT_TimerFrame.GAStart = time();
    MRT_TimerFrame.GALastMsg = time();
    MRT_TimerFrame.GADuration = MRT_Options["Attendance_GuildAttendanceCheckDuration"];
    -- Put decider here: Which textblock should be used for the attendance check?
    local unformattedAnnouncement = nil;
    local bossName = bosskilled;
    if (bosskilled == "_attendancecheck_") then
        bossName = MRT_L.Core["GuildAttendanceBossEntry"];
    end
    if (MRT_Options["Attendance_GuildAttendanceUseCustomText"]) then
        unformattedAnnouncement = MRT_Options["Attendance_GuildAttendanceCustomText"];
    else
        if (bosskilled == "_attendancecheck_") then
            if (MRT_Options["Attendance_GuildAttendanceCheckUseTrigger"]) then
                unformattedAnnouncement = MRT_GA_TEXT_TRIGGER_NOBOSS;
            else
                unformattedAnnouncement = MRT_GA_TEXT_CHARNAME_NOBOSS;
            end
        else
            if (MRT_Options["Attendance_GuildAttendanceCheckUseTrigger"]) then
                unformattedAnnouncement = MRT_GA_TEXT_TRIGGER_BOSS;
            else
                unformattedAnnouncement = MRT_GA_TEXT_CHARNAME_BOSS;
            end
        end
    end
    -- send announcement text
    MRT_GuildAttendanceSendAnnouncement(unformattedAnnouncement, bossName, MRT_TimerFrame.GADuration);
    -- start GA timer frame
    MRT_TimerFrame.GAText = unformattedAnnouncement;
    MRT_TimerFrame.GABoss = bossName;
    MRT_TimerFrame.GADuration = MRT_TimerFrame.GADuration - 1;
    MRT_TimerFrame:SetScript("OnUpdate", function() MRT_GuildAttendanceCheckUpdate(); end);
end

function MRT_GuildAttendanceCheckUpdate()
    if (MRT_TimerFrame.GARunning) then
        -- is last message one minute ago?
        if ((time() - MRT_TimerFrame.GALastMsg) >= 60) then
            MRT_TimerFrame.GALastMsg = time();
            -- is GACheck duration up?
            if (MRT_TimerFrame.GADuration <= 0) then
                local timerUpText = "MRT: "..MRT_L.Core["GuildAttendanceTimeUpText"];
                MRT_GuildAttendanceSendAnnouncement(timerUpText, nil, nil);
                MRT_TimerFrame.GARunning = nil;
            else
                MRT_GuildAttendanceSendAnnouncement(MRT_TimerFrame.GAText, MRT_TimerFrame.GABoss, MRT_TimerFrame.GADuration);
                MRT_TimerFrame.GADuration = MRT_TimerFrame.GADuration - 1;
            end
        end
    end
    if (not MRT_TimerFrame.GARunning) then
        MRT_TimerFrame:SetScript("OnUpdate", nil);
    end
end

function MRT_GuildAttendanceSendAnnouncement(unformattedText, boss, timer)
    -- format text
    local announcement = unformattedText;
    if (boss) then
        announcement = string.gsub(announcement, "<<BOSS>>", boss);
    end
    if (timer) then
        announcement = string.gsub(announcement, "<<TIME>>", timer);
    end
    if (MRT_Options["Attendance_GuildAttendanceCheckTrigger"]) then
        announcement = string.gsub(announcement, "<<TRIGGER>>", MRT_Options["Attendance_GuildAttendanceCheckTrigger"]);
    end
    -- split announcement text block into multiple lines
    local textlineList = { strsplit("\n", announcement) };
    -- send announcement
    local targetChannel = "GUILD";
    for index, textline in ipairs(textlineList) do
        SendChatMessage(textline, targetChannel);
    end
end

function MRT_GuildAttendanceWhisper(player, source)
    if (MRT_NumOfCurrentRaid ~= nil) then
        local sendMsg = nil;
        local player_exist = nil;
        if (MRT_NumOfLastBoss) then
            for i, v in ipairs(MRT_RaidLog[MRT_NumOfCurrentRaid]["Bosskills"][MRT_NumOfLastBoss]["Players"]) do
                if (v == player) then player_exist = true; end;
            end
            if (player_exist == nil) then tinsert(MRT_RaidLog[MRT_NumOfCurrentRaid]["Bosskills"][MRT_NumOfLastBoss]["Players"], player); end;
        end
        if (player_exist) then
            sendMsg = "MRT: "..string.format(MRT_L.Core.GuildAttendanceReplyFail, player);
            MRT_Print(string.format(MRT_L.Core.GuildAttendanceFailNotice, source, player)); -- this line might just be deleted
        else
            sendMsg = "MRT: "..string.format(MRT_L.Core.GuildAttendanceReply, player);
            MRT_Print(string.format(MRT_L.Core.GuildAttendanceAddNotice, source, player));
        end
        SendChatMessage(sendMsg, "WHISPER", nil, source);
        MRT_ChatHandler.MsgToBlock = sendMsg;
    end
end


------------------------
--  helper functions  --
------------------------
function MRT_Debug(text)
    if (MRT_Options["General_DebugEnabled"]) then
        DEFAULT_CHAT_FRAME:AddMessage("MRT v."..MRT_ADDON_VERSION.." Debug: "..text, 1, 0.5, 0);
    end
end

function MRT_Debug_Always(text)
        DEFAULT_CHAT_FRAME:AddMessage(text, 1, 0.5, 0);
end

function MRT_Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("MRT: "..text, 1, 1, 0);
end

-- Parse static local strings
function MRT_Core_Frames_ParseLocal()
    MRT_GetDKPValueFrame_Title:SetText(" "..MRT_L.Core["DKP_Frame_Title"]);
    MRT_GetDKPValueFrame_CostString:SetText(MRT_L.Core["DKP_Frame_Cost"]);
    MRT_GetDKPValueFrame_NoteString:SetText(MRT_L.Core["DKP_Frame_Note"]);
    MRT_GetDKPValueFrame_OKButton:SetText(MRT_L.Core["DKP_Frame_OK_Button"]);
    MRT_GetDKPValueFrame_CancelButton:SetText(MRT_L.Core["DKP_Frame_Cancel_Button"]);
    MRT_GetDKPValueFrame_DeleteButton:SetText(MRT_L.Core["DKP_Frame_Delete_Button"]);
    MRT_GetDKPValueFrame_BankButton:SetText(MRT_L.Core["DKP_Frame_Bank_Button"]);
    MRT_GetDKPValueFrame_DisenchantedButton:SetText(MRT_L.Core["DKP_Frame_Disenchanted_Button"]);
    MRT_ExportFrame_Title:SetText(" "..MRT_L.Core["Export_Frame_Title"]);
    MRT_ExportFrame_ExplanationText:SetText(MRT_L.Core["Export_Explanation"]);
    MRT_ExportFrame_OKButton:SetText(MRT_L.Core["Export_Button"]);
    MRT_ExportFrame_ImportButton:SetText(MRT_L.Core["Import_Button"]);

end

-- GetNPCID - returns the NPCID or nil, if GUID was no NPC
function MRT_GetNPCID(GUID)
    if (uiVersion < 60000) then
        local first3 = tonumber("0x"..strsub(GUID, 3, 5));
        local unitType = bit.band(first3, 0x007);
        if ((unitType == 0x003) or (unitType == 0x005)) then
            return tonumber("0x"..strsub(GUID, 6, 10));
        else
            return nil;
        end
    else
        -- Player-GUID: Player-[server ID]-[player UID]
        -- other GUID: [Unit type]-0-[server ID]-[instance ID]-[zone UID]-[ID]-[Spawn UID]
        local unitType, _, _, _, _, ID = strsplit("-", GUID);
        if (unitType == "Creature") or (unitType == "Vehicle") then
            return tonumber(ID);
        else
            return nil;
        end
    end
end

-- @param itemIdentifer: Either itemLink or itemID and under special circumstances itemName
-- @usage local itemName, itemLink, itemId, itemString, itemRarity, itemColor, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice, itemClassID, itemSubClassID = MRT_GetDetailedItemInformation(itemIdentifier)
-- If itemIdentifier is not valid, the return value will be nil
-- otherwise, it will be a long tuple of item information
function MRT_GetDetailedItemInformation(itemIdentifier)
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice, itemClassID, itemSubClassID = GetItemInfo(itemIdentifier);
    if (not itemLink) then return nil; end
    local _, itemString, _ = deformat(itemLink, "|c%s|H%s|h%s|h|r");
    local itemId, _ = deformat(itemString, "item:%d:%s");
    local itemColor = MRT_ItemColors[itemRarity + 1];
    return itemName, itemLink, itemId, itemString, itemRarity, itemColor, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice, itemClassID, itemSubClassID;
end

function MRT_GetCurrentTime()
    if MRT_Options["Tracking_UseServerTime"] then
        local timestamp = GetServerTime();
        return timestamp;
    else
        return time();
    end
end

function MRT_MakeEQDKP_Time(timestamp)
    return date("%m/%d/%y %H:%M:%S", timestamp)
end

function MRT_MakeEQDKP_TimeShort(timestamp)
    return date("%H:%M:%S", timestamp)
end

function MRT_DeleteRaidLog()
    if (MRT_NumOfCurrentRaid) then
        MRT_Print(MRT_L.GUI["Active raid in progress."]);
        return;
    end
    MRT_RaidLog = {};
    MRT_PlayerDB = {};
    if (MRT_GUIFrame) then
        MRT_GUI_CompleteTableUpdate();
    end
end

-- Adding generic function for counting raid members in order to deal with WoW MoP changes
function MRT_GetNumRaidMembers()
    if (IsInRaid()) then
        return GetNumGroupMembers();
    else
        return 0;
    end
end

-- Adding generic function in order to deal with WoW MoP changes (to ensure backwards compatibility)
function MRT_IsInRaid()
    return IsInRaid();
end

function MRT_GetInstanceDifficulty()
    local _, _, iniDiff = GetInstanceInfo();
    -- handle non instanced territories as 40 player raids
    if (iniDiff == 0) then iniDiff = 9; end
    return iniDiff
end

function MRT_GetInstanceInfo()
    local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo()
    -- handle non instanced territories as 40 player raids
    if (difficultyID == 0) then
        difficultyID = 9;
        maxPlayers = 40;
    end
    return name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize
end
