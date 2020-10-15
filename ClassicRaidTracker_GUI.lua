-- ********************************************************
-- **              Mizus RaidTracker - GUI               **
-- **              <http://cosmocanyon.de>               **
-- ********************************************************
--
-- This addon is written and copyrighted by:
--    * Mîzukichan @ EU-Antonidas (2010-2018)
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
local mrt = ClassicRaidTracker

--------------
--  Locals  --
--------------
local deformat = LibStub("LibDeformat-3.0");
local ScrollingTable = LibStub("ScrollingTable");
local LibSFGP = LibStub("LibSFGearPoints-1.0");
LibSFGP:CacheTokenItemInfo();
local ag -- import reminder animationgroup
local agTrade -- trade reminder animationgroup

local MRT_GUI_RaidLogTableSelection = nil;
local MRT_GUI_RaidBosskillsTableSelection = nil;
local MRT_ExternalLootNotifier = {};
local lastShownNumOfRaids = nil;
local lastSelectedRaidNum = nil;
local lastShownNumOfBosses = nil;
local lastSelectedBossNum = nil;
local lastloot_select = nil;
local lastLootNum = nil;
local lastBossNum = nil;
local lastRaidNum = nil;
local MRT_RaidPlayerList= {};

--state of dialog
local lastLooter = nil;
local lastValue = nil;
local lastNote = nil;
local lastOS = nil;
local lastTraded = nil;
local lastLootItem = nil;
local lootFilterHack = 0;
local attendeeFilterHack = 0;
local bAutoCompleteCreated = false;

--tooltip for parsing loot time remaining
local tooltipForParsing = CreateFrame("GameTooltip", "RCLootCouncil_Tooltip_Parse", nil, "GameTooltipTemplate")
tooltipForParsing:UnregisterAllEvents() -- Don't use GameTooltip for parsing, because GameTooltip can be hooked by other addons.

-- table definitions
local MRT_RaidLogTableColDef = {
    {["name"] = MRT_L.GUI["Col_Num"], ["width"] = 25, ["defaultsort"] = "dsc"},
    {["name"] = MRT_L.GUI["Col_Date"], ["width"] = 75},
    {["name"] = MRT_L.GUI["Col_Zone"], ["width"] = 50},
    --{["name"] = MRT_L.GUI["Col_Size"], ["width"] = 25},
};
local MRT_RaidAttendeesTableColDef = {
    {["name"] = "", ["width"] = 1},                            -- invisible column for storing the player number index from the raidlog-table
    {["name"] = MRT_L.GUI["Col_Name"], ["width"] = 75},
    {["name"] = MRT_L.GUI["Col_PR"], ["width"] = 37},
    {["name"] = MRT_L.GUI["Col_Join"], ["width"] = 38},

};
--SF: Old RaidBosskillstable
--[[ local MRT_RaidBosskillsTableColDef = {
    {["name"] = MRT_L.GUI["Col_Num"], ["width"] = 25, ["defaultsort"] = "dsc"},
    {["name"] = MRT_L.GUI["Col_Time"], ["width"] = 40},
    {["name"] = MRT_L.GUI["Col_Name"], ["width"] = 105},
    {["name"] = MRT_L.GUI["Col_Difficulty"], ["width"] = 45},
}; ]]
--SF: new RaidBossKillsTable
local MRT_RaidBosskillsTableColDef = {
    {["name"] = MRT_L.GUI["Col_Num"], ["width"] = 25, ["defaultsort"] = "dsc"},
    {["name"] = MRT_L.GUI["Col_Name"], ["width"] = 125},
};
local MRT_BossLootTableColDef = {
    {["name"] = "", ["width"] = 1},                            -- invisible column for storing the loot number index from the raidlog-table
    {                                                          -- coloumn for Item Icon - need to store ID
        ["name"] = "Icon",
        ["width"] = 30,
        ["DoCellUpdate"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, self, ...)
            -- icon handling
            if fShow then
                --MRT_Debug("self:GetCell(realrow, column) = "..self:GetCell(realrow, column));
                local itemId = self:GetCell(realrow, column);
                local itemTexture = GetItemIcon(itemId);
                --cellFrame:SetBackdrop( { bgFile = itemTexture } );            -- put this back in, if and when SetBackdrop can handle texture IDs
                if not (cellFrame.cellItemTexture) then
                    cellFrame.cellItemTexture = cellFrame:CreateTexture();
                end
                cellFrame.cellItemTexture:SetTexture(itemTexture);
                cellFrame.cellItemTexture:SetTexCoord(0, 1, 0, 1);
                cellFrame.cellItemTexture:Show();
                cellFrame.cellItemTexture:SetPoint("CENTER", cellFrame.cellItemTexture:GetParent(), "CENTER");
                cellFrame.cellItemTexture:SetWidth(30);
                cellFrame.cellItemTexture:SetHeight(30);
            end
            -- tooltip handling
            local itemLink = self:GetCell(realrow, 6);
            cellFrame:SetScript("OnEnter", function()
                                             MRT_GUI_ItemTT:SetOwner(cellFrame, "ANCHOR_RIGHT");
                                             MRT_GUI_ItemTT:SetHyperlink(itemLink);
                                             MRT_GUI_ItemTT:Show();
                                           end);
            cellFrame:SetScript("OnLeave", function()
                                             MRT_GUI_ItemTT:Hide();
                                             MRT_GUI_ItemTT:SetOwner(UIParent, "ANCHOR_NONE");
                                           end);
        end,
    },
    {["name"] = MRT_L.GUI["Col_Name"], ["width"] = 120},
    {["name"] = MRT_L.GUI["Col_Looter"], ["width"] = 85},
    {["name"] = MRT_L.GUI["Col_Cost"], ["width"] = 45},
    {["name"] = "", ["width"] = 1},                            -- invisible column for itemString (needed for tooltip)
    {["name"] = MRT_L.GUI["Col_Time"], ["width"] = 45},
--[[ {
        ["name"] = MRT_L.GUI["Note"],
        ["width"] = 30,
        ["DoCellUpdate"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, self, ...)
            -- icon handling
            local lootNote = self:GetCell(realrow, column);
            if fShow and lootNote then
                cellFrame:SetBackdrop( { bgFile = "Interface\\BUTTONS\\UI-GuildButton-PublicNote-Up", insets = { left = 5, right = 5, top = 5, bottom = 5 }, } );
                cellFrame:SetScript("OnEnter", function()
                                                 MRT_GUI_ItemTT:SetOwner(cellFrame, "ANCHOR_RIGHT");
                                                 MRT_GUI_ItemTT:SetText(lootNote);
                                                 MRT_GUI_ItemTT:Show();
                                               end);
                cellFrame:SetScript("OnLeave", function()
                                                 MRT_GUI_ItemTT:Hide();
                                                 MRT_GUI_ItemTT:SetOwner(UIParent, "ANCHOR_NONE");
                                               end);
            else
                cellFrame:SetBackdrop(nil);
                cellFrame:SetScript("OnEnter", nil);
                cellFrame:SetScript("OnLeave", nil);
                MRT_GUI_ItemTT:Hide();
                MRT_GUI_ItemTT:SetOwner(UIParent, "ANCHOR_NONE");
            end
        end,
    }, ]]
    {                                                          -- col for OffSpec
    ["name"] = "Done", 
    ["width"] = 30,
    ["DoCellUpdate"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, self, ...)
        -- Show Checkbox
        if fShow then
            local itemId = self:GetCell(realrow, column);
            --MRT_Debug("DoCellUpdateCB: Column: " ..column);
            
            if itemId then
                cellFrame:SetBackdrop( { bgFile = "Interface\\BUTTONS\\ui-checkbox-check", insets = { left = 0, right = 2, top = 2, bottom = 2 }, } );
            else
                cellFrame:SetBackdrop(nil);
            end
        end
        -- tooltip handling
        --[[ local itemLink = self:GetCell(realrow, 6);
        cellFrame:SetScript("OnEnter", function()
                                         MRT_GUI_ItemTT:SetOwner(cellFrame, "ANCHOR_RIGHT");
                                         MRT_GUI_ItemTT:SetHyperlink(itemLink);
                                         MRT_GUI_ItemTT:Show();
                                       end);
        cellFrame:SetScript("OnLeave", function()
                                         MRT_GUI_ItemTT:Hide();
                                         MRT_GUI_ItemTT:SetOwner(UIParent, "ANCHOR_NONE");
                                       end);  ]]
    end,
    },                  
};
local MRT_BossAttendeesTableColDef = {
    {["name"] = "", ["width"] = 1},                            -- invisible column for storing the attendee number index from the raidlog-table
    {["name"] = MRT_L.GUI["Col_Name"], ["width"] = 85},
};
local MRT_PlayerDropDownTableColDef = {
    {["name"] = "", ["width"] = 100},
};


-----------------
--  API-Stuff  --
-----------------
function MRT_RegisterLootNotifyGUI(functionToCall)
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

function MRT_UnregisterLootNotifyGUI(functionCalled)
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
---------------------------------------------------------------
--  Helper Function to detect dirty dialog                   --
---------------------------------------------------------------

function isDirty (strLooter, strValue, strNote, strOS, strTraded, strItemLink)
    --MRT_Debug("isDirty fired!");
    if not strItemLink then 
        if (strLooter == lastLooter) and (strValue == lastValue) and (strNote == lastNote) and (strOS == lastOS) and (strTraded == lastTraded) then
            --MRT_Debug("isDirty = false");
            return false;
        else
            --MRT_Debug("isDirty = true");
            return true;
        end
    else
        if (strLooter == lastLooter) and (strValue == lastValue) and (strNote == lastNote) and (strOS == lastOS) and (strTraded == lastTraded) and (strItemLink == lastLootItem) then
            --MRT_Debug("isDirty = false");
            return false;
        else
            --MRT_Debug("isDirty = true");
            return true;
        end
    end
end

