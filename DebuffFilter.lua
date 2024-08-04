


local DebuffFilter = CreateFrame("Frame")
DebuffFilter.cache = {}

local DEFAULT_DEBUFF = 3
local DEFAULT_BIGDEBUFF = 5
local DEFAULT_BUFF = 13 --This Number Needs to Equal the Number of tracked Table Buf
local BIGGEST = 1.6
local BIGGER = 1.45
local BIG = 1.45
local BOSSDEBUFF = 1.45
local BOSSBUFF = 1.45
local WARNING = 1.2
local PRIORITY = 1
local DEBUFF = .9

local row1BUFF_SIZE = .95
local SMALL_BUFF_SIZE = .85
local BOR_BUFF_SIZE = 1
local BOL_BUFF_SIZE = 1

local strfind = string.find
local strmatch = string.match
local tblinsert = table.insert
local tblremove= table.remove
local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_rand = math.random
local mathabs = math.abs
local bit_band = bit.band
local tblsort = table.sort
local Ctimer = C_Timer.After
local substring = string.sub

local SmokeBombAuras = {}
local DuelAura = {}

local UnitAura = UnitAura
if UnitAura == nil then
  --- Deprecated in 10.2.5
  UnitAura = function(unitToken, index, filter)
		local aura = C_UnitAuras.GetAuraDataByIndex(unitToken, index, filter)
		if not aura then
			return nil;
		end

		return aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime, aura.sourceUnit, aura.isStealable, nil, aura.spellId
	end
end

local UnitBuff = UnitBuff
if UnitBuff == nil then
  --- Deprecated in 10.2.5
  UnitBuff = function(unitToken, index, filter)
		local aura = C_UnitAuras.GetAuraDataByIndex(unitToken, index, filter)
		if not aura then
			return nil;
		end

		return aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime, aura.sourceUnit, aura.isStealable, nil, aura.spellId
	end
end

local UnitDebuff = UnitDebuff
if UnitDebuff == nil then
  --- Deprecated in 10.2.5
  UnitDebuff = function(unitToken, index, filter)
		if not filter then filter = "HARMFUL"end
		local aura = C_UnitAuras.GetAuraDataByIndex(unitToken, index, filter)
		if not aura then
			return nil;
		end

		return aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime, aura.sourceUnit, aura.isStealable, nil, aura.spellId
	end
end

local PriorityBuff = {}
for i = 1, DEFAULT_BUFF do
	if not PriorityBuff[i] then PriorityBuff[i] = {} end
end

local anybackCount = {}

local playerbackCount = {
	["Prayer of Mending"] = true,
	["Focused Growth"] = true
}

PriorityBuff[1] = {
	--"Power Infusion",
	"Power Word: Shield",
	"Beacon of Light",
	"Beacon of Faith",
	774, --Rejuv
}

PriorityBuff[2] = {
	"Renew",
	155777, --Rejuc Germ
	"Spring Blossoms",
	"Glimmer of Light",
}

PriorityBuff[3] = {
	"Atonement",
	"Echo of Light",
	"Prayer of Mending",
	"Lifebloom",
	"Bestow Faith",
	216328, --LightGrace
	"Focused Growth", --Focused Growth (Honor Talent)
}


local rowOneBuffs = {}
local rowOneBuffsCount = 1
for i = 1, 3 do
	for _, v in ipairs(PriorityBuff[i]) do
		rowOneBuffs[v] = rowOneBuffsCount
		rowOneBuffsCount = rowOneBuffsCount + 1
	end
end

local row1Buffs = {}
local row1BuffsCount = 1
for i = 1, 3 do
	row1Buffs[i] = {}
	for _, v in ipairs(PriorityBuff[i]) do
		row1Buffs[i][v] = row1BuffsCount
		row1BuffsCount = row1BuffsCount + 1
	end
end

--Second Row 
PriorityBuffRow2 = {
	"Regrowth",
	"Wild Growth",
	"Adaptive Swarm",
}

local row2Buffs = {}
local row2BuffsCount = 1
for _, v in ipairs(PriorityBuffRow2) do
	row2Buffs[v] = row2BuffsCount
	row2BuffsCount = row2BuffsCount  + 1
end

Buffs = {
	"Power Word: Fortitude",
	"Arcane Intellect",
	"Arcane Brilliance",
	"Dalaran Brilliance",
	"Mark of the Wild",
	"Blessing of the Bronze",
	"Battle Shout",
}

local smallBuffs = {}
local smallBuffsCount = 1
for _, v in ipairs(Buffs) do
	smallBuffs[v] = smallBuffsCount
	smallBuffsCount = smallBuffsCount  + 1
end



--------------------------------------------------------------------------------------------------------------------------------------------------
--UPPER RIGHT PRIO COUNT (Buff Overlay Right)
--------------------------------------------------------------------------------------------------------------------------------------------------
BOR = {
		--**Stealth Given**
	198158, --Mass Invisibility
	414664, --Mass Invisibility
	"Shroud of Concealment",

	--**Class Stealth**--

	"Stealth",
	199483, --Camouflage
	5384, --Feign Death
	"Camouflage",
	5215, --Prowl
	110960, --Greater Invisibility
	"Invisibility",


	--**Secondary’s CD’s Given**--

	53480,  --Roar of Sacrifice
	212640, --Mending Bandage
	223658, --Safeguard
	213871, --Bodyguard
	207810, --Nether Bond
	291944, --Regeneration’
	59543, --Gift of the Naaru


	--**DMG/Heal CDs Given**--
	--**Threat MIsdirect Given**--

	57934, --Tricks of the Trade 221630 is DMG
	"Misdirection",

	--** Secondary’ Class Ds**--

	414661, --Frost Mass Barrier
	414662, --Fire Mass Barrier
	414663, --Arcane Mass Barrier
	19236, --Desperate Prayer
	387636, --Soulburn: Healthstone
	17767, --Shadow Bulwark
	277187, --Gladiator’s Emblem
	"Gladiator's Emblem",
	363522, --Gladiator's Eternal Aegis
	310143, --Soulshape
	--"Spirit Mend",
	388035, --Fortitude of the Bear


	--**Class Perm Passive Buffs & DMG CDs**--

	315443, --Abomination Limb
	383269, --Abomination Limb
	152279, --Breath of Sindragosa
	47568,	--Empower Rune Weapon
	51271, --Pillars of Frost
	49206, --Ebon Gargoyle
	207289, --Unholy Assault
	--356337, --Rune of Spellwarding

	162264, -- Metamorphosis (Havoc)


	319454, --Heart of the Wild
	108293, --Heart of the Wild (Guardian)
	50334,  --Berserk (Guardian)
	102558, --Incarnation: Guardian of Ursoc
	5487,   --Bear Form
	108291, --Heart of the Wild (Boomy)
	108292, --Heart of the Wild (Feral)
	108294, --Heart of the Wild (Resto)
	102560, --Incarnation: Chosen of Elune
	390414, --Incarnation: Chosen of Elune (Orbital)
	194223, --Celestial Alignment 
	383410, --Celestial Alignment (Orbital)
	102543, --Incarnation: Avatar of Ashamane
	106951, --Berserk
	117679, --Incarnation Tree of Life
	124974, --Nature's Vigel
	410406, --Wild Attunement (Frenzy from Clone)
	5217,   --Tiger Fury
	202425, --Warrior of Elune
	202770, --Fury of Elune
	202359, --Astral Communion
	102693, --Grove Guardians
	248280, --Trees CLEU
	197625, --Moonkin Form (Resto)
	24858, --Moonkin Form
	768, --Cat Form
	783, --Travel Form

	375087, --Dragonrage
	374349, --Renewing Blaze Hot
	370537, --Stasis
	404977, --Timeskip

	266779, --Coordinated Assaults
	360966, --Spearhead
	186289, --Aspect of the Eagle
	260402, -- Double Tap
	288613, -- True Shot
	359844, --Call of the Wild
	212704, --The Beast within
	19574, --Bestial Wraith
	205691, --Dire Beast Basilisk [summonid]

	382440, --Shifting Power
	383874, --Hyperthermia
	190319, --Combustion
	12042, --Arcane Power
	365362, --Arcane Surge
	389794, --Snowdrift
	--198144, --Ice Form
	12472, --Icy Veins
	382148, --Slick Ice
	342242, --Time Warp
	332928, --Siphon Storm
	321686, --Mirror Image CLEU,
	235313, --Blazing Barrier
	11426, --Ice Barrier
	235450, --Prismatic Barrier

	310454, --Weapons of Order
	152173, --Serenity
	137639, --Storm, Earth, and Fire
	123904, --WW Xuen Pet Summmon "Xuen" same Id has sourceGUID

	231895, --Crusade
	247677, --Reckoning
	
	319952, --Surrender to Madness
	194249, --Voidform
	391109, --Dark Ascension
	325013, --Boon of the Ascended
	372617, --Empyreal Blaze
	372760, --Divine Word
	372761, --Divine Favor DMG
	372791, --Divine Favor Healing
	196490, --Divine Favor AOE
	15286,  --Vampiric Embrace
	193065, --Masochism
	327710, --Benevolent Faerie CD Reduction (Night Fae Priest)
	123040, --Disc Pet Summmon Mindbender
	34433,  --Disc Pet Summmon Sfiend
	405963, --Divine Image
	47536, 	--Rapture
	197862, --ArchAngel
	322105, --Shadow Covenant
	232698, --Shadowform
	355898, --Inner Shadow
	355897, --Inner Light


	121471, --Shadow Blades
	13750,  --Adrenline Rush

	260881, --Spirit Wolf
	204262, --Spectral Recovery
	2645,   --Ghost Wolf
	335903, --Doomwinds (shadowlands legendary)
	384352, --Doomwinds 
	114050, --Ascendance
	114051, --Ascendance
	333957, --Feral Spirits (Summon or Buff)
	191634, --Stormkeeper
	320137, --Stormkeeper
	383009, --Stormkeeper (Resto)
	210714, --Ice Fury 
	375986, --Primordial Wave
	157319, --Prima Storm Ele
	157299, --Storm Ele
	118291, --Primal Fire Ele
	188592, --Fire Ele
	118323, --Primal Earth Ele
	188616, --Earth Ele

	113860, --Dark Soul: Instability
	113860, --Dark Soul: Misery
	111685, --Warlock Infernals,  has sourceGUID (spellId and Summons are different) [spellbookid]
	265187, --Demonic Tyrant has sourceGUID [summonid]
	265273, --Demonic Power
	267218, --Nether Portal
	201996, --Call Observer
	353601, --Fel Obelisk
	394243, --Choas Tear
	387979, --Unstable Tear
	394235, --Shadowy Tear
	205180, --Warlock Darkglare
	285933, --Demon Armor

	46924,  --Bladestorm
	107574, --Avatar
	1719,   --Recklessness
	197690, --Defensive Stance
	386208, --Defense Stance
	199261, --Death Wish
	329038, --Bloodrage (root break)
}

local BORBuffs = {}
local BORBuffsCount = 1
for _, v in ipairs(BOR) do
	BORBuffs[v] = BORBuffsCount 
	BORBuffsCount = BORBuffsCount  + 1
end
--------------------------------------------------------------------------------------------------------------------------------------------------
--UPPER LEFT PRIO COUNT (Buff Overlay Right)
--------------------------------------------------------------------------------------------------------------------------------------------------
BOL = {
	185710, --Sugar-Crusted Fish Feast
	"Food",
	"Drink",
	"Food & Drink",
	"Refreshment",
	
	--**Immunity Raid**-----------------------------------------------------------------------
	
	--**Healer CDs Given**--------------------------------------------------------------------
	199448, --Blessing of Sacrifice (100%)
	1022, --Blessing of Protection
	204018, --Blessing of Spellwarding
	6940, --Blessing of Sacrifice (30%)
	31821, --Aura Mastery
	33206, --Pain Suppression
	81782, --Power Word: Barrier
	47788, --Guardian Spirit
	356968, --+20% -Benevolent Faerie
	"Lightwell", --Lightwell Charges
	327694, --Benevolent Faerie 40% DMG Reduction (Night Fae Priest)
	64844,   --Divine Hymn Stacks
	64843, --Divine Hymn
	64901, --Symbols of Hope
	247563, --Nature's Grasp (Has Stacks)
	102342, --Ironbark
	157982, --Tranquility (Has Stacks)
	98007, --Spirit Link Totem
	325174, --Spirit Link Totem
	201633, --Earthen Shield
	363534, --Rewind
	357170, --Time Dilation
	370666, --Rescue
	116849, --Life Cocoon
	
	--**Class Healing CDs**---------------------------------------------------------------------
	207498, --Ancestral Protection
	209426, --Darkness
	145629, --Anti-Magic Zone
	97463, --Rallying Cry
	
	--**CC Help**-------------------------------------------------------------------------------
	213610, --Holy Ward
	359816, --Dream Flight
	378464, --Nullifying Shourd
	210256, --Blessing of Sanctuary
	236321, --War Banner (Arms Only)
	
	383020, -- Tranquil Totem
	234084, -- Moon & Stars
	
	--**Class Healing & DMG CDs Given**---------------------------------------------------------
	375226, -- Time Spiral (Death Knight)
	375229, -- Time Spiral (Demon Hunter)
	375230, -- Time Spiral (Druid)
	375234, -- Time Spiral (Evoker)
	375238, -- Time Spiral (Hunter)
	375240, -- Time Spiral (Mage)
	375252, -- Time Spiral (Monk)
	375253, -- Time Spiral (Paladin)
	375254, -- Time Spiral (Priest)
	375255, -- Time Spiral (Rogue)
	375256, -- Time Spiral (Shaman)
	375257, -- Time Spiral (Warlock)
	375258, -- Time Spiral (Warrior)
	
	"Power Infusion",
	204361, --Bloodlust
	204362, --Heroism
	29166, --Innervate

	393774, --Sentinal Perception (From Hunter)
	388045, --Sentinal Owl (Hunter Only)
	
	324143, --Conqueror's Banner (Necrolord)
	--201940, --Protector of the Pack **MAJOR DEFENSIVE**
	305497, --Thorns(Friendly and Enemy spellId)
	
	
	--** Healer CDs Given w/ Short CD**---------------------------------------------------------
	--325748, --Adaptive Swarm
	--391891, --Adaptive Swarm
	102351, --Cenarion Ward
	102352, --Cenarion Ward
	415649, --Dreamwalker's Embrace
	360827, --Blistering Scales
	--974, --Earth Shield (Has Stacks)
	
	
	--**Passive Buffs Given**------------------------------------------------------------------
	289318, --Mark of the Wild
	--317920, --Concentration Aura
	--465, --Devotion Aura
	--32223, --Crusader Aura
}

