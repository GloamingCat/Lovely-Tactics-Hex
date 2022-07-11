
--[[===============================================================================================

Intro
---------------------------------------------------------------------------------------------------
First scene after title screen.

=================================================================================================]]

-- For debug. 
-- mode = 0 is default intro scene.
local mode = 0

return function(script)
  if mode == 1 then
    -----------------------------------------------------------------------------------------------
    -- Test battle
    -----------------------------------------------------------------------------------------------
    script:addMember { key = 'Merlin', x = 0, y = 0 }
    --AudioManager.battleTheme = nil
    AudioManager:setBGMVolume(1)
    script:startBattle { fieldID = 12, fade = 60, intro = true, 
      gameOverCondition = 1, escapeEnabled = true }
    --AudioManager.battleTheme = Config.sounds.battleTheme
  end
  FieldManager.renderer:fadein(0)
  FieldManager.currentField.loadScript = { name = '' }
  AudioManager:playBGM (Config.sounds.fieldsTheme)
end
