local toc, data = ...
local AddonId = toc.identifier
local TXT = Library.Translate

local initDone = false
local dialog = false

-- Initialiser waits until a Gadget is created before registering event handlers
-- This should be done in all gadgets to save on overhead when no gadget instances exist 
local function Init()
	table.insert(WT.Event.PlayerAvailable, {OnPlayerAvailable, AddonId, "BuffIcons_OnPlayerAvailable"})
	table.insert(Event.Stat, { Buffcalc, AddonId, "OnStat" })
	initDone = true
end
local function OnPlayerAvailable()
	
end

local TankMeters = {}

local BuffList = {}
local BuffFilter = {
	"Reef Barrier", -- 2% DR
	"Motif of Tenacity", -- 5% DR
	"Call of Stone", -- 5% DR
	"Ablative Coil", -- 30% DR
	"Sign of Anticipation", -- 3% Dodge/Parry/Block
	"Reinforcement", -- 6% Block amount
	"Sign of Faith", -- 7% DR
	"Link of Agony", -- 30% DR
	"Link of Suffering", -- 20% DR
	"Link of Misery", -- 10% DR
	"Link of Distress", -- 5% DR
	"Shadow Breach", -- 30% dodge
	"Doctrine of Glory", -- up to 20% DR
	"Healer's Covenant", -- 40% DR
	"Unstable Transformation", --50% DR
	"Precept of Refuge", -- 5% block
	"Phantom Blow", -- 2% DR
	"Rift Guard", --  7% DR
	"Soul Coalescence", -- up to 20% DR
	"Scatter the Shadows", -- 90% DR
	"Sidesteps", -- 50% dodge chance
	"Pacification", -- 0% +3% DR 3/3 pacification
	"Shield Defense", -- 35% DR
	"Aggressive Block", -- 3% block
	"Shield of the Chosen", -- 5% block
	"Life's Rapture", -- 10% DR
	"Aegis of the Light", -- 20% DR
	"Light's Benediction", -- 7% DR
	"Void", -- 1% +4% DR 2/2 devourer
	"Power Shield", -- 20% DR
	"Unstable Void", -- 5% DR
	"Crest of Entropy", -- 30% DR
	"Binding of Death", -- 5% DR
	"Crest of Consumption", -- 20% DR
	"Binding of Devouring Darkness", -- 5% DR
	"Brothers in Arms", -- 15% link
}

-- General config
local  selectClass = nil
local  CHKpassivemit = nil
--cleric talents

--local SLDclericpts = nil

--local SLDarmorofvirtue = nil
--local SLDstronghold = nil
--local SLDstalwartcitadel = nil
local SLDshieldoffaith = nil
--local SLDdevoutdeflection = nil
--local SLDthorvinslaw = nil
local SLDunshakablefaith = nil

--local SLDstrokeofgenius = nil
--local SLDopenminded = nil
--local SLDspeaksoftly = nil
--local SLDspiritguidance = nil
local SLDthickskinned = nil

-- local selUnitToTrack = nil
-- local chkTooltips = nil
-- local chkCancel = nil


--rogue

--local SLDroguepts = nil

local SLDonguard = nil -- 5% block 5% block amount 5/5
local SLDimprovedriftguard = nil -- 2% DR on rift guard 1/1

local SLDquickreflexes = nil
local SLDbolster = nil
local SLDboosteddefenses = nil 

-- warrior
	-- Paladin
local SLDstalwartshield = nil -- 2.5% block 5/5
local SLDunyieldingdefense = nil -- 3% block amount 3/3
local SLDpacification = nil -- 3% DR on pacification 3/3
	-- Reaver
local SLDpowerfromthemasses = nil --5% DR 5/5
	-- Void Knight
local SLDdevourer = nil -- +4% DR on void 2/2
	-- Warlord
local SLDdownanddirty = nil -- 4% DR 2/2

--calculations

local BuffBamount = 0
local BuffBchance = 0
local BuffDchance = 0
local BuffPchance = 0
local BuffDR = 0
local BuffDRlink = 0
local BuffDRshield = 0
local BuffDRactive = 0

