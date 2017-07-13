
--[[===============================================================================================

TurnManager
---------------------------------------------------------------------------------------------------


=================================================================================================]]

-- Imports
local yield = coroutine.yield
local time = love.timer.getDelta

local TurnManager = class()

---------------------------------------------------------------------------------------------------
-- Turn Queue
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Searchs for the next character turn and starts.
-- @param(ignoreAnim : boolean) true to skip bar increasing animation
-- @ret(Character) the next turn's character
-- @ret(number) the number of iterations it took from the previous turn
function TurnManager:getNextTurn(ignoreAnim)
  local turnQueue = TroopManager:getTurnQueue()
  local currentCharacter, iterations = turnQueue:front()
  if Battle.turnBar and not ignoreAnim then
    local i = 0
    while i < iterations do
      i = i + time() * 60
      TroopManager:incrementTurnCount(time() * 60)
      yield()
    end
  else
    TroopManager:incrementTurnCount(iterations)
  end
  return currentCharacter, iterations
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Executes turn and returns when the turn finishes.
function TurnManager:runTurn()
  if InputManager.keys['kill']:isPressing() then
    BattleManager:killAll(TroopManager.playerParty)
    return 1, TroopManager.playerParty
  end
  local char, iterations = self:getNextTurn()
  self:startTurn(char, iterations)
  local actionCost = 0
  local AI = char.battler.AI
  if not BattleManager.params.skipAnimations then
    FieldManager.renderer:moveToObject(char, nil, true)
  end
  if AI then
    actionCost = AI:runTurn(iterations, char)
  else
    actionCost = GUIManager:showGUIForResult('battle/BattleGUI')
  end
  if actionCost >= 0 then
    self:endTurn(char, actionCost, iterations)
    local winner = TroopManager:winnerParty()
    if winner then
      return self:getResult(winner), winner
    end
  else
    return -2, char.battler.party
  end
end
-- Prepares for turn.
-- @param(char : Character) the new character of the turn
-- @param(iterations : number) the time since the last turn
function TurnManager:startTurn(char, iterations)
  BattleManager.currentCharacter = char
  char.battler:onSelfTurnStart(iterations)
  BattleManager:updatePathMatrix()
  for bc in TroopManager.characterList:iterator() do
    bc.battler:onTurnStart(iterations)
  end
end
-- Closes turn.
-- @param(char : Character) the character of the turn
-- @param(actionCost : number) the time spend by the character of the turn
-- @param(iterations : number) the time since the last turn
function TurnManager:endTurn(char, actionCost, iterations)
  char.battler:onSelfTurnEnd(iterations, actionCost + 1)
  for bc in TroopManager.characterList:iterator() do
    bc.battler:onTurnEnd(iterations)
  end
  BattleManager.currentCharacter = nil
end

function TurnManager:getResult(winner)
  if winner == TroopManager.playerParty then
    return 1 -- Victory.
  elseif winner == 0 then
    return 0 -- Draw.
  else
    return -1 -- Lost.
  end
end

return TurnManager