local BOLBuffs = {}
local BOLBuffsCount = 1
for _, v in ipairs(BOL) do
	BOLBuffs[v] = BOLBuffsCount 
	BOLBuffsCount = BOLBuffsCount  + 1
end

 --------------------------------------------------------------------------------------------------------------------------------------------------
 --Debuffs
 --------------------------------------------------------------------------------------------------------------------------------------------------
local spellIds = {

--DONT SHOW
	[57723] = "Hide", --Exhaustion
	[390435] = "Hide", --Exhaustion
	[57724] = "Hide", --Sated
	[264689] = "Hide", --Fatigued
	[80354] = "Hide", --Temporal Displacement
	[287825] = "Hide", --Lethargy
	[206151] = "Hide", --Challenger's Burden
	[295339] = "Hide", --Will to Survive
	[306474] = "Hide", --Recharging
	[313471] = "Hide", --Faceless Masks
	[110310] = "Hide", --Dampening
	[338906] = "Hide", -- The Jailer's Chains

---Priority--
--	[317265] = "Priority", --Infinite Stars
--	[318187] = "Priority", --Gushing Wounds

---WARNINGS---
--DEATH KNIGHT
  	[123981] = "Warning", --Perdition
--DH
	[209261] = "Warning", --Uncontained Fel
--Mage
	[87024] = "Warning", --Cauterized
	[41425] = "Warning", --Hypothermia
--PALLY
	[25771] = "Warning", --Forbearance
	[393879] = "Warning", --Gift of the Golden Val'kyr
--ROGUE
	[45181] = "Warning", --Cheated Death

--GENERAL WARNINGS
	[46392] = "Warning", --Focused Assault (flag carrier, increasing damage taken by 10%)
	[195901]= "Warning", --Adapted
	[288756]= "Warning", --Gladiator's Safeguard

---GENERAL DANGER---
--DEATH KNIGHT
	--[130736] = "Big", -- Soul Reaper
	--[48743] = "Big", -- Death Pact
	[204206] = "Big", --Chilled (Chill Streak)
	[343294] = "Big", --Soul Reaper
	[214975] = "Warning", -- Shourd of Winter
	[233397] = "Warning", -- Delirium
	[214975] = "Warning", -- Heartstop Aura
	[199719] = "Warning", -- Heartstop Aura

--DEMON HUNTER
	[320338] = "Big", --Essence Break
	[370969] = "Big", -- The Hunt Dot

--DRUID
	[274838] = "Big",  --Feral Frenzy
	[391889] = "Big", -- Adpative Swarm
	[410063] = "Warning", -- Reactive Resin
	[236021] = "Warning", --Ferocious Wound (5% & 10%)
	[58180] = "Warning", --Infected Wounds (PvP MS)
	[202347] = "Warning", --Stellar Flare

--EVOKER
	[383005] = "Bigger", -- Chrono Loop
	[409560] = "Bigger", -- Temporal Wound
	[372048] = "Big", -- Oppressing Roar
	[404369] = "Warning", --Defy Fate

--HUNTER
	[131894] = "Big", -- A Murder of Crows (BM)
	[321538] = "Big", --Bloodshed (BM)
	[212431] = "Big", -- Explosive Shot (MM)
	[361049] = "Big", -- Bleeding Gash (Kill Shot w/CA) (SV)
	[257284] = "Warning", -- Hunter's Mark

--MAGE
	[390612] = "Big", -- Frostbomb
	[376103] = "Big", --Radiant Spark Vulnerability
	[12654] = "Warning", --Ignite

--MONK
	[122470] = "Bigger", -- Touch of Karma
	[124280] = "Big", -- Touch of Karma Dot
	[393047] = "Big", --Skyreach
	[386276] = "Big", -- Bonedust Brew

--PALLY
	--[206891] = "Big", -- Focused Assault
	[343721] = "Big", --  --Final Reckoning
	[343527] = "Big", --  --Execution Sentence
	[2812] = "Warning", -- Denouce

--PRIEST
	--[322461] = "Big" --Thoughtstolen
	--[199845] = "Bigger", --Psyflay
	--[247777] = "Big", --Mind Trauma
	--[214621] = "Big", --Schism
	[375901] = "Big", -- Priest: Mindgames
	[335467] = "Big", --Devouring Plague

--ROGUE
	[79140]  = "Biggest", -- Vendetta
	[360194] = "Biggest", -- Deathmark
	[207736] = "Bigger", -- Shadowy Duel
	[212183] = "Bigger", -- Smoke Bomb
	[385408] = "Big", -- Rogue: Sepsis
	[384631] = "Big", -- Rogue: Flagellation 
	[GetSpellInfo(385627) or 385627] = "Big", -- Rogue: Kingsbane
	[8680] = "Warning", --Wound Poison
	[383414] = "Warning", --Amplyfying Poison
	[5760] =  "Warning", --Numbing Posion

--SHAMAN
	[197209] = "Bigger", --Lightning Rod
	[382089] = "Big", -- Electrified Shocks
	[188389] =  "Warning", --Flame Shock
	--[208997] = "Big", -- Counterstrike Totem
	--[206647] = "Big", -- Electrocute

--WARLOCK
	--[80240] = "Bigger", -- Havoc
	--[200587] = "Bigger", -- Fel Fissure
	--[199954] = "Big", -- Curse of Fragility
	--[199890] = "Big", -- Curse of Tongues
	--[199892] = "Big", -- Curse of Weakness
	--[48181] = "Big", -- Haunt
	--[234877] = "Big", -- Curse of Shadows
	--[196414] = "Big", -- Eradication
	--[233582] = "Warning", --Entrenched Flame
	[386997] = "Bigger", -- Warlock: Soulrot 
	[205179] = "Big", --Phantom Singularity
	--[212580] = "Big", --Call Observer
	[199954] = "Warning", --Curse of Fragility
	[603] = "Warning", -- Doom (Demo)

--WARRIOR
  --[198819] = "Bigger", -- Sharpen
  --[236273] = "Big", -- Duel
  --[208086] = "Big", -- Colossus Smash
	--[354788] = "Warning", --Slaughterhouse (Stacking MS)
	[208086] = "Big", --Colossus Smash
	[397364] = "Big", --Thunderous Roar

--TRINKETS


--------------------------------------------------------------------------------------------------------------------------------------------------
--BGs & Pets
--------------------------------------------------------------------------------------------------------------------------------------------------
}

-- data from LoseControl
local bgBiggerspellIds = { --Always Shows for Pets
	
}