local Buffpacification = false
local Buffvoid = false
local Buffriftguard = false


local function GetConfiguration()

	local config = {}

--general config

	config.class = selectClass:GetText()
	config.passivemit = CHKpassivemit:GetChecked()
	
--cleric	
	--config.clericpts = SLDclericpts:GetPosition()
	
	--config.armorofvirtue = SLDarmorofvirtue:GetPosition()
	--config.stronghold = SLDstronghold:GetPosition()
	--config.stalwartcitadel = SLDstalwartcitadel:GetPosition()
	config.shieldoffaith = SLDshieldoffaith:GetPosition()
	--config.devoutdeflection = SLDdevoutdeflection:GetPosition()
	--config.thorvinslaw = SLDthorvinslaw:GetPosition()
	config.unshakablefaith = SLDunshakablefaith:GetPosition()
	
	--config.strokeofgenius = SLDstrokeofgenius:GetPosition()
	--config.openminded = SLDopenminded:GetPosition()
	--config.speaksoftly = SLDspeaksoftly:GetPosition()
	--config.spiritguidance = SLDspiritguidance:GetPosition()
	config.thickskinned = SLDthickskinned:GetPosition()
	
	
--rogue	

	config.onguard = SLDonguard:GetPosition()
	config.improvedriftguard = SLDimprovedriftguard:GetPosition()
	config.quickreflexes = SLDquickreflexes:GetPosition()
	config.bolster = SLDbolster:GetPosition()
	config.boosteddefenses = SLDboosteddefenses:GetPosition()


--Warrior	

	config.stalwartshield = SLDstalwartshield:GetPosition()
	config.unyieldingdefense = SLDunyieldingdefense:GetPosition()
	config.pacification = SLDpacification:GetPosition()
	config.powerfromthemasses = SLDpowerfromthemasses:GetPosition()
	config.devourer = SLDdevourer:GetPosition()
	config.downanddirty = SLDdownanddirty:GetPosition()
	
	return config 
end

local function SetConfiguration(config)
--general config
	selectClass:SetText(config.class)
	CHKpassivemit:SetChecked(WT.Utility.ToBoolean(config.passivemit))
--Cleric
	--SLDclericpts:SetPosition(config.clericpts or 61)
	
	--SLDarmorofvirtue:SetPosition(config.armorofvirtue or 5)
	--SLDstronghold:SetPosition(config.stronghold or 5)
	--SLDstalwartcitadel:SetPosition(config.stalwartcitadel or 2)
	SLDshieldoffaith:SetPosition(config.shieldoffaith or 5)
	--SLDdevoutdeflection:SetPosition(config.devoutdeflection or 2)
	--SLDthorvinslaw:SetPosition(config.thorvinslaw or 3)
	SLDunshakablefaith:SetPosition(config.unshakablefaith or 2)
	
	--SLDstrokeofgenius:SetPosition(config.strokeofgenius or 5)
	--SLDopenminded:SetPosition(config.openminded or 5)
	--SLDspeaksoftly:SetPosition(config.speaksoftly or 5)
	--SLDspiritguidance:SetPosition(config.spiritguidance or 5)
	SLDthickskinned:SetPosition(config.thickskinned or 5)
	
--Rogue	 
	
	SLDonguard:SetPosition(config.onguard or 5)
	SLDimprovedriftguard:SetPosition(config.improvedriftguard or 1)
	SLDquickreflexes:SetPosition(config.quickreflexes or 0)
	SLDbolster:SetPosition(config.bolster or 3)
	SLDboosteddefenses:SetPosition(config.boosteddefenses or 0)

	
--Warrior	

	SLDstalwartshield:SetPosition(config.SLDstalwartshield or 5)
	SLDunyieldingdefense:SetPosition(config.unyieldingdefense or 3)
	SLDpacification:SetPosition(config.pacification or 3)
	SLDpowerfromthemasses:SetPosition(config.powerfromthemasses or 0)
	SLDdevourer:SetPosition(config.devourer or 0)
	SLDdownanddirty:SetPosition(config.downanddirty or 0)

end


