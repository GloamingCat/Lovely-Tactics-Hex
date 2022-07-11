
--[[===============================================================================================

Dialogue Test
---------------------------------------------------------------------------------------------------

=================================================================================================]]

return function(script)

  script:turnCharTile { key = 'self', other = 'player' }

  script:showDialogue { id = 1, character = "self", portrait = "BigIcon", message = 
    Vocab.dialogues.actor.Hi
  }
  
  local troop = TroopManager:getPlayerTroop()
  if not troop:hasMember('Merlin') then
    
    script:showDialogue { id = 1, character = "self", portrait = "BigIcon", message = 
      Vocab.dialogues.actor.CanIJoin
    }

    script:openChoiceWindow { width = 50, choices = {
      Vocab.yes,
      Vocab.no
    }}

    if script.gui.choice == 1 then
      script:showDialogue { id = 1, character = "self", portrait = "BigIcon", message = 
        Vocab.dialogues.actor.ThatsGood
      }
      script:addMember { key = 'Merlin', x = 0, y = 0 }
    else
      script:showDialogue { id = 1, character = "self", portrait = "BigIcon", message = 
        Vocab.dialogues.actor.ThatsBad
      }
    end
    
  end

  script:closeDialogueWindow { id = 1 }

end
