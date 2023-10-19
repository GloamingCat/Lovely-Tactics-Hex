
-- ================================================================================================

--- Simple dialogue with choice. It adds a new member if the player wishes so.
---------------------------------------------------------------------------------------------------
-- @event Merlin

-- ================================================================================================

return function(script)

  script:addEvent(function()
    script:turnCharTile { key = 'self', other = 'player' }
    script:turnCharTile { key = 'player', other = 'self' }
    script:showDialogue { id = 1, character = "self", portrait = "BigIcon", message = 
      Vocab.dialogues.npc.Hi
    }
  end)
  
  script:addEvent(function()
    script:showDialogue { id = 1, character = "self", portrait = "BigIcon", message = 
      Vocab.dialogues.npc.CanIJoin
    }
    script:openChoiceWindow { width = 50, y = -20, choices = {
      'yes',
      'no'
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
  end, not TroopManager:getPlayerTroop():hasMember('Merlin'))

  script:addEvent(function()
    script:closeDialogueWindow { id = 1 }
  end)

end