-- data from LoseControl
local bgBigspellIds = { --Always Shows for Pets
--CC--
	[3355] = "True",			-- Freezing Trap
	[203337] = "True",			-- Freezing Trap (Diamond Ice - pvp honor talent)
	[24394] = "True",			-- Intimidation
	[213691] = "True",			-- Scatter Shot (pvp honor talent)
	[1513 ] = "True",        		-- Scare Beast

	["Hex"] = "True",			-- Hex
	[51514] = "True",			-- Hex
	[210873] = "True",			-- Hex (compy)
	[211010] = "True",			-- Hex (snake)
	[211015] = "True",			-- Hex (cockroach)
	[211004] = "True",			-- Hex (spider)
	[196942] = "True",			-- Hex (Voodoo Totem)
	[269352] = "True",			-- Hex (skeletal hatchling)
	[277778] = "True",			-- Hex (zandalari Tendonripper)
	[277784] = "True",			-- Hex (wicker mongrel)
	[77505] = "True",			-- Earthquake
	[118905] = "True",			-- Static Charge (Capacitor Totem)
	[305485] = "True",			-- Lightning Lasso
	[197214] = "True",			-- Sundering
	[118345] = "True",			-- Pulverize (Shaman Primal Earth Elemental)

	[108194] = "True",			-- Asphyxiate
	[221562] = "True",			-- Asphyxiate
	[207167] = "True",			-- Blinding Sleet
	[287254] = "True",			-- Dead of Winter (pvp talent)
	[210141] = "True",			-- Zombie Explosion (Reanimation PvP Talent)
	[91800] = "True",			-- Gnaw
	[91797] = "True",			-- Monstrous Blow (Dark Transformation)
	[334693] = "True",       			-- Absolute Zero (Shadowlands Legendary Stun)
	[377048] = "True",       			-- Absolute Zero

	[33786] = "True",			-- Cyclone
	[5211] = "True",			-- Mighty Bash
	[163505] = "True",			-- Rake
	[203123] = "True",			-- Maim
	[202244] = "True",			-- Overrun (pvp honor talent)
	[99] = "True",			-- Incapacitating Roar
	[2637] = "True",			-- Hibernate

	[372245] = "True",			-- Terror of the Skies
	[360806] = "True",			-- Sleep Walk

	["Polymorph"] = "True",		-- Polymorph
	[118] = "True",			-- Polymorph
	[61305] = "True",			-- Polymorph: Black Cat
	[28272] = "True",			-- Polymorph: Pig
	[61721] = "True",			-- Polymorph: Rabbit
	[61780] = "True",			-- Polymorph: Turkey
	[28271] = "True",			-- Polymorph: Turtle
	[161353] = "True",			-- Polymorph: Polar bear cub
	[126819] = "True",			-- Polymorph: Porcupine
	[161354] = "True",			-- Polymorph: Monkey
	[61025] = "True",			-- Polymorph: Serpent
	[161355] = "True",			-- Polymorph: Penguin
	[277787] = "True",			-- Polymorph: Direhorn
	[277792] = "True",			-- Polymorph: Bumblebee
	[161372] = "True",			-- Polymorph: Peacock
	[391622] = "True",			-- Polymorph: Duck
	[389831] = "True",			-- Snowdrift
	[82691] = "True",			-- Ring of Frost
	[140376] = "True",			-- Ring of Frost
	[31661] = "True",			-- Dragon's Breath

	[119381] = "True",			-- Leg Sweep
	[115078] = "True",			-- Paralysis
	[198909] = "True",			-- Song of Chi-Ji
	[202274] = "True",			-- Incendiary Brew (honor talent)
	[202346] = "True",			-- Double Barrel (honor talent)

	[853] = "True",			-- Hammer of Justice
	[105421] = "True",			-- Blinding Light
	[20066] = "True",			-- Repentance

	[605] = "True",			-- Dominate Mind
	[8122] = "True",			-- Psychic Scream
	[9484] = "True",			-- Shackle Undead
	[64044] = "True",			-- Psychic Horror
	[87204] = "True",			-- Sin and Punishment
	[226943] = "True",			-- Mind Bomb
	[205369] = "True",			-- Mind Bomb
	[200196] = "True",			-- Holy Word: Chastise
	[200200] = "True",			-- Holy Word: Chastise (talent)
	[358861] = "True",			-- Void Volley: Horrify

	[2094] = "True",			-- Blind
	[1833] = "True",			-- Cheap Shot
	[1776] = "True",			-- Gouge
	[408] = "True",			-- Kidney Shot
	[6770] = "True",			-- Sap
	--[199804] = "True",			-- Between the eyes

	[118699] = "True",			-- Fear
	[5484] = "True",	    	-- Howl of Terror
	[6789] = "True",			-- Mortal Coil
	[30283] = "True",			-- Shadowfury
	[710] = "True",			-- Banish
	[22703] = "True",			-- Infernal Awakening
	[213688] = "True",	  		-- Fel Cleave (Fel Lord - PvP Talent)
	[89766] = "True",	  		-- Axe Toss (Felguard/Wrathguard)
	--[347008] = "True",	  		-- Axe Toss (Felguard/Wrathguard)
	[115268] = "True",		    -- Mesmerize (Shivarra)
	[6358] = "True",	  		-- Seduction (Succubus)
	[261589] = "True",		 	-- Seduction (Succubus)
	[171017] = "True",		 	-- Meteor Strike (infernal)
	[171018] = "True",		  	-- Meteor Strike (abisal)

	[5246] = "True",			-- Intimidating Shout (aoe)
	[316593] = "True",			--Intimidating Shout
	[316595] = "True", 				--Intimidating Shout
	[132169] = "True",			-- Storm Bolt
	[325886] = "True",       			-- Ancient Aftershock
	[326062] = "True",       			-- Ancient Aftershock
	[132168] = "True",			-- Shockwave
	[199085] = "True",			-- Warpath

	[179057] = "True",			-- Chaos Nova
	[211881] = "True",			-- Fel Eruption
	[217832] = "True",			-- Imprison
	[221527] = "True",			-- Imprison (pvp talent)
	[200166] = "True",			-- Metamorfosis stun
	[207685] = "True",			-- Sigil of Misery
	[205630] = "True",			-- Illidan's Grasp
	[208618] = "True",			-- Illidan's Grasp (throw stun)
	[213491] = "True",			-- Demonic Trample Stun

	[331866] = "True",        		-- Door of Shadows Fear (Venthyr)
	[332423] = "True",        		-- Sparkling Driftglobe Core 35% Stun (Kyrian)
	[324263] = "True",        		-- Sulfuric Emission (Necrolord)
	[20549] = "True",			-- War Stomp (tauren racial)
	[107079] = "True",			-- Quaking Palm (pandaren racial)
	[255723] = "True",			-- Bull Rush (highmountain tauren racial)
	[287712] = "True",			-- Haymaker (kul tiran racial)

	[47476] = "True",			-- Strangulate
	[374776] = "True",			-- Tightening Grasp
	[356727] = "True",			-- Spider Venom  (Chimaeral Sting)
	[317589] = "True",			-- Tormenting Backlash (Venthyr Mage)
	[81261] = "True",			-- Solar Beam
	[410065] = "True",			-- Reactive Resin
	[217824] = "True",			-- Shield of Virtue (pvp honor talent)
	[15487] = "True",			-- Silence
	[1330] = "True",			-- Garrote - Silence
	[196364] = "True",			-- Unstable Affliction
	[204490] = "True",			-- Sigil of Silence

	[212638] = "True",				-- Tracker's Net (pvp honor talent) -- Also -80% hit chance melee & range physical (CC and Root category)
	[356723] = "True",				-- Scorpid Venom (Chimaeral Sting)
	[307871] = "True",				-- Spear of Bastion
	[376080] = "True",				-- Spear of Bastion
	[114404] = "True", 				-- Void Tendrils

	[454787] = "True",				-- Ice Prison (Talent) w/ Chains
	[233395] = "True",				-- Deathchill (pvp talent)
	[204085] = "True",				-- Deathchill (pvp talent)
	[91807] = "True",				-- Shambling Rush (Dark Transformation)
	[117526] = "True",				-- Binding Shot
	[190927] = "True",				-- Harpoon
	[190925] = "True",				-- Harpoon
	[162480] = "True",				-- Steel Trap
	[393456] = "True",				-- Entrapment
	[53148] = "True",				-- Charge (tenacity ability)
	[64695] = "True",				-- Earthgrab (Earthgrab Totem)
	[285515] = "True",	    		-- Surge of Power
	[356738] = "True",	     		-- Earth Unleashed
	[339] = "True",				-- Entangling Roots
	[170855] = "True",				-- Entangling Roots (Nature's Grasp)
	[45334] = "True",				-- Immobilized (Wild Charge - Bear)
	[102359] = "True",				-- Mass Entanglement
	[355689] = "True",				-- Landslide
	[122] = "True",				-- Frost Nova
	[198121] = "True",				-- Frostbite (pvp talent)
	[386770] = "True",				-- Freezing Cold
	[378760] = "True",				-- Frost Bite
	[157997] = "True",				-- Ice Nova
	[228600] = "True",				-- Glacial Spike
	[33395] = "True",				-- Freeze
	[116706] = "True",				-- Disable
	[324382] = "True",				-- Clash
	[105771] = "True",				-- Charge (root)
	[199042] = "True",				-- Thunderstruck
	[356356] = "True",				-- Warbringer
	[323996] = "True",				-- The Hunt
	[370970] = "True",				-- The Hunt
	[354051] = "True",				-- Nimble Steps

}

-- data from LoseControl Warning 
local bgWarningspellIds = { --Always Shows for Pets

	[233490] = "True", -- UA
	[233497] = "True", -- UA
	[233496] = "True", -- UA
	[233498] = "True", -- UA
	[233499] = "True", -- UA
	[342938] = "True", -- UA Shadowlands
	[316099] = "True", -- UA
	[43522] = "True", -- UA
	[34438] = "True", -- UA
	[34439] = "True", -- UA
	[251502] = "True", -- UA
	[65812] = "True", -- UA
	[35183] = "True", -- UA
	[211513] = "True", -- UA
	[285142] = "True", -- UA
	[285143] = "True", -- UA
	[285144] = "True", -- UA
	[285145] = "True", -- UA
	[285146] = "True", -- UA
	[34914] = "True", -- VT
	[202347] = "True", --Stellar Flare
	[188389]= "True", --Flame Shock

}


local function ActionButton_SetupOverlayGlow(button)
	-- If we already have a SpellActivationAlert then just early return. We should already be setup
	if button.SpellActivationAlert then
		return;
	end

	button.SpellActivationAlert = CreateFrame("Frame", nil, button, "ActionBarButtonSpellActivationAlert");

	--Make the height/width available before the next frame:
	local frameWidth, frameHeight = button:GetSize();
	button.SpellActivationAlert:SetSize(frameWidth * 1.5, frameHeight * 1.5);
	button.SpellActivationAlert:SetPoint("CENTER", button, "CENTER", 0, 0);
	button.SpellActivationAlert:Hide();
end

local function ActionButton_ShowOverlayGlow(button)
	ActionButton_SetupOverlayGlow(button);

	button.SpellActivationAlert:Show();
	button.SpellActivationAlert.ProcLoop:Play();
	button.SpellActivationAlert.ProcStartFlipbook:Hide()
end

local function ActionButton_HideOverlayGlow(button)
	if not button.SpellActivationAlert then
		return;
	end

 	button.SpellActivationAlert:Hide();

end




local function ObjectDNE(guid) --Used for Infrnals and Ele
	local tooltipData =  C_TooltipInfo.GetHyperlink('unit:' .. guid or '')
	TooltipUtil.SurfaceArgs(tooltipData)

	for _, line in ipairs(tooltipData.lines) do
		TooltipUtil.SurfaceArgs(line)
	end
	--print(#tooltipData.lines)
	if #tooltipData.lines == 1 then -- Fel Obelisk
		return "Despawned"
	end
	for i = 1, #tooltipData.lines do 
 		local text = tooltipData.lines[i].leftText
		 if text and (type(text == "string")) then
			--print(i.." "..text)
			if strfind(text, "Level ??") or strfind(text, "Corpse") then 
				return "Despawned"
			end
		end
	end
end

--[[local DNEtooltip = CreateFrame("GameTooltip", "DFDNEScanSpellDescTooltip", UIParent, "GameTooltipTemplate")

local function ObjectDNE(guid) --Used for Infrnals and Ele
	DNEtooltip:SetOwner(WorldFrame, 'ANCHOR_NONE')
	DNEtooltip:SetHyperlink("unit:"..guid or '')

	for i = 1 , DNEtooltip:NumLines() do
		local text =_G["DFDNEScanSpellDescTooltipTextLeft"..i]; 
		text = text:GetText()
		if text and (type(text == "string")) then
			--print(i.." "..text)
			if strfind(text, "Level ??") or strfind(text, "Corpse") then 
				return "Despawned"
			end
		end
	end
end]]

local function compare_1(a,b)
	return a[13] < b[13]
  end
  
  
local function compare_2(a, b)
	if a[13] < b[13] then return true end
	if a[13] > b[13] then return false end
	return a[6] > b[6]
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CLEU Events
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--BOC CLEU Events
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function DebuffFilter:BOCCLEU()
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--BOL CLEU Events
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local CLEUBOL = {}
local WarBanner = {}
local Barrier = {}
local Earthen = {}

function DebuffFilter:BOLCLEU()
	local _, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellId, _, _, _, _, spellSchool = CombatLogGetCurrentEventInfo()
	local scf, uid

	-----------------------------------------------------------------------------------------------------------------
	--Barrier Check
	-----------------------------------------------------------------------------------------------------------------
	if ((sourceGUID ~= nil) and (event == "SPELL_CAST_SUCCESS") and (spellId == 62618)) then
		scf = self.cache[sourceGUID]
		if scf then 
			uid = scf.unit
		end
		if (sourceGUID ~= nil) then
		local duration = 10
		local expiration = GetTime() + duration
			if (Barrier[sourceGUID] == nil) then
				Barrier[sourceGUID] = {}
			end
			Barrier[sourceGUID] = { ["duration"] = duration, ["expiration"] = expiration }
			Ctimer(duration + 1, function()	-- execute iKn some close next frame to accurate use of UnitAura function
			Barrier[sourceGUID] = nil
			end)
		end
	end

	-----------------------------------------------------------------------------------------------------------------
	--Earthen Check (Totems Need a Spawn Time Check)
	-----------------------------------------------------------------------------------------------------------------
	if ((event == "SPELL_SUMMON") or (event == "SPELL_CREATE")) and (spellId == 198838) then
		if sourceGUID and not (bit_band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE) then
			scf = self.cache[sourceGUID]
			if scf then 
				uid = scf.unit
			end
			local duration = 18 --Totemic Focus Makes it 18
			local expirationTime = GetTime() + duration
			if (Earthen[sourceGUID] == nil) then  --source is friendly unit party12345 raid1...
				Earthen[sourceGUID] = {}
			end
			Earthen[sourceGUID] = { ["duration"] = duration, ["expirationTime"] = expirationTime }
			Ctimer(duration + .2, function()	-- execute in some close next frame to accurate use of UnitAura function
				Earthen[sourceGUID] = nil
			end)
			local spawnTime
			local unitType, _, _, _, _, _, spawnUID = strsplit("-", destGUID)
			if unitType == "Creature" or unitType == "Vehicle" then
				local spawnEpoch = GetServerTime() - (GetServerTime() % 2^23)
				local spawnEpochOffset = bit_band(tonumber(substring(spawnUID, 5), 16), 0x7fffff)
				spawnTime = spawnEpoch + spawnEpochOffset
				--print("Earthen Totem Spawned at: "..spawnTime)
			end
			if (Earthen[spawnTime] == nil) then --source becomes the totem ><
				Earthen[spawnTime] = {}
			end
			Earthen[spawnTime] = { ["duration"] = duration, ["expirationTime"] = expirationTime }
		end
	end

	-----------------------------------------------------------------------------------------------------------------
	--WarBanner Check (Totems Need a Spawn Time Check)
	-----------------------------------------------------------------------------------------------------------------
	if ((event == "SPELL_SUMMON") or (event == "SPELL_CREATE")) and (spellId == 236320) then
		if sourceGUID and not (bit_band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE) then
			scf = self.cache[sourceGUID]
			if scf then 
				uid = scf.unit
			end
			local duration = 15
			local expirationTime = GetTime() + duration
			if (WarBanner[sourceGUID] == nil) then --source is friendly unit party12345 raid1...
				WarBanner[sourceGUID] = {}
			end
			WarBanner[sourceGUID] = { ["duration"] = duration, ["expirationTime"] = expirationTime }
			Ctimer(duration + 1, function()	-- execute in some close next frame to accurate use of UnitAura function
			WarBanner[sourceGUID] = nil
			end)
		end
	end
	if scf and uid then 
		self:BuffFilter(scf, uid, "BOL")
	end
end



-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--BOR CLEU Events
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local CLEUBOR = {}
local summonedAura = {
	[49206]  = 25, --Ebon Gargoyle

	[248280] = 10, --Trees
	[102693] = 15, --Grove Guardians


	[205691] = 30, --Dire Beast Basilisk

	[321686] = 40, --Mirror Image

	[123904] = 24,--WW Xuen Pet Summmon "Xuen" same Id has sourceGUID

	[123040] = 12, --Mindbender
	[34433]  = 15, --Disc Pet Summmon Sfiend "Shadowfiend" same Id has sourceGUID

	[188616] = 60, --Shaman Earth Ele "Greater Earth Elemental", has sourceGUID [summonid]
	[118323] = 60, --Shaman Primal Earth Ele "Primal Earth Elemental", has sourceGUID [summonid]
	[188592] = 30, --Shaman Fire Ele "Fire Elemental", has sourceGUID [summonid]
	[118291] = 30, --Shaman Primal Fire Ele "Primal Fire Earth Elemental", has sourceGUID [summonid]
	[157299] = 30, --Storm Ele , has sourceGUID [summonid]
	[157319] = 30, --Primal Storm Ele , has sourceGUID [summonid]

	[201996] = 20, --Call Observer
	[111685] = 30, --Warlock Infernals,  has sourceGUID (spellId and Summons are different) [spellbookid]
	[205180] = 20, --Warlock Darkglare
	[265187] = 15, --Warlock Demonic Tyrant
	[353601] = 15, --Fel Obelisk
	[394243] = 2,  --Choas Tear
	[387979]  = 6,  --Unstable Tear
	[394235] = 14, --Shadowy Tear

}

local castedAura = {
--Casted Spells
	[202770] = 8, --Fury of Elune
	[202359] = 6, --Astral Communion

}

function DebuffFilter:BORCLEU()
	local _, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellId, _, _, _, _, spellSchool = CombatLogGetCurrentEventInfo()
	local scf, uid

	-----------------------------------------------------------------------------------------------------------------
	--Summoned
	-----------------------------------------------------------------------------------------------------------------
	if (event == "SPELL_SUMMON") or (event == "SPELL_CREATE") then --Summoned CDs
		--print(event.." "..spellId.." "..GetSpellInfo(spellId).." "..(destName or ""))
		if summonedAura[spellId] and sourceGUID and not (bit_band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE) then
			scf = self.cache[sourceGUID]
			if not scf then return end 
			uid = scf.unit
			local guid = destGUID
			local duration = summonedAura[spellId]
			local namePrint, _, icon = GetSpellInfo(spellId)
			local expirationTime = GetTime() + duration

			if spellId == 321686 then -- Mirror Image
				icon = 135994
			end

			if spellId == 157299 or spellId == 157319 then -- Strom Elemental
				icon = 2065626
			end
			--print(sourceName.." Summoned "..namePrint.." "..substring(destGUID, -7).." for "..duration.." BOR")
			if not CLEUBOR[sourceGUID] then
				CLEUBOR[sourceGUID] = {}
			end
			tblinsert(CLEUBOR[sourceGUID], {namePrint, icon, _, _, duration, expirationTime, sourceName, _, _, spellId, _, destGUID, BORBuffs[spellId]})
			--{icon, duration, expirationTime, spellId, destGUID, BORBuffs[spellId], sourceName, namePrint})
			tblsort(CLEUBOR[sourceGUID], compare_1)
			tblsort(CLEUBOR[sourceGUID], compare_2)
			local ticker = 1
			Ctimer(duration, function()
				if CLEUBOR[sourceGUID] then
					for k, v in pairs(CLEUBOR[sourceGUID]) do
						if v[10] == spellId then
							--print(v[1].." ".."Timed Out".." "..v[1].." "..substring(v[12], -7).." left w/ "..string.format("%.2f", v[6]-GetTime()).." BOR C_Timer")
							tremove(CLEUBOR[sourceGUID], k)
							tblsort(CLEUBOR[sourceGUID], compare_1)
							tblsort(CLEUBOR[sourceGUID], compare_2)
							if #CLEUBOR[sourceGUID] ~= 0 then self:BuffFilter(scf, uid, "BOR") end
							if #CLEUBOR[sourceGUID] == 0 then
								CLEUBOR[sourceGUID] = nil
								self:BuffFilter(scf, uid, "BOR")
							end
						end
					end
				end
			end)
			self.ticker = C_Timer.NewTicker(.1, function()
				if CLEUBOR[sourceGUID] then
					for k, v in pairs(CLEUBOR[sourceGUID]) do
						if (v[12] and (v[10] ~= 394243 and v[10] ~= 387979 and v[10] ~= 394235)) then --Dimmensional Rift Hack to Not Deswpan
							if substring(v[12], -5) == substring(guid, -5) then --string.sub is to help witj Mirror Images bug
								if ObjectDNE(v[12]) then
								--print(v[1].." "..ObjectDNE(v[12], ticker, v[1], v[7]).." "..v[1].." "..substring(v[12], -7).." left w/ "..string.format("%.2f", v[6]-GetTime()).." BOR C_Ticker")
								tremove(CLEUBOR[sourceGUID], k)
								tblsort(CLEUBOR[sourceGUID], compare_1)
								tblsort(CLEUBOR[sourceGUID], compare_2)
								if #CLEUBOR[sourceGUID] ~= 0 then self:BuffFilter(scf, uid, "BOR") end
								if #CLEUBOR[sourceGUID] == 0 then
									CLEUBOR[sourceGUID] = nil
									self:BuffFilter(scf, uid, "BOR")
									end
									break
								end
							end
						end
					end
				end
				ticker = ticker + 1
			end, duration * 10 + 5)
		end
	end

	-----------------------------------------------------------------------------------------------------------------
	--Casted  CDs w/o Aura
	-----------------------------------------------------------------------------------------------------------------
	if (event == "SPELL_CAST_SUCCESS") then --Casted  CDs w/o Aura
		if castedAura[spellId] and sourceGUID and not (bit_band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE) then
			scf = self.cache[sourceGUID]
			if not scf then return end 
			uid = scf.unit
			local duration = castedAura[spellId]
			local namePrint, _, icon = GetSpellInfo(spellId)
			local expirationTime = GetTime() + duration
			--print(sourceName.." Casted "..namePrint.." "..substring(destGUID, -7).." for "..duration.." BOR")
			if not CLEUBOR[sourceGUID] then
				CLEUBOR[sourceGUID] = {}
			end
			tblinsert(CLEUBOR[sourceGUID], {namePrint, icon, count, debuffType, duration, expirationTime, sourceName, canStealOrPurge, _, spellId, canApplyAura, destGUID, BORBuffs[spellId]})
			tblsort(CLEUBOR[sourceGUID], compare_1)
			tblsort(CLEUBOR[sourceGUID], compare_2)
			Ctimer(duration, function()
				if CLEUBOR[sourceGUID] then
					for k, v in pairs(CLEUBOR[sourceGUID]) do
						if v[10] == spellId then
							--print(v[1].." ".."Timed Out".." "..v[1].." "..substring(v[12], -7).." left w/ "..string.format("%.2f", v[6]-GetTime()).." BOR C_Timer")
							tremove(CLEUBOR[sourceGUID], k)
							tblsort(CLEUBOR[sourceGUID], compare_1)
							tblsort(CLEUBOR[sourceGUID], compare_2)
							if #CLEUBOR[sourceGUID] ~= 0 then self:BuffFilter(scf, uid, "BOR") end
							if #CLEUBOR[sourceGUID] == 0 then
								CLEUBOR[sourceGUID] = nil
								self:BuffFilter(scf, uid, "BOR")
							end
						end
					end
				end
			end)
		end
	end

	if scf and uid then 
		self:BuffFilter(scf, uid, "BOR")
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--DF CLEU Events
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DebuffFilter:DFCLEU()
	local _, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, _, _, _, spellId, _, _, _, _, spellSchool = CombatLogGetCurrentEventInfo()
	-----------------------------------------------------------------------------------------------------------------
	--SmokeBomb Check
	-----------------------------------------------------------------------------------------------------------------
	if ((event == "SPELL_CAST_SUCCESS") and (spellId == 212182 or spellId == 359053)) then
		if (sourceGUID ~= nil) then
		local duration = 5
		local expirationTime = GetTime() + duration
			if not SmokeBombAuras[sourceGUID] then
				SmokeBombAuras[sourceGUID] = {}
			end
			SmokeBombAuras[sourceGUID] = { ["duration"] = duration, ["expirationTime"] = expirationTime }
			Ctimer(duration + 1, function()	-- execute in some close next frame to accurate use of UnitAura function
			SmokeBombAuras[sourceGUID] = nil
			end)
		end
	end

	-----------------------------------------------------------------------------------------------------------------
	--Shaodwy Duel Enemy Check
	-----------------------------------------------------------------------------------------------------------------
	if (event == "SPELL_CAST_SUCCESS") and (spellId == 207736) then
		if sourceGUID and (bit_band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE) then
			if (DuelAura[sourceGUID] == nil) then
				DuelAura[sourceGUID] = {}
			end
			if not DuelAura[destGUID] then
				DuelAura[destGUID] = {}
			end
			local duration = 5
			Ctimer(duration + 1, function()
			DuelAura[sourceGUID] = nil
			DuelAura[destGUID] = nil
			end)
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Debuf Scale Filters
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function isBiggestDebuff(unit, index, filter)
  local  name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, index, "HARMFUL");
	if (spellIds[spellId] == "Biggest" or spellIds[name] == "Biggest") then
		return true
	else
		return false
	end
