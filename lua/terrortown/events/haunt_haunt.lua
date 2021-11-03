--Note: The vast majority of this code was pilfered from the Spectre by Zac

EVENT.base = "kill"

if CLIENT then
	--EVENT.icon = Material("vgui/ttt/dynamic/roles/icon_haunt.vmt")
    EVENT.title = "title_haunt_haunt"
	
    function EVENT:GetText()
        local kill_text = self.BaseClass.GetText(self)
		
        kill_text[#kill_text + 1] = {
            string = "desc_haunt_haunt",
            params = {
                attacker = self.event.attacker.nick,
                victim = self.event.victim.nick
            }
        }
		
        return kill_text
    end
end

if SERVER then
    function EVENT:Trigger(victim, attacker, dmgInfo)
        victim.was_haunted_death = true 
		
        return self.BaseClass.Trigger(self, victim, attacker, dmgInfo)
    end
end

hook.Add("TTT2OnTriggeredEvent", "TTT2OnTriggeredEventHaunted", function(event_type, event_data)
    if event_type ~= EVENT_KILL then
		return
	end
	
    local ply = player.GetBySteamID64(event_data.victim.sid64)
    
    if not IsValid(ply) or not ply.was_haunted_death then
		return
	end
	
    ply.was_haunted_death = nil 
	
    return false
end)