---------------------------------------------------------------
--  parse localization and set up tables after ADDON_LOADED  --
---------------------------------------------------------------
function MRT_GUI_ParseValues()


    -- Parse title strings
    MRT_GUIFrame_Title:SetText(MRT_L.GUI["Header_Title"]);
  --  MRT_GUIFrame_RaidLogTitle:SetText(MRT_L.GUI["Tables_RaidLogTitle"]);
    MRT_GUIFrame_RaidLogTitle:SetPoint("TOPLEFT", MRT_GUIFrame, "TOPLEFT", 20, -10);

 --   MRT_GUIFrame_RaidBosskillsTitle:SetText(MRT_L.GUI["Tables_RaidBosskillsTitle"]);
  --  MRT_GUIFrame_BossLootTitle:SetText(MRT_L.GUI["Tables_RaidLootTitle"]);
    --MRT_GUIFrame_BossAttendeesTitle:SetText(MRT_L.GUI["Tables_BossAttendeesTitle"]);
    -- Create and anchor tables
    MRT_GUI_RaidLogTable = ScrollingTable:CreateST(MRT_RaidLogTableColDef, 4, nil, nil, MRT_GUIFrame);
    MRT_GUI_RaidLogTable.frame:SetPoint("TOPLEFT", MRT_GUIFrame_RaidLog_Export_Button, "BOTTOMLEFT", 0, -20);
    MRT_GUI_RaidLogTable:EnableSelection(true);

 --   MRT_GUIFrame_RaidAttendees_Filter:SetText(MRT_L.GUI["Header_Title"]);
    MRT_GUIFrame_RaidAttendees_Filter:SetPoint("TOPLEFT", MRT_GUI_RaidLogTable.frame, "BOTTOMLEFT", 7, -5);
    local valueList = {":casters", ":druid", ":healers", ":hunter", ":mage", ":melee", ":paladin", ":command", ":dominance", ":ranged",  ":rogue", ":shaman", ":diadem", ":circlet", ":warlock", ":warrior"}
    local maxButtonCount = 20;
    SetupAutoComplete(MRT_GUIFrame_RaidAttendees_Filter, valueList, maxButtonCount);
    --MRT_GUIFrame_RaidAttendees_Filter:SetAutoFocus(false);

 --   MRT_GUIFrame_RaidAttendeesTitle:SetText(MRT_L.GUI["Tables_RaidAttendeesTitle"]);
 --   MRT_GUIFrame_RaidAttendeesTitle:SetPoint("TOPLEFT", MRT_GUI_RaidLogTable.frame, "BOTTOMLEFT", 0, -15);
    MRT_GUI_RaidAttendeesTable = ScrollingTable:CreateST(MRT_RaidAttendeesTableColDef, 18, nil, nil, MRT_GUIFrame);
    MRT_GUI_RaidAttendeesTable.frame:SetPoint("TOPLEFT", MRT_GUIFrame_RaidAttendees_Filter, "BOTTOMLEFT",-7, -18);
    MRT_GUI_RaidAttendeesTable:EnableSelection(true);
    --uncomment when ready to try group by sorting
    MRT_GUI_RaidAttendeesTable:RegisterEvents({
        ["OnClick"] = function(rowFrame, cellFrame, data, cols, row, realrow, coloumn, scrollingTable, button, ...)
            MRT_Debug("MRT_GUI_RaidAttendeesTable:MRT_Onclick fired!");
            doOnClick(rowFrame, cellFrame, data, cols, row, realrow, coloumn, scrollingTable, button, false, MRT_GUIFrame_RaidAttendee_GroupByCB:GetChecked())  --pass group by true if checked.
            return true;
        end,
        
    });
    MRT_GUI_RaidBosskillsTable = ScrollingTable:CreateST(MRT_RaidBosskillsTableColDef, 6, nil, nil, MRT_GUIFrame);
    MRT_GUI_RaidBosskillsTable.frame:SetPoint("TOPLEFT", MRT_GUIFrame_RaidBosskillsTitle, "BOTTOMLEFT", 0, -15);
    MRT_GUI_RaidBosskillsTable:EnableSelection(true);
    MRT_GUI_RaidBosskillsTable:Hide();

    MRT_GUIFrame_BossLoot_Filter:SetPoint("TOPLEFT", MRT_GUIFrame_RaidLogTitle, "BOTTOMLEFT", 198, -15);    
    --setup bossloot filter
    MRT_GUIFrame_BossLoot_Filter:SetScript("OnEscapePressed", function (...)
            MRT_GUI_BossLootFilterResetFilter();
            return true;
        end);
    --local valueLootList = {":casters", ":druid", ":healers", ":hunter", ":mage", ":melee", ":ranged", ":paladin", ":players", ":rogue", ":shaman", ":warlock", ":warrior"}
    local valueLootList = {":player", ":players"}
    local maxButtonCount = 15;
    SetupAutoComplete(MRT_GUIFrame_BossLoot_Filter, valueLootList, maxButtonCount);
    MRT_GUIFrame_BossLoot_Filter:SetAutoFocus(false);

    MRT_GUIFrame_BossLoot_Add_Button:SetText(MRT_L.GUI["Button_Small_Add"]);
    MRT_GUIFrame_BossLoot_Add_Button:SetPoint("RIGHT", MRT_GUIFrame_BossLoot_Filter, "RIGHT", 23, 0);
    MRT_GUIFrame_BossLoot_Delete_Button:SetText(MRT_L.GUI["Button_Small_Delete"]);
    MRT_GUIFrame_BossLoot_Delete_Button:SetPoint("LEFT", MRT_GUIFrame_BossLoot_Add_Button, "RIGHT", 0, 0);
    MRT_GUIFrame_BossLoot_Modify_Button:SetText(MRT_L.GUI["Button_Modify"]);
    MRT_GUIFrame_BossLoot_Modify_Button:SetPoint("LEFT", MRT_GUIFrame_BossLoot_Delete_Button, "RIGHT", 0, 0);
    MRT_GUIFrame_BossLoot_RaidLink_Button:SetText("Link");
    MRT_GUIFrame_BossLoot_RaidLink_Button:SetPoint("LEFT", MRT_GUIFrame_BossLoot_Modify_Button, "RIGHT", 0, 0);
    MRT_GUIFrame_BossLoot_RaidAnnounce_Button:SetText("Bid");
    MRT_GUIFrame_BossLoot_RaidAnnounce_Button:SetPoint("LEFT", MRT_GUIFrame_BossLoot_RaidLink_Button, "RIGHT", 0, 0);
    MRT_GUIFrame_BossLoot_Trade_Button:SetText("Trade");
    MRT_GUIFrame_BossLoot_Trade_Button:SetPoint("LEFT", MRT_GUIFrame_BossLoot_RaidAnnounce_Button, "RIGHT", 0, 0);
    MRT_GUIFrame_BossLoot_Trade_Button:SetEnabled(false);

    MRT_GUI_BossLootTable = ScrollingTable:CreateST(MRT_BossLootTableColDef, 12, 32, nil, MRT_GUIFrame);           -- ItemId should be squared - so use 30x30 -> 30 pixels high
    MRT_GUI_BossLootTable.head:SetHeight(15);                                                                     -- Manually correct the height of the header (standard is rowHight - 30 pix would be different from others tables around and looks ugly)
    MRT_GUI_BossLootTable.frame:SetPoint("TOPLEFT", MRT_GUIFrame_BossLoot_Filter, "BOTTOMLEFT", -5, -20);
    MRT_GUI_BossLootTable:EnableSelection(true);
    MRT_GUI_BossLootTable:RegisterEvents({
        ["OnDoubleClick"] = function(rowFrame,cellFrame, data, cols, row, realrow, coloumn, scrollingTable, ...)
            --MRT_Debug("Doubleclick fired!");
            if not MRT_ReadOnly then 
                if MRT_GUI_FourRowDialog:IsVisible() then
                    if isDirty(MRT_GUI_FourRowDialog_EB2:GetText(), MRT_GUI_FourRowDialog_EB3:GetText(), MRT_GUI_FourRowDialog_EB4:GetText(),MRT_GUI_FourRowDialog_CB1:GetChecked(), MRT_GUI_FourRowDialog_CBTraded:GetChecked()) then
                        --MRT_Debug("STOnDoubleClick: isDirty == True");
                        local error = false;
                        error = MRT_GUI_LootModifyAccept(lastRaidNum, lastBossNum, lastLootNum);
                        if error then
                            StaticPopupDialogs.MRT_GUI_ok.text = MRT_GUI_FourRowDialog_EB2:GetText().." is not in this raid.  Please choose a valid character."
                            StaticPopup_Show("MRT_GUI_ok");
                            MRT_GUI_BossLootTable:SetSelection(lastloot_select);
                        end
                    end
                    MRT_GUI_LootModify();
                else
                    --MRT_Debug("in false condition");
                    MRT_GUI_LootModify();
                end
            end
        end,
        ["OnClick"] = function(rowFrame, cellFrame, data, cols, row, realrow, coloumn, scrollingTable, button, ...)
            --MRT_Debug("MRT_BoosLootTable:Onclick fired!");
            if not MRT_ReadOnly then 
                donotdeselect = false;
                doOnClick(rowFrame, cellFrame, data, cols, row, realrow, coloumn, scrollingTable, button, true, false)  --passing true so that we don't deselect in the loot table.
                if MRT_GUI_FourRowDialog:IsVisible() then
                    if isDirty(MRT_GUI_FourRowDialog_EB2:GetText(), MRT_GUI_FourRowDialog_EB3:GetText(), MRT_GUI_FourRowDialog_EB4:GetText(), MRT_GUI_FourRowDialog_CB1:GetChecked(),  MRT_GUI_FourRowDialog_CBTraded:GetChecked()) then
                        --MRT_Debug("STOnClick: isDirty == True");
                        local error = false;
                        error = MRT_GUI_LootModifyAccept(lastRaidNum, lastBossNum, lastLootNum);
                        if error then
                            MRT_Debug("STOnClick:error occured");
                            StaticPopupDialogs.MRT_GUI_ok.text = MRT_GUI_FourRowDialog_EB2:GetText().." is not in this raid.  Please choose a valid character."
                            StaticPopup_Show("MRT_GUI_ok");
                            MRT_GUI_BossLootTable:SetSelection(lastloot_select);
                            return true
                        end
                    end
                    MRT_GUI_LootModify();
                end
                return true;
            end
        end,
        
    });
    
    -- parse button local / anchor buttons relative to raid title
    MRT_GUIFrame_RaidLog_Export_Button:SetText(MRT_L.GUI["Button_Export"]);
    MRT_GUIFrame_RaidLog_Export_Button:SetPoint("TOPLEFT", MRT_GUIFrame_RaidLogTitle, "BOTTOMLEFT", -3, -12);
    MRT_GUIFrame_Import_PR_Button:SetText(MRT_L.GUI["Button_Import_PR"]);
    MRT_GUIFrame_Import_PR_Button:SetPoint("LEFT", MRT_GUIFrame_RaidLog_Export_Button, "RIGHT", 0, 0);
    MRT_GUIFrame_StartNewRaid_Button:SetText(MRT_L.GUI["Button_StartNewRaid"]);
    MRT_GUIFrame_StartNewRaid_Button:SetPoint("TOPRIGHT", MRT_GUIFrame_Import_PR_Button, "RIGHT", 22, 11);
    MRT_GUIFrame_RaidLog_Delete_Button:SetText(MRT_L.GUI["Button_Delete_Raid"]);
    MRT_GUIFrame_RaidLog_Delete_Button:SetPoint("LEFT", MRT_GUIFrame_StartNewRaid_Button, "RIGHT", 0, 0);

    MRT_GUIFrame_RaidAttendees_Add_Button:SetText(MRT_L.GUI["Button_Small_Add"]);
    MRT_GUIFrame_RaidAttendees_Add_Button:SetPoint("TOPLEFT", MRT_GUIFrame_RaidAttendees_Filter, "RIGHT", 1, 11);
    MRT_GUIFrame_RaidAttendees_Delete_Button:SetText(MRT_L.GUI["Button_Small_Delete"]);
    MRT_GUIFrame_RaidAttendees_Delete_Button:SetPoint("LEFT", MRT_GUIFrame_RaidAttendees_Add_Button, "RIGHT", 0, 0);
    MRT_GUIFrame_RaidAttendee_GroupByCB:SetPoint("LEFT", MRT_GUIFrame_RaidAttendees_Delete_Button, "RIGHT", 0, 0);

    -- Create difficulty drop down menu
    mrt:UI_CreateTwoRowDDM()
    -- Insert table data
    MRT_GUI_CompleteTableUpdate();

    --Above the raid list
    local l = MRT_GUIFrame:CreateLine()
    print(l)
    l:SetThickness(1)
    l:SetColorTexture(235,231,223,.5)
    l:SetStartPoint("TOPLEFT",22,-48)
    l:SetEndPoint("TOPLEFT",197,-48)

    --Above the player list
    local l = MRT_GUIFrame:CreateLine()
    print(l)
    l:SetThickness(1)
    l:SetColorTexture(235,231,223,.5)
    l:SetStartPoint("TOPLEFT",22,-171)
    l:SetEndPoint("TOPLEFT",197,-171)

    --Above the loot list
    local l = MRT_GUIFrame:CreateLine()
    print(l)
    l:SetThickness(1)
    l:SetColorTexture(235,231,223,.5)
    l:SetStartPoint("TOPLEFT",217,-57)
    l:SetEndPoint("TOPLEFT",600,-57)

    -- Create and anchor drop down menu table for add/modify loot dialog
    MRT_GUI_PlayerDropDownTable = ScrollingTable:CreateST(MRT_PlayerDropDownTableColDef, 9, nil, nil, MRT_GUI_FourRowDialog);
    MRT_GUI_PlayerDropDownTable.head:SetHeight(1);
    MRT_GUI_PlayerDropDownTable.frame:SetFrameLevel(3);
    MRT_GUI_PlayerDropDownTable.frame:Hide();
    MRT_GUI_PlayerDropDownTable:EnableSelection(false);
    MRT_GUI_PlayerDropDownTable:RegisterEvents({
        ["OnClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
            if (not realrow) then return true; end
            local playerName = MRT_GUI_PlayerDropDownTable:GetCell(realrow, column);
            if (playerName) then
                MRT_GUI_FourRowDialog_EB2:SetText(playerName);
                MRT_GUI_PlayerDropDownList_Toggle();
            end
            return true;
        end
    });

    ag = MRT_GUIFrame_Import_PR_Button:CreateAnimationGroup(); -- import button animationgroup
    agTrade =  MRT_GUIFrame_BossLoot_Trade_Button:CreateAnimationGroup(); -- trade button animationgroup


    MRT_GUI_FourRowDialog_CB1:SetHitRectInsets(0, 0, 0, 0)
    MRT_GUI_FourRowDialog_CBTraded:SetHitRectInsets(0, 0, 0, 0)
    MRT_GUI_FourRowDialog_CBTraded:Disable();

end

function mrt:UI_CreateTwoRowDDM()
    -- Create DropDownFrame
    if (not MRT_GUI_TwoRowDialog_DDM) then
        CreateFrame("Frame", "MRT_GUI_TwoRowDialog_DDM", MRT_GUI_TwoRowDialog, "MRT_Lib_UIDropDownMenuTemplate")
        MRT_GUI_TwoRowDialog_DDM:CreateFontString("MRT_GUI_TwoRowDialog_DDM_Text", "OVERLAY", "ChatFontNormal")
    end
    -- List of DropDownMenuItems
    local items = {
        { [1] = "Normal".." (20)" },
    }
    -- Anchor DropDownFrame
    MRT_GUI_TwoRowDialog_DDM:ClearAllPoints();
    MRT_GUI_TwoRowDialog_DDM:SetPoint("TOP", MRT_GUI_TwoRowDialog_EB1, "TOP", -4, -64);
    MRT_GUI_TwoRowDialog_DDM_Text:ClearAllPoints();
    MRT_GUI_TwoRowDialog_DDM_Text:SetPoint("BOTTOMLEFT", MRT_GUI_TwoRowDialog_DDM, "TOPLEFT", 14, 0);
    MRT_GUI_TwoRowDialog_DDM:Show();
    -- Click handler function
    local function OnClick(self)
       MRT_Lib_UIDropDownMenu_SetSelectedID(MRT_GUI_TwoRowDialog_DDM, self:GetID())
    end
    -- DropDownMenu initialize function
    local function initialize(self, level)
        local info = MRT_Lib_UIDropDownMenu_CreateInfo()
        for k2, v2 in ipairs(items) do
            for k, v in pairs(v2) do
                info = MRT_Lib_UIDropDownMenu_CreateInfo()
                info.text = v
                info.value = k
                info.func = OnClick
                MRT_Lib_UIDropDownMenu_AddButton(info, level)
            end
        end
    end
    -- Setup DropDownMenu
    MRT_Lib_UIDropDownMenu_Initialize(MRT_GUI_TwoRowDialog_DDM, initialize);
    MRT_Lib_UIDropDownMenu_SetWidth(MRT_GUI_TwoRowDialog_DDM, 236);
    MRT_Lib_UIDropDownMenu_SetButtonWidth(MRT_GUI_TwoRowDialog_DDM, 260);
    MRT_Lib_UIDropDownMenu_SetSelectedID(MRT_GUI_TwoRowDialog_DDM, 3);
    MRT_Lib_UIDropDownMenu_JustifyText(MRT_GUI_TwoRowDialog_DDM, "LEFT");
    -- Setup text
    MRT_GUI_TwoRowDialog_DDM_Text:SetText(MRT_L.GUI["Raid size"])
    -- Hide element
    MRT_GUI_TwoRowDialog_DDM:Hide();
end


---------------------
--  Show/Hide GUI  --
---------------------
function MRT_GUI_Toggle(readonly)

    if (not MRT_GUIFrame:IsShown()) then
        if MRT_ReadOnly then
            MRT_ReadOnly = false;
            RevertUI(false)
        end
        MRT_GUIFrame:Show();
        MRT_GUIFrame:SetScript("OnUpdate", function() MRT_GUI_OnUpdateHandler(); end);
        if (lastShownNumOfRaids ~= #MRT_RaidLog) then
            MRT_GUI_CompleteTableUpdate();
        elseif (lastSelectedRaidNum and lastShownNumOfBosses ~= #MRT_RaidLog[lastSelectedRaidNum]["Bosskills"]) then
            MRT_GUI_RaidDetailsTableUpdate(lastSelectedRaidNum);
        else
            MRT_GUI_RaidAttendeesTableUpdate(lastSelectedRaidNum);
            MRT_GUI_BossDetailsTableUpdate(lastSelectedBossNum);
        end
        --select active raid
        if (MRT_NumOfCurrentRaid) then
            MRT_Debug("MRT_GUI_TOGGLE MRT_NumOfCurrentRaid: " .. MRT_NumOfCurrentRaid);
            --MRT_GUIFrame_StartNewRaid_Button:SetEnabled(false);
            MRT_GUIFrame_StartNewRaid_Button:SetText(MRT_L.GUI["Button_EndCurrentRaid"]);
            --MRT_GUIFrame_EndCurrentRaid_Button:SetEnabled(true);
            MRT_GUI_RaidLogTable:SetSelection(1);
        else
            MRT_GUIFrame_StartNewRaid_Button:SetText(MRT_L.GUI["Button_StartNewRaid"]);
            --MRT_GUIFrame_StartNewRaid_Button:SetEnabled(true);
            --MRT_GUIFrame_EndCurrentRaid_Button:SetEnabled(false);
            local blnIsRowVisible = MRT_GUI_RaidLogTable:GetRow(1); -- get first row
            if not blnIsRowVisible then  -- if there is no row, then it is empty
                MRT_GUI_RaidLogTable:ClearSelection();
            else
                MRT_GUI_RaidLogTable:SetSelection(1);   --if there is a row, select the most current
            end 
        end
        MRT_GUI_RaidLogTableSelection = MRT_GUI_RaidLogTable:GetSelection();
        --if this is readonly mode we need to set things up
        if readonly then
            --setup UI for readonly mode
            --setup event bypassing to channel
            MRT_Debug("MRT_GUI_Toggle: readonly = True")
            MRT_ReadOnly = true;
            RevertUI(true)

        else
            --only run this if we're not in readonly mode
            MRT_Debug("MRT_GUI_Toggle: readonly = false")
            MRT_ReadOnly = false;
            ImportReminder();
        end
        --update all the tables
        --MRT_Debug("MRT_GUI_Toggle: Updating table")
        local raid_select = MRT_GUI_RaidLogTable:GetSelection();
        --MRT_Debug("MRT_GUI_Toggle: raid_select: " ..raid_select)
        local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
        --MRT_Debug("MRT_GUI_Toggle: raidnum: " ..raidnum)
        MRT_GUI_RaidDetailsTableUpdate(raidnum)
    else
        MRT_GUIFrame:Hide();
        MRT_GUIFrame:SetScript("OnUpdate", nil);
    end
end

function RevertUI(readonly)
    if readonly then
        MRT_GUIFrame_RaidLog_Export_Button:SetEnabled(false)
        MRT_GUIFrame_Import_PR_Button:SetEnabled(false)
        MRT_GUIFrame_RaidAttendees_Delete_Button:SetEnabled(false)
        MRT_GUIFrame_BossLoot_Delete_Button:SetEnabled(false)
        MRT_GUIFrame_BossLoot_RaidAnnounce_Button:SetEnabled(false)
        MRT_GUIFrame_BossLoot_RaidLink_Button:SetEnabled(false)
        MRT_GUIFrame_BossLoot_Trade_Button:SetEnabled(false)
        MRT_GUIFrame_RaidAttendees_Add_Button:SetScript("OnEnter", function() MRT_GUI_SetTT(MRT_GUIFrame_RaidAttendees_Add_Button, "BA_Update"); end);
        MRT_GUIFrame_RaidAttendees_Add_Button:SetScript("OnLeave", function() MRT_GUI_HideTT(); end);
        MRT_GUIFrame_BossLoot_Add_Button:SetScript("OnEnter", function() MRT_GUI_SetTT(MRT_GUIFrame_RaidAttendees_Add_Button, "Loot_Request"); end);
        MRT_GUIFrame_BossLoot_Add_Button:SetScript("OnLeave", function() MRT_GUI_HideTT(); end);
        MRT_GUIFrame_BossLoot_Modify_Button:SetEnabled(false)
    else
        MRT_GUIFrame_RaidLog_Export_Button:SetEnabled(true)
        MRT_GUIFrame_Import_PR_Button:SetEnabled(true)
        MRT_GUIFrame_RaidAttendees_Delete_Button:SetEnabled(true)
        MRT_GUIFrame_BossLoot_Delete_Button:SetEnabled(true)
        MRT_GUIFrame_BossLoot_RaidAnnounce_Button:SetEnabled(true)
        MRT_GUIFrame_BossLoot_RaidLink_Button:SetEnabled(true)
        MRT_GUIFrame_BossLoot_Trade_Button:SetEnabled(true)
        MRT_GUIFrame_RaidAttendees_Add_Button:SetScript("OnEnter", function() MRT_GUI_SetTT(MRT_GUIFrame_RaidAttendees_Add_Button, "BA_Add"); end);
        MRT_GUIFrame_RaidAttendees_Add_Button:SetScript("OnLeave", function() MRT_GUI_HideTT(); end);
        MRT_GUIFrame_BossLoot_Add_Button:SetScript("OnEnter", function() MRT_GUI_SetTT(MRT_GUIFrame_RaidAttendees_Add_Button, "Loot_Add"); end);
        MRT_GUIFrame_BossLoot_Add_Button:SetScript("OnLeave", function() MRT_GUI_HideTT(); end);
        MRT_GUIFrame_BossLoot_Modify_Button:SetEnabled(true)
    end
end

-- enable reminder if your in an active raid that hasn't imported since raid start
function ImportReminder()

    --disable reminder by default
    stopEncouragingImport();

    --if not in active raid, don't show reminder
    if (not MRT_NumOfCurrentRaid) then
        MRT_Debug("IR: No Active Raid Detected");
        return; 
    end

    --if no raid selected, don't show reminder
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (not raid_select) then
        MRT_Debug("IR: No raid selected");
        return;
    end

    --if they have never imported
    if (not MRT_LastPRImport) then
         encourageImport();
        return;
    end

    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    baseline = MRT_RaidLog [raidnum]["StartTime"];
    MRT_Debug(MRT_MakeEQDKP_Time(baseline));
    MRT_Debug(MRT_MakeEQDKP_Time(MRT_LastPRImport));

    --if the last import was before the start time of current raid, remind to import
    if (MRT_LastPRImport < baseline) then
        encourageImport();
    end

end

 function encourageImport()
    MRT_GUIFrame_Import_PR_Button:SetNormalFontObject("GameFontGreen");
  
    local FadeOut = ag:CreateAnimation("Alpha");
    FadeOut:SetToAlpha(.25);
    FadeOut:SetFromAlpha(1);
    FadeOut:SetDuration(1);
    FadeOut:SetOrder(1);
    FadeOut:SetSmoothing("OUT")
  
    local FadeIn = ag:CreateAnimation("Alpha");
    FadeIn:SetToAlpha(1);
    FadeIn:SetFromAlpha(.25);
    FadeIn:SetDuration(1);
    FadeOut:SetOrder(2);
    FadeIn:SetSmoothing("OUT")
  
    ag:SetLooping("Repeat")
    ag:Play();
  end
  
  function stopEncouragingImport()
      MRT_GUIFrame_Import_PR_Button:SetNormalFontObject("GameFontWhite");
      ag:Stop();
  end

  function encourageTrade()

    --don't encourage if there are no tradeable items for the player trying to trade
    local tradeableItems = MRT_GetTradeableItems();
    
    if not tradeableItems then
        MRT_Debug("encourageTrade: nothing, don't encourage")
        return;
    elseif #tradeableItems == 0 then
        MRT_Debug("encourageTrade: tradeableitems is not null, but == 0, don't encourage")
        return
    end

    MRT_GUIFrame_BossLoot_Trade_Button:SetNormalFontObject("GameFontGreen");
  
    local FadeOut = agTrade:CreateAnimation("Alpha");
    FadeOut:SetToAlpha(.25);
    FadeOut:SetFromAlpha(1);
    FadeOut:SetDuration(1);
    FadeOut:SetOrder(1);
    FadeOut:SetSmoothing("OUT")
  
    local FadeIn = agTrade:CreateAnimation("Alpha");
    FadeIn:SetToAlpha(1);
    FadeIn:SetFromAlpha(.25);
    FadeIn:SetDuration(1);
    FadeOut:SetOrder(2);
    FadeIn:SetSmoothing("OUT")
  
    agTrade:SetLooping("Repeat")
    agTrade:Play();
  end
  
  function stopEncouragingTrade()
    MRT_GUIFrame_BossLoot_Trade_Button:SetNormalFontObject("GameFontWhite");
    agTrade:Stop();
  end

----------------------
--  Button handler  --
----------------------
function MRT_GUI_RaidExportComplete()
    MRT_GUI_HideDialogs();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        MRT_Print(MRT_L.GUI["No raid selected"]);
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    MRT_CreateRaidExport(raidnum, nil, nil);
end

function MRT_GUI_RaidDelete()
    MRT_GUI_HideDialogs();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        MRT_Print(MRT_L.GUI["No raid selected"]);
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    if (raidnum == MRT_NumOfCurrentRaid) then
        MRT_Print(MRT_L.GUI["Can not delete current raid"]);
        return;
    end
    StaticPopupDialogs.MRT_GUI_ZeroRowDialog.text = string.format(MRT_L.GUI["Confirm raid entry deletion"], raidnum);
    StaticPopupDialogs.MRT_GUI_ZeroRowDialog.OnAccept = function() MRT_GUI_RaidDeleteAccept(raidnum); end
    StaticPopup_Show("MRT_GUI_ZeroRowDialog");
end

function MRT_GUI_ImportPR()
    MRT_GUI_HideDialogs();
    MRT_ExportFrame_Show(export,true);
end

function MRT_GUI_RaidDeleteAccept(raidnum)
    table.remove(MRT_RaidLog, raidnum);
    -- Modify MRT_NumOfCurrentRaid if there is an active raid
    if (MRT_NumOfCurrentRaid ~= nil) then
        MRT_NumOfCurrentRaid = #MRT_RaidLog;
    end
    -- Do a table update
    MRT_GUI_CompleteTableUpdate();
end

function MRT_GUI_BossAdd()
    MRT_GUI_HideDialogs();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        MRT_Print(MRT_L.GUI["No raid selected"]);
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    MRT_GUI_ThreeRowDialog_Title:SetText(MRT_L.GUI["Add bosskill"]);
    MRT_GUI_ThreeRowDialog_EB1_Text:SetText(MRT_L.GUI["Bossname"]);
    MRT_GUI_ThreeRowDialog_EB1:SetText("");
    MRT_GUI_ThreeRowDialog_EB2_Text:SetText(MRT_L.GUI["Difficulty N or H"]);
    MRT_GUI_ThreeRowDialog_EB2:SetText("N");
    MRT_GUI_ThreeRowDialog_EB3_Text:SetText(MRT_L.GUI["Time"]);
    MRT_GUI_ThreeRowDialog_EB3:SetText("");
    MRT_GUI_ThreeRowDialog_EB3:SetScript("OnEnter", function() MRT_GUI_SetTT(MRT_GUI_ThreeRowDialog_EB3, "Boss_Add_TimeEB"); end);
    MRT_GUI_ThreeRowDialog_EB3:SetScript("OnLeave", function() MRT_GUI_HideTT(); end);
    MRT_GUI_ThreeRowDialog_OKButton:SetText(MRT_L.GUI["Button_Add"]);
    MRT_GUI_ThreeRowDialog_OKButton:SetScript("OnClick", function() MRT_GUI_BossAddAccept(raidnum); end);
    MRT_GUI_ThreeRowDialog_CancelButton:SetText(MRT_L.Core["MB_Cancel"]);
    
    MRT_GUI_ThreeRowDialog:Show();
end

function MRT_GUI_BossAddAccept(raidnum)
    -- sanity check inputs - if error, print error message (bossname is free text, Time has to match HH:MM)
    local bossname = MRT_GUI_ThreeRowDialog_EB1:GetText();
    local difficulty = MRT_GUI_ThreeRowDialog_EB2:GetText();
    local enteredTime = MRT_GUI_ThreeRowDialog_EB3:GetText();
    local hours = nil;
    local minutes = nil;
    local bossTimestamp = nil;
    if (bossname == "") then
        MRT_Print(MRT_L.GUI["No boss name entered"]);
        return;
    end
    if (enteredTime == "") then
        -- check if there is an active raid
        if (MRT_NumOfCurrentRaid == nil) then
            MRT_Print(MRT_L.GUI["No active raid in progress. Please enter time."]);
            return;
        end
        hours = 255;
        minutes = 255;
    else
        hours, minutes = deformat(enteredTime, "%d:%d");
        if (hours == nil or minutes == nil or hours > 23 or hours < 0 or minutes > 59 or minutes < 0) then
            MRT_Print(MRT_L.GUI["No valid time entered"]);
            return;
        end
        -- check timeline of chosen raid
        local raidStart = MRT_RaidLog[raidnum]["StartTime"];
        local raidStartDateTable = date("*t", raidStart);
        raidStartDateTable.hour = hours;
        raidStartDateTable.min = minutes;
        bossTimestamp = time(raidStartDateTable);
        -- if bossTimestamp < raidStart, try raidStart + 24 hours (one day - time around 01:25 is next day)
        if (bossTimestamp < raidStart) then
            bossTimestamp = bossTimestamp + 86400;
        end
        local raidStop = MRT_RaidLog[raidnum]["StopTime"];
        if (MRT_RaidLog[raidnum]["StopTime"] == nil) then
            if (bossTimestamp < raidStart or bossTimestamp > time()) then
                MRT_Print(MRT_L.GUI["Entered time is not between start and end of raid"]);
                return;
            end
        else
            if (bossTimestamp < raidStart or bossTimestamp > raidStop) then
                MRT_Print(MRT_L.GUI["Entered time is not between start and end of raid"]);
                return;
            end
        end
    end
    MRT_GUI_HideDialogs();
    local insertPos = nil;
    -- add boss to kill list
    -- if boss shall be added as last recent boss kill, just call 'AddBosskill' - else do it manually
    if (hours == 255 and minutes == 255) then
        if (difficulty == "H") then
            MRT_AddBosskill(bossname, "H");
        else
            MRT_AddBosskill(bossname, "N");
        end;
    else
        -- prepare bossdata table
        local bossdata = {};
        bossdata["Players"] = {};
        bossdata["Name"] = bossname;
        bossdata["Date"] = bossTimestamp;
        bossdata["Difficulty"] = MRT_RaidLog[raidnum]["DiffID"];
        if (difficulty == "H" and (bossdata["Difficulty"] == 3 or bossdata["Difficulty"] == 4)) then
            bossdata["Difficulty"] = bossdata["Difficulty"] + 2;
        end
        -- search position in RaidLog (based on time) and insert data
        if (#MRT_RaidLog[raidnum]["Bosskills"] > 0) then
            insertPos = 1;
            for i, val in ipairs(MRT_RaidLog[raidnum]["Bosskills"]) do
                if (bossTimestamp > val["Date"]) then
                    insertPos = i + 1;
                end
            end
            tinsert(MRT_RaidLog[raidnum]["Bosskills"], insertPos, bossdata);
            -- update data of associated loot
            for i, val in ipairs(MRT_RaidLog[raidnum]["Loot"]) do
                if (insertPos <= val["BossNumber"]) then
                    val["BossNumber"] = val["BossNumber"] + 1;
                end
            end
        else
            tinsert(MRT_RaidLog[raidnum]["Bosskills"], bossdata);
            insertPos = 1;
        end
        -- if current raid was modified, change raid parameters accordingly
        if (MRT_NumOfCurrentRaid and raidnum == MRT_NumOfCurrentRaid) then
            MRT_NumOfLastBoss = #MRT_RaidLog[raidnum]["Bosskills"];
        end
        -- save raid attendees as boss attendees for the new boss
        for key, val in pairs(MRT_RaidLog[raidnum]["Players"]) do
            if (val["Join"] < bossTimestamp and (val["Leave"] == nil or val["Leave"] > bossTimestamp)) then
                tinsert(MRT_RaidLog[raidnum]["Bosskills"][insertPos]["Players"], val["Name"]);
            end
        end
    end
    -- Do a table update, if the displayed raid was modified
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then return; end
    local raidnum_selected = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    if (raidnum_selected == raidnum) then
        MRT_GUI_RaidDetailsTableUpdate(raidnum);
    end
end

function MRT_GUI_BossDelete()
    MRT_GUI_HideDialogs();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        MRT_Print(MRT_L.GUI["No raid selected"]);
        return;
    end
    local boss_select = MRT_GUI_RaidBosskillsTable:GetSelection();
    if (boss_select == nil) then
        MRT_Print(MRT_L.GUI["No boss selected"]);
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local bossnum = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 1);
    --local bossname = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 3);
    local bossname = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 2);
    StaticPopupDialogs.MRT_GUI_ZeroRowDialog.text = string.format(MRT_L.GUI["Confirm boss entry deletion"], bossnum, bossname);
    StaticPopupDialogs.MRT_GUI_ZeroRowDialog.OnAccept = function() MRT_GUI_BossDeleteAccept(raidnum, bossnum); end
    StaticPopup_Show("MRT_GUI_ZeroRowDialog");
end

function MRT_GUI_BossDeleteAccept(raidnum, bossnum)
    table.remove(MRT_RaidLog[raidnum]["Bosskills"], bossnum);
    -- Modify MRT_NumOfLastBoss if active raid was modified
    if (MRT_NumOfCurrentRaid == raidnum) then
        MRT_NumOfLastBoss = #MRT_RaidLog[raidnum]["Bosskills"];
    end
    -- update data of associated loot
    local lootDeleteList = {}
    for i, val in ipairs(MRT_RaidLog[raidnum]["Loot"]) do
        if (bossnum == val["BossNumber"]) then
            tinsert(lootDeleteList, i);
        end
        if (bossnum < val["BossNumber"]) then
            val["BossNumber"] = val["BossNumber"] - 1;
        end
    end
    -- sort table - descending order
    table.sort(lootDeleteList, function(val1, val2) return (val1 > val2); end);
    -- delete loot associated with deleted boss
    for i, num in ipairs(lootDeleteList) do
        tremove(MRT_RaidLog[raidnum]["Loot"], num);
    end
    -- Do a table update, if the displayed raid was modified
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then return; end
    local raidnum_selected = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    if (raidnum_selected == raidnum) then
        MRT_GUI_RaidDetailsTableUpdate(raidnum);
    end
end

--[[ function MRT_GUI_BossExport()
    MRT_GUI_HideDialogs();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        MRT_Print(MRT_L.GUI["No raid selected"]);
        return;
    end
    local boss_select = MRT_GUI_RaidBosskillsTable:GetSelection();
    if (boss_select == nil) then
        MRT_Print(MRT_L.GUI["No boss selected"]);
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local bossnum = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 1);
    MRT_CreateRaidExport(raidnum, bossnum, nil);
end ]]