end

local function isBiggerDebuff(unit, index, filter)
  local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, index, "HARMFUL");
	local inInstance, instanceType = IsInInstance()
	if (instanceType =="pvp" or strfind(unit,"pet")) and (bgBiggerspellIds[spellId] or bgBiggerspellIds[name]) then
		return true
	elseif (spellIds[spellId] == "Bigger" or spellIds[name] == "Bigger") and instanceType ~="pvp" then
		return true
	else
		return false
	end
end

local function isBigDebuff(unit, index, filter)
	local name, _, count, _, _, _, source, _, _, spellId = UnitAura(unit, index, "HARMFUL");
	  local inInstance, instanceType = IsInInstance()
	  if (spellId == 325216 or spellId == 386276) then --BoneDust Brew
		  local id, specID
		  if source then
			  if strfind(source, "nameplate") then
				  if (UnitGUID(source) == UnitGUID("arena1")) then id = 1 elseif (UnitGUID(source) == UnitGUID("arena2")) then id = 2 elseif (UnitGUID(source) == UnitGUID("arena3")) then id = 3 end
			  else
				  if strfind(source, "arena1") then id = 1 elseif strfind(source, "arena2") then id = 2 elseif strfind(source, "arena3") then id = 3 end
			  end
			  specID = GetArenaOpponentSpec(id)
			  if specID then
				  if (specID == 270) then --Monk: Brewmaster: 268 / Windwalker: 269 / Mistweaver: 270
					  spellIds[spellId] = "Warning"
					  bgWarningspellIds[spellId] = "True"
				  else
					  spellIds[spellId] = "Big"
					  bgWarningspellIds[spellId] = nil
				  end
			  end
		  end
	  end
	  if (spellId == 391889) then --Adaptive Swarm
		  local id, specID
		  if source then
			  if strfind(source, "nameplate") then
				  if (UnitGUID(source) == UnitGUID("arena1")) then id = 1 elseif (UnitGUID(source) == UnitGUID("arena2")) then id = 2 elseif (UnitGUID(source) == UnitGUID("arena3")) then id = 3 end
			  else
				  if strfind(source, "arena1") then id = 1 elseif strfind(source, "arena2") then id = 2 elseif strfind(source, "arena3") then id = 3 end
			  end
			  specID = GetArenaOpponentSpec(id)
			  if specID then
				  if (specID == 105) then --Druid: Balance: 102 / Feral: 103 / Guardian: 104 /Restoration: 105
					  spellIds[spellId] = "Priority"
					  bgWarningspellIds[spellId] = "True"
				  else
					  spellIds[spellId] = "Warning"
					  bgWarningspellIds[spellId] = nil
				  end
			  end
		  end
	  end
	  if (instanceType =="pvp" or strfind(unit,"pet")) and (bgBigspellIds[spellId] or bgBigspellIds[name])then
		  return true
	  elseif (spellIds[spellId] == "Big" or spellIds[name] == "Big")  and instanceType ~="pvp" then
		  return true
	  else
		  return false
	  end
  end

local function CompactUnitFrame_UtilIsBossDebuff(unit, index, filter)
  local _, _, _, _, _, _, _, _, _, _, _, isBossDeBuff = UnitAura(unit, index, "HARMFUL");
	if isBossDeBuff then
		return true
	else
		return false
	end
end

local function CompactUnitFrame_UtilIsBossAura(unit, index, filter)
  local _, _, _, _,_, _, _, _, _, _, _, isBossDeBuff = UnitAura(unit, index, "HELPFUL");
	if isBossDeBuff then
		return true
	else
		return false
	end
end

local function isWarning(unit, index, filter)
    local name, _, count, _, _, _, source, _, _, spellId = UnitAura(unit, index, "HARMFUL");
	local inInstance, instanceType = IsInInstance()
	if (spellId == 188389) then --Flame Shock
		local id, specID
		if source then
			if strfind(source, "nameplate") then
				if (UnitGUID(source) == UnitGUID("arena1")) then id = 1 elseif (UnitGUID(source) == UnitGUID("arena2")) then id = 2 elseif (UnitGUID(source) == UnitGUID("arena3")) then id = 3 end
			else
				if strfind(source, "arena1") then id = 1 elseif strfind(source, "arena2") then id = 2 elseif strfind(source, "arena3") then id = 3 end
			end
			specID = GetArenaOpponentSpec(id)
			if specID then
				if (specID == 262) then --Shaman: Elemental: 262 / Enhancement: 263 / Resto 264
					spellIds[spellId] = "Warning"
					bgWarningspellIds[spellId] = "True"
				else
					spellIds[spellId] = "Priority"
					bgWarningspellIds[spellId] = nil
				end
			end
		end
	end
	if (instanceType =="pvp" or strfind(unit,"pet")) and (bgWarningspellIds[spellId] or bgWarningspellIds[name]) then
		return true
	elseif (spellIds[spellId] == "Warning" or spellIds[name] == "Warning") and instanceType ~="pvp" then
		if spellId == 58180 or spellId == 8680 or spellId == 410063 then -- Only Warning if Two Stacks of MS
			if count >= 2 then
				return true
			else
				return false
			end
		end
		return true
	else
		return false
	end
end

local function isPriority(unit, index, filter)
    local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, index, "HARMFUL");
	local inInstance, instanceType = IsInInstance()
		if (spellIds[spellId] == "Priority" or spellIds[name] == "Priority") and instanceType ~="pvp" then
		return true
	else
		return false
	end
end

local function isMagicPriority(unit, index, filter)
    local name, _, _, debuffType, _, _, _, _, _, spellId = UnitAura(unit, index, "HARMFUL");
	local class_Name, UNIT_CLASS, class_Id = UnitClass("player")
	if (spellIds[spellId] == "Hide" or spellIds[name] == "Hide") then
		return false
	elseif UNIT_CLASS == "PRIEST" and debuffType == "Magic" then
		return true
	elseif UNIT_CLASS == "MAGE" and debuffType == "Curse" then
		return true
	elseif debuffType == "Magic" then
		return true
	else
		return false
	end
end

local function isDispelPriority(unit, index, filter)
    local  name, _, _, debuffType, _, _, _, _, _, spellId = UnitAura(unit, index, "HARMFUL");
	local class_Name, UNIT_CLASS, class_Id = UnitClass("player")
	if (spellIds[spellId] == "Hide" or spellIds[name] == "Hide") then
		return false
	elseif UNIT_CLASS == "PRIEST" and debuffType == "Disease" then
		return true
	elseif UNIT_CLASS == "MAGE" and debuffType == "Magic" then
		return true
	elseif debuffType == "Curse" or debuffType == "Poison" or  debuffType == "Disease" then
		return true
	else
		return false
	end
end

local function isDebuff(unit, index, filter)
    local  name, _, _, debuffType, _, _, _, _, _, spellId = UnitAura(unit, index, "HARMFUL");
		if (spellIds[spellId] == "Hide" or spellIds[name] == "Hide") then
		return false
	else
	  	return true
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Setting the Debuff Frame
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function CooldownFrame_Set(self, start, duration, enable, forceShowDrawEdge, modRate)
	if enable and enable ~= 0 and start > 0 and duration > 0 then
		self:SetDrawEdge(forceShowDrawEdge);
		self:SetCooldown(start, duration, modRate);
	else
		CooldownFrame_Clear(self);
	end
end

local function CooldownFrame_Clear(self)
	self:Clear();
end

