
--[[===============================================================================================

Inn
---------------------------------------------------------------------------------------------------

=================================================================================================]]

return function(script)

  FieldManager.renderer:fadeout(60, true)
  AudioManager:playSFX { name = "heal", pitch = 100, volume = 100 }
  script:wait(90)
  script:healAll {}
  FieldManager.renderer:fadein(60, true)

end
