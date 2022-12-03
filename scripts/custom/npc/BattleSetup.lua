
--[[===============================================================================================

BattleSetup
---------------------------------------------------------------------------------------------------
Checks whether the enemy was already defeated.

=================================================================================================]]

return function(script)
  
  -- Reset defeated flag when player re-enters the field.
  -- Keep the flag is it's loaded from save.
  if not FieldManager:loadedFromSave() then
    script.char.vars.defeated = nil
  end
  
  if script.char.vars.defeated then
    -- Deletes if already defeated.
    script:deleteChar { permanent = script.args.permanent, key = 'self' }
  elseif script.args.resetPos == 'true' and not FieldManager:loadedFromSave() then
    -- Reset position otherwise.
    local data = script.char.instData
    script.char:transferTile(data.x, data.y, data.h)
  end
  
end
