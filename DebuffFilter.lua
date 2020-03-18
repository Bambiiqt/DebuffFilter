
local debuffnumber = 3

DebuffFilter = CreateFrame("Frame")
DebuffFilter.cache = {}

local DEFAULT_BUFF = 3
local DEFAULT_DEBUFF = 3

function DebuffFilter:OnLoad()

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("UNIT_AURA")
	CompactRaidFrameContainer:HookScript("OnEvent", DebuffFilter.OnRosterUpdate)
	CompactRaidFrameContainer:HookScript("OnHide", DebuffFilter.ResetStyle)
	CompactRaidFrameContainer:HookScript("OnShow", DebuffFilter.OnRosterUpdate)
end

-- When roster updated, auto apply arena style or reset style
function DebuffFilter:OnRosterUpdate()
	local _,areaType = IsInInstance()
	if not CompactRaidFrameContainer:IsVisible() then return end
	local n = GetNumGroupMembers()
	if n <= 40 then DebuffFilter:ApplyStyle() else DebuffFilter:ResetStyle() end
end

-- If in raid reset style
function DebuffFilter:OnZoneChanged()
	local _,areaType = IsInInstance()
	self:ResetStyle()
	--if areaType ~= "raid" then self:ApplyStyle() end
end

hooksecurefunc("CompactRaidFrameContainer_SetFlowSortFunction", function(_,_)
	DebuffFilter:ResetStyle()
	DebuffFilter:OnRosterUpdate()
end)

function DebuffFilter:ApplyStyle() ----- Find A Way to Always Show Debuffs
	if CompactRaidFrameManager.container.groupMode == "flush" then
		for i = 1,80 do
			local f = _G["CompactRaidFrame"..i]
			if f and not self.cache[f] and f.inUse and f.maxBuffs ~= 0 and #f.buffFrames == DEFAULT_BUFF and f.unit and not strfind(f.unit,"pet") and not strfind(f.unit,"target") then
				self:ApplyFrame(f)
				self:UpdateAura(f.unit)
			end
			if f and not f.inUse and self.cache[f] then
				self:ResetFrame(f)
			end
		end
	elseif CompactRaidFrameManager.container.groupMode == "discrete" then
		for i = 1,8 do
			for j = 1,5 do
				local f = _G["CompactRaidGroup"..i.."Member"..j]
				if f and not self.cache[f] and f.maxBuffs ~= 0 and #f.buffFrames == DEFAULT_BUFF and f.unit and not strfind(f.unit,"pet") and not strfind(f.unit,"target") then
					self:ApplyFrame(f)
					self:UpdateAura(f.unit)
				end
				if f and not f.unit and self.cache[f] then
					self:ResetFrame(f)
				end
				local f = _G["CompactPartyFrameMember"..j] --- Does
				if f and not self.cache[f] and f.maxBuffs ~= 0 and #f.buffFrames == DEFAULT_BUFF and f.unit and not strfind(f.unit,"pet") and not strfind(f.unit,"target") then
					self:ApplyFrame(f)
					self:UpdateAura(f.unit)
				end
				if f and not f.unit and self.cache[f] then
					self:ResetFrame(f)
				end
			end
		end
	end
end

