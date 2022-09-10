
--[[===============================================================================================

Lancelot
---------------------------------------------------------------------------------------------------
Test behavior for choices, shop menu and battle.

=================================================================================================]]

return function(script)
  
  -- Event 1: choice
  script:addEvent(function()
    FieldManager.player:playIdleAnimation()
    script:turnCharTile { key = 'self', other = 'player' }
    script:showDialogue { id = 1, character = 'self', portrait = 'BigIcon',  message = 
      Vocab.dialogues.npc.WhatDoYou
    }
    script:openChoiceWindow { width = 70, y = -20,
      choices = {
        Vocab.dialogues.npc.Shop,
        Vocab.dialogues.npc.Battle,
        Vocab.dialogues.npc.Nothing
      }
    }
    script:closeDialogueWindow { id = 1 }
  end)
    
  -- Event 2: shop
  script:addEvent(function()
    script:openShopMenu { sell = true, items = {
      { id = 2 },
      { id = 3 },
      { id = 4 },
      { id = 5 },
      { id = 6 },
      { id = 7 }
    }}
    script:skipEvents(2) -- Skips battle events.
  end, 
  function() return script.char.vars.choiceInput == 1 end)
  
  -- Event 3: battle
  script:addEvent(script.startBattle,
  function() return script.char.vars.choiceInput == 2 end,
  { 
    intro = true,
    escapeEnabled = true,
    gameOverCondition = 'none',
    fieldID = tonumber(script.args.fieldID) or 0,
    fade = 60
  })

  -- Event 4: aftermath
  script:addEvent(function()
    script:finishBattle { fade = 60, wait = true }
    script:showDialogue { id = 1, character = 'self', portrait = 'BigIcon', message = script.battleLog }
  end,
  function() return script.char.vars.choiceInput == 2 end)

end
