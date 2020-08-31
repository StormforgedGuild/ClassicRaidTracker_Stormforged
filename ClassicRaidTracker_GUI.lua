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
local ag -- import reminder animationgroup

local MRT_GUI_RaidLogTableSelection = nil;
local MRT_GUI_RaidBosskillsTableSelection = nil;

local MRT_ExternalLootNotifier = {};

local lastShownNumOfRaids = nil;
local lastSelectedRaidNum = nil;
local lastShownNumOfBosses = nil;
local lastSelectedBossNum = nil;
local lastLootNum = nil;
local lastBossNum = nil;
local lastRaidNum = nil;
--state of dialog
local lastLooter = nil;
local lastValue = nil;
local lastNote = nil;
local lastOS = nil;
local lootFilterHack = 0;
local attendeeFilterHack = 0;

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
    {["name"] = MRT_L.GUI["Col_PR"], ["width"] = 40},
    {["name"] = MRT_L.GUI["Col_Join"], ["width"] = 35},

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
    ["name"] = MRT_L.GUI["Col_OffSpec"], 
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

function isDirty (strLooter, strValue, strNote, strOS)
    MRT_Debug("isDirty fired!");
    if (strLooter == lastLooter) and (strValue == lastValue) and (strNote == lastNote) and (strOS == lastOS) then
        MRT_Debug("isDirty = false");
        return false;
    else
        MRT_Debug("isDirty = true");
        return true;
    end
end

