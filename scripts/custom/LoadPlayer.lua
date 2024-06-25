
-- ================================================================================================

--- Default script that runs when the player character is loaded.
---------------------------------------------------------------------------------------------------
-- @event LoadPlayer

-- ================================================================================================

return function(script)
  while true do
    script:wait()
    for fiber in FieldManager.currentField.blockingFibers:iterator() do
      fiber:waitForEnd()
    end
    if FieldManager.playerInput and not script.char:isBusy() then
      script.char:checkFieldInput()
    end
  end
end