local function CreateSlider(parent, placeUnder, text, minRange, maxRange, default)
	
	local label = UI.CreateFrame("Text", "txtSlider", parent)
	label:SetText(text)
	label:SetPoint("TOPLEFT", placeUnder, "BOTTOMLEFT", 0, 5)
	
	local slider = UI.CreateFrame("SimpleSlider", "sldSlider", parent)
	slider:SetRange(minRange, maxRange)
	slider:SetPosition(default)
	slider:SetPoint("TOPLEFT", label, "TOPLEFT", 150, 0)
	slider:SetWidth(200)
	
	slider.Label = label
	
	return slider
	
end


local function ConfigDialog(container)

-- Set up Tabs
	local tabs = UI.CreateFrame("SimpleTabView", "rfTabs", container)
	tabs:SetPoint("TOPLEFT", container, "TOPLEFT")
	tabs:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, -32)
	
	local configgeneral = UI.CreateFrame("Frame", "rfConfig", tabs.tabContent)
	local configgeneralInner = UI.CreateFrame("Frame", "bbConfigInner", configgeneral)
	configgeneralInner:SetPoint("TOPLEFT", configgeneral, "TOPLEFT", 12, 12)
	configgeneralInner:SetPoint("BOTTOMRIGHT", configgeneral, "BOTTOMRIGHT", -12, -12)
	
	local configcleric = UI.CreateFrame("Frame", "rfConfig", tabs.tabContent)
	local configclericInner = UI.CreateFrame("Frame", "bbConfigInner", configcleric)
	configclericInner:SetPoint("TOPLEFT", configcleric, "TOPLEFT", 12, 12)
	configclericInner:SetPoint("BOTTOMRIGHT", configcleric, "BOTTOMRIGHT", -12, -12)
	
	local configrogue = UI.CreateFrame("Frame", "rfMacros", tabs.tabContent)
	local configrogueInner = UI.CreateFrame("Frame", "bbFiltersInner", configrogue)
	configrogueInner:SetPoint("TOPLEFT", configrogue, "TOPLEFT", 4, 4)
	configrogueInner:SetPoint("BOTTOMRIGHT", configrogue, "BOTTOMRIGHT", -4, -4)

	local configwarrior = UI.CreateFrame("Frame", "rfMacros", tabs.tabContent)
	local configwarriorInner = UI.CreateFrame("Frame", "bbFiltersInner", configwarrior)
	configwarriorInner:SetPoint("TOPLEFT", configwarrior, "TOPLEFT", 4, 4)
	configwarriorInner:SetPoint("BOTTOMRIGHT", configwarrior, "BOTTOMRIGHT", -4, -4)

	tabs:SetTabPosition("top")
	tabs:AddTab("General Config", configgeneral)
	tabs:AddTab("Cleric", configcleric)
	tabs:AddTab("Rogue", configrogue)	
	tabs:AddTab("Warrior", configwarrior)	
	
-- general config tab

	selectClass = WT.Control.Select.Create(configgeneralInner, "Class:", "Cleric", 
	{ 
		{text = "Cleric", value = "Cleric"}, 
		{text = "Rogue", value = "Rogue"}, 
		{text = "Warrior", value = "Warrior"}, 
	})
	
	selectClass:SetPoint("TOPLEFT", configgeneralInner, "TOPLEFT", 5, 5)
	
	CHKpassivemit = UI.CreateFrame("SimpleCheckbox", "CHKpassivemit", configgeneralInner)
	CHKpassivemit:SetText("Passive Mitigation only");
	CHKpassivemit:SetChecked(false)
	CHKpassivemit:SetPoint("TOPLEFT", selectClass, "BOTTOMLEFT", 0, 5)
	
