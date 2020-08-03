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

local MAJOR_VERSION = "LibSFGearPoints-1.0"
local MINOR_VERSION = 10000

local lib, oldMinor = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end


-- **@Item Cost section
-- **Warning, this area will be generated.  Modifications will be lost!!!
local SF_ITEM_DATA = {
-- SF: Need to figure out the format  
  ["Forest Spider Webbing"] = 3000,
  ["Malachite"] = 200,
  ["Tigerseye"] = 400,
  ["Linen Cloth"] = 99999,
  ["Stringy Wolf Meat"] = 9000,
  ["Arcanist Boots"]= 500,
  ["Cenarion Boots"]= 500,
  ["Choker of Enlightenment"] = 500,
  ["Felheart Gloves"] = 500,
  ["Gauntlets of Might"] = 500,
  ["Lawbringer Boots"] = 500,
  ["Arcanist Leggings"] = 625,
  ["Cenarion Leggings"] = 625,
  ["Earthshaker"] = 250,
  ["Eskhandar's Right Claw"] = 1000,
  ["Felheart Pants"] = 625,
  ["Giantstalker's Leggings"] = 625,
  ["Lawbringer Legplates"] = 625,
  ["Legplates of Might"] = 625,
  ["Medallion of Steadfast Might"] = 500,
  ["Nightslayer Pants"] = 625,
  ["Pants of Prophecy"] = 625,
  ["Striker's Mark"] = 4000,
  ["Crimson Shocker"] = 125,
  ["Flamewaker Legplates"] = 313,
  ["Heavy Dark Iron Ring"] = 1000,
  ["Helm of the Lifegiver"] = 625,
  ["Mana Igniting Cord"] = 2000,
  ["Manastorm Leggings"] = 156,
  ["Ring of Spell Power"] = 1000,
  ["Robe of Volatile Power"] = 2500,
  ["Salamander Scale Pants"] = 1250,
  ["Sorcerous Dagger"] = 250,
  ["Talisman of Ephemeral Power"] = 3000,
  ["Wristguards of Stability"] = 1000,
  ["Aged Core Leather Gloves"] = 1500,
  ["Fire Runed Grimoire"] = 250,
  ["Flameguard Gauntlets"] = 500,
  ["Magma Tempered Boots"] = 500,
  ["Obsidian Edged Blade"] = 1000,
  ["Quick Strike Ring"] = 3000,
  ["Sabatons of the Flamewalker"] = 250,
  ["Bindings of the Windseeker"] = 20000,
  ["Giantstalker's Boots"] = 500,
  ["Gloves of Prophecy"] = 500,
  ["Lawbringer Gauntlets"] = 500,
  ["Nightslayer Gloves"] = 500,
  ["Sabatons of Might"] = 500,
  ["Arcanist Crown"] = 625,
  ["Aurastone Hammer"] = 1000,
  ["Brutality Blade"] = 4000,
  ["Cenarion Helm"] = 625,
  ["Circlet of Prophecy"] = 625,
  ["Drillborer Disk"] = 2250,
  ["Felheart Horns"] = 625,
  ["Giantstalker's Helmet"] = 625,
  ["Gutgore Ripper"] = 1500,
  ["Helm of Might"] = 625,
  ["Lawbringer Helm"] = 625,
  ["Nightslayer Cover"] = 625,
  ["Arcanist Mantle"] = 500,
  ["Cenarion Spaulders"] = 500,
  ["Felheart Shoulder Pads"] = 500,
  ["Lawbringer Spaulders"] = 500,
  ["Seal of the Archmagus"] = 125,
  ["Arcanist Gloves"] = 500,
  ["Boots of Prophecy"] = 500,
  ["Cenarion Gloves"] = 500,
  ["Felheart Slippers"] = 500,
  ["Giantstalker's Gloves"] = 500,
  ["Nightslayer Boots"] = 500,
  ["Giantstalker's Epaulets"] = 500,
  ["Mantle of Prophecy"] = 500,
  ["Nightslayer Shoulder Pads"] = 500,
  ["Pauldrons of Might"] = 500,
  ["Shadowstrike"] = 10000,
  ["Arcanist Robes"] = 625,
  ["Azuresong Mageblade"] = 2000,
  ["Blastershot Launcher"] = 2000,
  ["Silithid Carapace Chestguard"] = 391,
  ["Cenarion Vestments"] = 625,
  ["Felheart Robes"] = 625,
  ["Breastplate of Might"] = 625,
  ["Lawbringer Chestguard"] = 625,
  ["Giantstalker's Breastplate"] = 625,
  ["Robes of Prophecy"] = 625,
  ["Staff of Dominance"] = 1000,
  ["Ancient Petrified Leaf"] = 500,
  ["Cauterizing Band"] = 3000,
  ["Core Forged Greaves"] = 125,
  ["Core Hound Tooth"] = 3000,
  ["Finkle's Lava Dredger"] = 250,
  ["Fireguard Shoulders"] = 125,
  ["Fireproof Cloak"] = 125,
  ["Gloves of the Hypnotic Flame"] = 500,
  ["Sash of Whispered Secrets"] = 500,
  ["The Eye of Divinity"] = 500,
  ["Wild Growth Spaulders"] = 2000,
  ["Wristguards of True Flight"] = 1000,
  ["Band of Accuria"] = 3000,
  ["Band of Sulfuras"] = 500,
  ["Bloodfang Pants"] = 1875,
  ["Bonereaver's Edge"] = 4000,
  ["Choker of the Fire Lord"] = 2000,
  ["Cloak of the Shrouded Mists"] = 2000,
  ["Crown of Destruction"] = 625,
  ["Dragon's Blood Cape"] = 500,
  ["Dragonstalker's Legguards"] = 1875,
  ["Essence of the Pure Flame"] = 375,
  ["Eye of Sulfuras"] = 5000,
  ["Judgement Legplates"] = 1875,
  ["Leggings of Transcendence"] = 1875,
  ["Legplates of Wrath"] = 1875,
  ["Malistar's Defender"] = 750,
  ["Nemesis Leggings"] = 1875,
  ["Netherwind Pants"] = 1875,
  ["Onslaught Girdle"] = 4000,
  ["Perdition's Blade"] = 6000,
  ["Shard of the Flame"] = 188,
  ["Spinal Reaper"] = 1000,
  ["Stormrage Legguards"] = 1875,
  ["Arcanist Belt"] = 500,
  ["Belt of Might"] = 500,
  ["Cenarion Belt"] = 500,
  ["Felheart Belt"] = 500,
  ["Giantstalker's Belt"] = 500,
  ["Girdle of Prophecy"] = 500,
  ["Lawbringer Belt"] = 500,
  ["Nightslayer Belt"] = 500,
  ["Arcanist Bindings"] = 500,
  ["Felheart Bracers"] = 500,
  ["Nightslayer Bracelets"] = 500,
  ["Cenarion Bracers"] = 500,
  ["Giantstalker's Bracers"] = 500,
  ["Lawbringer Bracers"] = 500,
  ["Bracers of Might"] = 500,
  ["Vambraces of Prophecy"] = 500,
  ["Arcane Infused Gem"] = 375,
  ["Bindings of Transcendence"] = 1000,
  ["Bloodfang Bracers"] = 1000,
  ["Bracelets of Wrath"] = 1000,
  ["Dragonstalker's Bracers"] = 1000,
  ["Gloves of Rapid Evolution"] = 250,
  ["Judgement Bindings"] = 1000,
  ["Mantle of the Blackwing Cabal"] = 3000,
  ["Nemesis Bracers"] = 1000,
  ["Netherwind Bindings"] = 1000,
  ["Spineshatter"] = 2000,
  ["Stormrage Bracers"] = 1000,
  ["The Black Book"] = 375,
  ["The Untamed Blade"] = 4000,
  ["Belt of Transcendence"] = 1000,
  ["Bloodfang Belt"] = 1000,
  ["Dragonfang Blade"] = 5000,
  ["Dragonstalker's Belt"] = 1000,
  ["Helm of Endless Rage"] = 2500,
  ["Judgement Belt"] = 1000,
  ["Mind Quickening Gem"] = 3000,
  ["Nemesis Belt"] = 1000,
  ["Netherwind Belt"] = 1000,
  ["Pendant of the Fallen Dragon"] = 500,
  ["Red Dragonscale Protector"] = 3000,
  ["Rune of Metamorphosis"] = 375,
  ["Stormrage Belt"] = 1000,
  ["Waistband of Wrath"] = 1000,
  ["Black Brood Pauldrons"] = 250,
  ["Bloodfang Boots"] = 1000,
  ["Boots of Transcendence"] = 1000,
  ["Bracers of Arcane Accuracy"] = 2000,
  ["Dragonstalker's Greaves"] = 1000,
  ["Heartstriker"] = 1500,
  ["Judgement Sabatons"] = 1000,
  ["Lifegiving Gem"] = 3000,
  ["Maladath, Runed Blade of the Black Flight"] = 8000,
  ["Nemesis Boots"] = 1000,
  ["Netherwind Boots"] = 1000,
  ["Sabatons of Wrath"] = 1000,
  ["Stormrage Boots"] = 1000,
  ["Venomous Totem"] = 375,
  ["Aegis of Preservation"] = 375,
  ["Band of Forced Concentration"] = 2000,
  ["Dragonbreath Hand Cannon"] = 1500,
  ["Drake Fang Talisman"] = 9000,
  ["Ebony Flame Gloves"] = 2000,
  ["Nightslayer Chestpiece"] = 625,
  ["Black Ash Robe"] = 313,
  ["Claw of the Black Drake"] = 2000,
  ["Cloak of Firemaw"] = 1500,
  ["Firemaw's Clutch"] = 1000,
  ["Legguards of the Fallen Crusader"] = 3750,
  ["Scrolls of Blinding Light"] = 375,
  ["Circle of Applied Force"] = 3000,
  ["Dragon's Touch"] = 250,
  ["Emberweave Leggings"] = 313,
  ["Herald of Woe"] = 500,
  ["Shroud of Pure Thought"] = 1000,
  ["Styleen's Impeding Scarab"] = 4500,
  ["Bloodfang Gloves"] = 1000,
  ["Dragonstalker's Gauntlets"] = 1000,
  ["Drake Talon Cleaver"] = 1000,
  ["Drake Talon Pauldrons"] = 2000,
  ["Gauntlets of Wrath"] = 1000,
  ["Handguards of Transcendence"] = 1000,
  ["Judgement Gauntlets"] = 1000,
  ["Nemesis Gloves"] = 1000,
  ["Netherwind Gloves"] = 1000,
  ["Rejuvenating Gem"] = 9000,
  ["Ring of Blackrock"] = 500,
  ["Shadow Wing Focus Staff"] = 1000,
  ["Stormrage Handguards"] = 1000,
  ["Taut Dragonhide Belt"] = 2000,
  ["Angelista's Grasp"] = 1000,
  ["Ashjre'thul, Crossbow of Smiting"] = 8000,
  ["Bloodfang Spaulders"] = 1000,
  ["Chromatic Boots"] = 4000,
  ["Chromatically Tempered Sword"] = 8000,
  ["Claw of Chromaggus"] = 4000,
  ["Dragonstalker's Spaulders"] = 1000,
  ["Elementium Reinforced Bulwark"] = 6000,
  ["Elementium Threaded Cloak"] = 1500,
  ["Empowered Leggings"] = 5000,
  ["Girdle of the Fallen Crusader"] = 250,
  ["Judgement Spaulders"] = 1000,
  ["Nemesis Spaulders"] = 1000,
  ["Netherwind Mantle"] = 1000,
  ["Pauldrons of Transcendence"] = 1000,
  ["Pauldrons of Wrath"] = 1000,
  ["Shimmering Geta"] = 250,
  ["Stormrage Pauldrons"] = 1000,
  ["Taut Dragonhide Gloves"] = 250,
  ["Taut Dragonhide Shoulderpads"] = 2000,
  ["Archimtiros' Ring of Reckoning"] = 1500,
  ["Ashkandi, Greatsword of the Brotherhood"] = 4000,
  ["Interlaced Shadow Jerkin"] = 625,
  ["Boots of the Shadow Flame"] = 4000,
  ["Malfurion's Blessed Bulwark"] = 2500,
  ["Cloak of the Brood Lord"] = 2000,
  ["Crul'shorukh, Edge of Chaos"] = 8000,
  ["Bloodfang Chestpiece"] = 2500,
  ["Head of Nefarian"] = 1875,
  ["Judgement Breastplate"] = 2500,
  ["Lok'amir il Romathis"] = 8000,
  ["Mish'undare, Circlet of the Mind Flayer"] = 5000,
  ["Neltharion's Tear"] = 9000,
  ["Nemesis Robes"] = 2500,
  ["Netherwind Robes"] = 2500,
  ["Prestor's Talisman of Connivery"] = 4000,
  ["Pure Elementium Band"] = 4000,
  ["Robes of Transcendence"] = 2500,
  ["Staff of the Shadow Flame"] = 8000,
  ["Stormrage Chestguard"] = 2500,
  ["Therazane's Link"] = 250,
  ["Band of Dark Dominion"] = 1000,
  ["Boots of Pure Thought"] = 4000,
  ["Cloak of Draconic Might"] = 3000,
  ["Doom's Edge"] = 4000,
  ["Draconic Avenger"] = 500,
  ["Draconic Maul"] = 2000,
  ["Essence Gatherer"] = 2000,
  ["Breastplate of Wrath"] = 2500,
  ["Ringo's Blizzard Boots"] = 2000,
  ["Badge of the Swarmguard"] = 7500,
  ["Creeping Vine Helm"] = 3125,
  ["Gauntlets of Steadfast Determination"] = 1250,
  ["Gloves of Enforcement"] = 3750,
  ["Leggings of the Festering Swarm"] = 3125,
  ["Legplates of Blazing Light"] = 6250,
  ["Necklace of Purity"] = 313,
  ["Recomposed Boots"] = 313,
  ["Robes of the Battleguard"] = 781,
  ["Sartura's Might"] = 1875,
  ["Scaled Leggings of Qiraji Fury"] = 1563,
  ["Silithid Claw"] = 4688,
  ["Thick Qirajihide Belt"] = 2500,
  ["Belt of Never-ending Agony"] = 5000,
  ["Cloak of Clarity"] = 3125,
  ["Cloak of the Devoured"] = 3125,
  ["Dark Edge of Insanity"] = 5000,
  ["Dark Storm Gauntlets"] = 5625,
  ["Death's Sting"] = 10000,
  ["Eye of C'Thun"] = 5000,
  ["Eyestalk Waist Cord"] = 5625,
  ["Gauntlets of Annihilation"] = 4375,
  ["Grasp of the Old God"] = 5000,
  ["Mark of C'Thun"] = 1875,
  ["Ring of the Godslayer"] = 2500,
  ["Scepter of the False Prophet"] = 12500,
  ["Vanquished Tentacle of C'Thun"] = 938,
  ["Boots of Epiphany"] = 1250,
  ["Qiraji Execution Bracers"] = 3750,
  ["Ring of Emperor Vek'lor"] = 3750,
  ["Royal Qiraji Belt"] = 1250,
  ["Royal Scepter of Vek'lor"] = 3750,
  ["Vek'lor's Gloves of Devastation"] = 625,
  ["Amulet of Vek'nilash"] = 5000,
  ["Belt of the Fallen Emperor"] = 1250,
  ["Bracelets of Royal Redemption"] = 3750,
  ["Gloves of the Hidden Temple"] = 2500,
  ["Grasp of the Fallen Emperor"] = 313,
  ["Kalimdor's Revenge"] = 2500,
  ["Regenerating Belt of Vek'nilash"] = 1250,
  ["Ancient Qiraji Ripper"] = 10000,
  ["Barb of the Sand Reaver"] = 2500,
  ["Barbed Choker"] = 3125,
  ["Cloak of Untold Secrets"] = 313,
  ["Fetish of the Sand Reaver"] = 1875,
  ["Hive Tunneler's Boots"] = 1250,
  ["Libram of Grace"] = 1250,
  ["Mantle of Wicked Revenge"] = 2500,
  ["Pauldrons of the Unrelenting"] = 625,
  ["Robes of the Guardian Saint"] = 1563,
  ["Scaled Sand Reaver Leggings"] = 4688,
  ["Dragonstalker's Breastplate"] = 2500,
  ["Petrified Scarab"] = 469,
  ["Ring of the Devoured"] = 1250,
  ["Carapace of the Old God "] = 4688,
  ["Wand of Qiraji Nobility"] = 2500,
  ["Burrower Bracers"] = 3750,
  ["Don Rigoberto's Lost Hat"] = 6250,
  ["Jom Gabbar"] = 7500,
  ["Larvae of the Great Worm"] = 5000,
  ["The Burrower's Shell"] = 938,
  ["Wormscale Blocker"] = 1875,
  ["Cloak of the Golden Hive"] = 1250,
  ["Gloves of the Messiah"] = 1250,
  ["Hive Defiler Wristguards"] = 3750,
  ["Huhuran's Stinger"] = 2500,
  ["Ring of the Martyr"] = 5000,
  ["Wasphide Gauntlets"] = 1250,
  ["Bile-Covered Gauntlets"] = 313,
  ["Mantle of Phrenic Power"] = 2500,
  ["Mantle of the Desert Crusade"] = 1250,
  ["Mantle of the Desert's Fury"] = 1250,
  ["Ukko's Ring of Darkness"] = 313,
  ["Anubisath Warhammer"] = 7500,
  ["Garb of Royal Ascension"] = 391,
  ["Neretzek, The Blood Drinker"] = 2500,
  ["Ritssyn's Ring of Chaos"] = 2500,
  ["Shard of the Fallen Star"] = 938,
  ["Amulet of Foul Warding"] = 313,
  ["Barrage Shoulders"] = 313,
  ["Beetle Scaled Wristguards"] = 313,
  ["Boots of the Fallen Prophet"] = 1250,
  ["Boots of the Redeemed Prophecy"] = 1250,
  ["Boots of the Unwavering Will"] = 1250,
  ["Husk of the Old God"] = 4688,
  ["Cloak of Concentrated Hatred"] = 3750,
  ["Hammer of Ji'zhi"] = 625,
  ["Leggings of Immersion"] = 1563,
  ["Pendant of the Qiraji Guardian"] = 1250,
  ["Ring of Swarming Thought"] = 625,
  ["Staff of the Qiraji Prophets"] = 625,
  ["Angelista's Touch"] = 1250,
  ["Cape of the Trinity"] = 1250,
  ["Guise of the Devourer"] = 4688,
  ["Robes of the Triumvirate"] = 391,
  ["Ternary Mantle"] = 1250,
  ["Triad Girdle"] = 2500,
  ["Angelista's Charm"] = 2500,
  ["Boots of the Fallen Hero"] = 3750,
  ["Gloves of Ebru"] = 1250,
  ["Ooze-ridden Gauntlets"] = 313,
  ["Gauntlets of Kalimdor"] = 1250,
  ["Gauntlets of the Righteous Champion"] = 1250,
  ["Idol of Health"] = 1250,
  ["Ring of the Qiraji Fury"] = 3750,
  ["Scarab Brooch"] = 1875,
  ["Sharpened Silithid Femur"] = 6250,
  ["Slime-coated Leggings"] = 391,
  ["Qiraji Bindings of Command"] = 2500,
  ["Qiraji Bindings of Dominance"] = 2500,
  ["Vek'lor's Diadem"] = 3125,
  ["Vek'nilash's Circlet"] = 3125,
  ["Ouro's Intact Hide"] = 4688,
  ["Skin of the Great Sandworm"] = 3125,
  ["Vest of Swift Execution"] = 4688,
  ["Breastplate of Annihilation"] = 4688,
  ["Imperial Qiraji Armaments"] = 8750,
  ["Imperial Qiraji Regalia"] = 8750,
  ["Husk of the Old God"] = 3125,
  ["Carapace of the Old God"] = 3125,
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

-- Main Function to get GP
function lib:GetValue(item)
  if not item then return end

  local itemName, itemLink, rarity, level, _, _, _, _, equipLoc = GetItemInfo(item)

  MRT_Debug("GetValue called itemName: "..itemName.."rarity:"..rarity.."level: "..level); 
  if not itemLink then return end

  -- Get the item ID to check against known token IDs
  local itemID = itemLink:match("item:(%d+)")
  if not itemID then return end
  itemID = tonumber(itemID)
  local low = nil;
  
  -- Is the item above our minimum threshold?
  if not rarity or rarity < quality_threshold then
      
      --SF this is mostly for testing purposes
      MRT_Debug("GetValue: rarity too low"); 
      low = SF_ITEM_DATA[itemName];
      return low, level, rarity, equipLoc
  end
-- SF: not sure what this does.. keeping it for now.
  UpdateRecentLoot(itemLink)

  -- SF: Not really sure why this is needed.  keeping in just in case.
  if level < 463 then
    MRT_Debug("GetValue: level < 463, is this needed?");
    low = SF_ITEM_DATA[itemName];     
    return low, level, rarity, equipLoc
  end
  --SF: Get the GP For the item
  MRT_Debug("GetValue: Getting GP"); 
  low = SF_ITEM_DATA[itemName];
  return low, level, rarity, equipLoc
end
