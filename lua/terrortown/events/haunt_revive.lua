--Note: The vast majority of this code was pilfered from the Spectre by Zac

if CLIENT then
    EVENT.title = "title_haunt_revive"
    EVENT.icon = Material("vgui/ttt/dynamic/roles/icon_haunt.vmt")
	
    function EVENT:GetText()
        return {{
			string = "desc_haunt_revive", 
			params = {haunted = self.event.nick}
		}}
    end
end

if SERVER then
    function EVENT:Trigger(haunted)
		
        haunted.was_haunted_revive = true
		
        return self:Add({
            nick = haunted:Nick(),
            sid64 = haunted:SteamID64()
        })
    end
end

hook.Add("TTT2OnTriggeredEvent", "TTT2OnTriggeredEventHaunted", function(event_type, event_data)
    if event_type ~= EVENT_RESPAWN then
		return
	end
	
    local ply = player.GetBySteamID64(event_data.sid64)
	
    if not IsValid(ply) or not ply.was_haunted_revive then
		return
	end
	
    ply.was_haunted_revive = nil 
	
    return false
end)