-- Cleric tab
	
	-- SLDclericpts = CreateSlider(configclericInner, configclericInner, "Justicar Points:", 16, 61, 61)
	-- SLDclericpts.Label:SetPoint("TOPLEFT", configclericInner, "TOPLEFT", 4, 4)
	-- SLDclericpts:SetWidth(350)
	
	--SLDarmorofvirtue = CreateSlider(configclericInner, SLDclericpts.Label, "Armor of Virtue:", 0, 5, 5)
	--SLDstronghold = CreateSlider(configclericInner, SLDarmorofvirtue.Label, "Stronghold:", 0, 5, 5)
	--SLDstalwartcitadel = CreateSlider(configclericInner, SLDstronghold.Label, "Stalwart Citadel:", 0, 2, 2)
	SLDshieldoffaith = CreateSlider(configclericInner, configclericInner, "Shield of Faith:", 0, 5, 5)
	SLDshieldoffaith.Label:SetPoint("TOPLEFT", configclericInner, "TOPLEFT", 4, 4)
	--SLDdevoutdeflection = CreateSlider(configclericInner, SLDshieldoffaith.Label, "Devout Deflection:", 0, 2, 2)
	--SLDthorvinslaw = CreateSlider(configclericInner, SLDdevoutdeflection.Label, "Thorvin's Law:", 0, 3, 3)
	SLDunshakablefaith = CreateSlider(configclericInner, SLDshieldoffaith.Label, "Unshakable Faith:", 0, 2, 2)
	
	--SLDstrokeofgenius = CreateSlider(configclericInner, SLDunshakablefaith.Label, "Stroke of Genius:", 0, 5, 0)
	--SLDstrokeofgenius.Label:SetPoint("TOPLEFT", SLDunshakablefaith.Label, "TOPLEFT", 0, 50)	
	--SLDopenminded = CreateSlider(configclericInner, SLDstrokeofgenius.Label, "Open Minded:", 0, 5, 0)
	--SLDspeaksoftly = CreateSlider(configclericInner, SLDopenminded.Label, "Speak Softly:", 0, 5, 0)
	--SLDspiritguidance = CreateSlider(configclericInner, SLDspeaksoftly.Label, "Spirit Guidance:", 0, 5, 0)
	SLDthickskinned = CreateSlider(configclericInner, SLDunshakablefaith.Label, "Thick Skinned:", 0, 5, 5)
	
	
-- Rogue tab
	
	SLDonguard = CreateSlider(configrogueInner, configrogueInner, "On Guard:", 0, 5, 5)
	SLDonguard.Label:SetPoint("TOPLEFT", configrogueInner, "TOPLEFT", 4, 4)
	SLDimprovedriftguard = CreateSlider(configrogueInner, SLDonguard.Label, "Improved Rift Guard:", 0, 1, 1)
	SLDquickreflexes = CreateSlider(configrogueInner, SLDimprovedriftguard.Label, "Quick Reflexes:", 0, 5, 0)
	SLDbolster = CreateSlider(configrogueInner, SLDquickreflexes.Label, "Bolster:", 0, 3, 3)
	SLDboosteddefenses = CreateSlider(configrogueInner, SLDbolster.Label, "Boosted Defenses:", 0, 3, 0)
	
	

--Warrior tab	
	
	SLDstalwartshield = CreateSlider(configwarriorInner, configwarriorInner, "Stalwart Shield:", 0, 5, 0)
	SLDstalwartshield.Label:SetPoint("TOPLEFT", configwarriorInner, "TOPLEFT", 4, 4)
	SLDunyieldingdefense = CreateSlider(configwarriorInner, SLDstalwartshield.Label, "Unyielding Defense:", 0, 5, 0)
	SLDpacification = CreateSlider(configwarriorInner, SLDunyieldingdefense.Label, "Pacification:", 0, 3, 0)
	SLDpowerfromthemasses = CreateSlider(configwarriorInner, SLDpacification.Label, "Power from the Masses:", 0, 5, 0)
	SLDdevourer = CreateSlider(configwarriorInner, SLDpowerfromthemasses.Label, "Devourer:", 0, 2, 0)
	SLDdownanddirty = CreateSlider(configwarriorInner, SLDdevourer.Label, "Down and Dirty:", 0, 2, 0)


end

