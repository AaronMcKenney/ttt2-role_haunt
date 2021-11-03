--Note: The vast majority of this code was pilfered from the Spectre by Zac

local L = LANG.GetLanguageTableReference("en")

--GENERAL ROLE LANGUAGE STRINGS
L[HAUNTED.name] = "Haunted"
L["info_popup_" .. HAUNTED.name] = [[You are a Haunted! You haunt people who kill you!]]
L["body_found_" .. HAUNTED.abbr] = "They were a Haunted!"
L["search_role_" .. HAUNTED.abbr] = "This person was a Haunted!"
L["target_" .. HAUNTED.name] = "Haunted"
L["ttt2_desc_" .. HAUNTED.name] = [[The Haunted is an innocent who revives after their killer dies!]]

--OTHER ROLE LANGUAGE STRINGS
L["ttt2_haunted_killed_title"] = "A Haunted has been killed!"
L["ttt2_haunted_killed_text"] = "Be on the lookout!"
L["ttt2_haunted_self_title"] = "You are haunting {name}"
L["ttt2_haunted_self_text"] = "You will revive when they die."
L["ttt2_haunted_revived_title"] = "A Haunted has been revived!"
L["ttt2_haunted_revived_text"] = "Their killer has died so they have been reborn!"

--EVENT STRINGS
L["title_haunt_haunt"] = "A Haunted was killed"
L["desc_haunt_haunt"] = "{victim} haunted {attacker}."
L["tooltip_haunt_haunt_score"] = "Killed a Haunted: {score}"
L["title_haunt_revive"] = "A Haunted revived."
L["desc_haunt_revive"] = "{haunted} respawned."