local function SetdebuffFrame(scf, f, debuffFrame, uid, index, filter, scale)
	if not debuffFrame then return end 

	local frameWidth, frameHeight = f:GetSize()
	local componentScale = min(frameHeight / NATIVE_UNIT_FRAME_HEIGHT, frameWidth / NATIVE_UNIT_FRAME_WIDTH);
	local overlaySize = 11 * componentScale
	local buffId = index
	local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = UnitAura(uid, index, filter);

	if spellId == 45524 then --Chains of Ice Dk
		--icon = 463560
		--icon = 236922
		icon = 236925
	end
	
	if spellId == 454787 then --Ice Prison
		icon = 4226156
	end

	if spellId == 334693 then --Abosolute Zero Frost Dk Legendary Stun
		icon = 517161
	end

	if spellId == 317589 then --Mirros of Toremnt, Tormenting Backlash (Venthyr Mage) to Frost Jaw
		icon = 538562
	end

	if spellId == 199845 then --Psyflay
		icon = 537021
	end

	if spellId == 115196 then --Shiv
		icon = 135428
	end
	
	if spellId == 285515 then --Frost Shock to Frost Nove
		icon = 135848
	end

	debuffFrame.icon:SetTexture(icon);
	debuffFrame.icon:SetDesaturated(nil) --Destaurate Icon
	debuffFrame.icon:SetVertexColor(1, 1, 1);
	if filter == "HARMFUL" then 
		debuffFrame:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(debuffFrame.icon, "ANCHOR_RIGHT")
			if uid then
				GameTooltip:SetUnitDebuff(uid, buffId, "HARMFUL")
			else
				GameTooltip:SetSpellByID(buffId)
			end
			GameTooltip:Show()
		end)
		debuffFrame:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
	elseif filter == "HELPFUL" then 
		debuffFrame:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(debuffFrame.icon, "ANCHOR_RIGHT")
			if uid then
				GameTooltip:SetUnitBuff(uid, buffId, "HELPFUL")
			else
				GameTooltip:SetSpellByID(buffId)
			end
				GameTooltip:Show()
		end)
		debuffFrame:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
	end
	----------------------------------------------------------------------------------------------------------------------------------------------
	--SmokeBomb
	----------------------------------------------------------------------------------------------------------------------------------------------
	if spellId == 212183 then -- Smoke Bomb
		if unitCaster and SmokeBombAuras[UnitGUID(unitCaster)] then
			if UnitIsEnemy("player", unitCaster) then --still returns true for an enemy currently under mindcontrol I can add your fix.
				duration = SmokeBombAuras[UnitGUID(unitCaster)].duration --Add a check, i rogue bombs in stealth there is a unitCaster but the cleu doesnt regester a time
				expirationTime = SmokeBombAuras[UnitGUID(unitCaster)].expirationTime
				debuffFrame.icon:SetDesaturated(1) --Destaurate Icon
				debuffFrame.icon:SetVertexColor(1, .25, 0); --Red Hue Set For Icon
			elseif not UnitIsEnemy("player", unitCaster) then --Add a check, i rogue bombs in stealth there is a unitCaster but the cleu doesnt regester a time
				duration = SmokeBombAuras[UnitGUID(unitCaster)].duration --Add a check, i rogue bombs in stealth there is a unitCaster but the cleu doesnt regester a time
				expirationTime = SmokeBombAuras[UnitGUID(unitCaster)].expirationTime
			end
		end
	end

	-----------------------------------------------------------------------------------------------------------------
	--Enemy Duel
	-----------------------------------------------------------------------------------------------------------------
	if spellId == 207736 then --Shodowey Duel enemy on friendly, friendly frame (red)
		if DuelAura[UnitGUID(uid)] then --enemyDuel
			debuffFrame.icon:SetDesaturated(1) --Destaurate Icon
			debuffFrame.icon:SetVertexColor(1, .25, 0); --Red Hue Set For Icon
		else
		end
	end

	if count then
		if ( count > 1 ) then
			local countText = count;
			if ( count >= 100 ) then
			 countText = BUFF_STACKS_OVERFLOW;
			end
			debuffFrame.count:Show();
			debuffFrame.count:SetText(countText);
		else
			debuffFrame.count:Hide();
		end
	end

	local enabled = expirationTime and expirationTime ~= 0;
	if enabled then
		local startTime = expirationTime - duration;
		CooldownFrame_Set(debuffFrame.cooldown, startTime, duration, true);
	else
		CooldownFrame_Clear(debuffFrame.cooldown);
	end
	local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
	debuffFrame.border:SetVertexColor(color.r, color.g, color.b);
	if strfind(uid,"pet") and not scf.vehicle then
		debuffFrame:SetSize(overlaySize*scale*1.5,overlaySize*scale*1.5);
	elseif scf.vehicle then
		debuffFrame:SetSize(overlaySize*scale*1,overlaySize*scale*1);
	else
		debuffFrame:SetSize(overlaySize*scale,overlaySize*scale);
	end
	debuffFrame:Show();
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Debuff Main Loop
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DebuffFilter:UpdateDebuffs(scf, uid)
	local f = scf.f
	local filter = nil
	local debuffNum = 1
	local index = 1
	if ( f.optionTable.displayOnlyDispellableDebuffs ) then
		filter = "RAID"
	end
	--Biggest Debuffs
		while debuffNum <= DEFAULT_BIGDEBUFF do
			local debuffName = UnitDebuff(uid, index, filter)
			if ( debuffName ) then
				if isBiggestDebuff(uid, index, filter) then
					local debuffFrame = scf.debuffFrames[debuffNum]
					SetdebuffFrame(scf, f, debuffFrame, uid, index, "HARMFUL", BIGGEST)
					debuffNum = debuffNum + 1
				end
			else
				break
			end
			index = index + 1
		end
		index = 1
		--Bigger Debuff
		while debuffNum <= DEFAULT_BIGDEBUFF do
			local debuffName = UnitDebuff(uid, index, filter);
			if ( debuffName ) then
				if isBiggerDebuff(uid, index, filter) and not isBiggestDebuff(uid, index, filter) then
					local debuffFrame = scf.debuffFrames[debuffNum]
					SetdebuffFrame(scf, f, debuffFrame, uid, index, "HARMFUL", BIGGER)
					debuffNum = debuffNum + 1
				end
			else
				break
			end
			index = index + 1
		end
		index = 1
		--Big Debuff
		while debuffNum <= DEFAULT_BIGDEBUFF do
			local debuffName = UnitDebuff(uid, index, filter);
			if ( debuffName ) then
				if isBigDebuff(uid, index, filter) and not isBiggestDebuff(uid, index, filter) and not isBiggerDebuff(uid, index, filter) then
					local debuffFrame = scf.debuffFrames[debuffNum]
					SetdebuffFrame(scf, f, debuffFrame, uid, index, "HARMFUL", BIG)
					debuffNum = debuffNum + 1
				end
			else
				break
			end
			index = index + 1
		end
		index = 1
		--isBossDeBuff
		while debuffNum <= DEFAULT_DEBUFF do
			local debuffName = UnitDebuff(uid, index, filter);
			if ( debuffName ) then
				if CompactUnitFrame_UtilIsBossDebuff(uid, index, filter) and not isBiggestDebuff(uid, index, filter) and not isBiggerDebuff(uid, index, filter) and not isBigDebuff(uid, index, filter) then
					local debuffFrame = scf.debuffFrames[debuffNum]
					SetdebuffFrame(scf, f, debuffFrame, uid, index, "HARMFUL", BOSSDEBUFF)
					debuffNum = debuffNum + 1
				end
			else
				break
			end
			index = index + 1
		end
		index = 1
		--isBossBuff
		while debuffNum <= DEFAULT_DEBUFF do
			local debuffName = UnitBuff(uid, index, filter);
			if ( debuffName ) then
				if CompactUnitFrame_UtilIsBossAura(uid, index, filter) and not isBiggestDebuff(uid, index, filter) and not isBiggerDebuff(uid, index, filter) and not isBigDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossDebuff(uid, index, filter) then
					local debuffFrame = scf.debuffFrames[debuffNum]
					SetdebuffFrame(scf, f, debuffFrame, uid, index, "HELPFUL", BOSSBUFF)
					debuffNum = debuffNum + 1
				end
			else
				break
			end
			index = index + 1
		end
		index = 1
		--isWarning
		while debuffNum <= DEFAULT_DEBUFF do
			local debuffName = UnitDebuff(uid, index, filter)
			if ( debuffName ) then
				if  isWarning(uid, index, filter) and not isBiggestDebuff(uid, index, filter) and not isBiggerDebuff(uid, index, filter) and not isBigDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossAura(uid, index, filter) then
					local debuffFrame = scf.debuffFrames[debuffNum]
					SetdebuffFrame(scf, f, debuffFrame, uid, index, "HARMFUL", WARNING)
					debuffNum = debuffNum + 1
				end
			else
				break
			end
			index = index + 1
		end
		index = 1
		--Prio
		while debuffNum <= DEFAULT_DEBUFF do
			local debuffName = UnitDebuff(uid, index, filter)
			if ( debuffName ) then
				if isPriority(uid, index, filter) and not isBiggestDebuff(uid, index, filter) and not isBiggerDebuff(uid, index, filter) and not isBigDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossAura(uid, index, filter) and not isWarning(uid, index, filter) then
					local debuffFrame = scf.debuffFrames[debuffNum]
					SetdebuffFrame(scf, f, debuffFrame, uid, index, "HARMFUL", PRIORITY)
					debuffNum = debuffNum + 1
				end
			else
				break
			end
			index = index + 1
		end
		index = 1
		-------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--Magic
		while debuffNum <= DEFAULT_DEBUFF do
			local debuffName = UnitDebuff(uid, index, filter)
			if ( debuffName ) then
				if isMagicPriority(uid, index, filter) and not isBiggestDebuff(uid, index, filter) and not isBiggerDebuff(uid, index, filter) and not isBigDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossAura(uid, index, filter) and not isWarning(uid, index, filter) and not isPriority(uid, index, filter) then
					local debuffFrame = scf.debuffFrames[debuffNum]
					SetdebuffFrame(scf, f, debuffFrame, uid, index, "HARMFUL", DEBUFF)
					debuffNum = debuffNum + 1
				end
			else
				break
			end
			index = index + 1
		end
		index = 1
		--Curse & Disease
		while debuffNum <= DEFAULT_DEBUFF do
			local debuffName = UnitDebuff(uid, index, filter)
			if ( debuffName ) then
				if isDispelPriority(uid, index, filter) and not isBiggestDebuff(uid, index, filter) and not isBiggerDebuff(uid, index, filter) and not isBigDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossAura(uid, index, filter) and not isWarning(uid, index, filter) and not isPriority(uid, index, filter) and not isMagicPriority(uid, index, filter)  then
					local debuffFrame = scf.debuffFrames[debuffNum]
					SetdebuffFrame(scf, f, debuffFrame, uid, index, "HARMFUL", DEBUFF)
					debuffNum = debuffNum + 1
				end
			else
				break
			end
			index = index + 1
		end
		-------------------------------------------------------------------------------------------------------------------------------------------------------------------
		--[[Curse & Disease
		while debuffNum <= DEFAULT_DEBUFF do
			local debuffName = UnitDebuff(uid, index, filter)
			if ( debuffName ) then
				if isDispelPriority(uid, index, filter) and not isBiggestDebuff(uid, index, filter) and not isBiggerDebuff(uid, index, filter) and not isBigDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossAura(uid, index, filter) and not isWarning(uid, index, filter) and not isPriority(uid, index, filter) then
					local debuffFrame = scf.debuffFrames[debuffNum]
					SetdebuffFrame(scf, f, debuffFrame, uid, index, "HARMFUL", DEBUFF)
					debuffNum = debuffNum + 1
				end
			else
				break
			end
			index = index + 1
		end
		index = 1
		--Magic
		while debuffNum <= DEFAULT_DEBUFF do
			local debuffName = UnitDebuff(uid, index, filter)
			if ( debuffName ) then
				if isMagicPriority(uid, index, filter) and not isBiggestDebuff(uid, index, filter) and not isBiggerDebuff(uid, index, filter) and not isBigDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossAura(uid, index, filter) and not isWarning(uid, index, filter) and not isPriority(uid, index, filter) and not isDispelPriority(uid, index, filter) then
					local debuffFrame = scf.debuffFrames[debuffNum]
					SetdebuffFrame(scf, f, debuffFrame, uid, index, "HARMFUL", DEBUFF)
					debuffNum = debuffNum + 1
				end
			else
				break
			end
			index = index + 1
		end]]
		-------------------------------------------------------------------------------------------------------------------------------------------------------------------
		index = 1
		while debuffNum <= DEFAULT_DEBUFF do
			local debuffName = UnitDebuff(uid, index, filter)
			if ( debuffName ) then
				if ( isDebuff(uid, index, filter) and not isBiggestDebuff(uid, index, filter) and not isBiggerDebuff(uid, index, filter) and not isBigDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossDebuff(uid, index, filter) and not CompactUnitFrame_UtilIsBossAura(uid, index, filter) and not isWarning(uid, index, filter) and not isPriority(uid, index, filter) and not isDispelPriority(uid, index, filter) and not isMagicPriority(uid, index, filter)) then
					local debuffFrame = scf.debuffFrames[debuffNum]
					SetdebuffFrame(scf, f, debuffFrame, uid, index, "HARMFUL", DEBUFF)
					debuffNum = debuffNum + 1
				end
			else
				break
			end
			index = index + 1
		end
		for i=debuffNum, DEFAULT_DEBUFF do
		local debuffFrame = scf.debuffFrames[i];
		if debuffFrame then
			debuffFrame:Hide()
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Buff Filtering & Scale
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



local function buffTooltip(buffFrame, uid, index, spellId, filter)
	buffFrame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(buffFrame.icon, "ANCHOR_RIGHT")
		if index and uid and filter ==  "HELPFUL" then
			GameTooltip:SetUnitBuff(uid, index, "HELPFUL")
		elseif index and uid and filter ==  "HARMFUL" then
			GameTooltip:SetUnitDebuff(uid, index, "HARMFUL")
		elseif spellId then
			GameTooltip:SetSpellByID(spellId)
		end
		GameTooltip:Show()
	end)
	buffFrame:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