function MRT_GUI_RaidAttendeeAdd()
    if not MRT_ReadOnly then 
        MRT_GUI_HideDialogs();
        local raid_select = MRT_GUI_RaidLogTable:GetSelection();
        if (raid_select == nil) then
            MRT_Print(MRT_L.GUI["No raid selected"]);
            return;
        end
        local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
        MRT_GUI_ThreeRowDialog_Title:SetText(MRT_L.GUI["Add raid attendee"]);
        MRT_GUI_ThreeRowDialog_EB1_Text:SetText(MRT_L.GUI["Col_Name"]);
        MRT_GUI_ThreeRowDialog_EB1:SetText("");
        MRT_GUI_ThreeRowDialog_EB2_Text:SetText(MRT_L.GUI["Col_Join"]);
        MRT_GUI_ThreeRowDialog_EB2:SetText("");
        MRT_GUI_ThreeRowDialog_EB2:SetScript("OnEnter", function() MRT_GUI_SetTT(MRT_GUI_ThreeRowDialog_EB2, "Attendee_Add_JoinEB"); end);
        MRT_GUI_ThreeRowDialog_EB2:SetScript("OnLeave", function() MRT_GUI_HideTT(); end);
        MRT_GUI_ThreeRowDialog_EB3_Text:SetText(MRT_L.GUI["Col_Leave"]);
        MRT_GUI_ThreeRowDialog_EB3:SetText("");
        MRT_GUI_ThreeRowDialog_EB3:SetScript("OnEnter", function() MRT_GUI_SetTT(MRT_GUI_ThreeRowDialog_EB3, "Attendee_Add_LeaveEB"); end);
        MRT_GUI_ThreeRowDialog_EB3:SetScript("OnLeave", function() MRT_GUI_HideTT(); end);
        MRT_GUI_ThreeRowDialog_OKButton:SetText(MRT_L.GUI["Button_Add"]);
        MRT_GUI_ThreeRowDialog_OKButton:SetScript("OnClick", function() MRT_GUI_RaidAttendeeAddAccept(raidnum); end);
        MRT_GUI_ThreeRowDialog_CancelButton:SetText(MRT_L.Core["MB_Cancel"]);
        MRT_GUI_ThreeRowDialog:Show();
    else
        --update attendee PR
        --TODO: send whisper message to ML to update PR
        local msg = {
            ["RaidID"] = MRT_GUI_RaidLogTable:GetCell(raid_select, 1),
            ["ID"] = MRT_Msg_Request_ID,
            ["Time"] = MRT_MakeEQDKP_TimeShort(MRT_GetCurrentTime()),
            ["Data"] = "",
            ["EventID"] = "1",
        }
        MRT_SendAddonMessage(msg, "WHISPER");
        

    end
end
function MRT_GUI_RaidAttendeeAddAccept(raidnum)
    -- sanity check inputs - if error, print error message (bossname is free text, time has to match HH:MM)
    local currentTime = MRT_GetCurrentTime();
    local playerName = MRT_GUI_ThreeRowDialog_EB1:GetText();
    local joinTime = MRT_GUI_ThreeRowDialog_EB2:GetText();
    local leaveTime = MRT_GUI_ThreeRowDialog_EB3:GetText();
    local joinTimestamp, leaveTimestamp;
    local raidStart = MRT_RaidLog[raidnum]["StartTime"];
    local raidStop;
    if (raidnum == MRT_NumOfCurrentRaid) then
        raidStop = currentTime;
    else
        raidStop = MRT_RaidLog[raidnum]["StopTime"];
    end
    -- check name
    if (playerName == "") then
        MRT_Print(MRT_L.GUI["No name entered"]);
        return;
    end
    -- check format of join time and create join timestamp
    if (joinTime == "") then
        joinTimestamp = MRT_RaidLog[raidnum]["StartTime"] + 1;
    else
        local joinHours, joinMinutes = deformat(joinTime, "%d:%d");
        if (joinHours == nil or joinMinutes == nil or joinHours > 23 or joinHours < 0 or joinMinutes > 59 or joinMinutes < 0) then
            MRT_Print(MRT_L.GUI["No valid time entered"]);
            return;
        end
        -- check timeline of chosen raid
        local raidStartDateTable = date("*t", raidStart);
        raidStartDateTable.hour = joinHours;
        raidStartDateTable.min = joinMinutes;
        joinTimestamp = time(raidStartDateTable);
        -- if joinTimestamp < raidStart, try raidStart + 24 hours (one day - time around 01:25 is next day)
        if (joinTimestamp < raidStart) then
            joinTimestamp = joinTimestamp + 86400;
        end
    end
    -- check format of leave time and create leave timestamp
    if (leaveTime == "") then
        if (raidnum == MRT_NumOfCurrentRaid) then
            leaveTimestamp = currentTime - 1;
        else
            leaveTimestamp = MRT_RaidLog[raidnum]["StopTime"] - 1;
        end
    else
        local leaveHours, leaveMinutes = deformat(leaveTime, "%d:%d");
        if (leaveHours == nil or leaveMinutes == nil or leaveHours > 23 or leaveHours < 0 or leaveMinutes > 59 or leaveMinutes < 0) then
            MRT_Print(MRT_L.GUI["No valid time entered"]);
            return;
        end
        -- check timeline of chosen raid
        local raidStartDateTable = date("*t", raidStart);
        raidStartDateTable.hour = leaveHours;
        raidStartDateTable.min = leaveMinutes;
        leaveTimestamp = time(raidStartDateTable);
        -- if leaveTimestamp < raidStart, try raidStart + 24 hours (one day - time around 01:25 is next day)
        if (leaveTimestamp < raidStart) then
            leaveTimestamp = leaveTimestamp + 86400;
        end
    end
    -- check if timestamps make sense
    if not (raidStart < joinTimestamp and joinTimestamp < raidStop and raidStart < leaveTimestamp and leaveTimestamp < raidStop) then
        MRT_Print(MRT_L.GUI["Entered time is not between start and end of raid"]);
        return;
    end
    if (joinTimestamp > leaveTimestamp) then
        MRT_Print(MRT_L.GUI["Entered join time is not before leave time"]);
        MRT_Debug(tostring(joinTimestamp).." > "..tostring(leaveTimestamp));
        return;
    end
    MRT_GUI_HideDialogs();
    -- if we reach this point, we should have a valid raidnum, playername, join timestamp and leave timestamp - now add them to the raid attendee list...
    
    local playerInfo = {
        ["Name"] = playerName,
        ["Join"] = joinTimestamp,
        ["Leave"] = leaveTimestamp,
        ["PR"] = getPlayerPR();
    };
    tinsert(MRT_RaidLog[raidnum]["Players"], playerInfo);
    -- ... and as boss attendee to the relevant bosses
    for i, val in ipairs(MRT_RaidLog[raidnum]["Bosskills"]) do
        if (joinTimestamp < val["Date"] and val["Date"] < leaveTimestamp) then
            local playerList = {};
            for j, val2 in ipairs(val["Players"]) do
                playerList[val2] = true;
            end
            if (not playerList[playerName]) then
                tinsert(val["Players"], playerName);
            end
        end
    end
    -- Do a table update, if the displayed raid was modified
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then return; end
    local raidnum_selected = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    if (raidnum_selected == raidnum) then
        MRT_GUI_RaidAttendeesTableUpdate(raidnum);
    else
        return;
    end
    local boss_select = MRT_GUI_RaidBosskillsTable:GetSelection();
    if (boss_select == nil) then return; end
    local bossnum = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 1);
    MRT_GUI_BossAttendeesTableUpdate(bossnum);
end

function MRT_GUI_RaidAttendeeDelete()

    MRT_GUI_HideDialogs();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        MRT_Print(MRT_L.GUI["No raid selected"]);
        return;
    end
    local attendee_select = MRT_GUI_RaidAttendeesTable:GetSelection();
    if (attendee_select == nil) then
        MRT_Print(MRT_L.GUI["No raid attendee selected"]);
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local attendee = MRT_GUI_RaidAttendeesTable:GetCell(attendee_select, 1);
    local attendeeName = MRT_GUI_RaidAttendeesTable:GetCell(attendee_select, 2);
    StaticPopupDialogs.MRT_GUI_ZeroRowDialog.text = string.format(MRT_L.GUI["Confirm raid attendee entry deletion"], attendeeName);
    StaticPopupDialogs.MRT_GUI_ZeroRowDialog.OnAccept = function() MRT_GUI_RaidAttendeeDeleteAccept(raidnum, attendee); end
    StaticPopup_Show("MRT_GUI_ZeroRowDialog");
end

function MRT_GUI_RaidAttendeeDeleteAccept(raidnum, attendee)
    local playerInfo = MRT_RaidLog[raidnum]["Players"][attendee];
    if (not playerInfo["Leave"]) then
        playerInfo["Leave"] = MRT_GetCurrentTime();
    end
    -- Delete player from the boss attendees lists...
    for i, val in ipairs(MRT_RaidLog[raidnum]["Bosskills"]) do
        if (playerInfo["Join"] < val["Date"] and val["Date"] < playerInfo["Leave"]) then
            local playerPos;
            for j, val2 in ipairs(val["Players"]) do
                if (val2 == playerInfo["Name"]) then
                    playerPos = j;
                end
            end
            if (playerPos) then
                tremove(val["Players"], playerPos);
            end
        end
    end
    -- ...and raid attendees list
    MRT_RaidLog[raidnum]["Players"][attendee] = nil;
    -- Do a table update, if the displayed raid was modified
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then return; end
    local raidnum_selected = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    if (raidnum_selected == raidnum) then
        MRT_GUI_RaidAttendeesTableUpdate(raidnum);
    else
        return;
    end
    local boss_select = MRT_GUI_RaidBosskillsTable:GetSelection();
    if (boss_select == nil) then return; end
    local bossnum = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 1);
    MRT_GUI_BossAttendeesTableUpdate(bossnum);
end

