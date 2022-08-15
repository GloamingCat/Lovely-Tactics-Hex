
--[[===============================================================================================

Intro
---------------------------------------------------------------------------------------------------
First scene after title screen.

=================================================================================================]]

-- For debug. 
-- mode = 1 to test battle.
local mode = 0

return function(script)
  if mode == 0 then
    FieldManager.renderer:fadeout(0)
    FieldManager.renderer:fadein(60, true)
  else
    if not script.vars.onBattle then
      --script:showEmotionBalloon { key = 'player', emotion = '!' }
      --script:showIconBalloon { key = 'player', icon = 'sleepy' }
      --script:wait(60)
      script:addMember { key = 'Merlin', x = 3, y = 3 }
      script:startBattle { fieldID = 2, 
        fade = 60, 
        intro = true, 
        gameOverCondition = 1, 
        escapeEnabled = true }
    else
      script:finishBattle { fade = 60 }
    end
  end
  FieldManager.currentField.loadScript.name = 'Load.lua'
  FieldManager.hud:show()
end