end


local function buffCount(buffFrame, count, backCount)
	if count or backCount then
		if backCount then count = backCount end
		if ( count > 1 ) then
			local countText = count;
			if ( count >= 100 ) then
				countText = BUFF_STACKS_OVERFLOW;
			end
				buffFrame.count:Show();
				buffFrame.count:SetText(countText);
		else
			buffFrame.count:Hide();
		end
	end
end




function DebuffFilter:SetBuffIcon(scf, uid, j, name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, destGUID, position, index, filter, BUFFSIZE)
	local f = scf.f
	local frameWidth, frameHeight = f:GetSize()
	local componentScale = min(frameHeight / NATIVE_UNIT_FRAME_HEIGHT, frameWidth / NATIVE_UNIT_FRAME_WIDTH);
	local overlaySize = 11 * componentScale
	local buffFrame = scf.buffFrames[j]

	if strfind(uid,"pet") then 
		overlaySize = overlaySize * 1.55
	end
	
	if name then 

		if icon then
			buffFrame.icon:SetTexture(icon);
			buffFrame.icon:SetDesaturated(nil) --Destaurate Icon
			buffFrame.icon:SetVertexColor(1, 1, 1);
			buffFrame.icon:SetTexCoord(0.01, .99, 0.01, .99)
		end

		buffFrame.SpellId = spellId

		buffTooltip(buffFrame, uid, index, spellId, filter)

		if j == 4 or j == 5 or j == 6 or j == 7 then
			if name == GetSpellInfo(21562) then --Fort
				--ActionButton_ShowOverlayGlow(buffFrame)
			else
				ActionButton_HideOverlayGlow(buffFrame)
			end
			SetPortraitToTexture(buffFrame.icon, icon)
			buffFrame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
		end

		if j == 8 then
			scf.buffFrames[4]:ClearAllPoints() -- Buff Icons
			scf.buffFrames[4]:SetPoint("RIGHT", f, "RIGHT", -5.5, 5)
		end

		if j == 13 then
			if count == 1 or count == 2 then
				buffFrame.count:SetTextColor(.9, 0 ,0, 1)
			elseif count == 3 or count == 4 then 
				buffFrame.count:SetTextColor(1, 1 ,0, 1)
			else
				buffFrame.count:SetTextColor(1, 1 ,1, 1)
			end
		end



		buffCount(buffFrame, count, backCount)

		buffFrame:SetID(j);
		if expirationTime then
			local startTime = expirationTime - duration;
			if expirationTime - startTime > 60 then
				CooldownFrame_Clear(buffFrame.cooldown);
			else
				CooldownFrame_Set(buffFrame.cooldown, startTime, duration, true);
			end
		end
		buffFrame:SetSize(overlaySize*BUFFSIZE,overlaySize*BUFFSIZE);
		buffFrame:Show();
		
		if filter == "HARMFUL" then 
			local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
			buffFrame.debuffBorder:SetVertexColor(color.r, color.g, color.b, 1);
			buffFrame.debuffBorder:Show()
		else
			buffFrame.debuffBorder:Hide()
		end
		
	else
		if buffFrame then
			buffFrame:SetSize(overlaySize*BUFFSIZE,overlaySize*BUFFSIZE);
			buffFrame:Hide()
			--buffFrame.debuffBorder:Hide()
			if j == 8 then --BuffOverlay Right 
				scf.buffFrames[4]:ClearAllPoints() --Cleares SMall Buff Icon Positions
				scf.buffFrames[4]:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5.5, -6.5)
			end
		end
	end
end

function DebuffFilter:frameBuffs(scf, uid, tbl1, tbl2, tbl3)


	----------------------------------------------------------------------------------------------------------------------------------------------------------
	-- Main Row Used for Buff 123 and BOL, BOR
	----------------------------------------------------------------------------------------------------------------------------------------------------------
	if tbl1 then
		if tbl1[1] then
			local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, destGUID, position, index, filter = unpack(tbl1[1])


			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			----Two Debuff Conditions
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------------------------------
			--Icy Veins Stacks for Slick Ice
			-----------------------------------------------------------------------------------------------------------------
			if spellId == 12472 then
				for i = 1, 40 do
					local _, _, c, _, d, e, _, _, _, s = UnitAura(uid, i, "HELPFUL")
					if not s then break end
					if s == 382148 then
						count = c
					end
				end
			end

			-----------------------------------------------------------------------------------------------------------------------------------------------------------------
			--Icon Change
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------
			if spellId == 387636 then
				icon = 538745
			end

			-----------------------------------------------------------------------------------------------------------------
			--Barrier Check
			-----------------------------------------------------------------------------------------------------------------
			if spellId == 81782 then
				if unitCaster then 
					local guidCaster = UnitGUID(unitCaster)
					if guidCaster and Barrier[guidCaster] then
						duration = Barrier[guidCaster].duration
						expirationTime = Barrier[guidCaster].expiration
					end
				end
			end

			-----------------------------------------------------------------------------------------------------------------
			--Earthern Check
			-----------------------------------------------------------------------------------------------------------------
			if spellId == 201633 then -- Earthen Totem (Totems Need a Spawn Time Check)
				if unitCaster and not UnitIsEnemy("player", unitCaster) then
					local sourceGUID = UnitGUID(unitCaster)
					if Earthen[sourceGUID] then
						duration = Earthen[sourceGUID].duration
						expirationTime = Earthen[sourceGUID].expirationTime
					else
						local spawnTime
						local unitType, _, _, _, _, _, spawnUID = strsplit("-", sourceGUID)
						if unitType == "Creature" or unitType == "Vehicle" then
							local spawnEpoch = GetServerTime() - (GetServerTime() % 2^23)
							local spawnEpochOffset = bit_band(tonumber(substring(spawnUID, 5), 16), 0x7fffff)
							spawnTime = spawnEpoch + spawnEpochOffset
							--print("Earthen Buff Check at: "..spawnTime)
						end
						if Earthen[spawnTime] then
							duration = Earthen[spawnTime].duration
							expirationTime = Earthen[spawnTime].expirationTime
						end
					end
				end
			end

			--------------------------------------~---------------------------------------------------------------------------
			--Warbanner
			-----------------------------------------------------------------------------------------------------------------
			if spellId == 236321 then -- Warbanner (Totems Need a Spawn Time Check)
				if unitCaster and not UnitIsEnemy("player", unitCaster) then
					if WarBanner[UnitGUID(unitCaster)] then
						duration = WarBanner[UnitGUID(unitCaster)].duration
						expirationTime = WarBanner[UnitGUID(unitCaster)].expirationTime
					end
				end
			end

			if spellId == 321686 or spellId == 248280 or spellId == 102693 then -- Trees and Mirror Image Count
				local sourceGUID = UnitGUID(uid)
				if not count then count = 0 end
				for i = 1, #CLEUBOR[sourceGUID] do
					if CLEUBOR[sourceGUID][i][10] == 321686  or CLEUBOR[sourceGUID][i][10] == 248280 or CLEUBOR[sourceGUID][i][10] == 102693 then
						count = count + 1
					end
				end
			end

			DebuffFilter:SetBuffIcon(scf, uid, tbl1.j, name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, destGUID, position, index, filter, tbl1.BUFFSIZE)
		else
			DebuffFilter:SetBuffIcon(scf, uid, tbl1.j, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,nil, nil, nil, nil,nil, tbl1.BUFFSIZE)
		end
	end

	----------------------------------------------------------------------------------------------------------------------------------------------------------
	-- Used for Raid Buffs
	----------------------------------------------------------------------------------------------------------------------------------------------------------
	if tbl2 then
		if tbl2[1] then 
			local j = 4
			for i = 1, 4 do  
				if tbl2[i] then
					local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, destGUID, position, index, filter = unpack(tbl2[i])
					DebuffFilter:SetBuffIcon(scf, uid, j, name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, destGUID, position, index, filter, tbl2.BUFFSIZE)
				else
					DebuffFilter:SetBuffIcon(scf, uid, j, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,nil, nil, nil, nil,nil, tbl2.BUFFSIZE)
				end
				j = j + 1
			end
		else
			for j = 4, 7 do  
				DebuffFilter:SetBuffIcon(scf, uid, j, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,nil, nil, nil, nil,nil, tbl2.BUFFSIZE)
			end
		end
	end

	----------------------------------------------------------------------------------------------------------------------------------------------------------
	-- Used for row 2 Buffs j == 10  to 12 , Mainly Druid Healing 
	----------------------------------------------------------------------------------------------------------------------------------------------------------
	if tbl3 then 		
		if tbl3[1] then 
			local j = 10
			for i = 1, 3 do  
				if tbl3[i] then
					local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, destGUID, position, index, filter = unpack(tbl3[i])
					DebuffFilter:SetBuffIcon(scf, uid, j, name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, destGUID, position, index, filter, tbl3.BUFFSIZE)
				else
					DebuffFilter:SetBuffIcon(scf, uid, j, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,nil, nil, nil, nil,nil, tbl3.BUFFSIZE)
				end
				j = j + 1
			end
		else
			for j = 10, 12 do  
				DebuffFilter:SetBuffIcon(scf, uid, j, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,nil, nil, nil, nil,nil, tbl3.BUFFSIZE)
			end
		end
	end
end

local function compare_tbl1(a,b)
	return a[13] < b[13]
  end
  
  
  local function compare_tbl2(a, b)
	  if a[13] < b[13] then return true end
	  if a[13] > b[13] then return false end
	  return a[6] > b[6]
  end


local function Position(tbl, name, spellId)
	local position = tbl[name] or tbl[spellId]
	return position
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Filters Buff and Debuffs to Correct Loops
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DebuffFilter:BuffFilter(scf, uid, table)

	local buffTableBOL = {}; buffTableBOL.j = 9; buffTableBOL.BUFFSIZE = BOL_BUFF_SIZE
	local buffTableBOR = {}; buffTableBOR.j = 8; buffTableBOR.BUFFSIZE = BOR_BUFF_SIZE
	local buffTableBuff1 = {} buffTableBuff1.j = 1; buffTableBuff1.BUFFSIZE = row1BUFF_SIZE
	local buffTableBuff2 = {} buffTableBuff2.j = 2; buffTableBuff2.BUFFSIZE = row1BUFF_SIZE
	local buffTableBuff3 = {} buffTableBuff3.j = 3; buffTableBuff3.BUFFSIZE = row1BUFF_SIZE
	local buffTableBuffs = {}; buffTableBuffs.BUFFSIZE = SMALL_BUFF_SIZE
	local buffTableBuffs4 = {}; buffTableBuffs4.BUFFSIZE = row1BUFF_SIZE
	local MagicCountPlayerTableBuffs = {};MagicCountPlayerTableBuffs.j = 13; MagicCountPlayerTableBuffs.BUFFSIZE = SMALL_BUFF_SIZE
	local MagicCountPlayer = 0 
	local backCount
	
	for i = 1, 40 do
		local filter = "HELPFUL"
		local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura = UnitBuff(uid, i)
		if not name or not spellId then break end

		if table == "BOR" then
			if BORBuffs[name] or BORBuffs[spellId] then
				tblinsert(buffTableBOR, {name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, _, Position(BORBuffs, name, spellId), i, filter})
			elseif smallBuffs[name] or smallBuffs[spellId] then
				tblinsert(buffTableBuffs, {name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, _, Position(smallBuffs, name, spellId), i, filter})
			end
		end

		if table == "BOL" then
			if BOLBuffs[name] or BOLBuffs[spellId] then
				tblinsert(buffTableBOL, {name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, _, Position(BOLBuffs, name, spellId), i, filter})
			end
		end

		if table == "row1" and unitCaster == "player"then

			if (playerbackCount[name] or playerbackCount[spellId]) then 
				backCount = count 
			end 	--Prayer of mending hack

			if (row1Buffs[1][name] or row1Buffs[1][spellId]) then -- and unitCaster == "player" then
				tblinsert(buffTableBuff1, {name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, _, Position(row1Buffs[1], name, spellId), i, filter})
			elseif (row1Buffs[2][name] or row1Buffs[2][spellId]) then
				tblinsert(buffTableBuff2, {name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, _, Position(row1Buffs[2], name, spellId), i, filter})
			elseif (row1Buffs[3][name] or row1Buffs[3][spellId]) then
				tblinsert(buffTableBuff3, {name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, _, Position(row1Buffs[3], name, spellId), i, filter})
			end
		end

		if table == "row2" and unitCaster == "player"then
			if row2Buffs[name] or row2Buffs[spellId] then
				tblinsert(buffTableBuffs4, {name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, _, Position(row2Buffs, name, spellId), i, filter})
			end
		end


		if debuffType == "Magic" and UnitIsUnit(uid, "player") then 
			MagicCountPlayer = MagicCountPlayer + 1
		end
		if  MagicCountPlayer > 0 then 
			MagicCountPlayerTableBuffs[1] = {"MagicCount", nil, MagicCountPlayer, nil, nil, nil, nil, nil, nil, nil, nil, nil, 1, nil, nil}
		end
	end

	--[[for i = 1, 40 do
		local filter = "HARMFUL"
		local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura = UnitDebuff(uid, i)
		if not name or not spellId then break end
		if row1Buffs[1][name] or row1Buffs[1][spellId] then -- Currently Only Filtering Debuffs for Buff 1 Weakeend Soul
			tblinsert(buffTableBuff1, {name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, _, Position(row1Buffs[1], name, spellId), i, filter})
		end
	end]]

	local sourceGUID = UnitGUID(uid)
	if CLEUBOR[sourceGUID] then
		for k, v in pairs(CLEUBOR[sourceGUID]) do
			tblinsert(buffTableBOR, v )
		end
	end


	if table == "row1" then
		tblsort(buffTableBuff1, compare_tbl1)
		tblsort(buffTableBuff2, compare_tbl1)
		tblsort(buffTableBuff3, compare_tbl1)
		if backCount then
			buffTableBuff3[1][3] = backCount
		end
		self:frameBuffs(scf, uid, buffTableBuff1)
		self:frameBuffs(scf, uid, buffTableBuff2)
		self:frameBuffs(scf, uid, buffTableBuff3)
	end

	if table == "row2" then
		tblsort(buffTableBuffs4, compare_tbl1)
		self:frameBuffs(scf, uid, nil, nil, buffTableBuffs4) -- Used for row 2 Buffs j == 10  to 12 , Mainly Druid Healing 
	end

	if table == "BOR" then
		tblsort(buffTableBOR, compare_tbl1)
		tblsort(buffTableBOR, compare_tbl2)
		tblsort(buffTableBuffs, compare_tbl1)
		self:frameBuffs(scf, uid, buffTableBOR, buffTableBuffs)
	end

	if table == "BOL" then
		tblsort(buffTableBOL, compare_tbl1)
		self:frameBuffs(scf, uid, buffTableBOL)
	end

	if UnitIsUnit(uid, "player") then
		self:frameBuffs(scf, uid, MagicCountPlayerTableBuffs)
	end

