
--[[===============================================================================================

DefaultAI
---------------------------------------------------------------------------------------------------
Default troop AI. Manages the action for each member in order.
If a battler does not have an AI, it is ignored and does nothing.

=================================================================================================]]

return function (troop)
  TurnManager.characterIndex = 1
  while #TurnManager.turnCharacters > 0 do
    local char = TurnManager:currentCharacter()
    local AI = char.battler:getAI()
    if AI and char.battler:isActive() then
      local result = AI:runTurn()
      if result.endTurn then
        return result
      end
    else
      TurnManager:characterTurnStart()
      TurnManager:characterTurnEnd({})
    end
  end
  return { escaped = false }
end