-- data from LoseControl
local spellIds = {

--DONT SHOW
	[57723] = "Hide", --Exhaustion
	[57724] = "Hide", --Sated
	[264689] = "Hide", --Fatigued
	[80354] = "Hide", --Temporal Displacement
	[287825] = "Hide", --Lethargy
	[206151] = "Hide", --Challenger's Burden
	[295339] = "Hide", --Will to Survive
	[306474] = "Hide", --Recharging
	[313471] = "Hide", --Faceless Masks
---Priority--
	[317265] = "Priority", --Infinite Stars
---WARNINGS---
  --DEATH KNIGHT
  [123981] = "Warning", --Perdition
  --Mage
	[87024] = "Warning", --Cauterized
	[41425] = "Warning", --Hypothermia
  --ROGUE
	[45181] = "Warning", --Cheated Death
  --PALLY
	[25771] = "Warning", --Forbearance
	--DH
	[209261] = "Warning", --Uncontained Fel
	--GENERAL WARNINGS
	[46392] = "Warning", --Focused Assault (flag carrier, increasing damage taken by 10%)
	[195901]= "Warning", --Adapted
	[288756]= "Warning", --Gladiator's Safeguard

	[315179]= "Warning", --Inevitable Doom
	[315161]= "Warning", --Eye of Corruption
	[319695]= "Warning", --Grand Delusions
---GENERAL DANGER---
  --HUNTER
	--[209967] = "Biggest", -- Dire Beast: Basilisk
	--[202797] = "Bigger", -- Viper Sting
	--[202914] = "Bigger", -- Spider Sting
	--[202900] = "Big", -- Scorpid Sting
	--[203268] = "Big", -- Sticky Tar
	--[131894] = "Big", -- A Murder of Crows
  --SHAMAN
	--[208997] = "Big", -- Counterstrike Totem
	--[206647] = "Big", -- Electrocute
	--DEATH KNIGHT
	--[77606] = "Biggest", -- Dark Simulacrum
	--[130736] = "Big", -- Soul Reaper
	--[48743] = "Big", -- Death Pact
	[233397] = "Warning", -- Delirium
	[214975] = "Warning", -- Heartstop Aura
	[199719] = "Warning", -- Heartstop Aura
	--DRUID
	--[232559] = "Big", -- Thorns
	--[236021] = "Big", -- Ferocious Wound
	--[200947] = "Big", -- Encroaching Vines
	--MONK
	[115080] = "Biggest", -- Touch of Death
	[122470] = "Bigger", -- Touch of Karma
	[124280] = "Big", -- Touch of Karma Dot
  --PALLY
	--[206891] = "Big", -- Focused Assault
  --PRIEST
	--[205369] = "Bigger", -- Mind Bomb
	--[199845] = "Bigger", --Psyflay
	--[247777] = "Big", --Mind Trauma
	--[214621] = "Big", --Schism
	--ROGUE
	[79140] = "Biggest", -- Vendetta
	[198259] ="Biggest", --Plunder Armor
	--[197091] ="Biggest", --Neurotoxin
	[197051] = "Warning", --Mind-Numbing Poison
	--LOCK
	--[80240] = "Bigger", -- Havoc
	--[200587] = "Bigger", -- Fel Fissure
	--[199954] = "Big", -- Curse of Fragility
	--[199890] = "Big", -- Curse of Tongues
	--[199892] = "Big", -- Curse of Weakness
	--[48181] = "Big", -- Haunt
	--[234877] = "Big", -- Curse of Shadows
	--[196414] = "Big", -- Eradication
		[233582] = "Warning", --Entrenched Flame
  --WARRIOR
  --[198819] = "Bigger", -- Sharpen
  --[236273] = "Big", -- Duel
  --[208086] = "Big", -- Colossus Smash
	--DEMON HUNTER
	[206649] = "Bigger", -- Eye of Leotheras
	--[206491] = "Big", -- Nemesis
	--[207744] = "Big", -- Fiery Brand
	--TRINKETS
	--[293491] = "Biggest", -- Cyclotronic Blast
	[302144] = "Bigger", -- Gladiator’s Maledict S2
	[294127] = "Bigger", -- Gladiator’s Maledict S2
	[305249] = "Bigger", -- Gladiator’s Maledict S3 (Absorb)
	[305252] = "Bigger", -- Gladiator’s Maledict S3 (On Hit Dot)
	[271465] = "Big", -- Rotcrusted Voodoo Doll
	[313148] = "Big", -- Obsidian Claw
	[318476] = "Big", -- Obsidian Claw

---PVE---
--RAID
--  [240559] = "Bigger", -- Incubation Fluid

--MYTHICS AFFIX'S
	[240559] = "Bigger", -- Grievous Wound
	[209858] = "Bigger", -- Necrotic Wound
	--Voidweaver Mal'thir
	[314411] = "Bigger", --Lingering Doubt
	[314406] = "Bigger", -- Crippling Pestilence
	--Samh'rek, Beckoner of Chaos
	[314478] = "Bigger", --Cascading Terror
	[314531] = "Bigger", --Tear Flesh
	--Urg'roth, Breaker of Heroes
	[314308] = "Bigger", --Spirit Breaker

--VISIONS OF ORG
	[297315] = "Bigger", -- Void Buffet
	[298510] = "Bigger", -- Aqiri Mind Toxin

--FREEHOLD
	[257436] = "Bigger", -- Poisoning Strike
	[257437] = "Bigger", -- Poisoning Strike
	[258323] = "Bigger", -- Infected Wound
	[257775] = "Bigger", -- Plague Step
	[274555] = "Bigger", -- Scabrous Bite
	[278467] = "Bigger", -- Caustic Freehold Brew
	[257739] = "Bigger", -- Blind Rage
	[256363] = "Bigger", -- Ripper Punch
	[257908] = "Bigger", -- Oiled Blade

--KING'S REST
	[265773] = "Bigger", -- Spit Gold (265773)
	[265914] = "Bigger", -- Molten Gold (265914)
	[270084] = "Bigger", -- Axe Barrage (270084)
	[270865] = "Bigger", -- Hidden Blade (270865)
	[271564] = "Bigger", -- Embalming Fluid (271564)
	[267763] = "Bigger", -- Wretched Discharge
	[267618] = "Bigger", -- Drain Fluids (267618)
	[267626] = "Bigger", -- Dessication (267626)
	[270487] = "Bigger", -- Severing Blade (270487)
	[270507] = "Bigger", -- Poison Barrage (270507) (WA for Fixated)
	[266238] = "Bigger", -- Shattered Defenses (266238)
	[266231] = "Bigger", -- Severing Axe (266231)
	[267273] = "Bigger", -- Pioson Nova ???
	[272388] = "Bigger", -- Shadow Barrage (272388)
	--[] = "Bigger", -- Pool of Darkness ???
	[271640] = "Bigger", -- Dark Revelation (271640)

--WAYCREST MANOR
	[260703] = "Bigger", -- Unstable Runic Mark (260703)
	[268088] = "Bigger", --Aura of Dread (268088)[Doesnt Work!]
	[260741] = "Bigger", --Jagged Nettles (260741)
	------- RIght Room 1
	[263943] = "Biggest", --Etch
	[263905] = "Bigger", --Marking Cleave
	[264520] = "Big", --Serving Serpent
	--------Right Hall Way 1
	[271178] = "Bigger", --Ravaging Leap
	--------Court Yard
	[265761] = "Biggest", --Thorned Barrage
	[264556] = "Bigger", --Tearing Strike
	[264050] = "Big", --Infected Thorn
	--------Left Room (sisters)
	[266036] = "Biggest", --Drain Essence
	[266035] = "Bigger", --Bone Splinter
	--------Downstairs Hall
	[265881] = "Biggest", --Decaying Touch
	[265880] = "Bigger", --Dread Mark
	[265882] = "Warning", --Lingering Dread
	--------Downstairs
	[264378] = "Biggest", --Fragment Souls
	[264105] = "Bigger", --Runic Mark

--UNDERROT
	[265019] = "Bigger", -- Savage Cleave
	[265568] = "Bigger", -- Dark Omen
	[266107] = "Bigger", -- Thirst For Blood
	[273226] = "Bigger", -- Decaying Spores
	[269301] = "Bigger", -- Putrid Blood

--TOL DAGOR
	[258079] = "Bigger", -- Massive Chomp
	[258128] = "Bigger", -- Debilitating Shout
	[257028] = "Bigger", -- Fuselighter
	[256038] = "Bigger", -- Deadeye
	[256105] = "Bigger", -- Explosive Burst

--TEMPLE OF SETHRALISS
	[266923] = "Bigger", -- Galvanize
	[263371] = "Bigger", -- Conduction
	[267027] = "Bigger", -- Cytotoxin
	[272699] = "Bigger", -- Venomous Spit

--ATAL'DAZAR
	[255558] = "Bigger", -- Tainted Blood
	[255582] = "Bigger", -- Molten Gold
	[252687] = "Bigger", -- Venomfang Strike
	[250096] = "Bigger", -- Wracking Pain (Yazma)
	[257407] = "Biggest", -- Pursuit (Rezan)
	[250372] = "Big", -- Lingering Nausea [Vol'kaal]
	[258723] = "Biggest", -- Grotesque Pool [Add Pool]
	[250585] = "Biggest", -- Toxic Pool [Vol'kaal]
	[260668] = "Biggest", -- Transfusion (Add)
	[255835] = "Biggest", -- Transfusion (Boss Priestess)
	[256577] = "Biggest", -- Soulfest (Yazma)
--SIEGE OF BORULAS
	[279893] = "Bigger", -- Blood in the Water
	[273470] = "Bigger", -- Gut Shot
	[257168] = "Bigger", -- Cursed Slash
	[257036] = "Bigger", -- Feral Charge
	[260954] = "Bigger", -- Iron Gaze
	[257459] = "Bigger", -- On the Hook
	[272588] = "Bigger", -- Rotting Wounds
	[275836] = "Bigger", -- Stinging Venom
	[272421] = "Warning", -- Sighted Artiller

--SHRINE OF THE STORM
	[264166] = "Bigger", -- Undertow
	[279893] = "Bigger", -- Blood in the Water
	[268322] = "Bigger", -- Touch of the Drowned
	[268214] = "Bigger", -- Carve Flash
	[267818] = "Bigger", -- Slicing Blast
	[267034] = "Bigger", -- Whispers of Power
	[274633] = "Bigger", -- Sundering Blow
	[268317] = "Bigger", -- Rip Mind

--MOTHERLODE
	[269298] = "Bigger", -- Widowmaker
	[259853] = "Bigger", -- Chemical Burn

--Operation - Workshop
	[294929] = "Biggest", -- Blazing Chomp (Boss 3)
}
local function isBiggestDebuff(unit, index, filter)
    local name, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unit, index, "HARMFUL");
		if spellIds[spellId] == "Biggest"  then
		return true
	else
		return false
	end
end

local function isBiggerDebuff(unit, index, filter)
    local name, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unit, index, "HARMFUL");
		if spellIds[spellId] == "Bigger"  then
		return true
	else
		return false
	end