end




local function DebuffFilter_UpdateAuras(scf, unitAuraUpdateInfo, event)
	--print(event.." "..scf.displayedUnit)
	
	local debuffsChanged = false;
	local buffsRow1 = false;
	local buffsRow2 = false;
	local buffsBOR = false;
	local buffsBOL = false;
	local buffsBOC = false;

	--local weakenedSoul = false;


	local function HandleAura(aura)
		if aura then 
			if aura.isHarmful or aura.isBossAura then
				scf.debuffs[aura.auraInstanceID] = aura;
			elseif aura.isHelpful then
				scf.buffs[aura.auraInstanceID] = aura;
			end
		end
	end

	if unitAuraUpdateInfo == nil or unitAuraUpdateInfo.isFullUpdate or (scf.unit and scf.displayedUnit and scf.unit ~= scf.displayedUnit) or scf.debuffs == nil then
		scf.debuffs = {};scf.buffs = {}
		AuraUtil.ForEachAura(scf.displayedUnit, "HELPFUL", nil, HandleAura, true)
		AuraUtil.ForEachAura(scf.displayedUnit, "HARMFUL", nil, HandleAura, true)
		debuffsChanged = true;
		buffsRow1 = true;
		buffsRow2 = true;
		buffsBOR = true;
		buffsBOL = true;
		buffsBOC = true;
		--weakenedSoul = true;
	else
		if unitAuraUpdateInfo.addedAuras ~= nil then
			for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
				if aura and (aura.isHarmful or aura.isBossAura) then
					scf.debuffs[aura.auraInstanceID] = aura;
					debuffsChanged = true;
					--weakenedSoul = true;
				elseif aura and aura.isHelpful then
					scf.buffs[aura.auraInstanceID] = aura;
					if (aura.sourceUnit and aura.sourceUnit == "player") and ((aura.spellId and rowOneBuffs[aura.spellId]) or (aura.name and rowOneBuffs[aura.name])) then
						buffsRow1 = true
					end
					if (aura.sourceUnit and aura.sourceUnit == "player") and ((aura.spellId and row2Buffs[aura.spellId]) or (aura.name and row2Buffs[aura.name])) then
						buffsRow2 = true
					end
					if (aura.spellId and BORBuffs[aura.spellId]) or (aura.name and BORBuffs[aura.name]) or (aura.spellId and smallBuffs[aura.spellId]) or (aura.name and smallBuffs[aura.name]) then
						buffsBOR = true
					end
					if (aura.spellId and BOLBuffs[aura.spellId]) or (aura.name and BOLBuffs[aura.name]) then
						buffsBOL = true
					end
				end
			end
		end

		if unitAuraUpdateInfo.updatedAuraInstanceIDs ~= nil then
			for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
				local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(scf.displayedUnit, auraInstanceID)
				if aura and (aura.isHarmful or aura.isBossAura) then --todo: is aura shown, if not you do not need to fire
					scf.debuffs[aura.auraInstanceID] = aura;
					debuffsChanged = true;
					--weakenedSoul = true;
				elseif aura and aura.isHelpful then --todo: is aura, if not you do not need to fire
					scf.buffs[aura.auraInstanceID] = aura;
					if (aura.sourceUnit and aura.sourceUnit == "player") and ((aura.spellId and rowOneBuffs[aura.spellId]) or (aura.name and rowOneBuffs[aura.name])) then
						buffsRow1 = true
					end
					if (aura.sourceUnit and aura.sourceUnit == "player") and ((aura.spellId and row2Buffs[aura.spellId]) or (aura.name and row2Buffs[aura.name])) then
						buffsRow2 = true
					end
					if (aura.spellId and BORBuffs[aura.spellId]) or (aura.name and BORBuffs[aura.name]) or (aura.spellId and smallBuffs[aura.spellId]) or (aura.name and smallBuffs[aura.name]) then
						buffsBOR = true
					end
					if (aura.spellId and BOLBuffs[aura.spellId]) or (aura.name and BOLBuffs[aura.name]) then
						buffsBOL = true
					end
				end
			end
		end

		if unitAuraUpdateInfo.removedAuraInstanceIDs ~= nil then
			for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
				if scf.debuffs[auraInstanceID] ~= nil then --todo: is aura shown, if not you do not need to fire
					local aura = scf.buffs[auraInstanceID]
					scf.debuffs[auraInstanceID] = nil;
					debuffsChanged = true;
					--weakenedSoul = true;
				elseif scf.buffs[auraInstanceID] ~= nil then --todo: is aura shown, if not you do not need to fire
					local aura = scf.buffs[auraInstanceID]
					scf.buffs[auraInstanceID] = nil;
					if (aura.sourceUnit and aura.sourceUnit == "player") and ((aura.spellId and rowOneBuffs[aura.spellId]) or (aura.name and rowOneBuffs[aura.name])) then
						buffsRow1 = true
					end
					if (aura.sourceUnit and aura.sourceUnit == "player") and ((aura.spellId and row2Buffs[aura.spellId]) or (aura.name and row2Buffs[aura.name])) then
						buffsRow2 = true
					end
					if (aura.spellId and BORBuffs[aura.spellId]) or (aura.name and BORBuffs[aura.name]) or (aura.spellId and smallBuffs[aura.spellId]) or (aura.name and smallBuffs[aura.name]) then
						buffsBOR = true
					end
					if (aura.spellId and BOLBuffs[aura.spellId]) or (aura.name and BOLBuffs[aura.name]) then
						buffsBOL = true
					end
				end
			end
		end
	end

	if debuffsChanged then
		DebuffFilter:UpdateDebuffs(scf, scf.displayedUnit)
	end

	if buffsRow1 then
		DebuffFilter:BuffFilter(scf, scf.displayedUnit, "row1")
	end
	if buffsRow2 then
		DebuffFilter:BuffFilter(scf, scf.displayedUnit,  "row2")
	end
	if buffsBOR then
		DebuffFilter:BuffFilter(scf, scf.displayedUnit,  "BOR")
	end
	if buffsBOL then
		DebuffFilter:BuffFilter(scf, scf.displayedUnit, "BOL")
	end
	if buffsBOC then
	end

