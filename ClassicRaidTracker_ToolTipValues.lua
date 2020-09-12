-- Adds the EPGP value to item tooltips

local LibSFGP = LibStub("LibSFGearPoints-1.0");
local ItemText, ItemCount

local function OnItem(tooltip)
    local name, link = tooltip:GetItem()
    --MRT_Debug("tooltip shown")

    local gp1 = LibSFGP:GetValue(link);
    if gp1 then
        icon = GetItemIcon(4632) 
        iconTexture = CreateTextureMarkup( icon, 128,128,12,12,0,1,0,1,0,0)
        tooltip:AddDoubleLine(iconTexture.."  |cffC0C0C0".."Stormforged EPGP Cost: ".."|cffff5ccd"..gp1)
    end

	if name ~= '' then -- Blizzard broke tooltip:GetItem() in 6.2
	--	AddOwners(tooltip, link)
	end
end

local function OnTradeSkill(tooltip, recipe, reagent)
 --   AddOwners(tooltip, reagent and C_TradeSkillUI.GetRecipeReagentItemLink(recipe, reagent) or C_TradeSkillUI.GetRecipeItemLink(recipe))
end

local function OnQuest(tooltip, type, quest)
--	AddOwners(tooltip, GetQuestItemLink(type, quest))
end

local function OnClear(tooltip)
--	tooltip.__tamedCounts = false
end

local function HookTip(tooltip)
	tooltip:HookScript('OnTooltipCleared', OnClear)
	tooltip:HookScript('OnTooltipSetItem', OnItem)

	hooksecurefunc(tooltip, 'SetQuestItem', OnQuest)
	hooksecurefunc(tooltip, 'SetQuestLogItem', OnQuest)

	if C_TradeSkillUI then
		hooksecurefunc(tooltip, 'SetRecipeReagentItem', OnTradeSkill)
		hooksecurefunc(tooltip, 'SetRecipeResultItem', OnTradeSkill)
	end
end

--[[ Startup ]]--
function HookToolTips()
    MRT_Debug("Tooltip code initialized")
	HookTip(GameTooltip)
	HookTip(ItemRefTooltip)
end