end

local function isBigDebuff(unit, index, filter)
    local name, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unit, index, "HARMFUL");
		if spellIds[spellId] == "Big"  then
		return true
	else
		return false
	end
end

local function isWarning(unit, index, filter)
    local name, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unit, index, "HARMFUL");
		if spellIds[spellId] == "Warning" then
		return true
	else
		return false
	end
end


local function isPriority(unit, index, filter)
    local name, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unit, index, "HARMFUL");
		if spellIds[spellId] == "Priority" then
		return true
	else
		return false
	end
end

local function isDebuff(unit, index, filter)
    local name, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitAura(unit, index, "HARMFUL");
		if spellIds[spellId] == "Hide" then
		return false
	else
--print("isDebuff")
	  return true
	end
end
-- Update aura for each unit
function DebuffFilter:UpdateAura(uid)
	for f,v in pairs(self.cache) do
			if f.unit == uid then
			local filter = nil
			local debuffNum = 1
			local index = 1
			local hidedebuffs=0
			if ( f.optionTable.displayOnlyDispellableDebuffs ) then
				filter = "RAID"
			end
			--Biggest Debuffs
				while debuffNum <= debuffnumber do
					local debuffName = UnitDebuff(uid, index, nil)
					if ( debuffName ) then
							if ( --[===[ CompactUnitFrame_UtilShouldDisplayDebuff(uid, index, filter) and ]===] isBiggestDebuff(uid, index, nil)) then
							local debuffFrame = v.debuffFrames[debuffNum]
							local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId;
							name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = UnitDebuff(uid, index, filter);
							debuffFrame.filter = filter;
							debuffFrame.icon:SetTexture(icon);
							debuffFrame.SpellId = spellId
							debuffFrame:SetScript("OnEnter", function(self)
								GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
								GameTooltip:SetSpellByID(self.SpellId)
								GameTooltip:Show()
							end)
							debuffFrame:SetScript("OnLeave", function(self)
								GameTooltip:Hide()
							end)
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
							debuffFrame:SetID(index);
							local enabled = expirationTime and expirationTime ~= 0;
							if enabled then
							local startTime = expirationTime - duration;
							CooldownFrame_Set(debuffFrame.cooldown, startTime, duration, true);
							else
							CooldownFrame_Clear(debuffFrame.cooldown);
							end
							local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
							debuffFrame.border:SetVertexColor(color.r, color.g, color.b);
							debuffFrame:SetSize(f.buffFrames[3]:GetSize()*1.6,f.buffFrames[3]:GetSize()*1.6);
							debuffFrame:Show();
							debuffNum = debuffNum + 1
							hidedebuffs=1
						end
					else
						break
					end
					index = index + 1
				end
				index = 1
				--Bigger Debuff
				while debuffNum <= debuffnumber do
					local debuffName = UnitDebuff(uid, index, filter);
					if ( debuffName ) then
							if ( --[===[ CompactUnitFrame_UtilShouldDisplayDebuff(uid, index, filter) and ]===] isBiggerDebuff(uid, index, nil) and not isBiggestDebuff(uid, index, nil) and not isBigDebuff(uid, index, nil) and not isWarning(uid, index, nil) and not isPriority(uid, index, nil)) then
								local debuffFrame = v.debuffFrames[debuffNum]
								local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId;
								name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = UnitDebuff(uid, index, filter);
								debuffFrame.filter = filter;
								debuffFrame.icon:SetTexture(icon);
								debuffFrame.SpellId = spellId
								debuffFrame:SetScript("OnEnter", function(self)
									GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
									GameTooltip:SetSpellByID(self.SpellId)
									GameTooltip:Show()
								end)
								debuffFrame:SetScript("OnLeave", function(self)
									GameTooltip:Hide()
								end)
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
								debuffFrame:SetID(index);
								local enabled = expirationTime and expirationTime ~= 0;
								if enabled then
								local startTime = expirationTime - duration;
								CooldownFrame_Set(debuffFrame.cooldown, startTime, duration, true);
								else
								CooldownFrame_Clear(debuffFrame.cooldown);
								end
								local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
								debuffFrame.border:SetVertexColor(color.r, color.g, color.b);
								debuffFrame:SetSize(f.buffFrames[3]:GetSize()*1.4,f.buffFrames[3]:GetSize()*1.4);
								debuffFrame:Show();
								debuffNum = debuffNum + 1
						end
					else
						break
					end
					index = index + 1
				end
				index = 1
				--Big Debuff
				while debuffNum <= debuffnumber do
					local debuffName = UnitDebuff(uid, index, filter);
					if ( debuffName ) then
							if ( --[===[ CompactUnitFrame_UtilShouldDisplayDebuff(uid, index, filter) and ]===] isBigDebuff(uid, index, nil) and not isBiggestDebuff(uid, index, nil) and not isBiggerDebuff(uid, index, nil) and not isWarning(uid, index, nil) and not isPriority(uid, index, nil)) then
								local debuffFrame = v.debuffFrames[debuffNum]
								local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId;
								name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = UnitDebuff(uid, index, filter);
								debuffFrame.filter = filter;
								debuffFrame.icon:SetTexture(icon);
								debuffFrame.SpellId = spellId
								debuffFrame:SetScript("OnEnter", function(self)
									GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
									GameTooltip:SetSpellByID(self.SpellId)
									GameTooltip:Show()
								end)
								debuffFrame:SetScript("OnLeave", function(self)
									GameTooltip:Hide()
								end)
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
								debuffFrame:SetID(index);
								local enabled = expirationTime and expirationTime ~= 0;
								if enabled then
								local startTime = expirationTime - duration;
								CooldownFrame_Set(debuffFrame.cooldown, startTime, duration, true);
								else
								CooldownFrame_Clear(debuffFrame.cooldown);
								end
								local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
								debuffFrame.border:SetVertexColor(color.r, color.g, color.b);
								debuffFrame:SetSize(f.buffFrames[3]:GetSize()*1.4,f.buffFrames[3]:GetSize()*1.4);
								debuffFrame:Show();
								debuffNum = debuffNum + 1
						end
					else
						break
					end
					index = index + 1
				end
				index = 1
				--isBossDeBuff
				while debuffNum <= debuffnumber do
					local debuffName = UnitDebuff(uid, index, filter);
					if ( debuffName ) then
							if ( CompactUnitFrame_UtilIsBossAura(uid, index, filter, false) and not isBiggestDebuff(uid, index, nil) and not isBiggerDebuff(uid, index, nil) and not isBigDebuff(uid, index, nil) and not isWarning(uid, index, nil) and not isPriority(uid, index, nil)) then
								local debuffFrame = v.debuffFrames[debuffNum]
								local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId;
								name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = UnitDebuff(uid, index, filter);
								debuffFrame.filter = filter;
								debuffFrame.icon:SetTexture(icon);
								debuffFrame.SpellId = spellId
								debuffFrame:SetScript("OnEnter", function(self)
									GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
									GameTooltip:SetSpellByID(self.SpellId)
									GameTooltip:Show()
								end)
								debuffFrame:SetScript("OnLeave", function(self)
									GameTooltip:Hide()
								end)
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
								debuffFrame:SetID(index);
								local enabled = expirationTime and expirationTime ~= 0;
								if enabled then
								local startTime = expirationTime - duration;
								CooldownFrame_Set(debuffFrame.cooldown, startTime, duration, true);
								else
								CooldownFrame_Clear(debuffFrame.cooldown);
								end
								local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
								debuffFrame.border:SetVertexColor(color.r, color.g, color.b);
									--debuffFrame.border:Hide()
									debuffFrame:SetSize(f.buffFrames[3]:GetSize()*1.4,f.buffFrames[3]:GetSize()*1.4);
								debuffFrame:Show();
								debuffNum = debuffNum + 1
						end
					else
						break
					end
					index = index + 1
				end
				index = 1
				--isBossBuff
				while debuffNum <= debuffnumber do
					local debuffName = UnitBuff(uid, index, filter);
					if ( debuffName ) then
							if ( CompactUnitFrame_UtilIsBossAura(uid, index, filter, true)) then
								local debuffFrame = v.debuffFrames[debuffNum]
								local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId;
								name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = UnitBuff(uid, index, filter);
								debuffFrame.filter = filter;
								debuffFrame.icon:SetTexture(icon);
								debuffFrame.SpellId = spellId
								debuffFrame:SetScript("OnEnter", function(self)
									GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
									GameTooltip:SetSpellByID(self.SpellId)
									GameTooltip:Show()
								end)
								debuffFrame:SetScript("OnLeave", function(self)
									GameTooltip:Hide()
								end)
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
								debuffFrame:SetID(index);
								local enabled = expirationTime and expirationTime ~= 0;
								if enabled then
								local startTime = expirationTime - duration;
								CooldownFrame_Set(debuffFrame.cooldown, startTime, duration, true);
								else
								CooldownFrame_Clear(debuffFrame.cooldown);
								end
								local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
								debuffFrame.border:SetVertexColor(color.r, color.g, color.b);
								debuffFrame:SetSize(f.buffFrames[3]:GetSize()*1.4,f.buffFrames[3]:GetSize()*1.4);
								debuffFrame:Show();
								debuffNum = debuffNum + 1
						end
					else
						break
					end
					index = index + 1
				end
				index = 1
				--isWarning
				while debuffNum <= debuffnumber do
					local debuffName = UnitDebuff(uid, index, nil)
					if ( debuffName ) then
							if ( --[===[ CompactUnitFrame_UtilShouldDisplayDebuff(uid, index, filter) and ]===] isWarning(uid, index, nil) and not CompactUnitFrame_UtilIsBossAura(uid, index, filter, false) and not isBiggestDebuff(uid, index, nil) and not isBiggerDebuff(uid, index, nil) and not isBigDebuff(uid, index, nil) and not isPriority(uid, index, nil)) then
								local debuffFrame = v.debuffFrames[debuffNum]
								local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId;
								name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = UnitDebuff(uid, index, filter);
								debuffFrame.filter = filter;
								debuffFrame.icon:SetTexture(icon);
								debuffFrame.SpellId = spellId
								debuffFrame:SetScript("OnEnter", function(self)
									GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
									GameTooltip:SetSpellByID(self.SpellId)
									GameTooltip:Show()
								end)
								debuffFrame:SetScript("OnLeave", function(self)
									GameTooltip:Hide()
								end)
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
								debuffFrame:SetID(index);
								local enabled = expirationTime and expirationTime ~= 0;
								if enabled then
								local startTime = expirationTime - duration;
								CooldownFrame_Set(debuffFrame.cooldown, startTime, duration, true);
								else
								CooldownFrame_Clear(debuffFrame.cooldown);
								end
								local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
								debuffFrame.border:SetVertexColor(color.r, color.g, color.b);
								debuffFrame:SetSize(f.buffFrames[3]:GetSize()*1.15,f.buffFrames[3]:GetSize()*1.15);
								debuffFrame:Show();
								debuffNum = debuffNum + 1
						end
					else
						break
					end
					index = index + 1
				end
				index = 1
				--Prio
				while debuffNum <= debuffnumber do
					local debuffName = UnitDebuff(uid, index, nil)
					if ( debuffName ) then
							if ( --[===[ CompactUnitFrame_UtilShouldDisplayDebuff(uid, index, filter) and ]===] isPriority(uid, index, nil) and not CompactUnitFrame_UtilIsBossAura(uid, index, filter, false) and not isBiggestDebuff(uid, index, nil) and not isBiggerDebuff(uid, index, nil) and not isBigDebuff(uid, index, nil) and not isWarning(uid, index, nil)) then
								local debuffFrame = v.debuffFrames[debuffNum]
								local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId;
								name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = UnitDebuff(uid, index, filter);
								debuffFrame.filter = filter;
								debuffFrame.icon:SetTexture(icon);
								debuffFrame.SpellId = spellId
								debuffFrame:SetScript("OnEnter", function(self)
									GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
									GameTooltip:SetSpellByID(self.SpellId)
									GameTooltip:Show()
								end)
								debuffFrame:SetScript("OnLeave", function(self)
									GameTooltip:Hide()
								end)
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
								debuffFrame:SetID(index);
								local enabled = expirationTime and expirationTime ~= 0;
								if enabled then
								local startTime = expirationTime - duration;
								CooldownFrame_Set(debuffFrame.cooldown, startTime, duration, true);
								else
								CooldownFrame_Clear(debuffFrame.cooldown);
								end
								local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
								debuffFrame.border:SetVertexColor(color.r, color.g, color.b);
								debuffFrame:SetSize(f.buffFrames[3]:GetSize()*1,f.buffFrames[3]:GetSize()*1);
								debuffFrame:Show();
								debuffNum = debuffNum + 1
						end
					else
						break
					end
					index = index + 1
				end
				index = 1
				--BlizzardPriorityDebuff
				while debuffNum <= debuffnumber and hidedebuffs==0 do
					local debuffName = UnitDebuff(uid, index, nil)
					if ( debuffName ) then
							if ( CompactUnitFrame_UtilIsPriorityDebuff(uid, index, nil) and not CompactUnitFrame_UtilIsBossAura(uid, index, filter, false) and not isBiggestDebuff(uid, index, nil) and not isBiggerDebuff(uid, index, nil) and not isBigDebuff(uid, index, nil) and not isWarning(uid, index, nil) and not isPriority(uid, index, nil)) then
							local debuffFrame = v.debuffFrames[debuffNum]
							local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId;
							name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = UnitDebuff(uid, index, filter);
							debuffFrame.filter = filter;
							debuffFrame.icon:SetTexture(icon);
							debuffFrame.SpellId = spellId
							debuffFrame:SetScript("OnEnter", function(self)
								GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
								GameTooltip:SetSpellByID(self.SpellId)
								GameTooltip:Show()
							end)
							debuffFrame:SetScript("OnLeave", function(self)
								GameTooltip:Hide()
							end)
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
							debuffFrame:SetID(index);
							local enabled = expirationTime and expirationTime ~= 0;
							if enabled then
							local startTime = expirationTime - duration;
							CooldownFrame_Set(debuffFrame.cooldown, startTime, duration, true);
							else
							CooldownFrame_Clear(debuffFrame.cooldown);
							end
							local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
							debuffFrame.border:SetVertexColor(color.r, color.g, color.b);
							debuffFrame:SetSize(f.buffFrames[3]:GetSize()*1,f.buffFrames[3]:GetSize()*1);
							debuffFrame:Show();
							debuffNum = debuffNum + 1
						end
					else
						break
					end
					index = index + 1
				end
				index = 1
				--isDebuff
				while debuffNum <= debuffnumber and hidedebuffs==0 do
					local debuffName = UnitDebuff(uid, index, filter)
					if ( debuffName ) then
						if ( --[===[ CompactUnitFrame_UtilShouldDisplayDebuff(uid, index, filter) and ]===] isDebuff(uid, index, nil) and not CompactUnitFrame_UtilIsBossAura(uid, index, filter, false) and not isBiggestDebuff(uid, index, nil) and not isBiggerDebuff(uid, index, nil) and not isBigDebuff(uid, index, nil) and not isWarning(uid, index, nil) and not isPriority(uid, index, nil)) then
							local debuffFrame = v.debuffFrames[debuffNum]
							local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId;
							name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = UnitDebuff(uid, index, filter);
							debuffFrame.filter = filter;
							debuffFrame.icon:SetTexture(icon);
							debuffFrame.SpellId = spellId
							debuffFrame:SetScript("OnEnter", function(self)
								GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
								GameTooltip:SetSpellByID(self.SpellId)
								GameTooltip:Show()
							end)
							debuffFrame:SetScript("OnLeave", function(self)
								GameTooltip:Hide()
							end)
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
							debuffFrame:SetID(index);
							local enabled = expirationTime and expirationTime ~= 0;
							if enabled then
							local startTime = expirationTime - duration;
							CooldownFrame_Set(debuffFrame.cooldown, startTime, duration, true);
							else
							CooldownFrame_Clear(debuffFrame.cooldown);
							end
							local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
							debuffFrame.border:SetVertexColor(color.r, color.g, color.b);
							debuffFrame:SetSize(f.buffFrames[3]:GetSize()*1,f.buffFrames[3]:GetSize()*1);
							debuffFrame:Show();
							debuffNum = debuffNum + 1
						end
					else
						break
					end
					index = index + 1
				end
				for i=debuffNum, debuffnumber do
				local debuffFrame = v.debuffFrames[i];
				if debuffFrame then
					debuffFrame:Hide()
				end
			end
			break
		end
	end
