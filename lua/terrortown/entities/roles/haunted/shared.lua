--Note: The vast majority of this code was pilfered from the Spectre by Zac

if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_haunt.vmt")
	util.AddNetworkString("TTT2HauntedShowPopup")
end

function ROLE:PreInitialize()
	--Light Halloween color (shows up as a sort-of light Halloween color in-game, and forces the icon to be black instead of white)
	self.color = Color(255, 150, 100, 255)
	self.abbr = "haunt"
	
	--Score vars
	self.score.surviveBonusMultiplier = 0.5
	self.score.timelimitMultiplier = -0.5
	self.score.killsMultiplier = 2
	self.score.teamKillsMultiplier = -16
	self.score.bodyFoundMuliplier = 0
	
	--Prevent the Hautned from gaining credits normally.
	self.preventFindCredits = true
	
	self.defaultTeam = TEAM_TRAITOR
	self.defaultEquipment = TRAITOR_EQUIPMENT
	
	--This role can see which players are missing in action as well as the haste timer.
	self.isOmniscientRole = true
	
	self.conVarData = {
		pct = 0.15, -- necessary: percentage of getting this role selected (per player)
		maximum = 1, -- maximum amount of roles in a round
		minPlayers = 6, -- minimum amount of players until this role is able to get selected
		togglable = true, -- option to toggle a role for a client if possible (F1 menu)
		random = 30,
		traitorButton = 1, -- can use traitor buttons
		
		--Haunted can't access shop, and has no credits.
		credits = 0,
		creditsAwardDeadEnable = 0,
		creditsAwardKillEnable = 0,
		shopFallback = SHOP_DISABLED
	}
end

function ROLE:Initialize()
	roles.SetBaseRole(self, ROLE_TRAITOR)
end

local function IsInSpecDM(ply)
	if SpecDM and (ply.IsGhost and ply:IsGhost()) then
		return true
	end
	
	return false
end

--Enum to determine type of pop-up
local POPUP_MODE = {DEATH = 0, DEATH_SELF = 1, REVIVE = 2}

