
--[[===============================================================================================

Shop Test
---------------------------------------------------------------------------------------------------
A shop open when player interacts with an NPC.

=================================================================================================]]

return function(script)

  if script.vars.onBattle then
    goto afterBattle
  end
  
  script:turnCharTile { key = 'self', other = 'player' }

  FieldManager.player:playIdleAnimation()
  
  script:showDialogue { id = 1, character = "self", portrait = "BigIcon", message = 
    Vocab.dialogues.npc.WhatDoYou
  }
  
  script:openChoiceWindow { width = 60, choices = {
    Vocab.dialogues.npc.Shop,
    Vocab.dialogues.npc.Battle,
    Vocab.dialogues.npc.Nothing
  }}

  script:closeDialogueWindow { id = 1 }

  if script.vars.choiceInput == 1 then
    script:openShopMenu { sell = true, items = {
      { id = 2 },
      { id = 3 },
      { id = 4 },
      { id = 5 },
      { id = 6 },
      { id = 7 }
    }}
    return
  elseif script.vars.choiceInput == 3 then
    return
  end

  script:startBattle { 
    fieldID = tonumber(script.args.fieldID) or 0, 
    fade = 60, 
    intro = true, 
    gameOverCondition = 0, 
    escapeEnabled = false 
  }
  
  ::afterBattle::
  
  script:finishBattle { fade = 60 }
  
  local message = "???"
  if BattleManager:playerWon() then
    message = 'You won!'
  elseif BattleManager:enemyWon() then
    message = 'You lost...'
  elseif BattleManager:drawed() then
    message = 'Draw.'
  elseif BattleManager:playerEscaped() then
    message = 'You escaped!'
  elseif BattleManager:enemyEscaped() then
    message = 'The enemy escaped...'
  end
  
  script:showDialogue { id = 1, character = "self", portrait = "BigIcon", message = message }
  script:closeDialogueWindow { id = 1 }

end