local function EHPcalc()
	if not WT.Player then return end
	if not WT.Player.healthMax then return end
	
	-- local variables
	
	local config = {}
	local class = ""
	
	local Armor = Inspect.Stat("armor")
	local Block = (Inspect.Stat("block") + Inspect.Stat("deflect"))
	local Dodge = Inspect.Stat("dodge")
	local Parry = Inspect.Stat("parry")
	
	local Health = WT.Player.healthMax
	
	local TalentDR = 0
	local TalentBamount = 0
	local TalentBchance = 0
	local TalentDchance = 0
	local TalentPchance = 0
	
	local IRG = 0
	local pac = 0
	local void = 0
	
	local DT = 0
	local ArmMit = 0
	local DTafterarmor = 0
	local Dchance = 0
	local Pchance = 0
	local Bchance = 0
	
	local Bamount = 0
	local Achance = 0
	local Adamage = 0	
	local Amit = 0
	local Mit = ""
	local TEHP = ""
	
	 -- For each TankMeter do:
	
	for i, TankMeter in pairs(TankMeters) do
		config = TankMeters[i].configvalues
		class = config.class
		
		--print("class = " .. class)
		
		-- class based Talent configuration
		
		if class == "Cleric" then
		
			TalentDR = (config.shieldoffaith + config.thickskinned)/100
			TalentBamount = (config.unshakablefaith * 2)/100
			--print("TalentDR = " .. TalentDR)
			--print("TalentBamount = " .. TalentBamount)
			
		elseif class == "Rogue" then
		
			TalentDR = (config.bolster + config.boosteddefenses)/100
			TalentBamount = (config.onguard)/100
			TalentBchance = (config.onguard)/100
			TalentDchance = (config.quickreflexes)/100
			if Buffriftguard == true then IRG = .02 end
			--print("TalentDR = " .. TalentDR)
			--print("TalentBamount = " .. TalentBamount)
			--print("TalentBchance = " .. TalentBchance)
			--print("TalentDchance = " .. TalentDchance)
			
		elseif class == "Warrior" then
		
			TalentBchance = (config.stalwartshield/2)/100
			TalentBamount = (config.unyieldingdefense)/100
			TalentDR = (config.pacification + config.powerfromthemasses + config.downanddirty)/100
			if Buffpacification == true then pac = (config.pacification/100) end
			if Buffvoid == true then void = (config.devourer*2/100) end
			
		else
			
		end
		
		--Initial Damage Taken calculations
		passiveDT = (1-TalentDR)
		activeDT = (1-BuffDRactive-pac)
		buffDT = (1-BuffDR-void)
		shieldDT = (1-BuffDRshield-IRG)
		linkDT = (1-BuffDRlink)
		DT = (passiveDT * activeDT * shieldDT * linkDT * buffDT)
		ArmMit = (Armor/(Armor + 74570))
		DTafterarmor = (DT*(1-ArmMit))
		
		--Block, Dodge, Parry percent conversion
		
		Dchance = (math.min((Dodge/23563.2),.4) + TalentDchance + BuffDchance)
		Pchance = (math.min((Parry/23563.2),.4) + TalentPchance + BuffPchance)

		if (Block < 3535) then 
			Bchance =((Block/7853.1) + BuffBchance + TalentBchance)
		else
			Bchance =(.4 + ((Block-3535)/7853.1/3) + BuffBchance + TalentBchance)
		end
		
		Bamount = (.3 + TalentBamount + BuffBamount)
		
		--Final TEHP and Mit calculations
		
		Achance = (Pchance + (1-Pchance)*Dchance)
		Adamage = (DTafterarmor*(1-Achance)*(1-Bchance*Bamount))	
		
		if config.passivemit == true then
			Amit = (1-DTafterarmor)
			Mit = WT.Utility.TextConvertPercent(Amit, 1)
			TankMeter.txtMit:SetText("Mitigation:  " .. Mit)
			TEHP = WT.Utility.NumberComma(round((Health/DTafterarmor)))
			TankMeter.txtHeading:SetText("Effective HP:")
		else
			Amit = (1-Adamage)
			Mit = WT.Utility.TextConvertPercent(Amit, 1)
			TankMeter.txtMit:SetText("Avg. Mitigation:  " .. Mit)
			TEHP = WT.Utility.NumberComma(round((Health/Adamage)))
			TankMeter.txtHeading:SetText("Total Avg. Effective HP:")
		end

		TankMeter.txtEHP:SetLabelText(TEHP)

	end
