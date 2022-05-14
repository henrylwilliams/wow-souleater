local frame = CreateFrame("Frame")

function SoulEaterAnnounce(msg)
	local SeAnnounceChat = SeAnnounceMode
	if SeAnnounceMode=="SELF" then
		print(msg)
		return
	elseif SeAnnounceMode == "AUTO" then
		if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
			SeAnnounceChat = "INSTANCE_CHAT"
		elseif IsInRaid() then
			SeAnnounceChat = "RAID"
		elseif IsInGroup() then
			SeAnnounceChat = "PARTY"
		end
	end
	SendChatMessage(msg,SeAnnounceChat)
end

local function handler (msg)
	msg=string.upper(msg)
	if msg == 'ON' or msg == 'OFF' then
		SeState = (msg == 'ON')
		if SeState then
			frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		else
			frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
		print("SoulEater is now |CFF7EBFF1"..(SeState and "On" or "Off").."|r.")
		
	elseif msg == 'AUTO' or msg == 'SELF' then
			SeAnnounceMode = msg
		print("SoulEater is now set for announcing to |CFFFF0303"..SeAnnounceMode.."|r.")
		
	else
		print("SoulEater is |CFF20C000"..(SeState and "ENABLED" or "DISABLED").."|r and in |CFF20C000"..SeAnnounceMode.."|r mode.\nCommands:\non/off, auto/self\n\nExmaple: /se auto")
	end
end

SlashCmdList["SOULEATER"] = handler;
SLASH_SOULEATER1 = "/se"

local brSpells = {
	[231811] = true, 	-- Warlock, Soulstone R2
	[20707] = true, 	-- Warlock, Soulstone
	[95750] = true, 	-- Warlock, Soulstone Resurrection
	[20484] = true, 	-- Druid, Rebirth
	[61999] = true, 	-- Death Knight, Raise Ally
	[54732] = true, 	-- Engineering, Defibrillate
	[348479] = true, 	-- Engineering, Unstable Temporal Time Shifter
	[348477] = true, 	-- Engineering, Disposable Spectrophasic Reanimator
}

local wipeProtection = {
	["Soulstone"] = true, -- Warlock Soulstone
}

local stunSpells = {
	[30283] = true,		-- Warlock, Shadowfury
}

local ccSpells = {
	[710] = true,		-- Warlock, Banish
	[5782] = true,		-- Warlock, Fear
	[6789] = true,		-- Warlock, Mortal Coil
}

local curseSpells = {
	[702] = true,		-- Curse of Weakness
	[1714] = true,		-- Curse of Tongues
	[334275] = true,	-- Curse of Exhaustion
}

local helpfulSpells = {
	[29893] = true, 	-- Create Soulwell
	[698] = true,		-- Riutal of Summoning
}

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("READY_CHECK")

frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		if SeState == nil then
			SeState = true
		end
		
		if SeAnnounceMode == nil then
			SeAnnounceMode = "AUTO"
		elseif SeAnnounceMode ~= string.upper(SeAnnounceMode) then
			SeAnnounceMode = string.upper(SeAnnounceMode)
		end
		
		if SeState == true then
			frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		else
			frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
	elseif event == "READY_CHECK" then
		local ssCount = 0
		local hasWarlock = false

		for i = 1, MAX_RAID_MEMBERS do
			local unit = format("%s%i", 'raid', i)
			local unit = nil
			local isInRaid = IsInRaid()

			if isInRaid then
				unit = format("%s%i", 'raid', i)
			else 
				unit = format("%s%i", 'party', i)
			end
			
			local name = AuraUtil.FindAuraByName("Soulstone", unit)
			if(name) then
				ssCount = ssCount + 1
			end

			localizedClass, englishClass, classIndex = UnitClass("player");
			if classIndex and classIndex == 9 then
				hasWarlock = true
			end
		end

		if ssCount > 0 and hasWarlock then
			SoulEaterAnnounce("[SE]: Soulstone found, wipe recovery is {triangle}{triangle}GOOD{triangle}{triangle}!")
		elseif ssCount <= 0 and hasWarlock then
			SoulEaterAnnounce("[SE]: {cross}{cross}Soulstone NOT found; Warlock SS someone before pull!{cross}{cross}")
		else
			print("SoulEater - There is currently no Warlock found in party/raid.")
		end
	else
		local _, event, _, _, sourceName, _, _, _, destName, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()		
		local gNum=GetNumGroupMembers()
		local incombat = InCombatLockdown()
		if !incombat then
			incombat = UnitAffectingCombat("party1")
		end
		
		if !incombat then
			incombat = UnitAffectingCombat("player")
		end

		-- Check for BR Spells
		if SeState and brSpells[spellID] and gNum > 0 and (event=="SPELL_CAST_SUCCESS") then
			if (UnitPlayerOrPetInParty(sourceName) or UnitPlayerOrPetInRaid(sourceName)) then
				if UnitIsPlayer(sourceName) then
					if incombat then
						SoulEaterAnnounce("[SE]: "..sourceName.." is resurrecting "..destName.." with {skull}"..GetSpellLink(spellID).."{skull}!")
					else
						SoulEaterAnnounce("[SE]: "..sourceName.." setup wipe recovery on "..destName.." with {skull}"..GetSpellLink(spellID).."{skull}!")
					end
				end
			end
		end

		-- Check for CC Spells
		if SeState and ccSpells[spellID] and gNum > 0 and (event=="SPELL_CAST_SUCCESS") then
			SoulEaterAnnounce("[SE]: "..sourceName.." casted {moon}"..GetSpellLink(spellID).."{moon} on "..destName.."!")
		end

		-- Check for Curse Spells
		if SeState and curseSpells[spellID] and gNum > 0 and (event=="SPELL_CAST_SUCCESS") then
			SoulEaterAnnounce("[SE]: "..sourceName.." cursed "..destName.." with {cross}"..GetSpellLink(spellID).."{cross}!")
		end

		-- Check for Helpful Spells
		if SeState and helpfulSpells[spellID] and gNum > 0 and (event=="SPELL_CAST_SUCCESS") then
			if spellID == 698 then 
				SoulEaterAnnounce("[SE]: "..sourceName.." is casting "..GetSpellLink(spellID).." {star}{star}{star}Please Click{star}{star}{star}")
			else
				SoulEaterAnnounce("[SE]: "..sourceName.." put down {circle}{circle}{circle}"..GetSpellLink(spellID).."{circle}{circle}{circle}")
			end
		end

		-- Check for Stun Spells
		if SeState and stunSpells[spellID] and gNum > 0 and (event=="SPELL_CAST_SUCCESS") then
			SoulEaterAnnounce("[SE]: "..sourceName.." stunned with {diamond}"..GetSpellLink(spellID).."{diamond}!")
		end
	end
end)
