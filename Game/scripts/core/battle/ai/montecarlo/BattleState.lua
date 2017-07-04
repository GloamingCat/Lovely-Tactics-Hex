
--[[===============================================================================================

Battle State
---------------------------------------------------------------------------------------------------
Stores data about the current battle state (character's HP, SP, turn count, position and bonus, as
well as possible tile's modifications [TODO]).

=================================================================================================]]

-- Alias
local copyTable = util.deepCopyTable

local BattleState = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Creates a state that stores FieldManager's current state.
function BattleState:init()
  self.characters = {}
  self.tiles = {}
  -- Stores current state
  for char in TroopManager.characterList:iterator() do
    local state = copyTable(char.battler.state)
    state.x = char.position.x
    state.y = char.position.y
    state.z = char.position.z
    self.characters[char] = state
  end
  self.currentCharacter = BattleManager.currentCharacter
  self.pathMatrix = BattleManager.pathMatrix
end

---------------------------------------------------------------------------------------------------
-- Modification
---------------------------------------------------------------------------------------------------

-- Executes an input and generates a new state.
-- @param(input : ActionInput) input to be applied
-- @param(iterations : number) number of iterations since last turn
-- @ret(BattleState) the new current state
-- @ret(Character) the character of the next turn
-- @ret(number) the iterations to the next turn
function BattleState:applyInput(input, iterations)
  local actionCost = input:execute()
  if actionCost == -1 then
    actionCost = 0
  end
  BattleManager:endTurn(actionCost, iterations)
  local newUser, newIt = BattleManager:getNextTurn()
  BattleManager:startTurn(newUser, newIt)
  return BattleState(), newUser, newIt
end

-- Sets FieldManager's current state to this one.
function BattleState:revert()
  for char in TroopManager.characterList:iterator() do
    local state = self.characters[char]
    char:moveTo(state.x, state.y, state.z)
    char.battler.state = copyTable(state)
  end
  BattleManager.pathMatrix = self.pathMatrix
  BattleManager.currentCharacter = self.currentCharacter
end

return BattleState
