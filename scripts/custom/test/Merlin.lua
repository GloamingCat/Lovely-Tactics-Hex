
--[[===============================================================================================

Merlin
---------------------------------------------------------------------------------------------------
Simple dialogue with choice. It adds a new member if the player wishes so.

=================================================================================================]]

return function(script)

  local troop = TroopManager:getPlayerTroop()
  
  script:addEvent(function()
    script:turnCharTile { key = 'self', other = 'player' }
    script:showDialogue { id = 1, character = "self", portrait = "BigIcon", message = 
      Vocab.dialogues.npc.Hi
    }
  end)
  
  script:addEvent(function()
    script:showDialogue { id = 1, character = "self", portrait = "BigIcon", message = 
      Vocab.dialogues.npc.CanIJoin
    }
    script:openChoiceWindow { width = 50, choices = {
      Vocab.yes,
      Vocab.no
    }}
    if script.vars.choiceInput == 1 then
      script:showDialogue { id = 1, character = "self", portrait = "BigIcon", message = 
        Vocab.dialogues.npc.ThatsGood
      }
      script:addMember { key = 'Merlin' }
    else
      script:showDialogue { id = 1, character = "self", portrait = "BigIcon", message = 
        Vocab.dialogues.npc.ThatsBad
      }
    end
  end, not troop:hasMember('Merlin'))

  script:addEvent(function()
    script:closeDialogueWindow { id = 1 }
  end)

end