end


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Applys all Buff and Debuff Shell Icons to the Frame
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DebuffFilter:ApplyFrame(f)
	--print(f.displayedUnit)
	local frameWidth, frameHeight = f:GetSize()

	local componentScale = min(frameHeight / NATIVE_UNIT_FRAME_HEIGHT, frameWidth / NATIVE_UNIT_FRAME_WIDTH);
	local overlaySize =  11 * componentScale

	local scf = self.cache[f]

	if not scf.buffFrames then scf.buffFrames = {} end
	if not scf.debuffFrames then scf.debuffFrames = {} end

	for j = 1, DEFAULT_DEBUFF do
		scf.debuffFrames[j] = _G["scfDebuff"..f:GetName()..j] or CreateFrame("Button" , "scfDebuff"..f:GetName()..j, UIParent, "CompactDebuffTemplate")
		local debuffFrames = scf.debuffFrames[j]
		debuffFrames:ClearAllPoints()
		debuffFrames:SetParent(f)
		if j == 1 then
			if strfind(f.unit,"pet") then
				debuffFrames:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT",3, 3)
			else
				debuffFrames:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT",3,10)
			end
		else
			debuffFrames:SetPoint("BOTTOMLEFT",scf.debuffFrames[j-1],"BOTTOMRIGHT",0,0)
		end
		debuffFrames:SetSize(overlaySize, overlaySize)  --ensures position is prelocked before showing , avoids the growing of row
		debuffFrames:Hide()
	end
	for j = 1,#f.debuffFrames do
		f.debuffFrames[j]:Hide()
		f.debuffFrames[j]:SetScript("OnShow", function(self) self:Hide() end)
	end

	for j = 1, DEFAULT_BUFF do
		if strfind(f.unit,"pet") then
			if j == 8 then --BUffOverlay Right
				scf.buffFrames[j] = _G["scfPetBORBuff"..f:GetName()..j] or CreateFrame("Button" , "scfPetBORBuff"..f:GetName()..j, UIParent, "CompactAuraTemplate")
			elseif j == 9 then --BUffOverlay Left
				scf.buffFrames[j] = _G["scfPetBOLBuff"..f:GetName()..j] or CreateFrame("Button" , "scfPetBOLBuff"..f:GetName()..j, UIParent, "CompactAuraTemplate")
			elseif j == 14 then
				scf.buffFrames[j] = _G["scfPetBuff"..f:GetName()..j] or CreateFrame("Button" , "scfPetBuff"..f:GetName()..j, UIParent, "CompactDebuffTemplate")
			else
				scf.buffFrames[j] = _G["scfPetBuff"..f:GetName()..j] or CreateFrame("Button" , "scfPetBuff"..f:GetName()..j, UIParent, "CompactAuraTemplate")
			end
		else
			if j == 8 then --BUffOverlay Right
				scf.buffFrames[j] = _G["scfBORBuff"..f:GetName()..j] or CreateFrame("Button" , "scfBORBuff"..f:GetName()..j, UIParent, "CompactAuraTemplate")
			elseif j == 9 then --BUffOverlay Left
				scf.buffFrames[j] = _G["scfBOLBuff"..f:GetName()..j] or CreateFrame("Button" , "scfBOLBuff"..f:GetName()..j, UIParent, "CompactAuraTemplate")
			elseif j == 14 then
				scf.buffFrames[j] = _G["scfBuff"..f:GetName()..j] or CreateFrame("Button" , "scfBuff"..f:GetName()..j, UIParent, "CompactDebuffTemplate")
			else
				scf.buffFrames[j] = _G["scfBuff"..f:GetName()..j] or CreateFrame("Button" , "scfBuff"..f:GetName()..j, UIParent, "CompactAuraTemplate")
			end
		end
		local buffFrame = scf.buffFrames[j]
		buffFrame.cooldown:SetDrawSwipe(true)
		buffFrame.cooldown:SetSwipeColor(0, 0, 0, 0.7)
		buffFrame.cooldown:SetReverse(true)
		buffFrame:ClearAllPoints()
		buffFrame:SetParent(f)
		if j == 1 or j == 14 then --Buff One
			if not strfind(f.unit,"pet") then
				if j == 1 then 
					buffFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2.5, 9.5)
				else
					buffFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3.25, 10)
				end
			else
				if j == 1 then 
					buffFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2.5, 1)
				else
					buffFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3.25, 10)
				end
			end
		elseif j == 2 then --Buff Two
			buffFrame:SetPoint("BOTTOMRIGHT", scf.buffFrames[j-1], "BOTTOMLEFT", 0, 0)
		elseif j ==3 then --Buff Three
			buffFrame:SetPoint("BOTTOMRIGHT", scf.buffFrames[j-1], "BOTTOMLEFT", 0, 0)
		elseif j == 4 or j == 5 or j == 6 or j == 7 then
			if j == 4 then
				if not strfind(f.unit,"pet") then
					buffFrame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5.5, -6.5)
				else
					buffFrame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5.5, -6.5)
				end
			else
				if not strfind(f.unit,"pet") then
					buffFrame:SetPoint("RIGHT", scf.buffFrames[j -1], "LEFT", 0, 0)
				else
					buffFrame:SetPoint("RIGHT", scf.buffFrames[j -1], "LEFT", 0, 0)
				end
			end
				buffFrame:SetScale(.6)
		elseif j ==8 then --Upper Right Count Only)
			if not strfind(f.unit,"pet") then
				buffFrame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -1.5)
			else
				buffFrame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -1.5)
			end
			buffFrame:SetScale(1.15)
		elseif j ==9 then --Upper Left Count Only
			if not strfind(f.unit,"pet") then
				buffFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -1.5)
			else
				buffFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -1.5)
			end
			buffFrame:SetScale(1.15)
		elseif j == 10 or j == 11 or j == 12 then --Second Row 123
			if j == 10 then
				if not strfind(f.unit,"pet") then
					buffFrame:SetPoint("BOTTOM", scf.buffFrames[1], "TOP", 0, 0)
				else
					buffFrame:SetPoint("BOTTOM", scf.buffFrames[1], "TOP", 0, 0)
				end
			else
				if not strfind(f.unit,"pet") then
					buffFrame:SetPoint("RIGHT", scf.buffFrames[j -1], "LEFT", 0, 0)
				else
					buffFrame:SetPoint("RIGHT", scf.buffFrames[j -1], "LEFT", 0, 0)
				end
			end
		elseif j == 13 then --Second Row 123
			if not strfind(f.unit,"pet") then
				buffFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
			else
				--buffFrame:SetPoint("RIGHT", f, "RIGHT", 0, 0)
			end
		end
		if j == 1 or j == 2 or j == 3 or j == 10 or j == 11 or j == 12 or j == 14 then 
			if strfind(f.unit,"pet") then
				buffFrame.count:ClearAllPoints()
				buffFrame.count:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE") --, MONOCHROME")
				buffFrame.count:SetPoint("TOPRIGHT", -3, 4);
				buffFrame.count:SetJustifyH("RIGHT");
				buffFrame.count:SetTextColor(1, 1 ,0, 1)
			else
				buffFrame.count:ClearAllPoints()
				buffFrame.count:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") --, MONOCHROME")
				buffFrame.count:SetPoint("TOPRIGHT", -10, 6.5);
				buffFrame.count:SetJustifyH("RIGHT");
				buffFrame.count:SetTextColor(1, 1 ,0, 1)
			end
		elseif j == 13 then
			if strfind(f.unit,"pet") then
				buffFrame.count:ClearAllPoints()
				buffFrame.count:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE") --, MONOCHROME")
				buffFrame.count:SetPoint("RIGHT", 0,0);
				buffFrame.count:SetJustifyH("RIGHT");
				buffFrame.count:SetTextColor(1, 1 ,1, 1)
			else
				buffFrame.count:ClearAllPoints()
				buffFrame.count:SetFont("Fonts\\FRIZQT__.TTF", 10.5, "OUTLINE") --, MONOCHROME")
				buffFrame.count:SetPoint("RIGHT", 0, 2);
				buffFrame.count:SetJustifyH("RIGHT");
				buffFrame.count:SetTextColor(1, 1 ,1, 1)
			end
		else
			if strfind(f.unit,"pet") then
				buffFrame.count:ClearAllPoints()
				buffFrame.count:SetFont("Fonts\\FRIZQT__.TTF", 7, "OUTLINE") --, MONOCHROME")
				buffFrame.count:SetPoint("BOTTOMRIGHT", 3, -2);
				buffFrame.count:SetJustifyH("RIGHT");
			else
				buffFrame.count:ClearAllPoints()
				buffFrame.count:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE") --, MONOCHROME")
				buffFrame.count:SetPoint("BOTTOMRIGHT", 2, -4);
				buffFrame.count:SetJustifyH("RIGHT");
			end
		end
		
		buffFrame.debuffBorder = _G[buffFrame:GetName().."debuffBorder"] or buffFrame:CreateTexture(buffFrame:GetName().."debuffBorder", 'OVERLAY')
		buffFrame.debuffBorder:SetTexture("Interface/Buttons/UI-Debuff-Overlays")
		buffFrame.debuffBorder:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
		buffFrame.debuffBorder:SetAllPoints(buffFrame)

		buffFrame:SetSize(overlaySize, overlaySize) --ensures position is prelocked before showing , avoids the growing of row
		buffFrame:Hide()
	end
	for j = 1,#f.buffFrames do
		f.buffFrames[j]:Hide() --Hides Blizzards Frames
		f.buffFrames[j]:SetScript("OnShow", function(self) self:Hide() end)
	end
	f.dispelDebuffFrames[1]:SetAlpha(0); --Hides Dispel Icons in Upper Right
	f.dispelDebuffFrames[2]:SetAlpha(0); --Hides Dispel Icons in Upper Right
	f.dispelDebuffFrames[3]:SetAlpha(0); --Hides Dispel Icons in Upper Right
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Resets all Icons from the frame and the Events
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DebuffFilter:ResetFrame(f)
	local scf = self.cache[f]
	if scf.guid then 
		self.cache[scf.guid] = nil
	end
	if scf.displayedguid then
		self.cache[scf.displayedguid] = nil
	end
	for k,v in pairs(scf.debuffFrames) do
		if v then
			v:Hide()
		end
	end
	for k,v in pairs(scf.buffFrames) do
		if v then
			v:Hide()
		end
	end
	for j = 1,#f.debuffFrames do
		f.debuffFrames[j]:SetScript("OnShow",nil)
		f.debuffFrames[j]:SetScript("OnEnter",nil)
	end
	for j = 1,#f.buffFrames do
		f.buffFrames[j]:SetScript("OnShow",nil)
		f.buffFrames[j]:SetScript("OnEnter",nil)
	end
	scf:UnregisterAllEvents()
	scf:SetScript("OnEvent", nil)
	scf.debuff = nil
	scf.buffs = nil
	scf = nil
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Frame Handler
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function scf_OnEvent(self, event, ...)
	local arg1, arg2, arg3, arg4, arg5 = ...
	if ( event == 'PLAYER_ENTERING_WORLD' ) then
		DebuffFilter_UpdateAuras(self, nil, event)
	elseif ( event == 'ZONE_CHANGED_NEW_AREA' ) then
		DebuffFilter_UpdateAuras(self, nil, event)
	else
		local unitMatches = arg1 == self.unit or arg1 == self.displayedUnit
		if ( unitMatches ) then
			if ( event == 'UNIT_AURA' ) then
				local unitAuraUpdateInfo = arg2
				DebuffFilter_UpdateAuras(self, unitAuraUpdateInfo, event)
			end
		end
		--if ( unitMatches or arg1 == "player" then
		if ( unitMatches or arg1 == "player" )  then
			if ( event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" or event == "PLAYER_GAINS_VEHICLE_DATA" or event == "PLAYER_LOSES_VEHICLE_DATA" ) then
				if event == "UNIT_ENTERED_VEHICLE" or event == "PLAYER_GAINS_VEHICLE_DATA" then 
					self.vehicle = true 
				elseif event == "UNIT_EXITED_VEHICLE" or event == "PLAYER_LOSES_VEHICLE_DATA" then
					self.vehicle = nil
				end
				local f = _G[self.name]
				self:RegisterUnitEvent('UNIT_AURA', f.unit, f.displayedUnit)
				self:RegisterUnitEvent('PLAYER_GAINS_VEHICLE_DATA', f.unit, f.displayedUnit)
				self:RegisterUnitEvent('PLAYER_LOSES_VEHICLE_DATA', f.unit, f.displayedUnit)
				DebuffFilter_UpdateAuras(self, nil, event)
			end
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Frame Register
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function DebuffFilter:RegisterUnit(f, forced)
	local frame = _G["scf"..f:GetName()]
	local guid = UnitGUID(f.unit)
	local displayedguid = UnitGUID(f.displayedUnit) or UnitGUID(f.unit)

	if not guid or not displayedguid then return end
	if not forced and ( frame and frame.unit and frame.unit == f.unit and frame.displayedUnit == f.displayedUnit and frame.guid == guid and frame.displayedguid == displayedguid ) then return end 
	if forced and ( not f.unit or not f.displayedUnit ) then return end

	if not DebuffFilter.cache[f] then 
		DebuffFilter.cache[f] = frame or CreateFrame("Frame", "scf"..f:GetName()) 
	end

	local scf = DebuffFilter.cache[f]
	DebuffFilter.cache[guid] = DebuffFilter.cache[f]
	DebuffFilter.cache[displayedguid] = DebuffFilter.cache[f]
	scf.f = f
	scf.name = f:GetName()
	scf.guid = guid
	scf.displayedguid = displayedguid
	scf.unit = f.unit
	scf.displayedUnit = f.displayedUnit
	scf:SetScript("OnEvent", scf_OnEvent)
	--scf:RegisterUnitEvent('UNIT_PET', f.unit, f.displayedUnit)
	scf:RegisterUnitEvent('UNIT_AURA', f.unit, f.displayedUnit)
	scf:RegisterUnitEvent('PLAYER_GAINS_VEHICLE_DATA', f.unit, f.displayedUnit)
	scf:RegisterUnitEvent('PLAYER_LOSES_VEHICLE_DATA', f.unit, f.displayedUnit)
	scf:RegisterEvent('PLAYER_ENTERING_WORLD')
	scf:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	scf:RegisterEvent('UNIT_EXITED_VEHICLE')
	scf:RegisterEvent('UNIT_ENTERED_VEHICLE')

	DebuffFilter:ApplyFrame(f)
	DebuffFilter_UpdateAuras(scf, nil, "RegisterUnit "..f.unit)
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Finding Used Frames and Unused Fames from API
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function  DebuffFilter:findFrames(forced, event)
	--print("DebufF_Filter_Frames: "..event)
	if EditModeManagerFrame:UseRaidStylePartyFrames() then

		if not EditModeManagerFrame:ShouldRaidFrameShowSeparateGroups() then
			for i = 1, 80 do
				local f = _G["CompactRaidFrame"..i]
				if f and f.unit then
					self:RegisterUnit(f, forced)
				elseif self.cache[f] then 
					self:ResetFrame(f)
				end
			end
		elseif EditModeManagerFrame:ShouldRaidFrameShowSeparateGroups() then
			for i = 1, 8 do
				for j = 1, 5 do
					local f = _G["CompactRaidGroup"..i.."Member"..j]
					if f and f.unit then
						self:RegisterUnit(f, forced)
					elseif self.cache[f] then 
						self:ResetFrame(f)
					end
				end
			end
			for i = 1, 10 do
				local f = _G["CompactRaidFrame"..i]
				if f and f.unit and UnitIsPlayer(f.unit) and not strfind(f.unit, "target") then
					self:RegisterUnit(f, forced)
				elseif self.cache[f] then 
					self:ResetFrame(f)
				end
			end
		end
		for i = 1, 5 do
			local f = _G["CompactPartyFrameMember"..i]
			if f and f.unit then
				self:RegisterUnit(f, forced)
			elseif self.cache[f] then 
				self:ResetFrame(f)
			end
		end

		for i = 1, 5 do
			local f = _G["CompactPartyFramePet"..i]
			if f and f.unit then
				self:RegisterUnit(f, forced)
			elseif self.cache[f] then 
				self:ResetFrame(f)
			end
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--API Events
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
EditModeManagerFrame:HookScript("OnHide", function() 	 
	DebuffFilter:findFrames()
end)

EditModeManagerFrame:HookScript("OnShow", function() 	 
	DebuffFilter:findFrames()
	hooksecurefunc("CompactUnitFrame_UpdateAll", function(f)
		if EditModeManagerFrame:IsVisible() then
			if (not f) or (not f.unit) or (f and f.unit and (strmatch(f.unit, "target") or strmatch(f.unit, "nameplate"))) then return end
			if f:IsForbidden() then return end
			local name = f:GetName()
			if not name or not name:match("^Compact") then return end
			DebuffFilter:RegisterUnit(f, true)
		end
	end)
	hooksecurefunc("CompactUnitFrame_UnregisterEvents", function(f)
		if EditModeManagerFrame:IsVisible() then
			if DebuffFilter.cache[f] then
				DebuffFilter:ResetFrame(f)
			else
				return
			end
		end
	end)
	
end)


hooksecurefunc(CompactRaidFrameContainer, "SetGroupMode", function(groupMode)
	DebuffFilter:findFrames(false, "CompactRaidFrameContainer_SetGroupMode")
	--print("groupMode")
end)

hooksecurefunc(CompactRaidFrameContainer, "SetFlowFilterFunction", function(flowFilterFunc)
	DebuffFilter:findFrames(false,"CompactRaidFrameContainer_SetFlowFilterFunction")
	--print("flowFilterFunc")
end)

hooksecurefunc(CompactRaidFrameContainer, "SetGroupFilterFunction", function(groupFilterFunc)
	DebuffFilter:findFrames(false, "CompactRaidFrameContainer_SetGroupFilterFunction")
	--print("groupFilterFunc")
end)

hooksecurefunc(CompactRaidFrameContainer, "SetFlowSortFunction", function(flowSortFunc)
	DebuffFilter:findFrames(false, "CompactRaidFrameContainer_SetFlowSortFunction")
	--print("flowSortFunc")
end)

hooksecurefunc(CompactPartyFrame, "SetFlowSortFunction", function()
	DebuffFilter:findFrames(false, "CompactPartyFrame_SetFlowSortFunction")
end)

local function find_frames()
	DebuffFilter:findFrames()
end


-- Event handling
local function OnEvent(self,event,...)
	local arg1, arg2, arg3, arg4 = ...
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then 
		self:DFCLEU()
		self:BOLCLEU()
		self:BORCLEU()
		self:BOCCLEU()
	elseif ( event == 'GROUP_ROSTER_UPDATE' ) then
		self:findFrames(false, event)
	elseif ( event == 'UNIT_PET' ) then
		self:findFrames(false, event)
	elseif ( event == 'PLAYER_ENTERING_WORLD' ) then
		local CRFC =_G["CompactRaidFrameContainer"]
		local CPF = _G["CompactPartyFrame"]
		CPF:SetScript("OnShow", find_frames)
		CRFC:SetScript("OnShow", find_frames)
		CPF:SetScript("OnHide", find_frames)
		CRFC:SetScript("OnHide", find_frames)
		self:findFrames(true, event)
	elseif ( event == 'ZONE_CHANGED_NEW_AREA' ) then
		self:findFrames(true, event)
	end
end

DebuffFilter:SetScript("OnEvent", OnEvent)
DebuffFilter:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
DebuffFilter:RegisterEvent('PLAYER_ENTERING_WORLD')
DebuffFilter:RegisterEvent('ZONE_CHANGED_NEW_AREA')
DebuffFilter:RegisterEvent('GROUP_ROSTER_UPDATE')
DebuffFilter:RegisterEvent('UNIT_PET')

DebuffFilter_Force = CreateFrame('CheckButton', 'DebuffFilter_Force', DebuffFilter_Force, 'UICheckButtonTemplate')
DebuffFilter_Force:SetScript('OnClick', function() DebuffFilter:findFrames(true, "player"); print("DebuffFilter Forced") end)
