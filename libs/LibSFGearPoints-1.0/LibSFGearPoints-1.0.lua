-- A library to compute Gear Points for items as described in
-- https://www.stormforged.org/index.php/Points/Epgp-rules.html?

--[[
Copyright (c) 2020, SF
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
	* Neither the name of Stormforged nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]

-- History
-- 7/31/2020 Created

local MAJOR_VERSION = "LibSFGearPoints-1.0-MRT"
local MINOR_VERSION = 10000

local lib, oldMinor = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end


-- **@Item Cost section
-- **Warning, this area will be generated.  Modifications will be lost!!!
local SF_ITEM_DATA = {
-- Need to figure out the format  
}

local CUSTOM_ITEM_DATA = {
  -- Tier 4
  [29753] = { 4, 120, "INVTYPE_CHEST" },
  [29754] = { 4, 120, "INVTYPE_CHEST" },
  [29755] = { 4, 120, "INVTYPE_CHEST" },
  [29756] = { 4, 120, "INVTYPE_HAND" },
  [29757] = { 4, 120, "INVTYPE_HAND" },
  [29758] = { 4, 120, "INVTYPE_HAND" },
  [29759] = { 4, 120, "INVTYPE_HEAD" },
  [29760] = { 4, 120, "INVTYPE_HEAD" },
  [29761] = { 4, 120, "INVTYPE_HEAD" },
  [29762] = { 4, 120, "INVTYPE_SHOULDER" },
  [29763] = { 4, 120, "INVTYPE_SHOULDER" },
  [29764] = { 4, 120, "INVTYPE_SHOULDER" },
  [29765] = { 4, 120, "INVTYPE_LEGS" },
  [29766] = { 4, 120, "INVTYPE_LEGS" },
  [29767] = { 4, 120, "INVTYPE_LEGS" },

  
}

-- Used to add extra GP if the item contains bonus stats
-- generally considered chargeable.
local ITEM_BONUS_GP = {
  [40]  = 0,  -- avoidance, no material value
  [41]  = 0,  -- leech, no material value
  [42]  = 25,  -- speed, arguably useful, so 25 gp
  [43]  = 0,  -- indestructible, no material value
  [523] = 200, -- extra socket
  [563] = 200, -- extra socket
  [564] = 200, -- extra socket
  [565] = 200, -- extra socket
  [572] = 200, -- extra socket
  [1808] = 200, -- extra socket
}

-- The default quality threshold:
-- 0 - Poor
-- 1 - Uncommon
-- 2 - Common
-- 3 - Rare
-- 4 - Epic
-- 5 - Legendary
-- 6 - Artifact
local quality_threshold = 4

local recent_items_queue = {}
local recent_items_map = {}

local function UpdateRecentLoot(itemLink)
  if recent_items_map[itemLink] then return end

  -- Debug("Adding %s to recent items", itemLink)
  table.insert(recent_items_queue, 1, itemLink)
  recent_items_map[itemLink] = true
  if #recent_items_queue > 15 then
    local itemLink = table.remove(recent_items_queue)
    -- Debug("Removing %s from recent items", itemLink)
    recent_items_map[itemLink] = nil
  end
end

function lib:GetNumRecentItems()
  return #recent_items_queue
end

function lib:GetRecentItemLink(i)
  return recent_items_queue[i]
end

--- Return the currently set quality threshold.
function lib:GetQualityThreshold()
  return quality_threshold
end

--- Set the minimum quality threshold.
-- @param itemQuality Lowest allowed item quality.
function lib:SetQualityThreshold(itemQuality)
  itemQuality = itemQuality and tonumber(itemQuality)
  if not itemQuality or itemQuality > 6 or itemQuality < 0 then
    return error("Usage: SetQualityThreshold(itemQuality): 'itemQuality' - number [0,6].", 3)
  end

  quality_threshold = itemQuality
end

function lib:GetValue(item)
  if not item then return end

  local _, itemLink, rarity, level, _, _, _, _, equipLoc = GetItemInfo(item)
  if not itemLink then return end

  -- Get the item ID to check against known token IDs
  local itemID = itemLink:match("item:(%d+)")
  if not itemID then return end
  itemID = tonumber(itemID)

  -- For now, just use the actual ilvl, not the upgraded cost
  -- level = ItemUtils:GetItemIlevel(item, level)

  -- Check if item is relevant.  Item is automatically relevant if it
  -- is in CUSTOM_ITEM_DATA (as of 6.0, can no longer rely on ilvl alone
  -- for these).
  if level < 463 then
    return nil, nil, level, rarity, equipLoc
  end

  -- Check to see if there is custom data for this item ID

  -- Is the item above our minimum threshold?
  if not rarity or rarity < quality_threshold then
    return nil, nil, level, rarity, equipLoc
  end

  UpdateRecentLoot(itemLink)

  return high, low, level, rarity, equipLoc
end