---------------------------------------------------------------
--  parse localization and set up tables after ADDON_LOADED  --
---------------------------------------------------------------
function MRT_GUI_ParseValues()


    -- Parse title strings
    MRT_GUIFrame_Title:SetText(MRT_L.GUI["Header_Title"]);
  --  MRT_GUIFrame_RaidLogTitle:SetText(MRT_L.GUI["Tables_RaidLogTitle"]);
    MRT_GUIFrame_RaidLogTitle:SetPoint("TOPLEFT", MRT_GUIFrame, "TOPLEFT", 25, -10);

 --   MRT_GUIFrame_RaidBosskillsTitle:SetText(MRT_L.GUI["Tables_RaidBosskillsTitle"]);
  --  MRT_GUIFrame_BossLootTitle:SetText(MRT_L.GUI["Tables_RaidLootTitle"]);
    --MRT_GUIFrame_BossAttendeesTitle:SetText(MRT_L.GUI["Tables_BossAttendeesTitle"]);
    -- Create and anchor tables
    MRT_GUI_RaidLogTable = ScrollingTable:CreateST(MRT_RaidLogTableColDef, 4, nil, nil, MRT_GUIFrame);
    MRT_GUI_RaidLogTable.frame:SetPoint("TOPLEFT", MRT_GUIFrame_RaidLog_Export_Button, "BOTTOMLEFT", 0, -20);
    MRT_GUI_RaidLogTable:EnableSelection(true);

 --   MRT_GUIFrame_RaidAttendees_Filter:SetText(MRT_L.GUI["Header_Title"]);
    MRT_GUIFrame_RaidAttendees_Filter:SetPoint("TOPLEFT", MRT_GUI_RaidLogTable.frame, "BOTTOMLEFT", 7, -5);
    MRT_GUIFrame_RaidAttendees_Filter:SetAutoFocus(false);

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

    MRT_GUIFrame_BossLoot_Filter:SetPoint("TOPLEFT", MRT_GUIFrame_RaidLogTitle, "BOTTOMLEFT", 205, -15);
    MRT_GUIFrame_BossLoot_Filter:SetAutoFocus(false);
    MRT_GUIFrame_BossLoot_Add_Button:SetText(MRT_L.GUI["Button_Small_Add"]);
    MRT_GUIFrame_BossLoot_Add_Button:SetPoint("RIGHT", MRT_GUIFrame_BossLoot_Filter, "RIGHT", 26, 0);
    MRT_GUIFrame_BossLoot_Delete_Button:SetText(MRT_L.GUI["Button_Small_Delete"]);
    MRT_GUIFrame_BossLoot_Delete_Button:SetPoint("LEFT", MRT_GUIFrame_BossLoot_Add_Button, "RIGHT", 0, 0);
    MRT_GUIFrame_BossLoot_Modify_Button:SetText(MRT_L.GUI["Button_Modify"]);
    MRT_GUIFrame_BossLoot_Modify_Button:SetPoint("LEFT", MRT_GUIFrame_BossLoot_Delete_Button, "RIGHT", 0, 0);
    MRT_GUIFrame_BossLoot_RaidLink_Button:SetText("Link");
    MRT_GUIFrame_BossLoot_RaidLink_Button:SetPoint("LEFT", MRT_GUIFrame_BossLoot_Modify_Button, "RIGHT", 0, 0);
    MRT_GUIFrame_BossLoot_RaidAnnounce_Button:SetText("Bid");
    MRT_GUIFrame_BossLoot_RaidAnnounce_Button:SetPoint("LEFT", MRT_GUIFrame_BossLoot_RaidLink_Button, "RIGHT", 0, 0);

    MRT_GUI_BossLootTable = ScrollingTable:CreateST(MRT_BossLootTableColDef, 12, 32, nil, MRT_GUIFrame);           -- ItemId should be squared - so use 30x30 -> 30 pixels high
    MRT_GUI_BossLootTable.head:SetHeight(15);                                                                     -- Manually correct the height of the header (standard is rowHight - 30 pix would be different from others tables around and looks ugly)
    MRT_GUI_BossLootTable.frame:SetPoint("TOPLEFT", MRT_GUIFrame_BossLoot_Filter, "BOTTOMLEFT", -5, -20);
    MRT_GUI_BossLootTable:EnableSelection(true);
    MRT_GUI_BossLootTable:RegisterEvents({
        ["OnDoubleClick"] = function(rowFrame,cellFrame, data, cols, row, realrow, coloumn, scrollingTable, ...)
            MRT_Debug("Doubleclick fired!");
            if MRT_GUI_FourRowDialog:IsVisible() then
                if isDirty(MRT_GUI_FourRowDialog_EB2:GetText(), MRT_GUI_FourRowDialog_EB3:GetText(), MRT_GUI_FourRowDialog_EB4:GetText(),MRT_GUI_FourRowDialog_CB1:GetChecked()) then
                    MRT_Debug("STOnDoubleClick: isDirty == True");
                    MRT_GUI_LootModifyAccept(lastRaidNum, lastBossNum, lastLootNum);
                end
                MRT_GUI_LootModify();
            else
                MRT_Debug("in false condition");
                MRT_GUI_LootModify();
            end;
        end,
        ["OnClick"] = function(rowFrame, cellFrame, data, cols, row, realrow, coloumn, scrollingTable, button, ...)
            MRT_Debug("MRT_BoosLootTable:Onclick fired!");
            donotdeselect = false;
            doOnClick(rowFrame, cellFrame, data, cols, row, realrow, coloumn, scrollingTable, button, true, false)  --passing true so that we don't deselect in the loot table.
            if MRT_GUI_FourRowDialog:IsVisible() then
                if isDirty(MRT_GUI_FourRowDialog_EB2:GetText(), MRT_GUI_FourRowDialog_EB3:GetText(), MRT_GUI_FourRowDialog_EB4:GetText(), MRT_GUI_FourRowDialog_CB1:GetChecked()) then
                    MRT_Debug("STOnClick: isDirty == True");
                    MRT_GUI_LootModifyAccept(lastRaidNum, lastBossNum, lastLootNum);
                end
                MRT_GUI_LootModify();
            end;
            return true;
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
    l:SetStartPoint("TOPLEFT",26,-48)
    l:SetEndPoint("TOPLEFT",201,-48)

    --Above the player list
    local l = MRT_GUIFrame:CreateLine()
    print(l)
    l:SetThickness(1)
    l:SetColorTexture(235,231,223,.5)
    l:SetStartPoint("TOPLEFT",26,-171)
    l:SetEndPoint("TOPLEFT",201,-171)

    --Above the loot list
    local l = MRT_GUIFrame:CreateLine()
    print(l)
    l:SetThickness(1)
    l:SetColorTexture(235,231,223,.5)
    l:SetStartPoint("TOPLEFT",227,-57)
    l:SetEndPoint("TOPLEFT",595,-57)

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
function MRT_GUI_Toggle()
    if (not MRT_GUIFrame:IsShown()) then
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

        ImportReminder();

    else
        MRT_GUIFrame:Hide();
        MRT_GUIFrame:SetScript("OnUpdate", nil);
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
    if (boss_select == nil) then
        if (MRT_NumOfLastBoss == nil) or (MRT_NumOfLastBoss == 0) then
            MRT_Debug("MRT_GUI_LootAdd: adding boss kill");
            MRT_AddBosskill(MRT_L.Core["Trash Mob"], "N");
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
    
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    if createdTrash then
        --no boss is available, add one and select
        MRT_Debug("MRT_GUI_LootAdd: createdTrash == true ");
        --MRT_Debug("MRT_GUI_LootAdd: MRT_NumOfLastBoss = " ..MRT_NumOfLastBoss);    
        bossnum = 1;
    else
        MRT_Debug("MRT_GUI_LootAdd: boss_select: " ..boss_select);
        local bossnum = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 1);
        MRT_GUI_RaidBosskillsTable:ClearSelection();
        --local bossnum = MRT_NumOfLastBoss;
    end
    -- gather playerdata and fill drop down menu
    local playerData = {};
    for i, val in ipairs(MRT_RaidLog[raidnum]["Bosskills"][bossnum]["Players"]) do
        playerData[i] = { val };
    end
    table.sort(playerData, function(a, b) return (a[1] < b[1]); end );
    tinsert(playerData, 1, { "disenchanted" } );
    tinsert(playerData, 1, { "bank" } );
    tinsert(playerData,1, {"unassigned"});
    tinsert(playerData, 1, {"pug"} );
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
    MRT_GUI_FourRowDialog_OKButton:SetScript("OnClick", function() MRT_GUI_LootModifyAccept(raidnum, bossnum, nil); end);
    MRT_GUI_FourRowDialog_CancelButton:SetText(MRT_L.Core["MB_Cancel"]);
    MRT_GUI_FourRowDialog_AnnounceWinnerButton:SetText(MRT_L.Core["MB_Win"]);
    MRT_GUI_FourRowDialog:Show();
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
    lastRaidNum = raidnum;
    local lootnum = MRT_GUI_BossLootTable:GetCell(loot_select, 1);
    lastLootNum = lootnum;
    local bossnum = MRT_RaidLog[raidnum]["Loot"][lootnum]["BossNumber"];
    lastBossNum = bossnum;
    local lootnote = MRT_RaidLog[raidnum]["Loot"][lootnum]["Note"];
    local lootoffspec = MRT_RaidLog[raidnum]["Loot"][lootnum]["Offspec"];
    
    if lootoffspec then
        MRT_Debug("MRT_GUI_LootModify: lootoffspec: True");
    else
        MRT_Debug("MRT_GUI_LootModify: lastLooter: False");
    end

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
    tinsert(playerData,1, {"unassigned"});
    tinsert(playerData, 1, {"pug"} );
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
    MRT_GUI_FourRowDialog_EB2_Text:SetText(MRT_L.GUI["Looter"]);
    MRT_GUI_FourRowDialog_EB2:SetText(cleanString(MRT_GUI_BossLootTable:GetCell(loot_select, 4)));
    lastLooter = MRT_GUI_FourRowDialog_EB2:GetText();
    MRT_Debug("MRT_GUI_LootModify: lastLooter: "..lastLooter);
    MRT_GUI_FourRowDialog_EB3_Text:SetText(MRT_L.GUI["Value"]);
    MRT_GUI_FourRowDialog_EB3:SetText(MRT_GUI_BossLootTable:GetCell(loot_select, 5));
    -- figure out how to get check box info
    if lootoffspec then 
        MRT_GUI_FourRowDialog_CB1:SetChecked(true);
    else
        MRT_GUI_FourRowDialog_CB1:SetChecked(false);
    end
    lastOS = MRT_GUI_FourRowDialog_CB1:GetChecked();
    if lastOS then 
        MRT_Debug("MRT_GUI_LootModify: lastOS = True");
    else
        MRT_Debug("MRT_GUI_LootModify: lastOS = False");
    end
    lastValue = MRT_GUI_FourRowDialog_EB3:GetText();
    MRT_Debug("MRT_GUI_LootModify: lastValue: "..lastValue);
    MRT_GUI_FourRowDialog_EB4_Text:SetText(MRT_L.GUI["Note"]);
    if (lootnote == nil or lootnote == "" or lootnote == " ") then
        MRT_GUI_FourRowDialog_EB4:SetText("");
        lastNote = "";
    else
        MRT_GUI_FourRowDialog_EB4:SetText(lootnote);
        lastNote = lootnote;
    end
    MRT_GUI_FourRowDialog_OKButton:SetText(MRT_L.GUI["Button_Modify"]);
    MRT_GUI_FourRowDialog_OKButton:SetScript("OnClick", function() MRT_GUI_LootModifyAccept(raidnum, bossnum, lootnum); end);
    MRT_GUI_FourRowDialog_CancelButton:SetText(MRT_L.Core["MB_Cancel"]);
    MRT_GUI_FourRowDialog_EB1:SetAutoFocus(false);
    MRT_GUI_FourRowDialog_EB1:SetCursorPosition(1);
    MRT_GUI_FourRowDialog_AnnounceWinnerButton:SetText(MRT_L.Core["MB_Win"]);

    MRT_GUI_FourRowDialog_EB2:SetFocus();
    MRT_GUI_FourRowDialog:Show();
    --MRT_GUI_FourRowDialog_EB1:SetEnabled(false);
    
end

function MRT_GUI_PlayerDropDownList_Toggle()
    if (MRT_GUI_PlayerDropDownTable.frame:IsShown()) then
        MRT_GUI_PlayerDropDownTable.frame:Hide();
    else
        MRT_GUI_PlayerDropDownTable.frame:Show();
        MRT_GUI_PlayerDropDownTable.frame:SetPoint("TOPRIGHT", MRT_GUI_FourRowDialog_DropDownButton, "BOTTOMRIGHT", 0, 0);
    end
end

function MRT_GUI_LootModifyAccept(raidnum, bossnum, lootnum)
    MRT_Debug("MRT_GUI_LootModifyAccept:Called!");
    local itemLinkFromText = MRT_GUI_FourRowDialog_EB1:GetText();
    local looter = MRT_GUI_FourRowDialog_EB2:GetText();
    local cost = MRT_GUI_FourRowDialog_EB3:GetText();
    local lootNote = MRT_GUI_FourRowDialog_EB4:GetText();
    local offspec = MRT_GUI_FourRowDialog_CB1:GetChecked();
    local newloot = false;
    if (cost == "") then cost = 0; end
    cost = tonumber(cost);
    if (lootNote == nil or lootNote == "" or lootNote == " ") then lootNote = nil; end
    -- sanity-check values here - especially the itemlink / looter is free text / cost has to be a number
    local itemName, itemLink, itemId, itemString, itemRarity, itemColor, _, _, _, _, _, _, _, _ = MRT_GetDetailedItemInformation(itemLinkFromText);
    if itemColor then 
        MRT_Debug("MRT_GUI_LootModifyAccept:itemColor: "..itemColor);
    end
    if (not itemName) then
        MRT_Print(MRT_L.GUI["No itemLink found"]);
        return;
    end
    if (not cost) then
        MRT_Print(MRT_L.GUI["Item cost invalid"]);
        return;
    end
    MRT_GUI_HideDialogs();
    -- insert new values here / if (lootnum == nil) then treat as a newly added item
    if (looter == "") then looter = "disenchanted"; end
    local MRT_LootInfo = {
        ["ItemLink"] = itemLink,
        ["ItemString"] = itemString,
        ["ItemId"] = itemId,
        ["ItemName"] = itemName,
        ["ItemColor"] = itemColor,
        ["BossNumber"] = bossnum,
        ["Looter"] = looter,
        ["DKPValue"] = cost,
        ["Note"] = lootNote,
        ["Offspec"] = offspec,
    }
    if (lootnum) then
        MRT_Debug("MRT_GUI_LootModifyAccept:lootnum if ");
        if MRT_LootInfo["Offspec"] then
            MRT_Debug("MRT_GUI_LootModifyAccept:Offspec = True");
        else
            MRT_Debug("MRT_GUI_LootModifyAccept:Offspec = False");
        end
        local oldLootDB = MRT_RaidLog[raidnum]["Loot"][lootnum];
        -- create a copy of the old loot data for the api
        local oldItemInfoTable = {}
        for key, val in pairs(oldLootDB) do
            oldItemInfoTable[key] = val;
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
    else
        newloot = true;
        MRT_LootInfo["ItemCount"] = 1;
        MRT_LootInfo["Time"] = MRT_RaidLog[raidnum]["Bosskills"][bossnum]["Date"] + 15;
        tinsert(MRT_RaidLog[raidnum]["Loot"], MRT_LootInfo);
        -- notify registered, external functions
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
    
    local item_select = MRT_GUI_BossLootTable:GetSelection();
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    if (raid_select == nil) then return; end
    local raidnum_selected = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local boss_select = MRT_GUI_RaidBosskillsTable:GetSelection();
    if (boss_select == nil) then
        if (raidnum_selected == raidnum) then
            MRT_Debug("MRT_GUI_Accept:About to call MRT_GUI_BossLootTableUpdate(nil,true)");
            MRT_GUI_BossLootTableUpdate(nil, true);
        end
        return;
    end
    local bossnum_selected = MRT_GUI_RaidBosskillsTable:GetCell(boss_select, 1);
    if (raidnum_selected == raidnum and bossnum_selected == bossnum) then
        MRT_Debug("MRT_GUI_Accept:About to call MRT_GUI_BossLootTableUpdate(bossnum,true)");
        MRT_GUI_BossLootTableUpdate(bossnum, true);
    end
    if newloot then
        MRT_Debug("MRT_GUI_Accept:new loot update the table");
        MRT_GUI_BossLootTableUpdate(bossnum);
    end
end

function MRT_GUI_LootRaidWinner()
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
    local looter = string.upper(MRT_GUI_FourRowDialog_EB2:GetText());
    local cost = MRT_GUI_FourRowDialog_EB3:GetText();
    local lootName = MRT_GUI_FourRowDialog_EB1:GetText();
    
    --"Congratz! %s receives %s for %sGP",   
    --local rwMessage = string.format(MRT_L.GUI["RaidWinMessage"], looter, MRT_RaidLog[raidnum]["Loot"][lootnum]["ItemLink"], cost);
    local rwMessage = string.format(MRT_L.GUI["RaidWinMessage"], looter, lootName, cost);
    SendChatMessage(rwMessage, "Raid");
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

    local rwMessage = string.format(MRT_L.GUI["RaidLinkMessage"], MRT_RaidLog[raidnum]["Loot"][lootnum]["ItemLink"], MRT_GUI_BossLootTable:GetCell(loot_select, 5));
    SendChatMessage(rwMessage, "Raid");
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

    local rwMessage = string.format(MRT_L.GUI["RaidAnnounceMessage"], MRT_RaidLog[raidnum]["Loot"][lootnum]["ItemLink"], MRT_GUI_BossLootTable:GetCell(loot_select, 5));
    SendChatMessage(rwMessage, "RAID_WARNING");
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
    if (bossnum ~= MRT_GUI_RaidBosskillsTableSelection) then
        MRT_GUI_RaidBosskillsTableSelection = bossnum;
        if (bossnum) then
            MRT_GUI_BossDetailsTableUpdate(MRT_GUI_RaidBosskillsTable:GetCell(bossnum, 1))
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
    MRT_Debug("MRT_GUI_RaidAttendeeFilter Called!");
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
    MRT_Debug("MRT_GUI_BossLootFilter Called!");
    local raid_select = MRT_GUI_RaidLogTable:GetSelection();
    local raidnum = MRT_GUI_RaidLogTable:GetCell(raid_select, 1);
    local strText = MRT_GUIFrame_BossLoot_Filter:GetText();
    MRT_Debug("MRT_GUI_BossLootFilter: strText = " ..strText);
    if lootFilterHack > 0 then
        MRT_GUI_BossLootTableUpdate(nil, false, strText);
    else
        lootFilterHack = lootFilterHack + 1;
    end
end


function MRT_GUI_RaidAttendeeResetFilter()
    MRT_GUIFrame_RaidAttendees_Filter:ClearFocus();
end

-- update raid attendees table
function MRT_GUI_RaidAttendeesTableUpdate(raidnum,filter)
  --  MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate Called!");
    local MRT_GUI_RaidAttendeesTableData = {};
    local indexofsub
    if (raidnum) then
        MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate: raidnum == true");
        local index = 1;
        for k, v in pairs(MRT_RaidLog[raidnum]["Players"]) do
            --always show PR
            --if (v["Leave"]) then
         --   MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate: v[Name]: ".. v["Name"]);
           --[[  if v["PR"] == "" then
                MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate: v[PR] == empty");
                --v["PR"] = getPlayerPR(v["Name"]);
                v["PR"] = getModifiedPR(raidnum, v["Name"]);
            else
                if not v["PR"] then
                    --v["PR"] = getPlayerPR(v["Name"]);
                    v["PR"] = getModifiedPR(raidnum, v["Name"]);
                end 
            end ]]
            --always get modified.

            classColor = "ff9d9d9d";

            -- add check here for filter
            if (not filter) or filter == "" then
                v["PR"] = getModifiedPR(raidnum, v["Name"]);
                v["Class"] = getPlayerClass(v["Name"]);
                
                classColor = getClassColor(v["Class"]);         

           --     MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate: v[PR]: ".. v["PR"]);
                MRT_GUI_RaidAttendeesTableData[index] = {k, "|c"..classColor..v["Name"], v["PR"], date("%H:%M", v["Join"]), v["Class"]};
                index = index + 1;
            else 
                local strFilter, classname = parseFilter(filter);
                MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate: strFilter =  ".. strFilter);
                if classname then
                    indexofsub = substr(v["Class"], strFilter);
                    if not indexofsub then
                        --skip
                    else 
                        v["PR"] = getModifiedPR(raidnum, v["Name"]);
                        v["Class"] = getPlayerClass(v["Name"]);
                        
                        classColor = getClassColor(v["Class"]); 

                --        MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate: v[PR]: ".. v["PR"]);
                        MRT_GUI_RaidAttendeesTableData[index] = {k, "|c"..classColor..v["Name"], v["PR"], date("%H:%M", v["Join"]), v["Class"]};
                        index = index + 1;
                    end
                else
                    indexofsub = substr(v["Name"], strFilter);
                    if not indexofsub then
                        --skip
                    else 
                        v["PR"] = getModifiedPR(raidnum, v["Name"]);
                        v["Class"] = getPlayerClass(v["Name"]);
                        
                        classColor = getClassColor(v["Class"]); 

                --        MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate: v[PR]: ".. v["PR"]);
                        MRT_GUI_RaidAttendeesTableData[index] = {k, "|c"..classColor..v["Name"], v["PR"], date("%H:%M", v["Join"]), v["Class"]};
                        index = index + 1;
                    end
                end
            end
        end
    else
        MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate: raidnum == false");
    end
    --table.sort(MRT_GUI_RaidAttendeesTableData, function(a, b) return (a[5] > b[5]); end);
    --table.sort(MRT_GUI_RaidAttendeesTableData, function(a, b) return (a[5] > b[5]); end);
    MRT_Debug("MRT_GUI_RaidAttendeesTableUpdate:about to call sort");
    table.sort(MRT_GUI_RaidAttendeesTableData, sortbyclassthenPR);
    MRT_GUI_RaidAttendeesTable:ClearSelection();
    MRT_GUI_RaidAttendeesTable:SetData(MRT_GUI_RaidAttendeesTableData, true);
    MRT_GUI_RaidAttendeesTable:SortData(MRT_GUIFrame_RaidAttendee_GroupByCB:GetChecked());
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

-- update bossloot table
function MRT_GUI_BossLootTableUpdate(bossnum, skipsort, filter)
    if skipsort then 
        MRT_Debug("MRT_GUI_BossLootTableUpdate: skipsort==True");
    else
        MRT_Debug("MRT_GUI_BossLootTableUpdate: skipsort:Nil ");
    end
    local MRT_GUI_BossLootTableData = {};
    local raidnum;
    local indexofsub1;
    local indexofsub2;
    -- check if a raid is selected
    if (MRT_GUI_RaidLogTable:GetSelection()) then
        raidnum = MRT_GUI_RaidLogTable:GetCell(MRT_GUI_RaidLogTableSelection, 1);
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

                if v["Looter"] == "unassigned" then
                    MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", "|cffff0000"..v["Looter"].."|r", v["DKPValue"], v["ItemLink"], lootTime, v["Offspec"]};
                    if v["Offspec"] then
                    --    MRT_Debug("MRT_GUI_BossLootTableUpdate: MRT_GUI_BossTableData2;dkpvalue: ".. v["DKPValue"].. "Offspec: True");
                    else
                    --    MRT_Debug("MRT_GUI_BossLootTableUpdate: MRT_GUI_BossTableData2;dkpvalue: ".. v["DKPValue"].. "Offspec: False");
                    end
                else
                    classColor = "ff9d9d9d";
                    local class = getPlayerClass(v["Looter"]);   
                    classColor = getClassColor(class);      
                    MRT_Debug(classColor);

                    MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", "|c"..classColor..v["Looter"], v["DKPValue"], v["ItemLink"], lootTime, v["Offspec"]};
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
        MRT_Debug("MRT_GUI_BossLootTableUpdate: elseif raidnum condition");
        local index = 1;

        for i, v in ipairs(MRT_RaidLog[raidnum]["Loot"]) do
            --MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", v["Looter"], v["DKPValue"], v["ItemLink"], v["Note"]};
            -- SF: if unassigned, make it red.
            
            --Set Class Color
            classColor = "ff9d9d9d";
            local playerClass = getPlayerClass(v["Looter"]);   
            classColor = getClassColor(playerClass);      

            --GetDate 
            loottime = calculateLootTimeLeft(v["Time"])

            if not filter then
                if v["Looter"] == "unassigned" then
                    MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", "|cffff0000"..v["Looter"].."|r", v["DKPValue"], v["ItemLink"], lootTime, v["Offspec"]};
                else 
                    MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", "|c"..classColor..v["Looter"], v["DKPValue"], v["ItemLink"], lootTime, v["Offspec"]};
                end 
                index = index + 1;
            else 
                indexofsub1 = substr(v["ItemName"], filter);
                indexofsub2 = substr(v["Looter"], filter);
                if not indexofsub1 and not indexofsub2 then
                    --skip
                else
                    ---
                    if v["Looter"] == "unassigned" then
                        MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", "|cffff0000"..v["Looter"].."|r", v["DKPValue"], v["ItemLink"], lootTime, v["Offspec"]};
                    else 
                        MRT_GUI_BossLootTableData[index] = {i, v["ItemId"], "|c"..v["ItemColor"]..v["ItemName"].."|r", "|c"..classColor..v["Looter"], v["DKPValue"], v["ItemLink"], lootTime, v["Offspec"]};
                    end 
                    index = index + 1;
                end
            end
        end
    --    MRT_GUIFrame_BossLootTitle:SetText(MRT_L.GUI["Tables_RaidLootTitle"]);
    -- if either raidnum nor bossnum, show an empty table
    else
    --    MRT_GUIFrame_BossLootTitle:SetText(MRT_L.GUI["Tables_RaidLootTitle"]);
    end
    table.sort(MRT_GUI_BossLootTableData, function(a, b) return (a[3] < b[3]); end);
    --MRT_GUI_BossLootTable:ClearSelection();
    if skipsort then 
        MRT_Debug("MRT_GUI_BossLootTableUpdate: skipsort==True about to call SetData");
    else
        MRT_Debug("MRT_GUI_BossLootTableUpdate: skipsort:Nil about to call SetData");
    end
    MRT_GUI_BossLootTable:SetData(MRT_GUI_BossLootTableData, true, skipsort);
    lastSelectedBossNum = bossnum;
end

function calculateLootTimeLeft (timeLooted)

    lootTimeStamp = timeLooted;
    local nowTimeStamp = MRT_GetCurrentTime();
    -- MRT_Debug(date("%m/%d/%y %H:%M:%S", nowTimeStamp));
    -- MRT_Debug(date("%m/%d/%y %H:%M:%S", lootTimeStamp));
    local deltaTime = 7200 - difftime(nowTimeStamp, lootTimeStamp);
    MRT_Debug(deltaTime)

    if deltaTime > 0 then
        local hours = math.floor(deltaTime /3600);
        local minutes = math.floor( (deltaTime - (hours*3600) )/60);
        -- MRT_Debug(hours);
        -- MRT_Debug(minutes);
        if hours > 0 then
            lootTime = hours.."h "..minutes.."m";
        else
            lootTime = minutes.."m";
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

