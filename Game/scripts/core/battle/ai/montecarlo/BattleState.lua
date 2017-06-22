
--[[===============================================================================================

Battle State
---------------------------------------------------------------------------------------------------
Stores data about the current battle state (character's HP, SP, turn count, position and bonus, as
well as possible tile's modifications [TODO]).

=================================================================================================]]

local BattleState = class()

-- Creates a state that stores FieldManager's current state.
function BattleState:init()
  self.characters = {}
  self.tiles = {}
  -- Stores current state
  for char in TroopManager.characterList:iterator() do
    local state = char.battler:getState()
    state.x = char.position.x
    state.y = char.position.y
    state.z = char.position.z
    self.characters[char] = state
  end
end

-- Executes an input and generates a new state.
function BattleState:applyInput(input)
  input:execute()
  return BattleState()
end

-- Sets FieldManager's current state to this one.
function BattleState:revert()
  for char in TroopManager.characterList:iterator() do
    local state = self.characters[char]
    char.battler:setState(state)
    char.position.x = state.x
    char.position.y = state.y
    char.position.z = state.z
  end
end

return BattleState
