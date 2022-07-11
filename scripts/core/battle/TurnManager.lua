
--[[===============================================================================================

TurnManager
---------------------------------------------------------------------------------------------------
Provides methods for battle's turn management.
At the end of each turn, a "battle result" table must be returned by either the GUI (player) or
the AI (enemies). 
This table must include the following entries:
* <endTurn> tells turn manager to pass turn to next party.
* <endCharacterTurn> tells the turn window to close and pass turn to the next character.
* <characterIndex> indicates the next turn's character (from same party).
* <executed> is true if the chosen action was entirely executed (usually true, unless it was a move
action to an unreachable tile, or the action could not be executed for some reason).
* <escaped> is true if all members of the current party have escaped.

=================================================================================================]]

-- Imports
local BattleMoveAction = require('core/battle/action/BattleMoveAction')
local PathFinder = require('core/battle/ai/PathFinder')
local BattleGUI = require('core/gui/battle/BattleGUI')

-- Alias
local indexOf = util.arrayIndexOf

local TurnManager = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function TurnManager:init()
  self.turnCharacters = nil
  self.pathMatrixes = nil
  self.party = nil
  self.finishTime = 20
end

---------------------------------------------------------------------------------------------------
-- Turn Info
---------------------------------------------------------------------------------------------------

-- Gets the current selected character.
function TurnManager:currentCharacter()
  return self.turnCharacters and self.turnCharacters[self.characterIndex]
end
-- Gets the current turn's troop.
function TurnManager:currentTroop()
  return TroopManager.troops and TroopManager.troops[self.party]
end
-- Gets the path matrix of the current character.
function TurnManager:pathMatrix()
  return self.pathMatrixes and self.pathMatrixes[self.characterIndex]
end
-- Recalculates the distance matrix.
function TurnManager:updatePathMatrix()
  local moveAction = BattleMoveAction()
  local path = PathFinder.dijkstra(moveAction, self:currentCharacter())
  self.pathMatrixes[self.characterIndex] = path
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Executes turn and returns when the turn finishes.
-- @ret(number) Result code (nil if battle is still running).
-- @ret(number) The party that won or escaped (nil if battle is still running).
function TurnManager:runTurn()
  local winner = TroopManager:winnerParty()
  if winner then
    if winner == TroopManager.playerParty then
      return 1, winner
    elseif winner == 0 then
      return 0, 0
    else
      return -1, winner
    end
  end
  self:startTurn()
  local result = true
  for i = 1, #self.turnCharacters do
    if self.turnCharacters[i].battler:isActive() then
      result = nil
      break
    end
  end
  if result then
    return nil
  end
  local troop = TroopManager.troops[self.party]
  if troop.AI then
    result = troop.AI(troop)
  else
    result = self:runPlayerTurn()
  end
  _G.Fiber:wait(self.finishTime)
  if result.escaped then
    if self.party == TroopManager.playerParty then
      return -2, TroopManager.playerParty
    else
      local winner = TroopManager:winnerParty()
      if winner then
        return -2, self.party
      end
    end
  end
  self:endTurn(result)
end
-- [COROUTINE] Runs the player's turn.
-- @ret(table) The action result table of the turn.
function TurnManager:runPlayerTurn()
  while true do
    if #self.turnCharacters == 0 then
      return { escaped = false }
    end
    self:characterTurnStart()
    local result = GUIManager:showGUIForResult(BattleGUI(self.GUI))
    if result.characterIndex then
      self.characterIndex = result.characterIndex
    else
      self:characterTurnEnd(result)
      if result.endTurn then
        return result
      end
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Party Turn
---------------------------------------------------------------------------------------------------

-- Prepares for turn.
function TurnManager:startTurn()
  repeat
    self:nextParty()
  until #self.turnCharacters > 0
  self.pathMatrixes = {}
  self.initialTurnCharacters = {}
  for i = 1, #self.turnCharacters do
    local char = self.turnCharacters[i]
    self.initialTurnCharacters[char] = true
    char:onTurnStart(true)
  end
  for char in TroopManager.characterList:iterator() do
    if not self.initialTurnCharacters[char] then
      char:onTurnStart(false)
    end
  end
end
-- Closes turn.
-- @param(char : Character) the character of the turn
function TurnManager:endTurn(char)
  for char in TroopManager.characterList:iterator() do
    char:onTurnEnd(self.initialTurnCharacters[char] ~= nil)
  end
end
-- Gets the next party.
function TurnManager:nextParty()
  self.party = math.mod(self.party + 1, TroopManager.partyCount)
  self.turnCharacters = {}
  for char in TroopManager.characterList:iterator() do
    if char.party == self.party and char.battler:isActive() then
      table.insert(self.turnCharacters, char)
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
  char:onSelfTurnStart()
  self:updatePathMatrix()
  FieldManager.renderer:moveToObject(char, nil, true)
end
-- Called the character's turn ended
-- @param(result : table) the action result returned by the BattleAction (or wait)
function TurnManager:characterTurnEnd(result)
  local char = self:currentCharacter()
  char:onSelfTurnEnd(result)
  table.remove(self.turnCharacters, self.characterIndex)
  if self.characterIndex > #self.turnCharacters then
    self.characterIndex = 1
  end
end

return TurnManager