end

local function Buffcalc()
	if BuffList == nil then EHPcalc() return end
	
	local Bamount = 0
	local Bchance = 0
	local Dchance = 0
	local Pchance = 0
	local DR = 0
	local linkDR = 0
	local shieldDR = 0
	local activeDR = 0
	
	for i, buff in pairs(BuffList) do
		--print("buff = " .. BuffList[i].name)
		if buff.name == "Precept of Refuge" then 
			Bchance = Bchance + .05
		elseif buff.name == "Reef Barrier" then 
			DR = DR + .02
		elseif buff.name == "Motif of Tenacity" then 
			DR = DR + .05
		elseif buff.name == "Call of Stone" then 
			DR = DR + .05
		elseif buff.name == "Ablative Coil" then 
			DR = DR + .3
		elseif buff.name == "Sign of Faith" then 
			DR = DR + .07
		elseif buff.name == "Link of Agony" then 
			linkDR = linkDR + .30
		elseif buff.name == "Link of Suffering" then 
			linkDR = linkDR + .20
		elseif buff.name == "Link of Misery" then 
			linkDR = linkDR + .10
		elseif buff.name == "Link of Distress" then 
			linkDR = linkDR + .05
		elseif buff.name == "Doctrine of Glory" then 
			activeDR = activeDR + .20
		elseif buff.name == "Unstable Transformation" then 
			DR = DR + .50
		elseif buff.name == "Healer's Covenant" then 
			DR = DR + .40
		elseif buff.name == "Phantom Blow" then 
			activeDR = activeDR + .02
		elseif buff.name == "Rift Guard" then 
			shieldDR = shieldDR + .05 -- +2% shieldDR 1/1 improved rift guard
			Buffriftguard = true
		elseif buff.name == "Soul Coalescence" then 
			activeDR = activeDR + .20
		elseif buff.name == "Scatter the Shadows" then 
			activeDR = activeDR + .40
		elseif buff.name == "Sidesteps" then 
			Dchance = Dchance + .50
		elseif buff.name == "Sign of Anticipation" then 
			Dchance = Dchance + .03
			Pchance = Pchance + .03
			Bchance = Bchance + .03
		elseif buff.name == "Reinforcement" then 
			Bamount = Bamount + .06
		elseif buff.name == "Pacification" then 
			Buffpacification = true --+3% DR 3/3 pacification
		elseif buff.name == "Shield Defense" then 
			activeDR = activeDR + .35
		elseif buff.name == "Aggressive Block" then 
			Bchance = Bchance + .03
		elseif buff.name == "Shield of the Chosen" then 
			Bchance = Bchance + .05
		elseif buff.name == "Life's Rapture" then 
			DR = DR + .10
		elseif buff.name == "Aegis of the Light" then 
			activeDR = activeDR + .20
		elseif buff.name == "Light's Benediction" then 
			activeDR = activeDR + .07
		elseif buff.name == "Void" then 
			DR = DR + .01 --+4% DR 2/2 devourer
			Buffvoid = true
		elseif buff.name == "Power Shield" then 
			activeDR = activeDR + .20
		elseif buff.name == "Unstable Void" then 
			DR = DR + .05
		elseif buff.name == "Crest of Entropy" then 
			activeDR = activeDR + .30
		elseif buff.name == "Binding of Death" or buff.name == "Binding of Devouring Darkness" then 
			DR = DR + .05
		elseif buff.name == "Crest of Consumption" then 
			activeDR = activeDR + .35
		elseif buff.name == "Brothers in Arms" then 
			linkDR = linkDR + .35	
		end
	end

	BuffBamount = Bamount
	BuffBchance = Bchance
	BuffDchance = Dchance
	BuffPchance = Pchance
	BuffDR = DR
	BuffDRlink = linkDR
	BuffDRshield = shieldDR
	BuffDRactive = activeDR
	--print(DR .. " = Buff DR")
	--print(linkDR .. " = Buff Link DR")
	--print(Bchance .. " = Buff block chance")
	--print(Dchance .. " = Buff Dodge chance")
	EHPcalc()
	
