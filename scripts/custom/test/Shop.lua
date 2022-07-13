
--[[===============================================================================================

Shop Test
---------------------------------------------------------------------------------------------------
A shop open when player interacts with an NPC.

=================================================================================================]]

return function(script)

  if script.char.vars.onBattle then
    goto afterBattle
  end

  script.player:playIdleAnimation()
  
  script:showDialogue { id = 1, character = "self", portrait = "BigIcon", message = 
    Vocab.dialogues.actor.WhatDoYou
  }
  
  script:openChoiceWindow { width = 60, choices = {
    Vocab.dialogues.actor.Shop,
    Vocab.dialogues.actor.Battle,
    Vocab.dialogues.actor.Nothing
  }}

  script:closeDialogueWindow { id = 1 }

  if script.gui.choice == 1 then
    script:openShopMenu { sell = true, items = {
      { id = 2 },
      { id = 3 },
      { id = 4 },
      { id = 5 },
      { id = 6 },
      { id = 7 }
    }}
  elseif script.gui.choice == 3 then
    return
  end

  script:startBattle { 
    fieldID = tonumber(script.args.fieldID) or 0, 
    fade = 60, 
    intro = true, 
    gameOverCondition = 0, 
    escapeEnabled = true 
  }
  
  ::afterBattle::
  
  script:finishBattle { fade = 60 }
  
  local message
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
