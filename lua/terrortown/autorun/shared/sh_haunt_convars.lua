--Note: The vast majority of this code was pilfered from the Spectre by Zac

--ConVar syncing
CreateConVar("ttt2_haunted_declare_mode", 2, {FCVAR_ARCHIVE, FCVAR_NOTIFY})
CreateConVar("ttt2_haunted_revive_health", 50, {FCVAR_ARCHIVE, FCVAR_NOTIFY})
CreateConVar("ttt2_haunted_smoke_mode", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY})
CreateConVar("ttt2_haunted_worldspawn", 0, {FCVAR_ARCHIVE, FCVAR_NOTIFY})

hook.Add("TTTUlxDynamicRCVars", "TTTUlxDynamicRCVarsHaunted", function(tbl)
	tbl[ROLE_HAUNTED] = tbl[ROLE_HAUNTED] or {}

	table.insert(tbl[ROLE_HAUNTED], {
		cvar = "ttt2_haunted_declare_mode",
		combobox = true,
		desc = "Declare Mode (Def. 2)",
		choices = {
			"0 - Don't declare the Haunted's status.",
			"1 - Declare the Haunted's status to every player.",
			"2 - Declare the Haunted's status to only traitors."
		},
		numStart = 0
	})
	
	table.insert(tbl[ROLE_HAUNTED], {
		cvar = "ttt2_haunted_revive_health",
		slider = true,
		min = 1,
		max = 100,
		decimal = 0,
		desc = "ttt2_haunted_revive_health (def. 50)"
	})
	
	table.insert(tbl[ROLE_HAUNTED], {
		cvar = "ttt2_haunted_smoke_mode",
		checkbox = true,
		desc = "ttt2_haunted_smoke_mode (Def. 1)"
	})
	
	table.insert(tbl[ROLE_HAUNTED], {
		cvar = "ttt2_haunted_worldspawn",
		checkbox = true,
		desc = "ttt2_haunted_worldspawn (Def. 0)"
	})
end)

hook.Add("TTT2SyncGlobals", "TTT2SyncGlobalsHaunted", function()
	SetGlobalInt("ttt2_haunted_declare_mode", GetConVar("ttt2_haunted_declare_mode"):GetInt())
	SetGlobalInt("ttt2_haunted_revive_health", GetConVar("ttt2_haunted_revive_health"):GetInt())
	SetGlobalBool("ttt2_haunted_smoke_mode", GetConVar("ttt2_haunted_smoke_mode"):GetBool())
	SetGlobalBool("ttt2_haunted_worldspawn", GetConVar("ttt2_haunted_worldspawn"):GetBool())
end)

cvars.AddChangeCallback("ttt2_haunted_declare_mode", function(name, old, new)
	SetGlobalInt("ttt2_haunted_declare_mode", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_haunted_revive_health", function(name, old, new)
	SetGlobalInt("ttt2_haunted_revive_health", tonumber(new))
end)
cvars.AddChangeCallback("ttt2_haunted_smoke_mode", function(name, old, new)
	SetGlobalBool("ttt2_haunted_smoke_mode", tobool(tonumber(new)))
end)
cvars.AddChangeCallback("ttt2_haunted_worldspawn", function(name, old, new)
	SetGlobalBool("ttt2_haunted_worldspawn", tobool(tonumber(new)))
end)
