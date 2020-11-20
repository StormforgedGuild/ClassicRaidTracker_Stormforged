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
local SF_FULL_ITEM_DATA = 
--download item spreadsheet info as excel spreadsheet
--hide columns C-J (A, B, K) should be the only once you copy
--go to https://thdoan.github.io/mr-data-converter/ and paste the excel sheet into the top
--choose the lua - array table
--copy and paste below and override what is there.
--Updated 11/06/2020
{
  [1]={["Item"]="Arcanist Boots",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Mage"},
  [2]={["Item"]="Cenarion Boots",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [3]={["Item"]="Choker of Enlightenment",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Caster DPS / Healer"},
  [4]={["Item"]="Felheart Gloves",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [5]={["Item"]="Gauntlets of Might",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Warrior"},
  [6]={["Item"]="Lawbringer Boots",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [7]={["Item"]="Arcanist Leggings",["GP"]=625,["MS_Only"]=1,["Bid_Priority"]="Mage"},
  [8]={["Item"]="Cenarion Leggings",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Mage"},
  [9]={["Item"]="Earthshaker",["GP"]=250,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [10]={["Item"]="Eskhandar's Right Claw",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS "},
  [11]={["Item"]="Felheart Pants",["GP"]=625,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [12]={["Item"]="Giantstalker's Leggings",["GP"]=625,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [13]={["Item"]="Lawbringer Legplates",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [14]={["Item"]="Legplates of Might",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Warrior"},
  [15]={["Item"]="Medallion of Steadfast Might",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [16]={["Item"]="Nightslayer Pants",["GP"]=625,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [17]={["Item"]="Pants of Prophecy",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [18]={["Item"]="Striker's Mark",["GP"]=4000,["MS_Only"]=0,["Bid_Priority"]="Tank / Melee DPS "},
  [19]={["Item"]="Crimson Shocker",["GP"]=125,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [20]={["Item"]="Flamewaker Legplates",["GP"]=313,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [21]={["Item"]="Heavy Dark Iron Ring",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Feral"},
  [22]={["Item"]="Helm of the Lifegiver",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [23]={["Item"]="Mana Igniting Cord",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS / Holy Paladin"},
  [24]={["Item"]="Manastorm Leggings",["GP"]=156,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [25]={["Item"]="Ring of Spell Power",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [26]={["Item"]="Robe of Volatile Power",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Caster DPS / Holy Paladin"},
  [27]={["Item"]="Salamander Scale Pants",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [28]={["Item"]="Sorcerous Dagger",["GP"]=250,["MS_Only"]=0,["Bid_Priority"]="Healer / Caster DPS"},
  [29]={["Item"]="Talisman of Ephemeral Power",["GP"]=3000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [30]={["Item"]="Wristguards of Stability",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [31]={["Item"]="Aged Core Leather Gloves",["GP"]=1500,["MS_Only"]=0,["Bid_Priority"]="Melee DPS "},
  [32]={["Item"]="Fire Runed Grimoire",["GP"]=250,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [33]={["Item"]="Flameguard Gauntlets",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Melee DPS "},
  [34]={["Item"]="Magma Tempered Boots",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [35]={["Item"]="Obsidian Edged Blade",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS "},
  [36]={["Item"]="Quick Strike Ring",["GP"]=3000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS "},
  [37]={["Item"]="Sabatons of the Flamewalker",["GP"]=250,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [38]={["Item"]="Bindings of the Windseeker",["GP"]=20000,["MS_Only"]=0,["Bid_Priority"]="Loot Council - SEE LC EXCEPTIONS"},
  [39]={["Item"]="Giantstalker's Boots",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [40]={["Item"]="Gloves of Prophecy",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [41]={["Item"]="Lawbringer Gauntlets",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [42]={["Item"]="Nightslayer Gloves",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [43]={["Item"]="Sabatons of Might",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Warrior"},
  [44]={["Item"]="Arcanist Crown",["GP"]=625,["MS_Only"]=1,["Bid_Priority"]="Mage"},
  [45]={["Item"]="Aurastone Hammer",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [46]={["Item"]="Brutality Blade",["GP"]=4000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS "},
  [47]={["Item"]="Cenarion Helm",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [48]={["Item"]="Circlet of Prophecy",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [49]={["Item"]="Drillborer Disk",["GP"]=2250,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [50]={["Item"]="Felheart Horns",["GP"]=625,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [51]={["Item"]="Giantstalker's Helmet",["GP"]=625,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [52]={["Item"]="Gutgore Ripper",["GP"]=1500,["MS_Only"]=0,["Bid_Priority"]="Melee DPS "},
  [53]={["Item"]="Helm of Might",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Warrior"},
  [54]={["Item"]="Lawbringer Helm",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [55]={["Item"]="Nightslayer Cover",["GP"]=625,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [56]={["Item"]="Arcanist Mantle",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Mage"},
  [57]={["Item"]="Cenarion Spaulders",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [58]={["Item"]="Felheart Shoulder Pads",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [59]={["Item"]="Lawbringer Spaulders",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [60]={["Item"]="Seal of the Archmagus",["GP"]=125,["MS_Only"]=0,["Bid_Priority"]="Healer / Caster DPS"},
  [61]={["Item"]="Arcanist Gloves",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Mage"},
  [62]={["Item"]="Boots of Prophecy",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [63]={["Item"]="Cenarion Gloves",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [64]={["Item"]="Felheart Slippers",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Paladin"},
  [65]={["Item"]="Giantstalker's Gloves",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [66]={["Item"]="Nightslayer Boots",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [67]={["Item"]="Giantstalker's Epaulets",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [68]={["Item"]="Mantle of Prophecy",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [69]={["Item"]="Nightslayer Shoulder Pads",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [70]={["Item"]="Pauldrons of Might",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Warrior"},
  [71]={["Item"]="Shadowstrike",["GP"]=10000,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [72]={["Item"]="Arcanist Robes",["GP"]=625,["MS_Only"]=1,["Bid_Priority"]="Mage"},
  [73]={["Item"]="Azuresong Mageblade",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS / Holy Paladin"},
  [74]={["Item"]="Blastershot Launcher",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Tank / Melee DPS "},
  [75]={["Item"]="Silithid Carapace Chestguard",["GP"]=391,["MS_Only"]=1,["Bid_Priority"]="Soaker"},
  [76]={["Item"]="Cenarion Vestments",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [77]={["Item"]="Felheart Robes",["GP"]=625,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [78]={["Item"]="Breastplate of Might",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Warrior"},
  [79]={["Item"]="Lawbringer Chestguard",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [80]={["Item"]="Giantstalker's Breastplate",["GP"]=625,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [81]={["Item"]="Robes of Prophecy",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [82]={["Item"]="Staff of Dominance",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [83]={["Item"]="Ancient Petrified Leaf",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Hunter"},
  [84]={["Item"]="Cauterizing Band",["GP"]=3000,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [85]={["Item"]="Core Forged Greaves",["GP"]=125,["MS_Only"]=1,["Bid_Priority"]="Any"},
  [86]={["Item"]="Core Hound Tooth",["GP"]=3000,["MS_Only"]=0,["Bid_Priority"]="Tank / Melee DPS "},
  [87]={["Item"]="Finkle's Lava Dredger",["GP"]=250,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [88]={["Item"]="Fireguard Shoulders",["GP"]=125,["MS_Only"]=1,["Bid_Priority"]="Feral"},
  [89]={["Item"]="Fireproof Cloak",["GP"]=125,["MS_Only"]=1,["Bid_Priority"]="Any"},
  [90]={["Item"]="Gloves of the Hypnotic Flame",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Mage"},
  [91]={["Item"]="Sash of Whispered Secrets",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Warlock / Shadow Priest"},
  [92]={["Item"]="The Eye of Divinity",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [93]={["Item"]="Wild Growth Spaulders",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [94]={["Item"]="Wristguards of True Flight",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [95]={["Item"]="Band of Accuria",["GP"]=3000,["MS_Only"]=0,["Bid_Priority"]="Tank / Physical DPS "},
  [96]={["Item"]="Band of Sulfuras",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [97]={["Item"]="Bloodfang Pants",["GP"]=1875,["MS_Only"]=0,["Bid_Priority"]="Rogue"},
  [98]={["Item"]="Bonereaver's Edge",["GP"]=4000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [99]={["Item"]="Choker of the Fire Lord",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [100]={["Item"]="Cloak of the Shrouded Mists",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Hunter / Rogue"},
  [101]={["Item"]="Crown of Destruction",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [102]={["Item"]="Dragon's Blood Cape",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Tank / Melee DPS "},
  [103]={["Item"]="Dragonstalker's Legguards",["GP"]=1875,["MS_Only"]=0,["Bid_Priority"]="Hunter"},
  [104]={["Item"]="Essence of the Pure Flame",["GP"]=375,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [105]={["Item"]="Eye of Sulfuras",["GP"]=5000,["MS_Only"]=0,["Bid_Priority"]="Loot Council - SEE LC EXCEPTIONS"},
  [106]={["Item"]="Judgement Legplates",["GP"]=1875,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [107]={["Item"]="Leggings of Transcendence",["GP"]=1875,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [108]={["Item"]="Legplates of Wrath",["GP"]=1875,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [109]={["Item"]="Malistar's Defender",["GP"]=750,["MS_Only"]=0,["Bid_Priority"]="Holy Paladin"},
  [110]={["Item"]="Nemesis Leggings",["GP"]=1875,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [111]={["Item"]="Netherwind Pants",["GP"]=1875,["MS_Only"]=0,["Bid_Priority"]="Mage"},
  [112]={["Item"]="Onslaught Girdle",["GP"]=4000,["MS_Only"]=0,["Bid_Priority"]="Warrior"},
  [113]={["Item"]="Perdition's Blade",["GP"]=6000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [114]={["Item"]="Shard of the Flame",["GP"]=188,["MS_Only"]=1,["Bid_Priority"]="Any"},
  [115]={["Item"]="Spinal Reaper",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [116]={["Item"]="Stormrage Legguards",["GP"]=1875,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [117]={["Item"]="Arcanist Belt",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Mage"},
  [118]={["Item"]="Belt of Might",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Warrior"},
  [119]={["Item"]="Cenarion Belt",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [120]={["Item"]="Felheart Belt",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [121]={["Item"]="Giantstalker's Belt",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [122]={["Item"]="Girdle of Prophecy",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [123]={["Item"]="Lawbringer Belt",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [124]={["Item"]="Nightslayer Belt",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [125]={["Item"]="Arcanist Bindings",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Mage"},
  [126]={["Item"]="Felheart Bracers",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [127]={["Item"]="Nightslayer Bracelets",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [128]={["Item"]="Cenarion Bracers",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [129]={["Item"]="Giantstalker's Bracers",["GP"]=500,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [130]={["Item"]="Lawbringer Bracers",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [131]={["Item"]="Bracers of Might",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Warrior"},
  [132]={["Item"]="Vambraces of Prophecy",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [133]={["Item"]="Arcane Infused Gem",["GP"]=375,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [134]={["Item"]="Bindings of Transcendence",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [135]={["Item"]="Bloodfang Bracers",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [136]={["Item"]="Bracelets of Wrath",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [137]={["Item"]="Dragonstalker's Bracers",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [138]={["Item"]="Gloves of Rapid Evolution",["GP"]=250,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [139]={["Item"]="Judgement Bindings",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [140]={["Item"]="Mantle of the Blackwing Cabal",["GP"]=3000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [141]={["Item"]="Nemesis Bracers",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [142]={["Item"]="Netherwind Bindings",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Mage"},
  [143]={["Item"]="Spineshatter",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Tank / Melee DPS "},
  [144]={["Item"]="Stormrage Bracers",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [145]={["Item"]="The Black Book",["GP"]=375,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [146]={["Item"]="The Untamed Blade",["GP"]=4000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [147]={["Item"]="Belt of Transcendence",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [148]={["Item"]="Bloodfang Belt",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [149]={["Item"]="Dragonfang Blade",["GP"]=5000,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [150]={["Item"]="Dragonstalker's Belt",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [151]={["Item"]="Helm of Endless Rage",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Melee DPS / Tanks"},
  [152]={["Item"]="Judgement Belt",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [153]={["Item"]="Mind Quickening Gem",["GP"]=3000,["MS_Only"]=1,["Bid_Priority"]="Mage"},
  [154]={["Item"]="Nemesis Belt",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [155]={["Item"]="Netherwind Belt",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Mage"},
  [156]={["Item"]="Pendant of the Fallen Dragon",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [157]={["Item"]="Red Dragonscale Protector",["GP"]=3000,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [158]={["Item"]="Rune of Metamorphosis",["GP"]=375,["MS_Only"]=1,["Bid_Priority"]="Feral"},
  [159]={["Item"]="Stormrage Belt",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [160]={["Item"]="Waistband of Wrath",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [161]={["Item"]="Black Brood Pauldrons",["GP"]=250,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [162]={["Item"]="Bloodfang Boots",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [163]={["Item"]="Boots of Transcendence",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [164]={["Item"]="Bracers of Arcane Accuracy",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [165]={["Item"]="Dragonstalker's Greaves",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [166]={["Item"]="Heartstriker",["GP"]=1500,["MS_Only"]=0,["Bid_Priority"]="Tank / Melee DPS "},
  [167]={["Item"]="Judgement Sabatons",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [168]={["Item"]="Lifegiving Gem",["GP"]=3000,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [169]={["Item"]="Maladath, Runed Blade of the Black Flight",["GP"]=8000,["MS_Only"]=0,["Bid_Priority"]="Warrior DPS (Human) / Rogue (Non-Human)"},
  [170]={["Item"]="Nemesis Boots",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [171]={["Item"]="Netherwind Boots",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Mage"},
  [172]={["Item"]="Sabatons of Wrath",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [173]={["Item"]="Stormrage Boots",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [174]={["Item"]="Venomous Totem",["GP"]=375,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [175]={["Item"]="Aegis of Preservation",["GP"]=375,["MS_Only"]=1,["Bid_Priority"]="Priest"},
  [176]={["Item"]="Band of Forced Concentration",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [177]={["Item"]="Dragonbreath Hand Cannon",["GP"]=1500,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [178]={["Item"]="Drake Fang Talisman",["GP"]=9000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [179]={["Item"]="Ebony Flame Gloves",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Warlock / Shadow Priest"},
  [180]={["Item"]="Nightslayer Chestpiece",["GP"]=625,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [181]={["Item"]="Black Ash Robe",["GP"]=313,["MS_Only"]=1,["Bid_Priority"]="Any"},
  [182]={["Item"]="Claw of the Black Drake",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [183]={["Item"]="Cloak of Firemaw",["GP"]=1500,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [184]={["Item"]="Firemaw's Clutch",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [185]={["Item"]="Legguards of the Fallen Crusader",["GP"]=3750,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [186]={["Item"]="Scrolls of Blinding Light",["GP"]=1500,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [187]={["Item"]="Circle of Applied Force",["GP"]=3000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [188]={["Item"]="Dragon's Touch",["GP"]=250,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [189]={["Item"]="Emberweave Leggings",["GP"]=313,["MS_Only"]=1,["Bid_Priority"]="Any"},
  [190]={["Item"]="Herald of Woe",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [191]={["Item"]="Shroud of Pure Thought",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [192]={["Item"]="Styleen's Impeding Scarab",["GP"]=4500,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [193]={["Item"]="Bloodfang Gloves",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [194]={["Item"]="Dragonstalker's Gauntlets",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [195]={["Item"]="Drake Talon Cleaver",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [196]={["Item"]="Drake Talon Pauldrons",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [197]={["Item"]="Gauntlets of Wrath",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [198]={["Item"]="Handguards of Transcendence",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [199]={["Item"]="Judgement Gauntlets",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [200]={["Item"]="Nemesis Gloves",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [201]={["Item"]="Netherwind Gloves",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Mage"},
  [202]={["Item"]="Rejuvenating Gem",["GP"]=9000,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [203]={["Item"]="Ring of Blackrock",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Healer / Caster DPS"},
  [204]={["Item"]="Shadow Wing Focus Staff",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [205]={["Item"]="Stormrage Handguards",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [206]={["Item"]="Taut Dragonhide Belt",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [207]={["Item"]="Angelista's Grasp",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [208]={["Item"]="Ashjre'thul, Crossbow of Smiting",["GP"]=8000,["MS_Only"]=0,["Bid_Priority"]="Hunter"},
  [209]={["Item"]="Bloodfang Spaulders",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [210]={["Item"]="Chromatic Boots",["GP"]=4000,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [211]={["Item"]="Chromatically Tempered Sword",["GP"]=8000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [212]={["Item"]="Claw of Chromaggus",["GP"]=4000,["MS_Only"]=0,["Bid_Priority"]="Healer / Caster DPS"},
  [213]={["Item"]="Dragonstalker's Spaulders",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [214]={["Item"]="Elementium Reinforced Bulwark",["GP"]=6000,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [215]={["Item"]="Elementium Threaded Cloak",["GP"]=1500,["MS_Only"]=0,["Bid_Priority"]="Feral"},
  [216]={["Item"]="Empowered Leggings",["GP"]=5000,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [217]={["Item"]="Girdle of the Fallen Crusader",["GP"]=250,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [218]={["Item"]="Judgement Spaulders",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [219]={["Item"]="Nemesis Spaulders",["GP"]=1000,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [220]={["Item"]="Netherwind Mantle",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Mage"},
  [221]={["Item"]="Pauldrons of Transcendence",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [222]={["Item"]="Pauldrons of Wrath",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [223]={["Item"]="Shimmering Geta",["GP"]=250,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [224]={["Item"]="Stormrage Pauldrons",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [225]={["Item"]="Taut Dragonhide Gloves",["GP"]=250,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [226]={["Item"]="Taut Dragonhide Shoulderpads",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [227]={["Item"]="Archimtiros' Ring of Reckoning",["GP"]=1500,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [228]={["Item"]="Ashkandi, Greatsword of the Brotherhood",["GP"]=4000,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [229]={["Item"]="Interlaced Shadow Jerkin",["GP"]=313,["MS_Only"]=1,["Bid_Priority"]="Any"},
  [230]={["Item"]="Boots of the Shadow Flame",["GP"]=4000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [231]={["Item"]="Malfurion's Blessed Bulwark",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [232]={["Item"]="Cloak of the Brood Lord",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [233]={["Item"]="Crul'shorukh, Edge of Chaos",["GP"]=8000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [234]={["Item"]="Bloodfang Chestpiece",["GP"]=2500,["MS_Only"]=1,["Bid_Priority"]="Rogue"},
  [235]={["Item"]="Head of Nefarian",["GP"]=1875,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [236]={["Item"]="Judgement Breastplate",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [237]={["Item"]="Lok'amir il Romathis",["GP"]=8000,["MS_Only"]=0,["Bid_Priority"]="Healer / Caster DPS"},
  [238]={["Item"]="Mish'undare, Circlet of the Mind Flayer",["GP"]=5000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS / Holy Paladin"},
  [239]={["Item"]="Neltharion's Tear",["GP"]=9000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [240]={["Item"]="Nemesis Robes",["GP"]=2500,["MS_Only"]=1,["Bid_Priority"]="Warlock"},
  [241]={["Item"]="Netherwind Robes",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Mage"},
  [242]={["Item"]="Prestor's Talisman of Connivery",["GP"]=4000,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [243]={["Item"]="Pure Elementium Band",["GP"]=4000,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [244]={["Item"]="Robes of Transcendence",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [245]={["Item"]="Staff of the Shadow Flame",["GP"]=8000,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [246]={["Item"]="Stormrage Chestguard",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [247]={["Item"]="Therazane's Link",["GP"]=250,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [248]={["Item"]="Band of Dark Dominion",["GP"]=1000,["MS_Only"]=0,["Bid_Priority"]="Warlock / Shadow Priest"},
  [249]={["Item"]="Boots of Pure Thought",["GP"]=4000,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [250]={["Item"]="Cloak of Draconic Might",["GP"]=3000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [251]={["Item"]="Doom's Edge",["GP"]=4000,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [252]={["Item"]="Draconic Avenger",["GP"]=500,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [253]={["Item"]="Draconic Maul",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [254]={["Item"]="Essence Gatherer",["GP"]=2000,["MS_Only"]=0,["Bid_Priority"]="Priest"},
  [255]={["Item"]="Breastplate of Wrath",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [256]={["Item"]="Ringo's Blizzard Boots",["GP"]=2000,["MS_Only"]=1,["Bid_Priority"]="Mage"},
  [257]={["Item"]="Badge of the Swarmguard",["GP"]=7500,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [258]={["Item"]="Creeping Vine Helm",["GP"]=3125,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [259]={["Item"]="Gauntlets of Steadfast Determination",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [260]={["Item"]="Gloves of Enforcement",["GP"]=3750,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [261]={["Item"]="Leggings of the Festering Swarm",["GP"]=1563,["MS_Only"]=0,["Bid_Priority"]="Mage"},
  [262]={["Item"]="Legplates of Blazing Light",["GP"]=6250,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [263]={["Item"]="Necklace of Purity",["GP"]=313,["MS_Only"]=1,["Bid_Priority"]="Soaker"},
  [264]={["Item"]="Recomposed Boots",["GP"]=313,["MS_Only"]=1,["Bid_Priority"]="Soaker"},
  [265]={["Item"]="Robes of the Battleguard",["GP"]=781,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [266]={["Item"]="Sartura's Might",["GP"]=1875,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [267]={["Item"]="Scaled Leggings of Qiraji Fury",["GP"]=1563,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [268]={["Item"]="Silithid Claw",["GP"]=4688,["MS_Only"]=0,["Bid_Priority"]="Hunter"},
  [269]={["Item"]="Thick Qirajihide Belt",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [270]={["Item"]="Belt of Never-ending Agony",["GP"]=5000,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [271]={["Item"]="Cloak of Clarity",["GP"]=3125,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [272]={["Item"]="Cloak of the Devoured",["GP"]=3125,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [273]={["Item"]="Dark Edge of Insanity",["GP"]=5000,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [274]={["Item"]="Dark Storm Gauntlets",["GP"]=5625,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [275]={["Item"]="Death's Sting",["GP"]=10000,["MS_Only"]=0,["Bid_Priority"]="Rogue > Warrior"},
  [276]={["Item"]="Eye of C'Thun",["GP"]=5000,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [277]={["Item"]="Eyestalk Waist Cord",["GP"]=5625,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [278]={["Item"]="Gauntlets of Annihilation",["GP"]=4375,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [279]={["Item"]="Grasp of the Old God",["GP"]=5000,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [280]={["Item"]="Mark of C'Thun",["GP"]=1875,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [281]={["Item"]="Ring of the Godslayer",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [282]={["Item"]="Scepter of the False Prophet",["GP"]=12500,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [283]={["Item"]="Vanquished Tentacle of C'Thun",["GP"]=469,["MS_Only"]=1,["Bid_Priority"]="Any"},
  [284]={["Item"]="Boots of Epiphany",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [285]={["Item"]="Qiraji Execution Bracers",["GP"]=3750,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [286]={["Item"]="Ring of Emperor Vek'lor",["GP"]=3750,["MS_Only"]=0,["Bid_Priority"]="Feral"},
  [287]={["Item"]="Royal Qiraji Belt",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [288]={["Item"]="Royal Scepter of Vek'lor",["GP"]=3750,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [289]={["Item"]="Vek'lor's Gloves of Devastation",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Hunter"},
  [290]={["Item"]="Amulet of Vek'nilash",["GP"]=3750,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [291]={["Item"]="Belt of the Fallen Emperor",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Paladin"},
  [292]={["Item"]="Bracelets of Royal Redemption",["GP"]=3750,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [293]={["Item"]="Gloves of the Hidden Temple",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [294]={["Item"]="Grasp of the Fallen Emperor",["GP"]=313,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [295]={["Item"]="Kalimdor's Revenge",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [296]={["Item"]="Regenerating Belt of Vek'nilash",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [297]={["Item"]="Ancient Qiraji Ripper",["GP"]=10000,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [298]={["Item"]="Barb of the Sand Reaver",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Hunter"},
  [299]={["Item"]="Barbed Choker",["GP"]=3125,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [300]={["Item"]="Cloak of Untold Secrets",["GP"]=313,["MS_Only"]=1,["Bid_Priority"]="Shadow Tank"},
  [301]={["Item"]="Fetish of the Sand Reaver",["GP"]=469,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [302]={["Item"]="Hive Tunneler's Boots",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [303]={["Item"]="Libram of Grace",["GP"]=250,["MS_Only"]=1,["Bid_Priority"]="Paladin"},
  [304]={["Item"]="Mantle of Wicked Revenge",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [305]={["Item"]="Pauldrons of the Unrelenting",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [306]={["Item"]="Robes of the Guardian Saint",["GP"]=6250,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [307]={["Item"]="Scaled Sand Reaver Leggings",["GP"]=4688,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [308]={["Item"]="Dragonstalker's Breastplate",["GP"]=2500,["MS_Only"]=1,["Bid_Priority"]="Hunter"},
  [309]={["Item"]="Petrified Scarab",["GP"]=469,["MS_Only"]=1,["Bid_Priority"]="Any"},
  [310]={["Item"]="Ring of the Devoured",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [311]={["Item"]="Gloves of the Immortal ",["GP"]=1,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [312]={["Item"]="Wand of Qiraji Nobility",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [313]={["Item"]="Burrower Bracers",["GP"]=3750,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [314]={["Item"]="Don Rigoberto's Lost Hat",["GP"]=6250,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [315]={["Item"]="Jom Gabbar",["GP"]=7500,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [316]={["Item"]="Larvae of the Great Worm",["GP"]=5000,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [317]={["Item"]="The Burrower's Shell",["GP"]=469,["MS_Only"]=1,["Bid_Priority"]="Any"},
  [318]={["Item"]="Wormscale Blocker",["GP"]=469,["MS_Only"]=0,["Bid_Priority"]="Paladin "},
  [319]={["Item"]="Cloak of the Golden Hive",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [320]={["Item"]="Gloves of the Messiah",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [321]={["Item"]="Hive Defiler Wristguards",["GP"]=3750,["MS_Only"]=0,["Bid_Priority"]="Warrior"},
  [322]={["Item"]="Huhuran's Stinger",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Melee DPS "},
  [323]={["Item"]="Ring of the Martyr",["GP"]=5000,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [324]={["Item"]="Wasphide Gauntlets",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [325]={["Item"]="Bile-Covered Gauntlets",["GP"]=313,["MS_Only"]=1,["Bid_Priority"]="Soaker"},
  [326]={["Item"]="Mantle of Phrenic Power",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Mage"},
  [327]={["Item"]="Mantle of the Desert Crusade",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Holy Paladin"},
  [328]={["Item"]="Mantle of the Desert's Fury",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Paladin "},
  [329]={["Item"]="Ukko's Ring of Darkness",["GP"]=313,["MS_Only"]=1,["Bid_Priority"]="Shadow Tank"},
  [330]={["Item"]="Anubisath Warhammer",["GP"]=7500,["MS_Only"]=0,["Bid_Priority"]="Warrior (Human) w/o Maladath"},
  [331]={["Item"]="Garb of Royal Ascension",["GP"]=391,["MS_Only"]=1,["Bid_Priority"]="Shadow Tank"},
  [332]={["Item"]="Neretzek, The Blood Drinker",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [333]={["Item"]="Ritssyn's Ring of Chaos",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [334]={["Item"]="Shard of the Fallen Star",["GP"]=469,["MS_Only"]=1,["Bid_Priority"]="Any"},
  [335]={["Item"]="Amulet of Foul Warding",["GP"]=313,["MS_Only"]=1,["Bid_Priority"]="Soaker"},
  [336]={["Item"]="Barrage Shoulders",["GP"]=313,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [337]={["Item"]="Beetle Scaled Wristguards",["GP"]=313,["MS_Only"]=1,["Bid_Priority"]="Soaker"},
  [338]={["Item"]="Boots of the Fallen Prophet",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [339]={["Item"]="Boots of the Redeemed Prophecy",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Paladin "},
  [340]={["Item"]="Boots of the Unwavering Will",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [341]={["Item"]="Cloak of Concentrated Hatred",["GP"]=3750,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [342]={["Item"]="Hammer of Ji'zhi",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [343]={["Item"]="Leggings of Immersion",["GP"]=1563,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [344]={["Item"]="Pendant of the Qiraji Guardian",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [345]={["Item"]="Ring of Swarming Thought",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [346]={["Item"]="Staff of the Qiraji Prophets",["GP"]=625,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [347]={["Item"]="Angelista's Touch",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Tank"},
  [348]={["Item"]="Cape of the Trinity",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [349]={["Item"]="Guise of the Devourer",["GP"]=4688,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [350]={["Item"]="Robes of the Triumvirate",["GP"]=391,["MS_Only"]=1,["Bid_Priority"]="Soaker"},
  [351]={["Item"]="Ternary Mantle",["GP"]=3750,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [352]={["Item"]="Triad Girdle",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [353]={["Item"]="Gloves of the Redeemed Prophecy",["GP"]=250,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [354]={["Item"]="Angelista's Charm",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [355]={["Item"]="Boots of the Fallen Hero",["GP"]=3750,["MS_Only"]=0,["Bid_Priority"]="Warrior"},
  [356]={["Item"]="Gloves of Ebru",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [357]={["Item"]="Ooze-ridden Gauntlets",["GP"]=313,["MS_Only"]=1,["Bid_Priority"]="Soaker"},
  [358]={["Item"]="Gauntlets of Kalimdor",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Paladin "},
  [359]={["Item"]="Gauntlets of the Righteous Champion",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Paladin "},
  [360]={["Item"]="Idol of Health",["GP"]=1250,["MS_Only"]=0,["Bid_Priority"]="Druid"},
  [361]={["Item"]="Ring of the Qiraji Fury",["GP"]=3750,["MS_Only"]=0,["Bid_Priority"]="Physical DPS"},
  [362]={["Item"]="Scarab Brooch",["GP"]=1875,["MS_Only"]=0,["Bid_Priority"]="Healer"},
  [363]={["Item"]="Sharpened Silithid Femur",["GP"]=7813,["MS_Only"]=0,["Bid_Priority"]="Caster DPS"},
  [364]={["Item"]="Slime-coated Leggings",["GP"]=391,["MS_Only"]=1,["Bid_Priority"]="Soaker"},
  [365]={["Item"]="Qiraji Bindings of Command",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [366]={["Item"]="Qiraji Bindings of Dominance",["GP"]=2500,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [367]={["Item"]="Vek'lor's Diadem",["GP"]=3125,["MS_Only"]=0,["Bid_Priority"]="Any "},
  [368]={["Item"]="Vek'nilash's Circlet",["GP"]=3125,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [369]={["Item"]="Ouro's Intact Hide",["GP"]=4688,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [370]={["Item"]="Skin of the Great Sandworm",["GP"]=1563,["MS_Only"]=0,["Bid_Priority"]="Any "},
  [371]={["Item"]="Vest of Swift Execution",["GP"]=4688,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [372]={["Item"]="Breastplate of Annihilation",["GP"]=4688,["MS_Only"]=0,["Bid_Priority"]="Melee DPS"},
  [373]={["Item"]="Imperial Qiraji Armaments",["GP"]=8750,["MS_Only"]=0,["Bid_Priority"]="Tank / Melee DPS"},
  [374]={["Item"]="Imperial Qiraji Regalia",["GP"]=8750,["MS_Only"]=0,["Bid_Priority"]="Healer / Caster DPS / Feral"},
  [375]={["Item"]="Husk of the Old God",["GP"]=4688,["MS_Only"]=0,["Bid_Priority"]="Any"},
  [376]={["Item"]="Carapace of the Old God",["GP"]=4688,["MS_Only"]=0,["Bid_Priority"]="Any"}
}




local SF_ITEM_DATA = {
-- SF: Need to figure out the format  
-- delete this when we're comfortable with the above import.
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
  ["Carapace of the Old God"] = 4688,
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
  ["Skin of the Great Sandworm"] = 1563,
  ["Vest of Swift Execution"] = 4688,
  ["Breastplate of Annihilation"] = 4688,
  ["Imperial Qiraji Armaments"] = 8750,
  ["Imperial Qiraji Regalia"] = 8750,
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

  --MRT_Debug("GetValue called itemName: "..itemName.."rarity:"..rarity.."level: "..level); 
  if not itemLink then return end

  -- Get the item ID to check against known token IDs
  local itemID = itemLink:match("item:(%d+)")
  if not itemID then return end
  itemID = tonumber(itemID)
  local low = nil;
  
  -- Is the item above our minimum threshold?
  if not rarity or rarity < quality_threshold then
      
      --SF this is mostly for testing purposes
      --MRT_Debug("GetValue: rarity too low"); 
      low = SF_ITEM_DATA[itemName];
      return low, level, rarity, equipLoc
  end
-- SF: not sure what this does.. keeping it for now.
  UpdateRecentLoot(itemLink)

  -- SF: Not really sure why this is needed.  keeping in just in case.
  if level < 463 then
    --MRT_Debug("GetValue: level < 463, is this needed?");
    --old code low = SF_ITEM_DATA[itemName];     
    low = getGP(itemName,true);     
    return low, level, rarity, equipLoc
  end
  --SF: Get the GP For the item
  --MRT_Debug("GetValue: Getting GP"); 
  --old code low = SF_ITEM_DATA[itemName];
  low = getGP(itemName, true);     
  return low, level, rarity, equipLoc
end

function getGP(itemName, new)
  --get old way by default
  if not new then
    --MRT_Debug("getGP: get old way"); 
    return SF_ITEM_DATA[itemName]
  else
    --MRT_Debug("getGP: get new way"); 
    --use the new way
    for i = 1, table.maxn(SF_FULL_ITEM_DATA) do
      local sitemName = SF_FULL_ITEM_DATA[i]["Item"]
      --MRT_Debug("getGP: sitemName: " ..sitemName); 
      if sitemName == itemName then
        return SF_FULL_ITEM_DATA[i]["GP"]
      end
    end
  end
  return nil
end
function lib:GetPrio(item)
  local itemName, itemLink, rarity, level, _, _, _, _, equipLoc = GetItemInfo(item)
  --MRT_Debug("LibSFGearPoitns: GetPrio"); 
  for i = 1, table.maxn(SF_FULL_ITEM_DATA) do
    local sitemName = SF_FULL_ITEM_DATA[i]["Item"]
    --MRT_Debug("getPrio: sitemName: " ..sitemName.. "itemName: " ..itemName); 
    if sitemName == itemName then
      return SF_FULL_ITEM_DATA[i]["Bid_Priority"]
    end
  end
  return "not found"
end

function lib:GetMSOnly(item)
  local itemName, itemLink, rarity, level, _, _, _, _, equipLoc = GetItemInfo(item)
  --MRT_Debug("LibSFGearPoitns: GetMSOnly"); 
  for i = 1, table.maxn(SF_FULL_ITEM_DATA) do
    local sitemName = SF_FULL_ITEM_DATA[i]["Item"]
    --MRT_Debug("GetMSOnly: sitemName: " ..sitemName.. "itemName: " ..itemName); 
    if sitemName == itemName then
      return SF_FULL_ITEM_DATA[i]["MS_Only"] == 1;
    end
  end
  return -1
end

local SF_TOKEN_DATA = {
  --Token list
  ["Vek'lor's Diadem"] = {21387, 21360, 21353, 21366},
  ["Vek'nilash's Circlet"] = {21329, 21337, 21347, 21348},
  ["Imperial Qiraji Armaments"] = {21242, 21244, 21272, 21269},
  ["Imperial Qiraji Regalia"] = {21268, 21273, 21275},
  ["Qiraji Bindings of Command"] = {21333, 21330, 21359, 21361, 21349, 21350, 21365, 21367},
  ["Qiraji Bindings of Dominance"] = {21388, 21391, 21338, 21335, 21344, 21345, 21355, 21354},
  ["Ouro's Intact Hide"] = {21332, 21362, 21346, 21352},
  ["Skin of the Great Sandworm"] = {21390, 21336, 21356, 21368},
  ["Carapace of the Old God"] = {21389, 21331, 21364, 21370},
  ["Husk of the Old God"] = {21334, 21343, 21357, 21351},
  ["Eye of C'Thun"] = {21712, 21710, 21709},
  ["Head of Nefarian"] = {19383, 19384, 19366},
}

-- this function is used to cache 
function lib:CacheTokenItemInfo()
  --MRT_Debug("CacheTokenItemInfo: called!"); 
  for i1,v in pairs(SF_TOKEN_DATA) do
    for i = 1, table.maxn(v) do
      local tItemName = SF_TOKEN_DATA[i1][i];
      --MRT_Debug("GetTokenLoot: tItemName: " ..tItemName); 
      if (tItemName) then
        local intID = tonumber(tItemName);
        local itemName1, itemLink1, rarity1, level1, _, _, _, _, equipLoc1 = GetItemInfo(intID);
        --MRT_Debug("GetTokenLoot: tItemName: " ..tItemName); 
      end 
    end
  end
end

function lib:GetTokenLoot(item)
  local itemName, itemLink, rarity, level, _, _, _, _, equipLoc = GetItemInfo(item);
  --local itemID = GetItemInfoInstant(item);
  MRT_Debug("GetTokenLoot: GetTokenLoot"); 
  MRT_Debug("GetTokenLoot: item: " ..item); 
  MRT_Debug("GetTokenLoot: itemName: " ..itemName); 
  --MRT_Debug("GetTokenLoot: itemID: " ..itemID); 
  local retVal = {};
  if (SF_TOKEN_DATA[itemName]) then
    for i = 1, table.maxn(SF_TOKEN_DATA[itemName]) do
      local tItemName = SF_TOKEN_DATA[itemName][i];
      MRT_Debug("GetTokenLoot: tItemName: " ..tItemName); 
      if (tItemName) then
        local intID = tonumber(tItemName);
        local itemName1, itemLink1, rarity1, level1, _, _, _, _, equipLoc1 = GetItemInfo(intID);
        if (itemLink1) then 
          MRT_Debug("GetTokenLoot:: GetTokenLoot: itemLink1: " ..itemLink1); 
          tinsert(retVal, 1, itemLink1);
        else
          MRT_Debug("GetTokenLoot:: GetTokenLoot: itemLink1: NIL"); 
        end 
      end 
    end
  end
  return retVal;
end
