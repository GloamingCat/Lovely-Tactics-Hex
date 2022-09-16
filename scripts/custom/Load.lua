
--[[===============================================================================================

Load
---------------------------------------------------------------------------------------------------
Default script that runs when the game is loaded.
It is used as load script for most non-battle fields.

=================================================================================================]]

return function(script)
  -- When loaded after battle, the script that called the battle should handle the transition effects.
  if not FieldManager.currentField.vars.onBattle then
    FieldManager.renderer:fadeout(0)
    FieldManager.renderer:fadein(60, true)
    FieldManager.hud:show()
  end
end
