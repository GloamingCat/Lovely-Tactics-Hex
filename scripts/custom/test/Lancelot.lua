
-- ================================================================================================

--- Test behavior for choices, shop menu and battle.
---------------------------------------------------------------------------------------------------
-- @event Lancelot

-- ================================================================================================

return function(script)
  
  -- Event 1: choice
  script:addEvent(function()
    script:stopChar { key = 'player' }
    script:turnCharTile { key = 'self', other = 'player' }
    script:turnCharTile { key = 'player', other = 'self' }
    script:showDialogue { id = 1, character = 'self', portrait = 'BigIcon', nameX = -85, message = 
      "{%dialogues.npc.WhatDoYou}"
    }
    script:openChoiceWindow { width = 70, y = -20,
      choices = {
        '{%dialogues.npc.Shop}',
        '{%dialogues.npc.Recruit}',
        '{%dialogues.npc.Battle}',
        '{%dialogues.npc.Nothing}'
      }
    }
    script:closeDialogueWindow { id = 1 }
  end)
    
  -- Event 2: shop
  script:addEvent(function()
    script:openShopMenu { sell = true, items = {
      { id = 'potionHP' },
      { id = 'potionSP' },
      { id = 'potionKO' },
      { id = 'antidote' },
      { id = 'sword' },
      { id = 'staff' },
      { id = 'ribbon' }
    }}
    script:skipEvents(3) -- Skips battle events.
  end, 
  function() return script.char.vars.choiceInput == 1 end)
  
  -- Event 3: recruit
  script:addEvent(function()
    script:openRecruitMenu { items = {
      { id = 'slime0' }
    }}
    script:skipEvents(2) -- Skips battle events.
  end, 
  function() return script.char.vars.choiceInput == 2 end)
  
  -- Event 4: battle
  script:addEvent(script.startBattle,
  function() return script.char.vars.choiceInput == 3 end,
  { 
    skipIntro = false,
    disableEscape = false,
    gameOverCondition = 'none',
    fieldID = tonumber(script.args.fieldID) or 0,
    fade = 60
  })

  -- Event 5: aftermath
  script:addEvent(function()
    script:finishBattle { fade = 60, wait = true }
    script:showDialogue { id = 1, character = 'self', portrait = 'BigIcon', message = script.battleLog }
  end,
  function() return script.char.vars.choiceInput == 3 end)

end
