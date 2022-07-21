
--[[===============================================================================================

Intro
---------------------------------------------------------------------------------------------------
First scene after title screen.

=================================================================================================]]

-- For debug. 
-- mode = 0 is default intro scene.
local mode = 1

return function(script)
  if mode == 0 then
    FieldManager.renderer:fadeout(0)
    FieldManager.renderer:fadein(60)
  else
    if not script.vars.onBattle then
      script:addMember { key = 'Merlin', x = 0, y = 0 }
      script:startBattle { fieldID = 2, 
        fade = 60, 
        intro = true, 
        gameOverCondition = 1, 
        escapeEnabled = true }
    else
      script:finishBattle { fade = 60 }
    end
  end
  FieldManager.currentField.loadScript.name = ''
end