if SERVER then
	--Declare Mode Enum for popups
	local DECLARE_MODE = {SILENT = 0, ALL = 1, TRA_ONLY = 2}
	
	local function SendHauntedNotification(dead_haunted_ply, notify_mode, killer)
		local dec_mode = GetConVar("ttt2_haunted_declare_mode"):GetInt()
		if dec_mode == DECLARE_MODE.SILENT then
			return
		end
		
		local plys = player.GetAll()
		for i = 1, #plys do
			local ply = plys[i]
			
			if  ply:SteamID64() == dead_haunted_ply:SteamID64() and notify_mode == POPUP_MODE.DEATH then
				--Notify the victim of their potential to revive.
				net.Start("TTT2HauntedShowPopup")
				net.WriteUInt(POPUP_MODE.DEATH_SELF, 2)
				net.WriteString(killer:GetName())
				net.Send(ply)
			elseif dec_mode == DECLARE_MODE.ALL or (dec_mode == DECLARE_MODE.TRA_ONLY and ply:GetBaseRole() == ROLE_TRAITOR) then
				net.Start("TTT2HauntedShowPopup")
				net.WriteUInt(notify_mode, 2)
				net.Send(ply)
			end
		end
	end
	
	local function AttemptHauntedRevival(dead_ply)
		local plys = player.GetAll()
		for i = 1, #plys do
			local ply = plys[i]
			
			if ply:GetSubRole() == ROLE_HAUNTED and (not ply:Alive() or IsInSpecDM(ply)) and ply:SteamID64() == dead_ply.haunt_haunted_by then
				local spawn_pos = nil
				local spawn_eye_ang = nil
				if GetConVar("ttt2_haunted_worldspawn"):GetBool() then
					--This function will do many checks to ensure that the randomly selected spawn position is safe.
					local spawn_point = plyspawn.GetRandomSafePlayerSpawnPoint(ply)
					if spawn_point then
						spawn_pos = spawn_point.pos
						spawn_eye_ang = spawn_point.ang
					end
				end
				
				--Even if the revival fails, we must end the haunting to prevent glitchy behavior
				dead_ply.haunt_haunted_by = nil
				dead_ply:SetNWBool("haunt_is_smoking", false)
				STATUS:RemoveStatus(dead_ply, "haunt_haunted_status")
				
				ply:Revive(
					0, --Respawn delay
					function(ply) --OnRevive function
						--Mess with the player's stats here.
						ply:SetHealth(GetConVar("ttt2_haunted_revive_health"):GetInt())
						ply:ResetConfirmPlayer()
						SendFullStateUpdate()
						SendHauntedNotification(ply, POPUP_MODE.REVIVE)
					end,
					function(ply) --DoCheck function
						--Return false (do not go through with the revival) if doing so could cause issues
						return GetRoundState() == ROUND_ACTIVE and (not ply:Alive() or IsInSpecDM(ply))
					end,
					false, --needsCorpse
					REVIVAL_BLOCK_AS_ALIVE, --blocksRound (Prevents anyone from winning during respawn delay)
					nil, --OnFail function
					spawn_pos, --The player's respawn point (If nil, will be their corpse if present, and their point of death otherwise)
					spawn_eye_ang --spawnEyeAngle
				)
				
				return
			end
		end
	end
	
	local function HauntPlayer(dead_ply, attacker)
		attacker.haunt_haunted_by = dead_ply:SteamID64()
		STATUS:AddStatus(attacker, "haunt_haunted_status")
		SendHauntedNotification(dead_ply, POPUP_MODE.DEATH, attacker)
		
		if GetConVar("ttt2_haunted_smoke_mode"):GetBool() then
			attacker:SetNWBool("haunt_is_smoking", true)
		end
	end
	
	hook.Add("TTT2PostPlayerDeath", "TTT2PostPlayerDeathHaunted", function(dead_ply, infl, attacker)
		if GetRoundState() ~= ROUND_ACTIVE or not IsValid(dead_ply) or not dead_ply:IsPlayer() or IsInSpecDM(dead_ply) or not IsValid(attacker) or not attacker:IsPlayer() or IsInSpecDM(attacker) then
			return
		end
		
		if dead_ply:GetSubRole() == ROLE_HAUNTED and dead_ply:SteamID64() ~= attacker:SteamID64() then
			HauntPlayer(dead_ply, attacker)
		end
		
		if dead_ply.haunt_haunted_by then
			AttemptHauntedRevival(dead_ply)
		end
	end)
	
	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		local plys = player.GetAll()
		for i = 1, #plys do
			local ply_i = plys[i]
			
			if ply_i.haunt_haunted_by == ply:SteamID64() then
				--Stop the haunting now that the Haunted has revived.
				--Could happen if, for example, the Haunted is revived by defib before their killer was killed.
				ply_i.haunt_haunted_by = nil
				ply_i:SetNWBool("haunt_is_smoking", false)
				STATUS:RemoveStatus(ply_i, "haunt_haunted_status")
			end
		end
	end
	
	local function ResetHauntedDataForServer()
		local plys = player.GetAll()
		for i = 1, #plys do
			local ply = plys[i]
			
			ply.haunt_haunted_by = nil
			ply:SetNWBool("haunt_is_smoking", false)
			STATUS:RemoveStatus(ply, "haunt_haunted_status")
		end
	end
	hook.Add("TTTPrepareRound", "TTTPrepareRoundHauntedServer", ResetHauntedDataForServer)
	hook.Add("TTTBeginRound", "TTTBeginRoundHauntedServer", ResetHauntedDataForServer)
	hook.Add("TTTEndRound", "TTTEndRoundHauntedServer", ResetHauntedDataForServer)
end