function MRT_GUI_LootAdd()
    --overload for readonly mode.
    if not MRT_ReadOnly then 
        MRT_GUI_HideDialogs();
        local raid_select = MRT_GUI_RaidLogTable:GetSelection();
        if (raid_select == nil) then
            MRT_Print(MRT_L.GUI["No raid selected"]);
            return;
        end
        local boss_select = MRT_GUI_RaidBosskillsTable:GetSelection();
        --[[ if (boss_select == nil) then
            MRT_Print(MRT_L.GUI["No boss selected"]);
            return;
        end ]]
        local createdTrash = false;
        local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
        if (boss_select == nil) then
            --if there is no current active raid, just add to last boss
            if not MRT_NumOfCurrentRaid then
                MRT_Debug("MRT_GUI_LootAdd: MRT_NumOfCurrentRaid is nill");    
                MRT_GUI_RaidBosskillsTable:SetSelection(1);
                boss_select = MRT_GUI_RaidBosskillsTable:GetSelection();
                MRT_NumOfLastBoss = boss_select;
            end 
            if (MRT_NumOfLastBoss == nil) or (MRT_NumOfLastBoss == 0) then
                MRT_Debug("MRT_GUI_LootAdd: adding boss kill");
                MRT_AddBosskill(MRT_L.Core["Trash Mob"], "N", nil, raidnum);
                boss_select = 1;
                createdTrash = true;
            else
                MRT_Debug("MRT_GUI_LootAdd: MRT_NumOfLastBoss = " ..MRT_NumOfLastBoss);    
                MRT_GUI_RaidBosskillsTable:SetSelection(1);
                boss_select = MRT_GUI_RaidBosskillsTable:GetSelection();
                --use last boss since the table is gone.
                --boss_select = 1;
            end
        end
        local bossnum
        if createdTrash then
            --no boss is available, add one and select
            MRT_Debug("MRT_GUI_LootAdd: createdTrash == true ");
            --MRT_Debug("MRT_GUI_LootAdd: MRT_NumOfLastBoss = " ..MRT_NumOfLastBoss);    
            bossnum = 1;
        else
            MRT_Debug("MRT_GUI_LootAdd: boss_select: " ..boss_select);
            if MRT_NumOfLastBoss then 
                bossnum = MRT_NumOfLastBoss
            else 
                bossnum = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 1);
                MRT_GUI_RaidBosskillsTable:ClearSelection();
            end
        end
        -- gather playerdata and fill drop down menu
        local playerData = {};
        --error check here for bossum.
        local errBoss = MRT_RaidLog[raidnum]["Bosskills"][bossnum];
        if not errBoss then
            MRT_Debug("MRT_GUI_LootAdd: adding boss kill, second chance");
            MRT_AddBosskill(MRT_L.Core["Trash Mob"], "N", nil, raidnum);
            boss_select = 1;
            createdTrash = true;
        end 
        for i, val in ipairs(MRT_RaidLog[raidnum]["Bosskills"][bossnum]["Players"]) do
            playerData[i] = { val };
        end
        table.sort(playerData, function(a, b) return (a[1] < b[1]); end );
        tinsert(playerData, 1, { "disenchanted" } );
        tinsert(playerData, 1, { "bank" } );
        tinsert(playerData,1, {"unassigned"});
        tinsert(playerData, 1, {"pug"} );
        MRT_RaidPlayerList = playerData;
        MRT_GUI_PlayerDropDownTable:SetData(playerData, true);
        if (#playerData < 9) then
            MRT_GUI_PlayerDropDownTable:SetDisplayRows(#playerData, 15);
        else
            MRT_GUI_PlayerDropDownTable:SetDisplayRows(9, 15);
        end
        MRT_GUI_PlayerDropDownTable.frame:Hide();
        -- prepare dialog
        MRT_GUI_FourRowDialog_Title:SetText(MRT_L.GUI["Add loot data"]);
        MRT_GUI_FourRowDialog_EB1:SetEnabled(true);
        MRT_GUI_FourRowDialog_EB1:SetAutoFocus(true);
        MRT_GUI_FourRowDialog_EB1_Text:SetText(MRT_L.GUI["Itemlink"]);
        MRT_GUI_FourRowDialog_EB1:SetText("");
        MRT_GUI_FourRowDialog_EB2_Text:SetText(MRT_L.GUI["Looter"]);
        MRT_GUI_FourRowDialog_EB2:SetText("unassigned");
        MRT_GUI_FourRowDialog_EB3_Text:SetText(MRT_L.GUI["Value"]);
        MRT_GUI_FourRowDialog_EB3:SetText("");                         --setting default to zero so that we won't get errors with OS
        MRT_GUI_FourRowDialog_EB4_Text:SetText(MRT_L.GUI["Note"]);
        MRT_GUI_FourRowDialog_EB4:SetText("Loot added manually");
        MRT_GUI_FourRowDialog_OKButton:SetText(MRT_L.GUI["Button_Add"]);
        MRT_GUI_FourRowDialog_OKButton:SetScript("OnClick", function() UpdateGP(); MRT_GUI_LootModifyAccept(raidnum, bossnum, nil); end);
        MRT_GUI_FourRowDialog_CancelButton:SetText(MRT_L.Core["MB_Cancel"]);
        MRT_GUI_FourRowDialog_AnnounceWinnerButton:SetText(MRT_L.Core["MB_Win"]);
        MRT_GUI_FourRowDialog_CBTraded:SetChecked(false);
        MRT_GUI_FourRowDialog:Show();
    else
        --update loot table
        --message to ML to send updated loot table.. but only diff of what I already have.

    end
    
end

function verifyPlayer(PlayerName)
    --iterate the dropdown table
    --MRT_Debug("verifyPlayer:PlayerName: ".. PlayerName);
    --MRT_Debug("verifyPlayer:PlayerName:strlen: ".. strlen(PlayerName));
    local cPlayerName = cleanString(PlayerName,true)
    --MRT_Debug("verifyPlayer:cPlayerName: ".. cPlayerName);
    --MRT_Debug("verifyPlayer:cPlayerName:strlen ".. strlen(cPlayerName));
    MRT_Debug("verifyPlayer");
    for i, v in ipairs(MRT_RaidPlayerList) do
        MRT_Debug("verifyPlayer: i: " ..i.." v: " ..v[1]);
        --MRT_Debug("verifyPlayer: strlen v[1]: " ..strlen(v[1]));
        if cPlayerName == v[1] then
            return true
        end
    end
    MRT_Debug("verifyPlayer: did not match!!!! cPlayerName: "..cPlayerName);
    return false;
end

function cleanFormatString(strText, keepCase)
    --|cff9d9d9d
    local sText;
    local cleanText;
    if not keepCase then 
        sText = string.lower(strText);
    else
        MRT_Debug("CleanFormatString keepCase");
        sText = strText;
    end 
    local strFound = strfind(sText, "|c")
    if not strFound then
        return sText;
    else
        MRT_Debug("CleanFormatString:format found, stripping")
        cleanText = string.sub(sText, 11);
        MRT_Debug("CleanFormatString:cleanText: " ..cleanText)
        return cleanText;
    end
end

function RemoveAutoComplete(editbox)
	MRT_Debug("LEB:RemoveAutoComplete called");

    MRT_Debug("LEB:RemoveAutoComplete:removing onTabPressed");
    MRT_GUI_FourRowDialog_EB2:SetScript("OnEnter", nil);
	editbox:SetScript("OnTabPressed", function (editbox) MRT_GUI_FourRowDialog_EB3:SetFocus(); end)
	MRT_Debug("LEB:RemoveAutoComplete:removing onEnterPressed");
	editbox:SetScript("OnEnterPressed", nil)
	MRT_Debug("LEB:RemoveAutoComplete:removing onTextChanged");
	editbox:SetScript("OnTextChanged", nil)
	MRT_Debug("LEB:RemoveAutoComplete:removing OnChar");
	editbox:SetScript("OnChar", nil)
	MRT_Debug("LEB:RemoveAutoComplete:removing OnEditFocusLost");
	editbox:SetScript("OnEditFocusLost", nil)
	MRT_Debug("LEB:RemoveAutoComplete:removing OnEscapePressed");
	editbox:SetScript("OnEscapePressed", function (editbox) MRT_GUI_HideDialogs() end);
	MRT_Debug("LEB:RemoveAutoComplete:removing valueList");
	editbox.valueList = {}
    MRT_Debug("LEB:RemoveAutoComplete:removing buttonCount");
	editbox.buttonCount = nil;
end
function MRT_GUI_LootModify()

    MRT_GUI_HideDialogs();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        MRT_Print(MRT_L.GUI["No raid selected"]);
        return;
    end
    local loot_select = MRT_GUI_BossLootTable:GetSelection();
    if (loot_select == nil) then
        MRT_Print(MRT_L.GUI["No loot selected"]);
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    if lastRaidNum ~= raidnum then
        lastRaidNum = raidnum;
        if bAutoCompleteCreated then
            RemoveAutoComplete(MRT_GUI_FourRowDialog_EB2);
            bAutoCompleteCreated = false;
        end
    end 
    local lootnum = MRT_GUI_BossLootTable:GetCell(loot_select, 1);
    lastloot_select = loot_select;
    lastLootNum = lootnum;
    local bossnum = MRT_RaidLog[raidnum]["Loot"][lootnum]["BossNumber"];
    lastBossNum = bossnum;
    local lootnote = MRT_RaidLog[raidnum]["Loot"][lootnum]["Note"];
    local lootoffspec = MRT_RaidLog[raidnum]["Loot"][lootnum]["Offspec"];
    local lootTraded = MRT_RaidLog[raidnum]["Loot"][lootnum]["Traded"];
    
   --if lootoffspec then
   --    MRT_Debug("MRT_GUI_LootModify: lootoffspec: True");
   -- else
   --     MRT_Debug("MRT_GUI_LootModify: lastLooter: False");
   -- end

    -- Force item into cache:
    GetItemInfo(MRT_RaidLog[raidnum]["Loot"][lootnum]["ItemLink"]);
    -- gather playerdata and fill drop down menu
    local playerData = {};
    for i, val in ipairs(MRT_RaidLog[raidnum]["Bosskills"][bossnum]["Players"]) do
        playerData[i] = { val };
    end
    table.sort(playerData, function(a, b) return (a[1] < b[1]); end );
    tinsert(playerData, 1, { "disenchanted" } );
    tinsert(playerData, 1, { "bank" } );
    tinsert(playerData, 1, {"unassigned"});
    tinsert(playerData, 1, {"pug"} );
    MRT_RaidPlayerList = playerData;
    MRT_GUI_PlayerDropDownTable:SetData(playerData, true);
    if (#playerData < 9) then
        MRT_GUI_PlayerDropDownTable:SetDisplayRows(#playerData, 15);
    else
        MRT_GUI_PlayerDropDownTable:SetDisplayRows(9, 15);
    end
    MRT_GUI_PlayerDropDownTable.frame:Hide();
    -- prepare dialog
    MRT_GUI_FourRowDialog_Title:SetText(MRT_L.GUI["Modify loot data"]);
    MRT_GUI_FourRowDialog_EB1_Text:SetText(MRT_L.GUI["Itemlink"]);
    MRT_GUI_FourRowDialog_EB1:SetText(MRT_RaidLog[raidnum]["Loot"][lootnum]["ItemLink"]);
    MRT_GUI_FourRowDialog_EB1:SetScript("OnEnter", function(self) 
        local ttText = "Prio to: " ..LibSFGP:GetPrio(MRT_GUI_FourRowDialog_EB1:GetText());
        --MRT_Debug("EB:OnEnter ttText: " ..ttText);
        MRT_GUI_SetPrioTT(self,ttText);
    end);
    MRT_GUI_FourRowDialog_EB1:SetScript("OnLeave", function(self) MRT_GUI_HideTT(); end);        
    MRT_GUI_FourRowDialog_EB2_Text:SetText(MRT_L.GUI["Looter"]);
    MRT_GUI_FourRowDialog_EB2:SetText(cleanString(MRT_GUI_BossLootTable:GetCell(loot_select, 4),true));
    MRT_GUI_FourRowDialog_EB2:SetScript("OnTextChanged", function(self)
        --MRT_Debug("MRT_GUI_LootModify: EB2:OnTextChanged Fired!");
        if MRT_LootBidding then
            --MRT_Debug("MRT_GUI_LootModify: Bidding!");
            if MRT_TopBidders["Loot"] then
                if MRT_GUI_FourRowDialog_EB2:GetText() ~= "unassigned" then
                    --MRT_Debug("MRT_GUI_LootModify: Looter is not unassigned");
                    if MRT_TopBidders["Loot"] == MRT_GUI_FourRowDialog_EB1:GetText() then
                        --MRT_Debug("MRT_GUI_LootModify: Loot matches bidding loot");
                        MRT_Print("Loot assignment changed")
                        StopBidding();
                    else
                        --MRT_Debug("MRT_GUI_LootModify: Bidding loot and Loot text don't match");
                    end
                end
            else
                --MRT_Debug("MRT_GUI_LootModify: Bidding Loot doesn't exist");
            end
        end
    end)
    --autocomplete here.
    if not bAutoCompleteCreated then
        MRT_Debug("MRT_GUI_LootModify: Creating autocomplete table");
        local valueList = {}
        local maxButtonCount = 20;
        --[[ --this is the playerdb imp
        local realm = GetRealmName();
        MRT_Debug("MRT_GUI_LootModify: realm: "..realm);
        for i, v in pairs(MRT_PlayerDB[realm]) do
            MRT_Debug("MRT_GUI_LootModify: first for loop");
            tinsert(valueList,1,i)
        end
        for i1, v1 in ipairs(valueList) do
            MRT_Debug("MRT_GUI_LootModify: v: " ..v1);
        end
        MRT_Debug("MRT_GUI_LootModify: for loops over ");
        tinsert(valueList, 1, "disenchanted");
        tinsert(valueList, 1, "bank" );
        tinsert(valueList, 1, "unassigned");
        tinsert(valueList, 1, "pug" ); ]]
        --Raid list imp
        for i, v in ipairs(MRT_RaidPlayerList) do
            tinsert(valueList, 1, v[1])
        end
        SetupAutoComplete(MRT_GUI_FourRowDialog_EB2, valueList, maxButtonCount);
        bAutoCompleteCreated = true;
    end

    --MRT_GUI_FourRowDialog_EB2:SetText(MRT_GUI_BossLootTable:GetCell(loot_select, 4));
    local cleanlooter = MRT_GUI_BossLootTable:GetCell(loot_select, 4)
    --MRT_Debug("MRT_GUI_LootModify: cleanLooter:before clean "..cleanlooter);
    --MRT_Debug("MRT_GUI_LootModify: cleanLooter:before clean strlen "..strlen(cleanlooter));
    local debuggingprestr = string.sub(cleanlooter,1,2);
    local debuggingpoststr = string.sub(cleanlooter,strlen(cleanlooter)-2, 2);
    --MRT_Debug("MRT_GUI_LootModify: cleanLooter:debuggingprestr "..debuggingprestr);
    --MRT_Debug("MRT_GUI_LootModify: cleanLooter:debuggingpoststr "..debuggingpoststr);
    --MRT_Debug("MRT_GUI_LootModify: cleanLooter:before clean strlen "..strlen(cleanlooter));
    --MRT_GUI_FourRowDialog_EB2:SetText(cleanString(cleanlooter,true));
    lastLooter = MRT_GUI_FourRowDialog_EB2:GetText();
    lastLootItem = MRT_GUI_FourRowDialog_EB1:GetText();
    --MRT_Debug("MRT_GUI_LootModify: lastLooter: afterclean "..lastLooter);
    --MRT_Debug("MRT_GUI_LootModify: lastLooter: afterclean strlen "..strlen(lastLooter));
    
    MRT_GUI_FourRowDialog_EB3_Text:SetText(MRT_L.GUI["Value"]);
    MRT_GUI_FourRowDialog_EB3:SetText(MRT_GUI_BossLootTable:GetCell(loot_select, 5));
    -- figure out how to get check box info
    if lootoffspec then 
        MRT_GUI_FourRowDialog_CB1:SetChecked(true);
    else
        MRT_GUI_FourRowDialog_CB1:SetChecked(false);
    end
    if lootTraded then 
        MRT_GUI_FourRowDialog_CBTraded:SetChecked(true);
    else
        MRT_GUI_FourRowDialog_CBTraded:SetChecked(false);
    end
    lastOS = MRT_GUI_FourRowDialog_CB1:GetChecked();
    lastTraded = MRT_GUI_FourRowDialog_CBTraded:GetChecked();
    --if lastOS then 
    --    MRT_Debug("MRT_GUI_LootModify: lastOS = True");
    --else
    --    MRT_Debug("MRT_GUI_LootModify: lastOS = False");
    --end
    lastValue = MRT_GUI_FourRowDialog_EB3:GetText();
    --MRT_Debug("MRT_GUI_LootModify: lastValue: "..lastValue);
    MRT_GUI_FourRowDialog_EB4_Text:SetText(MRT_L.GUI["Note"]);
    if (lootnote == nil or lootnote == "" or lootnote == " ") then
        MRT_GUI_FourRowDialog_EB4:SetText("");
        lastNote = "";
    else
        MRT_GUI_FourRowDialog_EB4:SetText(lootnote);
        lastNote = lootnote;
    end
    MRT_GUI_FourRowDialog_OKButton:SetText(MRT_L.Core["MB_Ok"]);
    MRT_GUI_FourRowDialog_OKButton:SetScript("OnClick", function() MRT_GUI_LootModifyAccept(raidnum, bossnum, lootnum); end);
    MRT_GUI_FourRowDialog_CancelButton:SetText(MRT_L.Core["MB_Cancel"]);
    MRT_GUI_FourRowDialog_EB1:SetAutoFocus(false);
    MRT_GUI_FourRowDialog_EB1:SetCursorPosition(1);
    MRT_GUI_FourRowDialog_AnnounceWinnerButton:SetText(MRT_L.Core["MB_Win"]);
    MRT_GUI_FourRowDialog_AnnounceWinnerButton:SetScript("OnEnter", function(self) 
        
        local ttText
        --if MRT_LootBidding then
            --ttText = "Current highest bidder is "..GetTopBidders();
        --else
            ttText = MRT_GUI_LootRaidWinner(true)
        --end
        --MRT_Debug("EB:OnEnter ttText: " ..ttText);
        MRT_GUI_SetPrioTT(self,ttText);
    end);
    MRT_GUI_FourRowDialog_AnnounceWinnerButton:SetScript("OnLeave", function(self) MRT_GUI_HideTT(); end);        
    MRT_GUI_FourRowDialog_EB2:SetFocus();
    MRT_GUI_FourRowDialog:Show();
    MRT_GUI_FourRowDialog_CB1:SetScript("OnClick", function(self) MRT_CB_Clicked(self); end);
    --MRT_GUI_FourRowDialog_CB1:SetScript("OnUpdate", function(self) MRT_CB_Clicked(self); end);
    --MRT_GUI_FourRowDialog_EB1:SetEnabled(false);
end
function MRT_CB_Clicked(self)
    local enable = self:GetChecked()
    local cost;
    self:SetChecked(enable and true or false)
    if enable then
        cost = MRT_GUI_FourRowDialog_EB3:GetText();
        if cost ~= "" then
            MRT_GUI_FourRowDialog_EB3:SetText(cost*.25);
        end
    else
        cost = MRT_GUI_FourRowDialog_EB3:GetText();
        if cost ~= "" then
            MRT_GUI_FourRowDialog_EB3:SetText(cost/.25);
        end
    end
end
function GetTopBidders()
    local retVal = ""
    for i, v in pairs(MRT_TopBidders["Players"]) do
        retVal = retVal ..v.. " ";
    end
    return retVal
end

function MRT_GUI_PlayerDropDownList_Toggle()
    EditBoxAutoComplete_HideIfAttachedTo(MRT_GUI_FourRowDialog_EB2);
    if (MRT_GUI_PlayerDropDownTable.frame:IsShown()) then
        MRT_GUI_PlayerDropDownTable.frame:Hide();
    else
        MRT_GUI_PlayerDropDownTable.frame:Show();
        MRT_GUI_PlayerDropDownTable.frame:SetPoint("TOPRIGHT", MRT_GUI_FourRowDialog_DropDownButton, "BOTTOMRIGHT", 0, 0);
    end
end

function MRT_GUI_LootModifyAccept(raidnum, bossnum, lootnum, msg)
    MRT_Debug("MRT_GUI_LootModifyAccept:Called!");
    local itemLinkFromText = "";
    local looter = "";
    local cost = "";
    local lootNote = "";
    local offspec = "";
    local traded = "";
    local strMsg = "";
    if not msg then 
        itemLinkFromText = MRT_GUI_FourRowDialog_EB1:GetText();
        looter = MRT_GUI_FourRowDialog_EB2:GetText();
        cost = MRT_GUI_FourRowDialog_EB3:GetText();
        lootNote = MRT_GUI_FourRowDialog_EB4:GetText();
        offspec = MRT_GUI_FourRowDialog_CB1:GetChecked();
        traded = MRT_GUI_FourRowDialog_CBTraded:GetChecked();
    else
        itemLinkFromText, strMsg = getToken(msg, ";")
        looter, strMsg = getToken(strMsg, ";")
        cost, strMsg = getToken(strMsg,";")
        lootNote, strMsg = getToken(strMsg,";")
        offspec, strMsg = getToken(strMsg,";")
        if offspec =="false" then
            offspec = false;
        else
            offspec = true;
        end
        if strMsg =="false" then	
            traded = false;	
        else	
            traded = true;	
        end
    end
    
    --MRT_Debug("MRT_GUI_LootModifyAccept: itemLinkFromText: "..itemLinkFromText.." looter: "..looter.." cost: "..cost.." lootNote: "..lootNote.." offspec: "..tostring(offspec));
    if cost == "" or cost =="0" then
        UpdateGP()
    end
    local newloot = false;
    if (cost == "") then cost = 0; end
    cost = tonumber(cost);
    if (lootNote == nil or lootNote == "" or lootNote == " ") then lootNote = nil; end
    -- sanity-check values here - especially the itemlink / looter is free text / cost has to be a number
    local itemName, itemLink, itemId, itemString, itemRarity, itemColor, _, _, _, _, _, _, _, _ = MRT_GetDetailedItemInformation(itemLinkFromText);
    if itemColor then 
        --MRT_Debug("MRT_GUI_LootModifyAccept:itemColor: "..itemColor);
    end
    if (not itemName) then
        MRT_Print(MRT_L.GUI["No itemLink found"]);
        return true;
    end
    if (not cost) then
        MRT_Print(MRT_L.GUI["Item cost invalid"]);
        return true;
    end
    --uncomment when ready to verify
    --MRT_Debug("MRT_GUI_LootModifyAccept: looter: " ..looter);
    --MRT_Debug("MRT_GUI_LootModifyAccept: looter:strlen " ..strlen(looter));
    local clooter = cleanFormatString(looter,true);
    --MRT_Debug("MRT_GUI_LootModifyAccept: clooter: " ..clooter);
    --MRT_Debug("MRT_GUI_LootModifyAccept: clooter:strLen " ..strlen(clooter));
    --MRT_Debug("MRT_GUI_LootModifyAccept: not channel msg, do dirty check")
    if not msg then 
        if isDirty(MRT_GUI_FourRowDialog_EB2:GetText(), MRT_GUI_FourRowDialog_EB3:GetText(), MRT_GUI_FourRowDialog_EB4:GetText(),MRT_GUI_FourRowDialog_CB1:GetChecked(), MRT_GUI_FourRowDialog_CBTraded:GetChecked(), MRT_GUI_FourRowDialog_EB1:GetText()) then
            MRT_Debug("MRT_GUI_LootModifyAccept: it's dirty");
            local validPlayerName = verifyPlayer(clooter);
            if not validPlayerName then
                StaticPopupDialogs.MRT_GUI_ok.text = MRT_GUI_FourRowDialog_EB2:GetText().." is not in this raid.  Please choose a valid character."
                StaticPopup_Show("MRT_GUI_ok");
                return true;
            end
        else
            MRT_Debug("MRT_GUI_LootModifyAccept: not dirty");
            MRT_GUI_HideDialogs();
            return true;
        end
    end
     
    MRT_GUI_HideDialogs();
    --MRT_Debug("MRT_GUI_LootModifyAccept: after Dirty check")
    -- insert new values here / if (lootnum == nil) then treat as a newly added item
    if (looter == "") then looter = "disenchanted"; end
    --create channel message data here.  bossnum;lootnum;itemLink;Looter;cost;lootNote;offspec, eventid=4
    
    local MRT_LootInfo = {
        ["ItemLink"] = itemLink,
        ["ItemString"] = itemString,
        ["ItemId"] = itemId,
        ["ItemName"] = itemName,
        ["ItemColor"] = itemColor,
        ["BossNumber"] = bossnum,
        ["Looter"] = looter,
        ["Traded"] = traded,
        ["DKPValue"] = cost,
        ["Note"] = lootNote,
        ["Offspec"] = offspec,
    }
    if (lootnum) then
        MRT_Debug("MRT_GUI_LootModifyAccept: old loot");
        --MRT_Debug("MRT_GUI_LootModifyAccept:lootnum if ");
        if MRT_LootInfo["Offspec"] then
            --MRT_Debug("MRT_GUI_LootModifyAccept:Offspec = True");
        else
            --MRT_Debug("MRT_GUI_LootModifyAccept:Offspec = False");
        end
        --MRT_Debug("MRT_GUI_LootModifyAccept:raidnum: " ..raidnum);
        --MRT_Debug("MRT_GUI_LootModifyAccept:lootnum: " ..lootnum);
        local oldLootDB = MRT_RaidLog[raidnum]["Loot"][lootnum];
    
        -- create a copy of the old loot data for the api
        --MRT_Debug("MRT_GUI_LootModifyAccept:lootnum: " ..MRT_RaidLog[raidnum]["Loot"][lootnum]["ItemName"]);
        --MRT_Debug("MRT_GUI_LootModifyAccept: oldLootDB[itemName]".. oldLootDB["ItemName"]);
        local oldItemInfoTable = {}
        for key, val in pairs(oldLootDB) do
            oldItemInfoTable[key] = val;
            --MRT_Debug("MRT_GUI_LootModifyAccept: val: " ..tostring(val))
        end
        MRT_LootInfo["ItemCount"] = oldLootDB["ItemCount"];
        MRT_LootInfo["Time"] = oldLootDB["Time"];
        MRT_RaidLog[raidnum]["Loot"][lootnum] = MRT_LootInfo;
        -- notify registered, external functions
        if (#MRT_ExternalLootNotifier > 0) then
            local itemInfo = {};
            for key, val in pairs(MRT_RaidLog[raidnum]["Loot"][lootnum]) do
                itemInfo[key] = val;
            end
            if (oldItemInfoTable.Looter == "bank") then
                oldItemInfoTable.Action = MRT_LOOTACTION_BANK;
            elseif (oldItemInfoTable.Looter == "disenchanted") then
                oldItemInfoTable.Action = MRT_LOOTACTION_DISENCHANT;
            elseif (oldItemInfoTable.Looter == "_deleted_") then
                oldItemInfoTable.Action = MRT_LOOTACTION_DELETE;
            else
                oldItemInfoTable.Action = MRT_LOOTACTION_NORMAL;
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
                pcall(val, itemInfo, MRT_NOTIFYSOURCE_EDIT_GUI, raidnum, lootnum, oldItemInfoTable);
            end
        end
        if isMasterLooter() then 
            MRT_Debug("MRT_GUI_LootModifyAccept: sending Loot Updated msg");
            -- send message to addon channel with new loot message
            if not MRT_MasterLooter then
                MRT_MasterLooter = getMasterLooter();
            end
            local msg = {
                ["RaidID"] = raidnum,
                ["ID"] = MRT_Msg_ID,
                ["Time"] = MRT_MakeEQDKP_TimeShort(MRT_GetCurrentTime()),
                ["Data"] = bossnum..";"..lootnum..";"..itemLink..";"..looter..";"..cost..";"..lootNote..";"..tostring(offspec)..";"..tostring(traded),
                ["EventID"] = "4",
            }
            MRT_SendAddonMessage(msg, "RAID");
        end
    else
        --MRT_Debug("MRT_GUI_LootModifyAccept: new loot");
        newloot = true;
        MRT_LootInfo["ItemCount"] = 1;
        MRT_LootInfo["Time"] = MRT_RaidLog[raidnum]["Bosskills"][bossnum]["Date"] + 15;
        tinsert(MRT_RaidLog[raidnum]["Loot"], MRT_LootInfo);
        -- notify registered, external functions
        if isMasterLooter() then 
            MRT_Debug("MRT_GUI_LootModifyAccept: sending new loot msg");
            -- send message to addon channel with new loot message
            local msg = {
                ["RaidID"] = raidnum,
                ["ID"] = MRT_Msg_ID,
                ["Time"] = MRT_MakeEQDKP_TimeShort(MRT_GetCurrentTime()),
                ["Data"] = MRT_LootInfo["Looter"]..";"..MRT_LootInfo["ItemLink"]..";".."1",
                ["EventID"] = "3",
            }
            MRT_SendAddonMessage(msg, "RAID");
        end
        if (#MRT_ExternalLootNotifier > 0) then
            local itemNum = #MRT_RaidLog[raidnum]["Loot"];
            local itemInfo = {};
            for key, val in pairs(MRT_RaidLog[raidnum]["Loot"][itemNum]) do
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
                pcall(val, itemInfo, MRT_NOTIFYSOURCE_ADD_GUI, raidnum, itemNum);
            end
        end
    end
    -- do table update, if selected loot table was modified
    MRT_GUI_RaidDetailsTableUpdate(raidnum,true);
    -- Send updated PR msg here.
  --[[   if isPlayer(MRT_LootInfo["Looter"]) then
        MRT_Debug("MRT_GUI_LootModifyAccept: sending modified PR msg");
        MRT_Debug("MRT_GUI_LootModifyAccept: MRT_LootInfo[Looter]"..MRT_LootInfo["Looter"]);
            -- send message to addon channel with new loot message
            local msg = {
                ["RaidID"] = "1",
                ["ID"] = MRT_Msg_ID,
                ["Time"] = MRT_MakeEQDKP_TimeShort(MRT_GetCurrentTime()),
                ["Data"] = MRT_LootInfo["Looter"]..";"..getModifiedPR(raidnum, MRT_LootInfo["Looter"]),
                ["EventID"] = "6",
            }
            MRT_SendAddonMessage(msg, "RAID");    
    end ]]
    local RaidAttendees = MRT_GUI_RaidAttendeesTableUpdate(raidnum);
    --create data
    if isMasterLooter() then 
        MRT_Debug("MRT_GUI_LootModifyAccept: MasterLooter send message");
        SendPRMsg(RaidAttendees);
        -- send message to addon channel with new loot message
    end
    local item_select = MRT_GUI_BossLootTable:GetSelection();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then return; end
    local raidnum_selected = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local boss_select = MRT_GUI_RaidBosskillsTable:GetSelection();
    if newloot then
        --MRT_Debug("MRT_GUI_Accept:new loot update the table");
        MRT_GUI_BossLootTableUpdate(bossnum);
        return;
    end
    if (boss_select == nil) then
        if (raidnum_selected == raidnum) then
            --MRT_Debug("MRT_GUI_Accept:About to call MRT_GUI_BossLootTableUpdate(nil,true)");
            MRT_GUI_BossLootTableUpdate(nil, true);
        end
        return;
    end
    local bossnum_selected = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 1);
    if (raidnum_selected == raidnum and bossnum_selected == bossnum) then
        --MRT_Debug("MRT_GUI_Accept:About to call MRT_GUI_BossLootTableUpdate(bossnum,true)");
        MRT_GUI_BossLootTableUpdate(bossnum, true);
    end

end

--This function returns whether or not a name is a reserved name, pug, bank, unassigned, disenchanted

function isPlayer(PlayerName)
    return (PlayerName ~= "pug") or (PlayerName  ~= "bank") or (PlayerName ~= "unassigned") or (PlayerName ~= "disenchanted");
end

function MRT_GUI_LootRaidWinner(textonly)
    --MRT_GUI_HideDialogs();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        MRT_Print(MRT_L.GUI["No raid selected"]);
        return;
    end
    local loot_select = MRT_GUI_BossLootTable:GetSelection();
    if (loot_select == nil) then
        MRT_Print(MRT_L.GUI["No loot selected"]);
        return;
    end
    --local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    --local lootnum = MRT_GUI_BossLootTable:GetCell(loot_select, 1);
    --local lootName = MRT_GUI_BossLootTable:GetCell(loot_select, 3);
    --local looter = string.upper(MRT_RaidLog[raidnum]["Loot"][lootnum]["Looter"]);
    --local cost = MRT_GUI_BossLootTable:GetCell(loot_select, 5);
    -- old code local looter = string.upper(MRT_GUI_FourRowDialog_EB2:GetText());
    local looter;    
    if #MRT_TopBidders["Players"] == 1 then
        if not textonly then 
            MRT_GUI_FourRowDialog_EB2:SetText(MRT_TopBidders["Players"][1])
            if MRT_TopBidders["Type"] == "os" then
                if not MRT_GUI_FourRowDialog_CB1:GetChecked() then 
                    MRT_GUI_FourRowDialog_CB1:Click();
                end
                --MRT_GUI_FourRowDialog_CB1:SetChecked(true);
            end
        end
    else
        if #MRT_TopBidders["Players"] > 1 then
            MRT_Print("There is a tie.  Roll off!  " ..GetTopBidders())
            return
        end
    end
    if not textonly then 
        looter = MRT_GUI_FourRowDialog_EB2:GetText();
    else
        if MRT_LootBidding and #MRT_TopBidders["Players"] > 0 then 
            looter = MRT_TopBidders["Players"][1];
        else
            looter = MRT_GUI_FourRowDialog_EB2:GetText();
        end
    end
    if looter == "unassigned" then
        looter = "disenchanted"
        if not textonly then 
            if #MRT_TopBidders["Players"] == 0 then
                MRT_GUI_FourRowDialog_EB2:SetText("disenchanted")
            end
        end
    else
        if looter ~= "disenchanted" then 
            looter = "{star}"..cleanString(looter):gsub("^%l", string.upper).."{star}";
        end
    end 
    local cost = MRT_GUI_FourRowDialog_EB3:GetText();
    if textonly then 
        local intCost = tonumber(cost)
        if MRT_TopBidders["Type"] == "os" then
            intCost = intCost * .25;
            cost = tostring(intCost);
        end
    end
    
    local lootName = MRT_GUI_FourRowDialog_EB1:GetText();
    local rwMessage;
    --if #MRT_TopBidders["Players"] == 1 then 
    --    MRT_GUI_FourRowDialog_EB2:SetText(MRT_TopBidders["Players"][1])
    --end
    --"Congratz! %s receives %s for %sGP",   
    --local rwMessage = string.format(MRT_L.GUI["RaidWinMessage"], looter, MRT_RaidLog[raidnum]["Loot"][lootnum]["ItemLink"], cost);
    if looter =="disenchanted" then 
        rwMessage = string.format("%s is being turned into {diamond}{diamond}{diamond}", lootName);
    else
        rwMessage = string.format(MRT_L.GUI["RaidWinMessage"], looter, lootName, cost);
    end
    if textonly then     
       return rwMessage; 
    else 
        SendChatMessage(rwMessage, "Raid");
        ResetBidding(false);
    end
end
function UpdateGP()
    local LibSFGP = LibStub("LibSFGearPoints-1.0");
    local itemlink = MRT_GUI_FourRowDialog_EB1:GetText();
    if (not itemlink) or (itemlink =="") then
    --do nothing
    else
        gp1 = LibSFGP:GetValue(itemlink);
        if (not gp1) then
            MRT_GUI_FourRowDialog_EB3:SetText("0");
        else
            local GPtext = MRT_GUI_FourRowDialog_EB3:GetText();
            if (GPtext == "") or (GPText == "0") then
                MRT_GUI_FourRowDialog_EB3:SetText(gp1);
            else
                --GP already set, do nothing.
            end 
        end
        --MRT_GUI_FourRowDialog_EB1:HighlightText(0,0);
    end 
end
function ResetBidding(start, loot)
    MRT_Debug("ResetBidding: start: " ..tostring(start));
    --start == true if starting false if ending
    MRT_TopBidders = {
        ["PR"] = nil,
        ["Players"] = {},
        ["Type"] = nil,
        ["History"] = {},
        ["Loot"] = loot,
    } 
    MRT_LootBidding = start;
    MRT_Debug("ResetBidding: MRT_LootBidding: " ..tostring(MRT_LootBidding));
    if loot then 
        MRT_Debug("ResetBidding: Loot: " ..MRT_TopBidders["Loot"]);
    else
        MRT_Debug("ResetBidding: Loot not passed in" );
    end
end
function StopBidding()
    --MRT_Print("Stopping bids")
    ResetBidding(false)
end
function GetSelectedRaid()
    local raidnum = nil;
    -- check if a raid is selected
    if (MRT_GUI_RaidLogTable:GetSelection()) then
        raidnum = MRT_GUI_RaidLogTable:GetCell(MRT_GUI_RaidLogTableSelection, 1);
    end

    return raidnum;
end


function MRT_GetTradeableItems()

    --Get name of player with an open trade window
    local tradePartnerName = UnitName("NPC");
    if not tradePartnerName then 
        MRT_Print("No one is trading")
        return nil;
    end
    MRT_TradePartner = tradePartnerName;
    MRT_Debug("MRT_GetTradeableItems: tradePartnerName: " ..tradePartnerName);
    local itemsToTrade = {};

    -----------------------------------------------------------------
    --Get list of items that person is the looter for in the loot list
    -----------------------------------------------------------------
    local raidnum;
    
    -- check if a raid is selected
    if (MRT_GUI_RaidLogTable:GetSelection()) then
        raidnum = MRT_GUI_RaidLogTable:GetCell(MRT_GUI_RaidLogTableSelection, 1);
    end
    --MRT_Debug("MRT_GetTradeableItems: raidnum: " ..raidnum)
    -- if there is no raid selected (ex. on launch, then return)
    if not raidnum then
        MRT_Debug("MRT_GetTradeableItems: no raidnum")
        return; 
    end

    --MRT_Debug("MRT_GUI_BossLootTableUpdate: if bossnum condition");
    local index = 1;
    for i, v in ipairs(MRT_RaidLog[raidnum]["Loot"]) do
        --MRT_Debug("MRT_GetTradeableItems: i: " ..i);
        --MRT_Debug("MRT_GetTradeableItems: v[looter]: " ..v["Looter"]);
        --MRT_Debug("MRT_GetTradeableItems: v[traded]: " ..tostring(v["Traded"]));
        if v["Looter"] == tradePartnerName and v["Traded"] == false then
            itemsToTrade[index] = v["ItemName"];
            tinsert(MRT_TradeItemsList,v["ItemName"]);
            MRT_Debug(tradePartnerName.. " should receive "..itemsToTrade[index]);
        end
        index = index + 1;
    end
    return itemsToTrade;

end

--puts all items the person with the trade window is supposed to receive in their trade window.
function MRT_GUI_TradeLink()

    --disable animation once clicked
    stopEncouragingTrade();
    MRT_Debug("MRT_GUI_TradeLink: Clicked!")
    MRT_BagFreeSlots = GetBagFreeSlots()
    MRT_TradeInitiated = true;
    --commit save if the loot dialog is visible.
    if MRT_GUI_FourRowDialog:IsVisible() then
        if isDirty(MRT_GUI_FourRowDialog_EB2:GetText(), MRT_GUI_FourRowDialog_EB3:GetText(), MRT_GUI_FourRowDialog_EB4:GetText(), MRT_GUI_FourRowDialog_CB1:GetChecked(), MRT_GUI_FourRowDialog_CBTraded:GetChecked()) then
            --MRT_Debug("STOnClick: isDirty == True");
            local error = false;
            error = MRT_GUI_LootModifyAccept(lastRaidNum, lastBossNum, lastLootNum);
            if error then
               --do nothing
            end
        end
    end;
    MRT_Debug("MRT_GUI_TradeLink: passed dirty check calling gettradeable")
    --get the items the person is supposed to get
    local itemsToTrade = MRT_GetTradeableItems();
    if not itemsToTrade then 
        --nothing to trade
        MRT_Debug("MRT_GUI_TradeLink: nothing to trade")
        return;
    end
    
    -----------------------------------------------------------------
    --Find those items in my bag & trade them
    -----------------------------------------------------------------
    for i in pairs(itemsToTrade) do
         local foundInBag, containerID, slotID = findItemInBag(itemsToTrade[i]);
         if foundInBag then
            --MRT_Debug("MRT_GUI_TradeLink: Found item "..sName.." at"..containerID.. slotID)
            --Validate that the item is tradeable by looking at the loot timer
            local timeRemaining = GetContainerItemTradeTimeRemaining(containerID, slotID);
            if timeRemaining>0 then
                local itemAlreadyTraded = false;

                --make sure the same item hasn't already been put in the loot window - ex. two aq40 weapon tokens are in your bag
                for j=1, 7 do
                    local name, texture, quantity, quality, isUsable, enchant =  GetTradePlayerItemInfo(j);
                    if name == itemsToTrade[i] then
                        itemAlreadyTraded = true;
                    end
                end

                --make sure the person hasn't already gotten traded that item, as it's been marked traded
                --for u, v in ipairs(MRT_RaidLog[GetSelectedRaid()]["Loot"]) do

                --    if v["ItemName"] == itemsToTrade[i] then
                 --       if v["Traded"] == true then
                 --            itemAlreadyTraded = true;
                 --            MRT_Print("Yo, you were already traded "..itemsToTrade[i]);
                --         end
                --    end
                --end
   
                if itemAlreadyTraded == false then
                    --Place those items in the trade window
                    MRT_Debug("about to use item: "..containerID.." "..slotID)
                    MRT_Debug("MRT_GUI_TradeLInk: click on item")
                    local intMax = 0;
                    local iCountBefore = GetNumberOfItemsInTrade()
                    local iCountAfter = 0;
                    while intMax < 10 do
                        MRT_Debug("MRT_GUI_TradeLInk: in while loop")
                        MRT_Debug("MRT_GUI_TradeLInk: about to click item: intMax: " ..tostring(intMax).. " iCountBefore: " ..tostring(iCountBefore).. " iCountAfter: " ..tostring(iCountAfter))
                        UseContainerItem(containerID,slotID);
                        iCountAfter = GetNumberOfItemsInTrade();
                        if not iCountAfter then
                            --returned nil trade window might be gone.. return
                            return;
                        end
                        MRT_Debug("MRT_GUI_TradeLInk: Clicked item: iCountAfter: " ..tostring(iCountAfter))
                        if (iCountAfter > iCountBefore) then 
                            MRT_Debug("MRT_GUI_TradeLInk: iCountAfter > iCountBefore: set intMax to 5 to exit loop")
                            intMax = 10;
                        else
                            MRT_Debug("MRT_GUI_TradeLInk: iCountAfter < = iCountBefore: increment and try again")
                            intMax = intMax + 1    
                            
                        end 
                    end 
                end
            end
         end
    end
end

function GetNumberOfItemsInTrade()
    local tradePartnerName = UnitName("NPC");
    if not tradePartnerName then 
        MRT_Print("No one is trading")
        return nil;
    end
    local intCount = 0
    for j=1, 7 do
        local name, texture, quantity, quality, isUsable, enchant =  GetTradePlayerItemInfo(j);
        if (name) then 
            intCount = intCount + 1
        end
    end
    return intCount
end
local messwArghCounter = 1
local messwArghCounter1 = 0
function MessWArgh() 
    -- to be used for surprise. -- Arghkettnaad
    --MRT_Debug("Surprise!")
    local MLplayerName = UnitName("player") 
    if MLplayerName == "Arghkettnaad" then -- Arghkettnaad
        local found, container, slot = findItemInBag("Sacred Candles")
        if found then
            --MRT_Debug("item found!")
            local bag2 = bagWFreeSlots(container)
            if bag2 then
                --MRT_Debug("bag with free slot found bag2: " ..bag2)
                SplitContainerItem(container, slot, 1)
                if bag2 == 0 then
                    --MRT_Debug("Putting thing in backpack")
                    PutItemInBackpack();
                else 
                    --MRT_Debug("Putting thing in bag with open")
                    PutItemInBag(bag2 + 19);
                end 
            end
        end
        local bag1 = messwArghCounter1 % 5
        local slot1 = messwArghCounter % (GetContainerNumSlots(bag1))
        --MRT_Debug("picking up bag1: " ..bag1.. " slot1: " ..slot1)
        --PickupContainerItem(bag1, slot1);
        SplitContainerItem(bag1, slot1, 1)
        local bag = bagWFreeSlots(bag1)
        if bag then
           --MRT_Debug("bag with free slot found bag: " ..bag)
            if bag == 0 then
                --MRT_Debug("putting in backback")
                PutItemInBackpack();
            else 
                --MRT_Debug("putting in bag: " ..bag)
                PutItemInBag(bag + 19);
            end 
        end
        messwArghCounter = messwArghCounter + 1;
        messwArghCounter1 = messwArghCounter1 + 1;
    end
end
function bagWFreeSlots(bag)
    --bag is where the item is, so return first empty bag without the item
    for container = 0, 5 do
        if GetContainerNumFreeSlots(container) > 0 and (container ~= bag) then
            return container
        end
    end
    return
end
function GetBagFreeSlots()
    local intSlots = 0
    for container = 0, 5 do
        intSlots = intSlots + GetContainerNumFreeSlots(container)
    end
    return intSlots
end
--returns true/false, container, and slot numbers of the item found. 
function findItemInBag(name)
    local c,s,t
    for container=0, 5 do
        if GetContainerNumSlots(container) > 0 then
            for slot=1, GetContainerNumSlots(container) or 0 do
      --        MRT_Debug("Iterating through bag #"..container.." at slot #"..slot)
                local itemLink = GetContainerItemLink(container, slot);
                if itemLink then
                    local sName, sLink, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount = GetItemInfo(itemLink);
                    if name == sName then
    --                    MRT_Debug("Found item "..sName.." at"..container.. slot)  
                        return true, container, slot
                    end
                end
            end
        end
    end
    return false, -1, -1
end

-- Return the remaining trade time in second for an item in the container.
-- Return math.huge(infinite) for an item not bounded.
-- Return the remaining trade time in second if the item is within 2h trade window.
-- Return 0 if the item is not tradable (bounded and the trade time has expired.)
function GetContainerItemTradeTimeRemaining(container, slot)
	tooltipForParsing:SetOwner(UIParent, "ANCHOR_NONE") -- This lines clear the current content of tooltip and set its position off-screen
	tooltipForParsing:SetBagItem(container, slot) -- Set the tooltip content and show it, should hide the tooltip before function ends
    if not tooltipForParsing:NumLines() or tooltipForParsing:NumLines() == 0 then
        MRT_Debug("GetContainerItemTradeTimeRemaining: first chance return")
        return 0
	end

	local bindTradeTimeRemainingPattern = escapePatternSymbols(BIND_TRADE_TIME_REMAINING):gsub("%%%%s", "%(%.%+%)") -- PT locale contains "-", must escape that.
	local bounded = false

	for i = 1, tooltipForParsing:NumLines() or 0 do
		local line = getglobal(tooltipForParsing:GetName()..'TextLeft' .. i)
		if line and line.GetText then
			local text = line:GetText() or ""
			if text == ITEM_SOULBOUND or text == ITEM_ACCOUNTBOUND or text == ITEM_BNETACCOUNTBOUND then
				bounded = true
			end

			local timeText = text:match(bindTradeTimeRemainingPattern)
			if timeText then -- Within 2h trade window, parse the time text
				tooltipForParsing:Hide()

				for hour=1, 0, -1 do -- time>=60s, format: "1 hour", "1 hour 59 min", "59 min", "1 min"
					local hourText = ""
					if hour > 0 then
						hourText = CompleteFormatSimpleStringWithPluralRule(INT_SPELL_DURATION_HOURS, hour)
					end
					for min=59,0,-1 do
						local time = hourText
						if min > 0 then
							if time ~= "" then
								time = time..TIME_UNIT_DELIMITER
							end
							time = time..CompleteFormatSimpleStringWithPluralRule(INT_SPELL_DURATION_MIN, min)
						end

						if time == timeText then
							return hour*3600 + min*60
						end
					end
				end
				for sec=59, 1, -1 do -- time<60s, format: "59 s", "1 s"
					local time = CompleteFormatSimpleStringWithPluralRule(INT_SPELL_DURATION_SEC, sec)
                    if time == timeText then
                        MRT_Debug("GetContainerItemTradeTimeRemaining: second chance return")
						return sec
					end
				end
				-- As of Patch 7.3.2(Build 25497), the parser have been tested for all 11 in-game languages when time < 1h and time > 1h. Shouldn't reach here.
                -- If it reaches here, there are some parsing issues. Let's return 2h.
                MRT_Debug("GetContainerItemTradeTimeRemaining: third chance return")
				return 7200
			end
		end
	end
	tooltipForParsing:Hide()
    if bounded then
        MRT_Debug("GetContainerItemTradeTimeRemaining: fourth chance return")
        --tooltipForParsing:Hide()
		return 0
    else
        MRT_Debug("GetContainerItemTradeTimeRemaining: fifth chance return")
        --tooltipForParsing:Hide()
		return math.huge
	end
end

function CompleteFormatSimpleStringWithPluralRule(str, count)
	local text = format(str, count)
	if count < 2 then
		return text:gsub("|4(.+):(.+);", "%1")
	else
		return text:gsub("|4(.+):(.+);", "%2")
	end
end

function MRT_GUI_LootRaidLink()
    --MRT_GUI_HideDialogs();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        MRT_Print(MRT_L.GUI["No raid selected"]);
        return;
    end
    local loot_select = MRT_GUI_BossLootTable:GetSelection();
    if (loot_select == nil) then
        MRT_Print(MRT_L.GUI["No loot selected"]);
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local lootnum = MRT_GUI_BossLootTable:GetCell(loot_select, 1);
    local loot = MRT_RaidLog[raidnum]["Loot"][lootnum]["ItemLink"];
    -- GetToken now returns a string table... need to write a function to parse and build smaller messages.
    --[[ local strTokens = LibSFGP:GetTokenLoot(loot);
    local rwMessage;
    rwMessage = string.format(MRT_L.GUI["RaidLinkMessage"], loot, MRT_GUI_BossLootTable:GetCell(loot_select, 5));
    SendChatMessage(rwMessage, "Raid");
    if strTokens~="" then
        MRT_Debug("strTokens: " ..strTokens)
        rwMessage = string.format(MRT_L.GUI["RaidLinkMessageToken"], loot, strTokens);
        SendChatMessage(rwMessage, "Raid");
    end ]]
    LootAnnounce("Raid", loot, MRT_GUI_BossLootTable:GetCell(loot_select, 5))
end

--messageType = "Raid", "RAID_WARNING"
function LootAnnounce(messageType, loot, gp, textonly)
    MRT_Debug("LootAnnouce:called!");
    local tTokens = LibSFGP:GetTokenLoot(loot);
    local rwMessage;
    
    if messageType == "Raid" then
        rwMessage = string.format(MRT_L.GUI["RaidLinkMessage"], loot, gp);
        SendChatMessage(rwMessage, messageType);
    elseif messageType == "RAID_WARNING" then
        rwMessage = string.format(MRT_L.GUI["RaidAnnounceMessage"], loot, gp);
        SendChatMessage(rwMessage, messageType);
    else
        return;
    end 
    local iCount = table.maxn(tTokens);
    if iCount > 0 then
        MRT_Debug("LootAnnouce: processing tokenloot list");
        local tokenLootList = "";
        for i = 1, iCount do
            if (tTokens[i]) then
                tokenLootList = tokenLootList ..tTokens[i];
                --MRT_Debug("LootAnnouce: tTokens[i]:  " ..tTokens[i]);
            else
                tokenLootList = tokenLootList .."";
                --MRT_Debug("LootAnnouce: tTokens[i]:NIL");
            end
            if (i % 4) == 0 then
                if i == 4 then 
                    rwMessage = string.format(MRT_L.GUI["RaidTokenMessage"], tokenLootList);
                else
                    rwMessage = string.format(MRT_L.GUI["RaidTokenMessageCont"], tokenLootList);
                end
                tokenLootList = "";
                SendChatMessage(rwMessage, "Raid");
            end
        end
        if tokenLootList ~= "" then
            if iCount < 4 then
                rwMessage = string.format(MRT_L.GUI["RaidTokenMessage"], tokenLootList);
            else
                rwMessage = string.format(MRT_L.GUI["RaidTokenMessageCont"], tokenLootList);
            end
            SendChatMessage(rwMessage, "Raid");
        end
    end
end

function MRT_GUI_LootRaidAnnounce()
    --MRT_GUI_HideDialogs();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        MRT_Print(MRT_L.GUI["No raid selected"]);
        return;
    end
    local loot_select = MRT_GUI_BossLootTable:GetSelection();
    if (loot_select == nil) then
        MRT_Print(MRT_L.GUI["No loot selected"]);
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local lootnum = MRT_GUI_BossLootTable:GetCell(loot_select, 1);
    local bossnum = MRT_RaidLog[raidnum]["Loot"][lootnum]["BossNumber"];
    --[[ local loot = MRT_RaidLog[raidnum]["Loot"][lootnum]["ItemLink"];
    -- GetToken now returns a string table... need to write a function to parse and build smaller messages.
    local strTokens = LibSFGP:GetTokenLoot(loot);
    local rwMessage;
    --local rwMessage = string.format(MRT_L.GUI["RaidAnnounceMessage"], MRT_RaidLog[raidnum]["Loot"][lootnum]["ItemLink"], MRT_GUI_BossLootTable:GetCell(loot_select, 5));
    rwMessage = string.format(MRT_L.GUI["RaidAnnounceMessage"], MRT_RaidLog[raidnum]["Loot"][lootnum]["ItemLink"], MRT_GUI_BossLootTable:GetCell(loot_select, 5));
    SendChatMessage(rwMessage, "RAID_WARNING");
    if strTokens~="" then
    
        MRT_Debug("strTokens: " ..strTokens)
        rwMessage = string.format(MRT_L.GUI["RaidAnnounceMessageToken"], MRT_RaidLog[raidnum]["Loot"][lootnum]["ItemLink"], strTokens);
        SendChatMessage(rwMessage, "RAID_WARNING");
    end ]]
    LootAnnounce("RAID_WARNING", MRT_RaidLog[raidnum]["Loot"][lootnum]["ItemLink"], MRT_GUI_BossLootTable:GetCell(loot_select, 5))
    ResetBidding(true, MRT_RaidLog[raidnum]["Loot"][lootnum]["ItemLink"]);
    
end


function MRT_GUI_LootDelete()
    MRT_GUI_HideDialogs();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        MRT_Print(MRT_L.GUI["No raid selected"]);
        return;
    end
    local loot_select = MRT_GUI_BossLootTable:GetSelection();
    if (loot_select == nil) then
        MRT_Print(MRT_L.GUI["No loot selected"]);
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local lootnum = MRT_GUI_BossLootTable:GetCell(loot_select, 1);
    local bossnum = MRT_RaidLog[raidnum]["Loot"][lootnum]["BossNumber"];
    local lootName = MRT_GUI_BossLootTable:GetCell(loot_select, 3);
    StaticPopupDialogs.MRT_GUI_ZeroRowDialog.text = string.format(MRT_L.GUI["Confirm loot entry deletion"], lootName);
    StaticPopupDialogs.MRT_GUI_ZeroRowDialog.OnAccept = function() MRT_GUI_LootDeleteAccept(raidnum, bossnum, lootnum); end
    StaticPopup_Show("MRT_GUI_ZeroRowDialog");
end

function MRT_GUI_LootDeleteAccept(raidnum, bossnum, lootnum)
    if (#MRT_ExternalLootNotifier > 0) then
        local itemInfo = {};
        for key, val in pairs(MRT_RaidLog[raidnum]["Loot"][lootnum]) do
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
            pcall(val, itemInfo, MRT_NOTIFYSOURCE_DELETE_GUI, raidnum, lootnum);
        end
    end
    tremove(MRT_RaidLog[raidnum]["Loot"], lootnum);
    -- do table update, if selected loot table was modified
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then return; end
    local raidnum_selected = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local boss_select = MRT_GUI_RaidBosskillsTable:GetSelection();
    if (boss_select == nil) then
        if (raidnum_selected == raidnum) then
            MRT_GUI_BossLootTableUpdate(nil);
        end
        return;
    end
    local bossnum_selected = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 1);
    if (raidnum_selected == raidnum and bossnum_selected == bossnum) then
        MRT_GUI_BossLootTableUpdate(bossnum);
    end
end

function MRT_GUI_BossAttendeeAdd()
    MRT_GUI_HideDialogs();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        MRT_Print(MRT_L.GUI["No raid selected"]);
        return;
    end
    local boss_select = MRT_GUI_RaidBosskillsTable:GetSelection();
    if (boss_select == nil) then
        MRT_Print(MRT_L.GUI["No boss selected"]);
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local bossnum = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 1);
    MRT_GUI_OneRowDialog_Title:SetText(MRT_L.GUI["Add boss attendee"]);
    MRT_GUI_OneRowDialog_EB1_Text:SetText(MRT_L.GUI["Col_Name"]);
    MRT_GUI_OneRowDialog_EB1:SetText("");
    MRT_GUI_OneRowDialog_OKButton:SetText(MRT_L.GUI["Button_Add"]);
    MRT_GUI_OneRowDialog_OKButton:SetScript("OnClick", function() MRT_GUI_BossAttendeeAddAccept(raidnum, bossnum); end);
    MRT_GUI_OneRowDialog_CancelButton:SetText(MRT_L.Core["MB_Cancel"]);
    MRT_GUI_OneRowDialog:Show();
end

function MRT_GUI_BossAttendeeAddAccept(raidnum, bossnum)
    MRT_GUI_HideDialogs();
    local attendee = MRT_GUI_OneRowDialog_EB1:GetText();
    tinsert(MRT_RaidLog[raidnum]["Bosskills"][bossnum]["Players"], attendee);
    -- do table update, if selected attendee table was modified
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then return; end
    local raidnum_selected = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local boss_select = MRT_GUI_RaidBosskillsTable:GetSelection();
    if (boss_select == nil) then return; end
    local bossnum_selected = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 1);
    if (raidnum_selected == raidnum and bossnum_selected == bossnum) then
        MRT_GUI_BossAttendeesTableUpdate(bossnum);
    end
end

function MRT_GUI_BossAttendeeDelete()
    MRT_GUI_HideDialogs();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        MRT_Print(MRT_L.GUI["No raid selected"]);
        return;
    end
    local boss_select = MRT_GUI_RaidBosskillsTable:GetSelection();
    if (boss_select == nil) then
        MRT_Print(MRT_L.GUI["No boss selected"]);
        return;
    end
    local attendee_select = MRT_GUI_BossAttendeesTable:GetSelection();
    if (attendee_select == nil) then
        MRT_Print(MRT_L.GUI["No boss attendee selected"]);
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local bossnum = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 1);
    local attendeenum = MRT_GUI_BossAttendeesTable:GetCell(attendee_select, 1);
    local attendeeName = MRT_GUI_BossAttendeesTable:GetCell(attendee_select, 2);
    StaticPopupDialogs.MRT_GUI_ZeroRowDialog.text = string.format(MRT_L.GUI["Confirm boss attendee entry deletion"], attendeeName);
    StaticPopupDialogs.MRT_GUI_ZeroRowDialog.OnAccept = function() MRT_GUI_BossAttendeeDeleteAccept(raidnum, bossnum, attendeenum); end
    StaticPopup_Show("MRT_GUI_ZeroRowDialog");
end

function MRT_GUI_BossAttendeeDeleteAccept(raidnum, bossnum, attendeenum)
    --MRT_RaidLog[raidnum]["Bosskills"][bossnum]["Players"][attendeenum] = nil;
    tremove(MRT_RaidLog[raidnum]["Bosskills"][bossnum]["Players"], attendeenum);
    -- do table update, if selected attendee table was modified
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then return; end
    local raidnum_selected = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local boss_select = MRT_GUI_RaidBosskillsTable:GetSelection();
    if (boss_select == nil) then return; end
    local bossnum_selected = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 1);
    if (raidnum_selected == raidnum and bossnum_selected == bossnum) then
        MRT_GUI_BossAttendeesTableUpdate(bossnum);
    end
end

function MRT_GUI_TakeSnapshot()
    local status = MRT_TakeSnapshot();
    if (status) then
        MRT_GUI_RaidLogTableUpdate();
    end
end

function MRT_GUI_StartNewRaid()
    local startorend = MRT_GUIFrame_StartNewRaid_Button:GetText();

    if (startorend == MRT_L.GUI["Button_StartNewRaid"]) then 
        if (MRT_NumOfCurrentRaid) then
            MRT_Print(MRT_L.GUI["Active raid found. End current one first."]);
            return;
        end
        if (not MRT_IsInRaid()) then
            MRT_Print(MRT_L.GUI["Player not in raid."]);
            return;
        end
        MRT_GUI_TwoRowDialog_Title:SetText(MRT_L.GUI["Button_StartNewRaid"]);
        MRT_GUI_TwoRowDialog_DDM:Show();
        MRT_GUI_TwoRowDialog_EB1_Text:SetText(MRT_L.GUI["Zone name"]);
        MRT_GUI_TwoRowDialog_EB1:SetText("");
        MRT_GUI_TwoRowDialog_EB1:SetScript("OnEnter", function() MRT_GUI_SetTT(MRT_GUI_TwoRowDialog_EB1, "StartNewRaid_ZoneNameEB"); end);
        MRT_GUI_TwoRowDialog_EB1:SetScript("OnLeave", function() MRT_GUI_HideTT(); end);
        MRT_GUI_TwoRowDialog_EB2:Hide();
        MRT_GUI_TwoRowDialog_OKButton:SetText(MRT_L.Core["MB_Ok"]);
        MRT_GUI_TwoRowDialog_OKButton:SetScript("OnClick", function() MRT_GUI_StartNewRaidAccept(); end);
        MRT_GUI_TwoRowDialog_CancelButton:SetText(MRT_L.Core["MB_Cancel"]);
        MRT_GUI_TwoRowDialog:Show();
    else
        MRT_GUI_EndCurrentRaid();
    end
end

function MRT_GUI_StartNewRaidAccept()
    local diffIDList = { 16, 15, 14, 17, 9, 4, 3 }
    local zoneName = MRT_GUI_TwoRowDialog_EB1:GetText()
    local diffId = diffIDList[MRT_Lib_UIDropDownMenu_GetSelectedID(MRT_GUI_TwoRowDialog_DDM)]
    local raidSize = mrt.raidSizes[diffId]
    -- Hide dialogs
    MRT_GUI_HideDialogs();
    -- check current raidstatus is ok
    if (MRT_NumOfCurrentRaid) then
        MRT_Print(MRT_L.GUI["Active raid found. End current one first."]);
        return;
    end
    if (not MRT_IsInRaid()) then
        MRT_Print(MRT_L.GUI["Player not in raid."]);
        return;
    end
    -- if no zoneName was entered, use the current zone
    if (zoneName == "" or zoneName == " " or zoneName == nil) then
        zoneName = GetRealZoneText();
    end
    -- create new raid
    MRT_CreateNewRaid(zoneName, raidSize, diffId);
    MRT_GUI_CompleteTableUpdate();
    MRT_GUIFrame_StartNewRaid_Button:SetText(MRT_L.GUI["Button_EndCurrentRaid"]); -- rename raid button to end
    MRT_GUI_RaidLogTable:SetSelection(1);
    if (MRT_NumOfCurrentRaid) then 
        MRT_GUI_RaidAttendeesTableUpdate(MRT_NumOfCurrentRaid);
    end 
    
    --MRT_GUIFrame_StartNewRaid_Button:SetEnabled(false); -- disable add raid button
    --MRT_GUIFrame_EndCurrentRaid_Button:SetEnabled(true); --enable end raid button
    
end

function MRT_GUI_MakeAttendanceCheck()
    if (not MRT_NumOfCurrentRaid) then
        MRT_Print(MRT_L.GUI["No active raid"]);
        return;
    end
    MRT_AddBosskill(MRT_L.Core["GuildAttendanceBossEntry"]);
    MRT_StartGuildAttendanceCheck("_attendancecheck_");
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    if (raidnum == MRT_NumOfCurrentRaid) then
        MRT_GUI_RaidDetailsTableUpdate(raidnum);
    end
end

function MRT_GUI_EndCurrentRaid()
    if (not MRT_NumOfCurrentRaid) then
        MRT_Print(MRT_L.GUI["No active raid"]);
        return;
    end
    MRT_EndActiveRaid();
    MRT_GUIFrame_StartNewRaid_Button:SetText(MRT_L.GUI["Button_StartNewRaid"]);  --rename raid button to start
    --MRT_GUIFrame_StartNewRaid_Button:SetEnabled(true);  --enable start new raid button.
    --MRT_GUIFrame_EndCurrentRaid_Button:SetEnabled(false); --disable end raid button.
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    MRT_GUI_RaidAttendeesTableUpdate(raidnum);
end

function MRT_GUI_ResumeLastRaid()
    if (MRT_NumOfCurrentRaid) then
        MRT_Print(MRT_L.GUI["Active raid in progress."]);
        return;
    end
    if (not MRT_IsInRaid()) then
        MRT_Print(MRT_L.GUI["Player not in raid."]);
        return;
    end
    local success = MRT_ResumeLastRaid();
    if (not success) then
        MRT_Print(MRT_L.GUI["Resuming last raid failed"]);
        return;
    else
        MRT_Print(MRT_L.GUI["Resuming last raid successful"]);
    end
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then
        return;
    end
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    MRT_GUI_RaidAttendeesTableUpdate(raidnum);
end


-----------------------
--  ToolTip handler  --
-----------------------
function MRT_GUI_SetTT(frame, button)
    MRT_GUI_TT:SetOwner(frame, "ANCHOR_BOTTOMRIGHT");
    if button == "Import_PR" then
        if not MRT_LastPRImport then
            MRT_GUI_TT:SetText(MRT_L.GUI["TT_"..button]);
        else
            local strDate = date("%c", MRT_LastPRImport)     
            MRT_GUI_TT:SetText("Last Imported PR - " ..strDate);  
        end
    else
        
        MRT_GUI_TT:SetText(MRT_L.GUI["TT_"..button]);
    end 
    MRT_GUI_TT:Show();
end
function MRT_GUI_SetPrioTT(frame, button)
    MRT_GUI_TT:SetOwner(frame, "ANCHOR_BOTTOMRIGHT");
    MRT_GUI_TT:SetText(button);  
    MRT_GUI_TT:Show();
end


function MRT_GUI_HideTT()
    MRT_GUI_TT:Hide();
    MRT_GUI_TT:SetOwner(UIParent, "ANCHOR_NONE");
end


------------------------
--  OnUpdate handler  --
------------------------
-- Is there a better way to handle OnClick-Events from each table without overwriting the sort functions?
function MRT_GUI_OnUpdateHandler()
    local raidnum = MRT_GUI_RaidLogTable:GetSelection();
    local bossnum = MRT_GUI_RaidBosskillsTable:GetSelection();
    if (raidnum ~= MRT_GUI_RaidLogTableSelection) then
        MRT_GUI_RaidLogTableSelection = raidnum;
        if (raidnum) then
            MRT_GUI_RaidDetailsTableUpdate(MRT_GUI_RaidLogTable:GetCell(raidnum, 1));
            ImportReminder();
        else
            MRT_GUI_RaidDetailsTableUpdate(nil);
        end
    end
    --we don't use the bosskillstable... can we comment this out?
    
    if (bossnum ~= MRT_GUI_RaidBosskillsTableSelection) then
        MRT_GUI_RaidBosskillsTableSelection = bossnum;
        if (bossnum) then
            --MRT_GUI_BossDetailsTableUpdate(MRT_GUI_RaidBosskillsTable:GetCell(bossnum, 1))
        else
            MRT_GUI_BossDetailsTableUpdate(nil);
        end
    end
end


------------------------------
--  table update functions  --
------------------------------
-- update all tables
function MRT_GUI_CompleteTableUpdate()
    MRT_GUI_RaidLogTableUpdate();
    MRT_GUI_RaidDetailsTableUpdate(nil);
    MRT_GUI_BossDetailsTableUpdate(nil);
end

-- update raid details tables
function MRT_GUI_RaidDetailsTableUpdate(raidnum, skipsort)
    MRT_GUI_RaidAttendeesTableUpdate(raidnum);
    MRT_GUI_RaidBosskillsTableUpdate(raidnum);
    MRT_GUI_BossDetailsTableUpdate(nil, skipsort);
end

-- update boss details tables
function MRT_GUI_BossDetailsTableUpdate(bossnum, skipsort)
    MRT_GUI_BossLootTableUpdate(bossnum, skipsort);
    MRT_GUI_BossAttendeesTableUpdate(bossnum);
end

-- update raid list table
function MRT_GUI_RaidLogTableUpdate()
    if (MRT_RaidLog == nil) then return; end
    local MRT_GUI_RaidLogTableData = {};
    -- insert reverse order
    for i, v in ipairs(MRT_RaidLog) do
        --MRT_GUI_RaidLogTableData[i] = {i, date("%m/%d %H:%M", v["StartTime"]), v["RaidZone"], v["RaidSize"]};
        MRT_GUI_RaidLogTableData[i] = {i, date("%m/%d %H:%M", v["StartTime"]), v["RaidZone"]};
    end
    table.sort(MRT_GUI_RaidLogTableData, function(a, b) return (a[1] > b[1]); end);
    MRT_GUI_RaidLogTable:ClearSelection();
    MRT_GUI_RaidLogTable:SetData(MRT_GUI_RaidLogTableData, true);
    lastShownNumOfRaids = #MRT_RaidLog;
end

function MRT_GUI_RaidAttendeeFilter()
    --MRT_Debug("MRT_GUI_RaidAttendeeFilter Called!");
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local strText = MRT_GUIFrame_RaidAttendees_Filter:GetText();
    --attendeeFilterHack
    if attendeeFilterHack > 0 then
        MRT_GUI_RaidAttendeesTableUpdate(raidnum,strText);
    else
        attendeeFilterHack = attendeeFilterHack + 1;
    end
    
end

function MRT_GUI_BossLootFilter()
    --MRT_Debug("MRT_GUI_BossLootFilter Called!");
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local strText = MRT_GUIFrame_BossLoot_Filter:GetText();
    --MRT_Debug("MRT_GUI_BossLootFilter: strText = " ..strText);
    if lootFilterHack > 0 then
        MRT_GUI_BossLootTableUpdate(nil, false, strText);
    else
        lootFilterHack = lootFilterHack + 1;
    end
end


function MRT_GUI_RaidAttendeeResetFilter()
    --MRT_Debug("MRT_GUI_RaidAttendeeResetFilter called!");
    MRT_GUIFrame_RaidAttendees_Filter:ClearFocus();
end

function MRT_GUI_BossLootFilterResetFilter()
    --MRT_Debug("MRT_GUI_BossLootFilterResetFilter called!");
    MRT_GUIFrame_BossLoot_Filter:ClearFocus();
end

-- update raid attendees table
function MRT_GUI_RaidAttendeesTableUpdate(raidnum, filter, dataonly)
  --  MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate Called!");
    local MRT_GUI_RaidAttendeesTableData = {};
    local indexofsub
    local checkFilter = filter;
    local PlayerCache = {};
    if not checkFilter then
        checkFilter = MRT_GUIFrame_RaidAttendees_Filter:GetText();
    end
    if (raidnum) then
        --MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate: raidnum == true");
        local index = 1;
        for k, v in pairs(MRT_RaidLog[raidnum]["Players"]) do
            local iList = PlayerCache[v["Name"]] -- if iList is nil then player has not been added to the PlayerCache
            if not iList then 
                PlayerCache[v["Name"]] = 1  --add the player to the PlayerCache 
                classColor = "ff9d9d9d";
                -- add check here for filter
                if (not checkFilter) or checkFilter == "" then
                    v["PR"] = getModifiedPR(raidnum, v["Name"]);
                    v["Class"] = getPlayerClass(v["Name"]);
                    classColor = getClassColor(v["Class"]);         
                    MRT_GUI_RaidAttendeesTableData[index] = {k, "|c"..classColor..v["Name"], v["PR"], date("%H:%M", v["Join"]), v["Class"]};
                    index = index + 1;
                else 
                    -- need function here to return true if there are classes to filter
                    --old code: local strFilter, classname = parseFilter(filter);
                    local strFilter, isClassFilter = parseFilter4Classes(checkFilter);
                    --old code: MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate: strFilter =  ".. strFilter);

                    --old code if classname then  -- if there are class filters then do something
                    if isClassFilter then
                        -- if there are classes to filter check for which classes
                        -- checking if class is in the classfilter list
                        -- new function to return true if class is in classfilter table.
                        -- old code: indexofsub = substr(v["Class"], strFilter);
                        -- old code: if not indexofsub then
                        local tblClassFilter = check4GroupFilters(strFilter);

                        --old code if not (isClassinClassFilter(v["Class"], strFilter)) then
                        if not (isClassinClassFilter(v["Class"], tblClassFilter)) then
                            --skip no class matches so don't do anything.
                        else 
                            --class match found so include in table
                            v["PR"] = getModifiedPR(raidnum, v["Name"]);
                            v["Class"] = getPlayerClass(v["Name"]);
                            
                            classColor = getClassColor(v["Class"]); 

                           -- MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate: v[PR]: ".. v["PR"]);
                            MRT_GUI_RaidAttendeesTableData[index] = {k, "|c"..classColor..v["Name"], v["PR"], date("%H:%M", v["Join"]), v["Class"]};
                            index = index + 1;
                        end
                    else --not class filter, do regular filter
                        indexofsub = substr(v["Name"], strFilter);
                        if not indexofsub then
                            --skip
                        else 
                            v["PR"] = getModifiedPR(raidnum, v["Name"]);
                            v["Class"] = getPlayerClass(v["Name"]);
                            
                            classColor = getClassColor(v["Class"]); 

                    --      MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate: v[PR]: ".. v["PR"]);
                            MRT_GUI_RaidAttendeesTableData[index] = {k, "|c"..classColor..v["Name"], v["PR"], date("%H:%M", v["Join"]), v["Class"]};
                            index = index + 1;
                        end
                    end
                end
            else
                --skip
            end
        end
    else
        --MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate: raidnum == false");
    end
    --table.sort(MRT_GUI_RaidAttendeesTableData, function(a, b) return (a[5] > b[5]); end);
    --table.sort(MRT_GUI_RaidAttendeesTableData, function(a, b) return (a[5] > b[5]); end);
    --MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate:about to call sort");
    
    if (dataonly) then
        --return table before updating
        return MRT_GUI_RaidAttendeesTableData;
    end
    --MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate:about to call sort");
    table.sort(MRT_GUI_RaidAttendeesTableData, sortbyclassthenPR);
    MRT_GUI_RaidAttendeesTable:ClearSelection();
    MRT_GUI_RaidAttendeesTable:SetData(MRT_GUI_RaidAttendeesTableData, true);
    MRT_GUI_RaidAttendeesTable:SortData(MRT_GUIFrame_RaidAttendee_GroupByCB:GetChecked());
    return MRT_GUI_RaidAttendeesTableData;

end
function parseFilter(strText)
    MRT_Debug("parseFilter called!");
    local filtertype = {
        [":warrior"] = "warrior",
        [":priest"] = "priest",
        [":warlock"] = "warlock",
        [":druid"] = "druid",
        [":hunter"] = "hunter",
        [":rogue"] = "rogue",
        [":paladin"] = "paladin",
        [":mage"] = "mage",
        [":shaman"] = "shaman",
    }
    if substr(strText,":") then
        MRT_Debug("parseFilter : found!");
        local classname = filtertype[strlower(strText)]
        if not classname then
            MRT_Debug("parseFilter classname not found");
            return strText;
        else
            return classname, true;
        end
    else
        return strText;
    end
end

function parseFilter4Classes(strText)
    --MRT_Debug("parseFilter4Classes called!");
    classFilters = {}
    local retVal = string.gsub(strText, " ", "")
    --MRT_Debug("parseFilter4Classes retVal == "..retVal);
    if string.len(retVal) > 3 and substr(strText,":") then
        for i in string.gmatch(retVal, "%a+") do
            --MRT_Debug("parseFilter4Classes i == "..i);
            table.insert(classFilters, i);
        end
        if table.maxn(classFilters) > 0 then
            --MRT_Debug("parseFilter4Classes:classFilters true");
            return classFilters, true;
        else
            --MRT_Debug("parseFilter4Classes:classFilters false");
            return strText, false;
        end 
    else
        return strText;
    end
end
function parseFilter4Special(strText)
    --MRT_Debug("parseFilter4Special called!");
    specialFilters = {}
    local retVal = string.gsub(strText, " ", "")
    --MRT_Debug("parseFilter4Special retVal == "..retVal);
    if string.len(retVal) > 3 and substr(strText,":") then
        for i in string.gmatch(retVal, "%a+") do
            --MRT_Debug("parseFilter4Special i == "..i);
            table.insert(specialFilters, i);
        end
        if table.maxn(specialFilters) > 0 then
            --MRT_Debug("parseFilter4Special:classFilters true");
            return specialFilters, true;
        else
            --MRT_Debug("parseFilter4Special:classFilters false");
            return strText, false;
        end 
    else
        return strText;
    end
end
function isLooterInSpecialFilter(looter, specialFilter)
    --return if looter is not in special filter
    --MRT_Debug("isLooterInSpecialFilter:Called!");
    MRT_Debug("isLooterInSpecialFilter: # of items: "..table.maxn(specialFilter));
    for i, v in pairs(specialFilter) do
        --MRT_Debug("isLooterInSpecialFilter:looter == " ..looter);
        --MRT_Debug("isLooterInSpecialFilter:i == " ..i.." :v == " ..v);
        if string.lower(v) == string.lower(looter) then
            return false;
        else 
            --MRT_Debug("isLooterInSpecialFilter: looter not in table");
        end
    end
    return true;
end
function isClassinClassFilter(class, classFilter)
    local strClass = class;
    if (not strClass) or (strClass == "") then
        strClass = "Unknown";
    end
    --MRT_Debug("isClassinClassFilter");
    for i, v in pairs(classFilter) do
        MRT_Debug("isClassinClassFilter:class == " ..strClass);
        MRT_Debug("isClassinClassFilter:v == " ..v);
        if string.lower(v) == string.lower(strClass) then
            MRT_Debug("isClassinClassFilter: condition is true");
            return true;
        end
    end
    return false;
end 
function check4GroupFilters(classFilter)
    MRT_Debug("check4GroupFilters: called!");

    local sgroupFilters = {
        ["healer"] = {"druid", "paladin", "priest"},
        ["healers"] = {"druid", "paladin", "priest"},
        ["caster"] = {"mage", "warlock"},
        ["casters"] = {"mage", "warlock"},
        ["ranged"] = {"mage", "warlock", "hunter"},
        ["melee"] = {"warrior", "rogue"},
        ["players"] = {"bank", "disenchanted"},
        ["player"] = {"bank", "disenchanted"},
        ["command"] = {"warrior", "hunter", "rogue", "priest"},
        ["dominance"] = {"druid", "mage", "paladin", "warlock", "shaman"},
        ["diadem"] = {"druid", "hunter", "paladin", "rogue", "shaman"},
        ["circlet"] = {"mage", "priest", "warlock", "warrior"},
    }
    local oclassFilter = classFilter;
    
    for i, v in pairs(oclassFilter) do
        --look for special filter
        local tblGroupFilter = sgroupFilters[string.lower(v)];

        if (tblGroupFilter) then
            --add the list into the classFilter
            for i1, v1 in pairs(tblGroupFilter) do
                MRT_Debug("check4GroupFilters: i1: " ..i1.. " v1: " ..v1);
                table.insert(oclassFilter,v1)
            end
        end
    end
    return oclassFilter
end

function sortbyclassthenPR (a, b)
    if a[5] == b[5] then
        if a[3] > b[3] then
            return true;
        else
            return false;
        end
    else
        if a[5] > b [5] then
            return true;
        else
            return false;
        end
    end
end

function getClassColor(class)
    local classColor = "ff9d9d9d";
    if class == "Hunter"
    then classColor = "ffA9D271";
    elseif class == "Druid"
    then classColor = "ffFF7D0A";   
    elseif class == "Mage"
    then classColor = "ff40C7EB";   
    elseif class == "Paladin"
    then classColor = "ffF58CBA";   
    elseif class == "Rogue"
    then classColor = "ffFFF569";   
    elseif class == "Warlock"
    then classColor = "ff8787ED";   
    elseif class == "Warrior"
    then classColor = "ffC79C6E";   
    elseif class == "Shaman"
    then classColor = "ff0070DE";   
    elseif class == "Priest"
    then classColor = "ffffffff";
    elseif class == "bank"
    then classColor = "ff9d8e8d";
    elseif class == "disenchanted"
    then classColor = "ff9d8e8d";
    end 
    return classColor;
end

function substr(str1, str2)
    local s1 = string.lower(str1);
    local s2 = string.lower(str2);
    return string.find(s1,s2);
end 
-- function to get adjusted PR from bossloottable
function getModifiedPR(raidnum, PlayerName)
    --MRT_Debug("getModifiedPR Called!");
    if not MRT_ReadOnly then 
        local pPR, pEP, pGP = getSFEPGP(PlayerName);
        local intLootGP = 0;
        if not pGP then
            pGP = "0";
        end 
        if not pEP then
            pEP = "0";
        end
        intpEP = tonumber(pEP);
    --  MRT_Debug("getModifiedPR: pPR: " .. pPR .. " pEP: " ..pEP.. " pGP: " .. pGP);
        intpGP = tonumber(pGP) + 2000;
        --MRT_Debug("getModifiedPR:intpGP = " ..tostring(intpGP));
        for i, v in pairs(MRT_RaidLog[raidnum]["Loot"]) do
            if v["Looter"] == PlayerName then
    --           MRT_Debug("getModifiedPR:Found Player in Loot table");
                intLootGP = intLootGP + tonumber(v["DKPValue"]);
    --          MRT_Debug("getModifiedPR:intLoopGP = " ..tostring(intLoopGP));
            end 
        end
        if intLootGP == 0 then
        --   MRT_Debug("getModifiedPR:intLootGP = 0");
            if not pPR then
                return "0";
            else 
                return pPR;
            end
        else 
        --    MRT_Debug("getModifiedPR:intLootGP <> 0");
            local newGP = intpGP + intLootGP
            local newPR = intpEP / newGP
            local retval = math.floor(newPR * 100)/100;
            return tostring(retval);
        end
    else
        --MRT_Debug("getModifiedPR: readonly mode get PR from MRT_ROPlayerPR")
        --If readonly mode, we need to get the PR data from ML if ML doesn't exist, use local data.
        local currentrealm = GetRealmName();
        local retVal
        local playerCheck
        retVal = MRT_ROPlayerPR[PlayerName]
        if not retVal then
            MRT_Debug("getModifiedPR: MRT_ROPlayerPR is blank, checking MRT_PlayerDB")
            MRT_Debug("getModifiedPR: currentrealm: " ..currentrealm.. " PlayerName: ".. PlayerName)
            --look for playing playerDB
            playerCheck = MRT_PlayerDB[currentrealm][PlayerName]
            if (playerCheck) then 
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

-- update bosskill table
function MRT_GUI_RaidBosskillsTableUpdate(raidnum)
    local MRT_GUI_RaidBosskillsTableData = {};
    local MRT_BosskillsCount = nil;
    if (raidnum) then MRT_BosskillsCount = #MRT_RaidLog[raidnum]["Bosskills"]; end;
    if (raidnum and MRT_BosskillsCount) then
       --[[  for i, v in ipairs(MRT_RaidLog[raidnum]["Bosskills"]) do
            if (not v["Difficulty"]) then
                MRT_GUI_RaidBosskillsTableData[i] = {i, date("%H:%M", v["Date"]), v["Name"], "-"};
            elseif (tContains(mrt.diffIDsNormal, v["Difficulty"])) then
                MRT_GUI_RaidBosskillsTableData[i] = {i, date("%H:%M", v["Date"]), v["Name"], PLAYER_DIFFICULTY1};
            elseif (tContains(mrt.diffIDsHeroic, v["Difficulty"])) then
                MRT_GUI_RaidBosskillsTableData[i] = {i, date("%H:%M", v["Date"]), v["Name"], PLAYER_DIFFICULTY2};
            elseif (v["Difficulty"] == 8) then
                MRT_GUI_RaidBosskillsTableData[i] = {i, date("%H:%M", v["Date"]), v["Name"], PLAYER_DIFFICULTY5};
            elseif (v["Difficulty"] == 16) then
                MRT_GUI_RaidBosskillsTableData[i] = {i, date("%H:%M", v["Date"]), v["Name"], PLAYER_DIFFICULTY6};
            elseif (tContains(mrt.diffIDsLFR, v["Difficulty"])) then
                MRT_GUI_RaidBosskillsTableData[i] = {i, date("%H:%M", v["Date"]), v["Name"], MRT_L.GUI.Cell_LFR};
            end
        end ]]
        for i, v in ipairs(MRT_RaidLog[raidnum]["Bosskills"]) do 
            MRT_GUI_RaidBosskillsTableData[i] = {i, v["Name"]};
        end
    end
    table.sort(MRT_GUI_RaidBosskillsTableData, function(a, b) return (a[1] > b[1]); end);
    MRT_GUI_RaidBosskillsTable:ClearSelection();
    MRT_GUI_RaidBosskillsTable:SetData(MRT_GUI_RaidBosskillsTableData, true);
    lastSelectedRaidNum = raidnum;
    lastShownNumOfBosses = MRT_BosskillsCount;
end

function SetDoneState(looter, traded, itemName)

    local doneState = false;

    if (looter == "unassigned") then
           return false;
    end

    --if it's assigned to disenchanted or bank... it's done
    if (looter == "disenchanted") or (looter == "bank") then
        return true;
    end

    --if it's been marked traded by the trade process.. it's done
    if traded then
        return true;
    end

    --if item is assigned to a player & not in your bag (or in your bag, but loot timer expired) set to done
    local foundInBag, containerID, slotID = findItemInBag(itemName);
    if not foundInBag then
        --not in your bag .
        doneState = true;
    else
        local timeRemaining = GetContainerItemTradeTimeRemaining(containerID, slotID);
        if timeRemaining==0 then
            --in your bag but not tradeable (loot timer expired), your done
            doneState=true;
        end
    end

    return doneState;
end    

-- update bossloot table
function MRT_GUI_BossLootTableUpdate(bossnum, skipsort, filter)
    --if skipsort then 
    --    MRT_Debug("MRT_GUI_BossLootTableUpdate: skipsort==True");
    --else
    --    MRT_Debug("MRT_GUI_BossLootTableUpdate: skipsort:Nil ");
    --end
    local MRT_GUI_BossLootTableData = {};
    local raidnum;
    local indexofsub1;
    local indexofsub2;

    -- check if a raid is selected
    if (MRT_GUI_RaidLogTable:GetSelection()) then
        raidnum = MRT_GUI_RaidLogTable:GetCell(MRT_GUI_RaidLogTableSelection, 1);
        --MRT_Debug("MRT_GUI_BossLootTableUpdate: raidnum: " ..raidnum);
    end
    -- if a bossnum is given, just list loot of this boss
    if (bossnum) then
        --MRT_Debug("MRT_GUI_BossLootTableUpdate: if bossnum condition");
        local index = 1;
        for i, v in ipairs(MRT_RaidLog[raidnum]["Loot"]) do
            if (v["BossNumber"] == bossnum) then

                --Set Class Color
                classColor = "ff9d9d9d";
                local playerClass = getPlayerClass(v["Looter"]);   
                classColor = getClassColor(playerClass);     

                --GetDate 
                loottime = calculateLootTimeLeft(v["Time"])

                --SetDoneState
                local doneState = SetDoneState(v["Looter"], v["Traded"], v["ItemName"])

                if v["Looter"] == "unassigned" then
                    MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", "|cffff0000"..v["Looter"], v["DKPValue"], v["ItemLink"], lootTime, doneState};
                    if v["Offspec"] then
                    --    MRT_Debug("MRT_GUI_BossLootTableUpdate: MRT_GUI_BossTableData2;dkpvalue: ".. v["DKPValue"].. "Offspec: True");
                    else
                    --    MRT_Debug("MRT_GUI_BossLootTableUpdate: MRT_GUI_BossTableData2;dkpvalue: ".. v["DKPValue"].. "Offspec: False");
                    end
                else
                    classColor = "ff9d9d9d";
                    local class = getPlayerClass(v["Looter"]);   
                    classColor = getClassColor(class);      
                    --MRT_Debug(classColor);

                    MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", "|c"..classColor..v["Looter"], v["DKPValue"], v["ItemLink"], lootTime, doneState};
                    if v["Offspec"] then
                      --  MRT_Debug("MRT_GUI_BossLootTableUpdate: MRT_GUI_BossTableData1;dkpvalue: ".. v["DKPValue"].. "Offspec: True");
                    else
                    --    MRT_Debug("MRT_GUI_BossLootTableUpdate: MRT_GUI_BossTableData1;dkpvalue: ".. v["DKPValue"].. "Offspec: False");
                    end
                end 
                index = index + 1;
            end
        end
        MRT_GUIFrame_BossLootTitle:SetText(MRT_L.GUI["Tables_BossLootTitle"]);
    -- there is only a raidnum and no bossnum, list raid loot
    elseif (raidnum) then
        --MRT_Debug("MRT_GUI_BossLootTableUpdate: elseif raidnum condition");
        local index = 1;

        for i, v in ipairs(MRT_RaidLog[raidnum]["Loot"]) do
            --MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", v["Looter"], v["DKPValue"], v["ItemLink"], v["Note"]};
            -- SF: if unassigned, make it red.
            
            --Set Class Color
            classColor = "ff9d9d9d";
            local playerClass = getPlayerClass(v["Looter"]);   
            classColor = getClassColor(playerClass);  
            --MRT_Debug("Row: "..v["ItemName"])
           --MRT_Debug("MRT_GUI_BossLootTableUpdate: elseif raidnum condition: looter: " ..v["Looter"] .."playerClass: "..playerClass..", classColor: " ..classColor);
            
            --GetDate 
            loottime = calculateLootTimeLeft(v["Time"])

            --SetDoneState
            local doneState = SetDoneState(v["Looter"], v["Traded"], v["ItemName"])

            if not filter then
                if v["Looter"] == "unassigned" then
                    MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", "|cffff0000"..v["Looter"], v["DKPValue"], v["ItemLink"], lootTime, doneState};
                else 
                    MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", "|c"..classColor..v["Looter"], v["DKPValue"], v["ItemLink"], lootTime, doneState};
                end 
                index = index + 1;
            else
                local checkFilter = filter;
                if not checkFilter then
                    checkFilter = MRT_GUIFrame_BossLoot_Filter:GetText();
                end
                -- need function here to return true if there are classes to filter
                --local strFilter, isSpecialFilter = parseFilter4Special(checkFilter); 
                local strFilter, isSpecialFilter = parseFilter4Classes(checkFilter);
                if isSpecialFilter then
                    -- if there are classes or special to filter check for which classes
                    -- checking if class is in the classfilter list
                    -- new function to return true if class is in classfilter table.
                    -- old code: indexofsub = substr(v["Class"], strFilter);
                    -- old code: if not indexofsub then
                    local tblSpecialFilter = check4GroupFilters(strFilter);
                    --tblSpecialFilter = filter out list.

                    if not (isLooterInSpecialFilter(v["Looter"], tblSpecialFilter)) then
                        --skip no special matches so don't do anything.
                    else 
                        --special match found so include in table
                        if v["Looter"] == "unassigned" then
                            MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", "|cffff0000"..v["Looter"], v["DKPValue"], v["ItemLink"], lootTime, doneState};
                        else 
                            MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", "|c"..classColor..v["Looter"], v["DKPValue"], v["ItemLink"], lootTime, doneState};
                        end 
                        index = index + 1;
                    end
                else -- if not special filter, do the normal thing 
                    indexofsub1 = substr(v["ItemName"], filter);
                    indexofsub2 = substr(v["Looter"], filter);
                    if not indexofsub1 and not indexofsub2 then
                        --skip
                    else
                        ---
                        if v["Looter"] == "unassigned" then
                            MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", "|cffff0000"..v["Looter"], v["DKPValue"], v["ItemLink"], lootTime, doneState};
                        else 
                            MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", "|c"..classColor..v["Looter"], v["DKPValue"], v["ItemLink"], lootTime, doneState};
                        end 
                        index = index + 1;
                    end
                end
            end
        end
    --    MRT_GUIFrame_BossLootTitle:SetText(MRT_L.GUI["Tables_RaidLootTitle"]);
    -- if either raidnum nor bossnum, show an empty table
    else
        --MRT_Debug("MRT_GUI_BossLootTableUpdate: no raidnum or bossnum");
    --    MRT_GUIFrame_BossLootTitle:SetText(MRT_L.GUI["Tables_RaidLootTitle"]);
    end
    table.sort(MRT_GUI_BossLootTableData, function(a, b) return (a[3] < b[3]); end);
    --MRT_GUI_BossLootTable:ClearSelection();
    --[[ if skipsort then 
        MRT_Debug("MRT_GUI_BossLootTableUpdate: skipsort==True about to call SetData");
    else
        MRT_Debug("MRT_GUI_BossLootTableUpdate: skipsort:Nil about to call SetData");
    end ]]
    MRT_GUI_BossLootTable:SetData(MRT_GUI_BossLootTableData, true, skipsort);
    lastSelectedBossNum = bossnum;
end

function calculateLootTimeLeft (timeLooted)

    lootTimeStamp = timeLooted;
    local nowTimeStamp = MRT_GetCurrentTime();
    -- MRT_Debug(date("%m/%d/%y %H:%M:%S", nowTimeStamp));
    -- MRT_Debug(date("%m/%d/%y %H:%M:%S", lootTimeStamp));
    local deltaTime = 7200 - difftime(nowTimeStamp, lootTimeStamp);
    --MRT_Debug(deltaTime)

    if deltaTime > 0 then
        local hours = math.floor(deltaTime /3600);
        local minutes = math.floor( (deltaTime - (hours*3600) )/60);
        local strM --string for minutes to get 01 instead of 1
        if minutes < 10 then
            strM = "0"..minutes
        else
            strM = minutes
        end
        -- MRT_Debug(hours);
        -- MRT_Debug(minutes);
        if hours > 0 then
            lootTime = hours ..":" ..strM;
        else
            lootTime = ":" ..strM;
        end
    else
        lootTime = date("%I:%M", timeLooted); --default to time stamp if the loot has expired
    end
end

-- update bossattendee table
function MRT_GUI_BossAttendeesTableUpdate(bossnum)
    local MRT_GUI_BossAttendeesTableData = {};
    if (bossnum) then
        local raidnum = MRT_GUI_RaidLogTable:GetCell(MRT_GUI_RaidLogTableSelection, 1);
        for i, v in ipairs(MRT_RaidLog[raidnum]["Bosskills"][bossnum]["Players"]) do
            --MRT_GUI_BossAttendeesTableData[i] = {i, v};
        end
        --MRT_GUIFrame_BossAttendeesTitle:SetText(MRT_L.GUI["Tables_BossAttendeesTitle"].." ("..tostring(#MRT_GUI_BossAttendeesTableData)..")");
    else
        --MRT_GUIFrame_BossAttendeesTitle:SetText(MRT_L.GUI["Tables_BossAttendeesTitle"]);
    end
    --table.sort(MRT_GUI_BossAttendeesTableData, function(a, b) return (a[2] < b[2]); end);
    --MRT_GUI_BossAttendeesTable:ClearSelection();
    --MRT_GUI_BossAttendeesTable:SetData(MRT_GUI_BossAttendeesTableData, true);
end


--------------------------------------
--  functions for the dialog boxes  --
--------------------------------------
function MRT_GUI_HideDialogs()
    StaticPopup_Hide("MRT_GUI_ZeroRowDialog");
    MRT_GUI_OneRowDialog_EB1:SetScript("OnEnter", nil);
    MRT_GUI_OneRowDialog_EB1:SetScript("OnLeave", nil);
    MRT_GUI_OneRowDialog:Hide();
    MRT_GUI_TwoRowDialog_DDM:Hide();
    MRT_GUI_TwoRowDialog_EB1:SetScript("OnEnter", nil);
    MRT_GUI_TwoRowDialog_EB1:SetScript("OnLeave", nil);
    MRT_GUI_TwoRowDialog_EB2:SetScript("OnEnter", nil);
    MRT_GUI_TwoRowDialog_EB2:SetScript("OnLeave", nil);
    MRT_GUI_TwoRowDialog_EB2:Show();
    MRT_GUI_TwoRowDialog:Hide();
    MRT_GUI_ThreeRowDialog_EB1:SetScript("OnEnter", nil);
    MRT_GUI_ThreeRowDialog_EB1:SetScript("OnLeave", nil);
    MRT_GUI_ThreeRowDialog_EB2:SetScript("OnEnter", nil);
    MRT_GUI_ThreeRowDialog_EB2:SetScript("OnLeave", nil);
    MRT_GUI_ThreeRowDialog_EB3:SetScript("OnEnter", nil);
    MRT_GUI_ThreeRowDialog_EB3:SetScript("OnLeave", nil);
    MRT_GUI_ThreeRowDialog:Hide();
    MRT_GUI_FourRowDialog_EB1:SetScript("OnEnter", nil);
    MRT_GUI_FourRowDialog_EB1:SetScript("OnLeave", nil);
    MRT_GUI_FourRowDialog_EB2:SetScript("OnEnter", nil);
    MRT_GUI_FourRowDialog_EB2:SetScript("OnLeave", nil);
    MRT_GUI_FourRowDialog_EB3:SetScript("OnEnter", nil);
    MRT_GUI_FourRowDialog_EB3:SetScript("OnLeave", nil);
    MRT_GUI_FourRowDialog_EB4:SetScript("OnEnter", nil);
    MRT_GUI_FourRowDialog_EB4:SetScript("OnLeave", nil);
    MRT_GUI_FourRowDialog:Hide();
    MRT_ExportFrame_Hide();
end

-- enable shift-click-parsing of item links
function MRT_GUI_Hook_ChatEdit_InsertLink(link)
    if MRT_GUI_OneRowDialog:IsVisible() then
        if MRT_GUI_OneRowDialog_EB1:HasFocus() then
            MRT_GUI_OneRowDialog_EB1:SetText(link);
        end
    end
    if MRT_GUI_TwoRowDialog:IsVisible() then
        if MRT_GUI_TwoRowDialog_EB1:HasFocus() then
            MRT_GUI_TwoRowDialog_EB1:SetText(link);
        elseif MRT_GUI_TwoRowDialog_EB2:HasFocus() then
            MRT_GUI_TwoRowDialog_EB2:SetText(link);
        end
    end
    if MRT_GUI_ThreeRowDialog:IsVisible() then
        if MRT_GUI_ThreeRowDialog_EB1:HasFocus() then
            MRT_GUI_ThreeRowDialog_EB1:SetText(link);
        elseif MRT_GUI_ThreeRowDialog_EB2:HasFocus() then
            MRT_GUI_ThreeRowDialog_EB2:SetText(link);
        elseif MRT_GUI_ThreeRowDialog_EB3:HasFocus() then
            MRT_GUI_ThreeRowDialog_EB3:SetText(link);
        end
    end
    if MRT_GUI_FourRowDialog:IsVisible() then
        if MRT_GUI_FourRowDialog_EB1:HasFocus() then
            MRT_GUI_FourRowDialog_EB1:SetText(link);
        elseif MRT_GUI_FourRowDialog_EB2:HasFocus() then
            MRT_GUI_FourRowDialog_EB2:SetText(link);
        elseif MRT_GUI_FourRowDialog_EB3:HasFocus() then
            MRT_GUI_FourRowDialog_EB3:SetText(link);
        elseif MRT_GUI_FourRowDialog_EB4:HasFocus() then
            MRT_GUI_FourRowDialog_EB4:SetText(link);
        end
    end
end
-- Hook on ChatEdit_InsertLink - execute own parsing after standard WoW parsing
hooksecurefunc("ChatEdit_InsertLink", MRT_GUI_Hook_ChatEdit_InsertLink);


-------------------------------------
--  ZeroRowDialog as static popup  --
-------------------------------------
-- To show/hide this dialog: StaticPopup_Show("Popup name") / StaticPopup_Hide("Popup name")
StaticPopupDialogs["MRT_GUI_ZeroRowDialog"] = {
    preferredIndex = 3,
    text = "FIXME!",
    button1 = MRT_L.Core["MB_Yes"],
    button2 = MRT_L.Core["MB_No"],
    OnAccept = nil,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}
StaticPopupDialogs["MRT_GUI_ok"] = {
    preferredIndex = 3,
    text = "FIXME!",
    button1 = MRT_L.Core["MB_Ok"],
    OnAccept = nil,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}
