
--[[===============================================================================================

Inn
---------------------------------------------------------------------------------------------------

=================================================================================================]]

return function(script)

  FieldManager.renderer:fadeout(60, true)
  AudioManager:playSFX { name = "heal", pitch = 100, volume = 100 }
  script:wait(90)
  script:healAll { status = { 0, 1, 17, 18, 15, 16 } }
  FieldManager.renderer:fadein(60, true)

end
