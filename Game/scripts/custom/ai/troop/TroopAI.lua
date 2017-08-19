
--[[===============================================================================================

TroopAI
---------------------------------------------------------------------------------------------------
The default AI for troops. Just executes all battlers' individual AIs, if they have one.

=================================================================================================]]

local TroopAI = class()

function TroopAI:init(param)
end

function TroopAI:runTurn()
  local result = nil
  for i = 1, #TurnManager.turnCharacters do
    local char = TurnManager:currentCharacter()
    local AI = char.battler.AI
    if AI then
      TurnManager.characterIndex = i
      result = AI:runTurn()
      if result.endTurn then
        break
      end
    end
  end
  return result
end

return TroopAI