end
-- Apply style for each frame
function DebuffFilter:ApplyFrame(f)
	self.cache[f] = {}
	local scf = self.cache[f]
	f:SetScript("OnSizeChanged",function() DebuffFilter:ResetFrame(f) DebuffFilter:ApplyFrame(f) end)
	if not scf.debuffFrames then scf.debuffFrames = {} end
	for j = 1, debuffnumber do
		if not scf.debuffFrames[j] then
			scf.debuffFrames[j] = CreateFrame("Button",nil,UIParent,"CompactDebuffTemplate")
			scf.debuffFrames[j].unit = f.unit
			scf.debuffFrames[j].baseSize = f.buffFrames[3]:GetSize()
			--scf.debuffFrames[j]:EnableMouse(false)
			if j == 1 then
				scf.debuffFrames[j]:ClearAllPoints()
				scf.debuffFrames[j]:SetParent(f)
				scf.debuffFrames[j]:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT",3,10)
			else
				scf.debuffFrames[j]:SetParent(f)
				scf.debuffFrames[j]:SetPoint("BOTTOMLEFT",scf.debuffFrames[j-1],"BOTTOMRIGHT",0,0)
			end
			--f.debuffFrames[j]:SetSize(f.buffFrames[3]:GetSize())
			scf.debuffFrames[j]:SetSize(f.buffFrames[3]:GetSize())
			scf.debuffFrames[j]:Hide()
		end
	end
	for j = 1,#f.debuffFrames do
		f.debuffFrames[j]:Hide()
		f.debuffFrames[j]:SetScript("OnShow",f.debuffFrames[j].Hide)
	end
end
-- Reset to the original style
function DebuffFilter:ResetStyle()
	for f,_ in pairs(DebuffFilter.cache) do
		DebuffFilter:ResetFrame(f)
	end
end
-- Reset style to each cached frame
function DebuffFilter:ResetFrame(f)
		for k,v in pairs(self.cache[f].debuffFrames) do
		if v then
				v:Hide()
		end
		end
	f:SetScript("OnSizeChanged",nil)
	for j = 1,#f.debuffFrames do
		f.debuffFrames[j]:SetScript("OnShow",nil)
	end
	self.cache[f] = nil
end

-- Event handling
local function OnEvent(self,event,...)
	if event == "VARIABLES_LOADED" then self:OnLoad()
	elseif event == "GROUP_ROSTER_UPDATE" or event == "UNIT_PET" then self:OnRosterUpdate()
	elseif event == "PLAYER_ENTERING_WORLD" then self:OnRosterUpdate()
	elseif event == "UNIT_AURA" then self:UpdateAura(...) end
end

DebuffFilter:SetScript("OnEvent",OnEvent)
DebuffFilter:RegisterEvent("VARIABLES_LOADED")
_G.DebuffFilter = DebuffFilter

--Test