if CLIENT then
	hook.Add("Initialize", "InitializeHaunted", function()
		STATUS:RegisterStatus("haunt_haunted_status", {
			hud = Material("vgui/ttt/dynamic/roles/icon_haunt.vmt"),
			type = "bad"
		})
	end)
	
	net.Receive("TTT2HauntedShowPopup", function()
		local client = LocalPlayer()
		local notify_mode = net.ReadUInt(2)
		local killer_name = ""
		if notify_mode == POPUP_MODE.DEATH_SELF then
			killer_name = net.ReadString()
		end
		
		if notify_mode == POPUP_MODE.DEATH then
			EPOP:AddMessage({text = LANG.GetTranslation("ttt2_haunted_killed_title"), color = HAUNTED.ltcolor}, LANG.GetTranslation("ttt2_haunted_killed_text"), 6)
		elseif notify_mode == POPUP_MODE.DEATH_SELF then
			EPOP:AddMessage({text = LANG.GetParamTranslation("ttt2_haunted_self_title", {name = killer_name}), color = HAUNTED.ltcolor}, LANG.GetTranslation("ttt2_haunted_self_text"), 6)
		else --notify_mode == POPUP_MODE.REVIVE
			EPOP:AddMessage({text = LANG.GetTranslation("ttt2_haunted_revived_title"), color = HAUNTED.ltcolor}, LANG.GetTranslation("ttt2_haunted_revived_text"), 6)
		end
	end)
	
	local function DoSmoke()
		local client = LocalPlayer()
		local cur_time = CurTime()
		for _, ply in ipairs(player.GetAll()) do
			if ply:Alive() and ply:GetNWBool("haunt_is_smoking") then
				local pos = ply:GetPos() + Vector(0, 0, 30)
				if not ply.SmokeEmitter then
					ply.SmokeEmitter = ParticleEmitter(ply:GetPos())
				end
				if not ply.SmokeNextPart then
					ply.SmokeNextPart = cur_time
				end
				
				if ply.SmokeNextPart < cur_time then
					if client:GetPos():Distance(pos) > 1000 then
						continue
					end
					local vec = Vector(math.Rand(-8, 8), math.Rand(-8, 8), math.Rand(10, 55))
					local size = math.random(4, 7)
					
					ply.SmokeEmitter:SetPos(pos)
					ply.SmokeNextPart = cur_time + math.Rand(0.003, 0.01)
					pos = ply:LocalToWorld(vec)
					
					local particle = ply.SmokeEmitter:Add("particle/snow.vmt", pos)
					particle:SetVelocity(Vector(0, 0, 4) + VectorRand() * 3)
					particle:SetDieTime(math.Rand(0.2, 2))
					particle:SetStartAlpha(math.random(80, 255))
					particle:SetEndAlpha(0)
					particle:SetStartSize(size)
					particle:SetEndSize(size + 1 * (-1 ^ math.random(1, 2)))
					particle:SetRoll(0)
					particle:SetRollDelta(0)
					particle:SetColor(46, 46, 46)
				end
			elseif ply.SmokeEmitter then
				ply.SmokeEmitter:Finish()
				ply.SmokeEmitter = nil
			end
		end
	end
	
	hook.Add("Think", "ThinkHaunted", function()
		if GetConVar("ttt2_haunted_smoke_mode"):GetBool() then
			DoSmoke()
		end
	end)

	-------------
	-- CONVARS --
	-------------
	function ROLE:AddToSettingsMenu(parent)
		local form = vgui.CreateTTT2Form(parent, "header_roles_additional")

		form:MakeComboBox({
			serverConvar = "ttt2_haunted_declare_mode",
			label = "label_haunted_declare_mode",
			choices = {{
				value = 0,
				title = LANG.GetTranslation("label_haunted_declare_mode_0")
			},{
				value = 1,
				title = LANG.GetTranslation("label_haunted_declare_mode_1")
			},{
				value = 2,
				title = LANG.GetTranslation("label_haunted_declare_mode_2")
			}}
		})

		form:MakeSlider({
			serverConvar = "ttt2_haunted_revive_health",
			label = "label_haunted_revive_health",
			min = 1,
			max = 100,
			decimal = 0
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_haunted_smoke_mode",
			label = "label_haunted_smoke_mode"
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_haunted_worldspawn",
			label = "label_haunted_worldspawn"
		})
	end
end
