
--[[===============================================================================================

TurnManager
---------------------------------------------------------------------------------------------------
Provides methods for battle's turn management.

=================================================================================================]]

-- Imports
local MoveAction = require('core/battle/action/MoveAction')
local PathFinder = require('core/battle/ai/PathFinder')

-- Alias
local indexOf = util.arrayIndexOf

local TurnManager = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

function TurnManager:init()
  self.turnCharacters = nil
  self.pathMatrixes = nil
  self.party = nil
end

function TurnManager:introTurn()
  self.party = TroopManager.playerParty - 1
  -- TODO: execute RepositionAction
end

---------------------------------------------------------------------------------------------------
-- Turn Info
---------------------------------------------------------------------------------------------------

-- Gets the current selected character.
function TurnManager:currentCharacter()
  return self.turnCharacters[self.characterIndex]
end
-- Gets the path matrix of the current character.
function TurnManager:pathMatrix()
  return self.pathMatrixes[self.characterIndex]
end
-- Recalculates the distance matrix.
function TurnManager:updatePathMatrix()
  if not self.pathMatrixes[self.characterIndex] then
    local moveAction = MoveAction()
    local path = PathFinder.dijkstra(moveAction, self:currentCharacter())
    self.pathMatrixes[self.characterIndex] = path
  end
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Executes turn and returns when the turn finishes.
function TurnManager:runTurn()
  self:startTurn()
  local result = nil
  local AI = TroopManager.troopAI[self.party]
  if AI then
    result = AI:runTurn()
  else
    result = self:runPlayerTurn()
  end
  if result.escaped then
    return -2, TroopManager.playerParty
  else
    self:endTurn(result)
    local winner = TroopManager:winnerParty()
    if winner then
      return self:getResult(winner), winner
    end
  end
end

function TurnManager:runPlayerTurn()
  while true do
    self:characterTurnStart()
    local result = GUIManager:showGUIForResult('battle/BattleGUI')
    if result.characterIndex then
      self.characterIndex = result.characterIndex
    else
      self:characterTurnEnd(result)
      if result.endTurn or #self.turnCharacters == 0 then
        return result
      end
    end
  end
end
-- Gets the code of the battle result based on the winner party.
-- @param(winner : number) the ID of the winner party
-- @ret(number) 1 is victory, 0 is draw, -1 is lost
function TurnManager:getResult(winner)
  if winner == TroopManager.playerParty then
    return 1 -- Victory.
  elseif winner == 0 then
    return 0 -- Draw.
  else
    return -1 -- Lost.
  end
end

---------------------------------------------------------------------------------------------------
-- Party Turn
---------------------------------------------------------------------------------------------------

-- Prepares for turn.
-- @param(char : Character) the new character of the turn
-- @param(iterations : number) the time since the last turn
function TurnManager:startTurn()
  repeat
    self:nextParty()
  until #self.turnCharacters > 0
  self.pathMatrixes = {}
  for bc in TroopManager.characterList:iterator() do
    bc.battler:onTurnStart(bc)
  end
end
-- Closes turn.
-- @param(char : Character) the character of the turn
-- @param(actionCost : number) the time spend by the character of the turn
-- @param(iterations : number) the time since the last turn
function TurnManager:endTurn(char, actionCost, iterations)
  for bc in TroopManager.characterList:iterator() do
    bc.battler:onTurnEnd(bc, char, iterations)
  end
end
-- Gets the next party.
function TurnManager:nextParty()
  self.party = math.mod1(self.party + 1, TroopManager.partyCount)
  self.turnCharacters = {}
  local i = 1
  for char in TroopManager.characterList:iterator() do
    if char.battler.party == self.party then
      self.turnCharacter[i] = char
      i = i + 1
    end
  end
  self.characterIndex = 1
end

---------------------------------------------------------------------------------------------------
-- Character Turn
---------------------------------------------------------------------------------------------------

-- Called when a character is selected so it's their turn.
function TurnManager:characterTurnStart()
  local char = self:currentCharacter()
  char.battler:onSelfTurnStart(char)
  self:updatePathMatrix()
  FieldManager.renderer:moveToObject(char, nil, true)
end
-- Called the character's turn ended
-- @param(result : table) the action result returned by the BattleAction (or wait)
function TurnManager:characterTurnEnd(result)
  local char = self:currentCharacter()
  char.battler:onSelfTurnEnd(char, result)
  table.remove(self.turnCharacters, self.characterIndex)
  if self.characterIndex > #self.turnCharacters then
    self.characterIndex = 1
  end
end

return TurnManager