end

local function Create(configuration)

	local TankMeterId = configuration.id
	local TankMeter = TankMeters[TankMeterId]

	if not TankMeter then
	

		TankMeter = WT.UnitFrame:Create("player")
		TankMeter.Id = configuration.id
		
		TankMeter:SetWidth(150)
		TankMeter:SetHeight(70)
		
		--set up buffs
		TankMeter.buffs = {}
		TankMeter.CanAccept = 
		  function(self, buff)
		  local accepted = false
			if buff.debuff ~= nil then return false end
			
			for i, buffname in ipairs(BuffFilter) do
				if buffname == buff.name then 
					accepted = true
					return accepted
				else
					accepted = false
				end
			end
			return accepted
		  end

		TankMeter.Add = 
		  function(self, buff)
			TankMeter.buffs[buff.id] = buff
			Buffcalc()
		  end

		TankMeter.Remove = 
		  function(self, buff)
			TankMeter.buffs[buff.id] = nil
			Buffcalc()
		  end

		TankMeter.Update = 
		  function(self, buff)
			Buffcalc()
		  end

		TankMeter.Done = Buffcalc

		TankMeter:RegisterBuffSet(TankMeter)
	
	else
		TankMeter.Bindings = {}
	end
	
	TankMeter.configvalues = configuration
	
	local rfBackground = UI.CreateFrame("Frame", "rfBackground", TankMeter)
	rfBackground:SetAllPoints(TankMeter)
	rfBackground:SetBackgroundColor(0,0,0,0.4)
    rfBackground:SetVisible(true)

	TankMeter.background = rfBackground

	local txtHeading = UI.CreateFrame("Text", WT.UniqueName("TankMeter"), rfBackground)
	txtHeading:SetText("Effective HP")
	txtHeading:SetPoint("TOPLEFT", TankMeter, "TOPLEFT", 5, 5)
	txtHeading:SetFontSize(10)
	txtHeading:SetFontColor(0.6, 1.0, 0.6, 1.0)
	txtHeading:SetVisible(true)
	
	TankMeter.txtHeading = txtHeading
	
	local txtMit = UI.CreateFrame("Text", WT.UniqueName("Mitigation"), rfBackground)
	txtMit:SetText("Mitigation:  " .. "--")
	txtMit:SetPoint("BOTTOMLEFT", TankMeter, "BOTTOMLEFT", 5, -5)
	txtMit:SetFontSize(10)
	txtMit:SetFontColor(0.6, 1.0, 0.6, 1.0)
	txtMit:SetVisible(true)
	
	TankMeter.txtMit = txtMit
	
	local txtEHP = TankMeter:CreateElement({
		id=WT.UniqueName("txtEHP"), type="Label", parent=rfBackground, layer=20,
		attach = {{ point="CENTER", element=rfBackground, targetPoint="CENTER", offsetX=0, offsetY=0 }},
		visibilityBinding="name", text="--", default="", fontSize=24, outline=true,
		color={ r=0.6, g=1.0, b=0.6, a=1.0 },
	});
	
	TankMeter.txtEHP = txtEHP
	
	
	TankMeter:CreateBinding("healthMax", TankMeter, Buffcalc, nil)
	
	TankMeters[TankMeterId] = TankMeter
	
	BuffList = TankMeter.buffs
		
	TankMeter:ApplyBindings()
	
	
	
	return TankMeter
end

function round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

WT.Gadget.RegisterFactory("Tank Meter",
	{
		name="Tank Meter",
		description="EHP and mitigation Meter",
		author="Vexxx@Greybriar",
		version="0.1",
		iconTexAddon = AddonId,
		iconTexFile = "img/Tankicon.png",
		["Create"] = Create,
		["ConfigDialog"] = ConfigDialog,
		["GetConfiguration"] = GetConfiguration, 
		["SetConfiguration"] = SetConfiguration, 
	})
