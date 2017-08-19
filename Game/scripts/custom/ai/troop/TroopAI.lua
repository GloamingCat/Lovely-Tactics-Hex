
--[[===============================================================================================

TroopAI
---------------------------------------------------------------------------------------------------
The default AI for troops. Just executes all battlers' individual AIs, if they have one.

=================================================================================================]]

local TroopAI = class()

function TroopAI:init(param)
end

function TroopAI:runTurn()
  local result, i = nil, 1
  while i <= #TurnManager.turnCharacters do
    TurnManager.characterIndex = i
    local char = TurnManager:currentCharacter()
    local AI = char.battler.AI
    if AI then
      result = AI:runTurn()
      if result.endTurn then
        break
      end
    else
      i = i + 1
    end
  end
  return result
end

return TroopAI
