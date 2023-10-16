
--[[===============================================================================================

@classmod TurnManager
---------------------------------------------------------------------------------------------------
Provides methods for battle's turn management.
-- At the end of each turn, a "battle result" table must be returned by either the GUI (player) or
-- the AI (enemies). 
-- This table must include the following entries:
-- * <endTurn> tells turn manager to pass turn to next party.
-- * <endCharacterTurn> tells the turn window to close and pass turn to the next character.
-- * <characterIndex> indicates the next turn's character (from same party).
-- * <executed> is true if the chosen action was entirely executed (usually true, unless it was a
-- move action to an unreachable tile, or the action could not be executed for some reason).
-- * <escaped> is true if all members of the current party have escaped.

=================================================================================================]]

-- Imports
local BattleMoveAction = require('core/battle/action/BattleMoveAction')
local PathFinder = require('core/battle/ai/PathFinder')
local BattleGUI = require('core/gui/battle/BattleGUI')

-- Alias
local indexOf = util.arrayIndexOf

-- Class table.
local TurnManager = class()

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function TurnManager:init()
  self.turnCharacters = nil
  self.initialTurnCharacters = nil
  self.characterIndex = 1
  self.pathMatrixes = nil
  self.party = nil
  self.finishTime = 20
end
--- Sets starting party.
-- @tparam table state Data about turn state for when the game is loaded mid-battle (optional).
function TurnManager:setUp(state)
  if state then
    self.party = state.party
    self.turnCharacters = {}
    self.initialTurnCharacters = util.table.deepCopy(state.initialCharacters)
    for i = 1, #state.characters do
      self.turnCharacters[i] = FieldManager.characterList[state.characters[i]]
    end
    self.turns = state.turns or 0
  else
    self.turns = 0
    self.party = TroopManager.playerParty - 1
    self.turnCharacters = {}
  end
end

-- ------------------------------------------------------------------------------------------------
-- Turn Info
-- ------------------------------------------------------------------------------------------------

--- Gets the current selected character.
function TurnManager:currentCharacter()
  return self.turnCharacters and self.turnCharacters[self.characterIndex]
end
--- Gets the current turn's troop.
function TurnManager:currentTroop()
  return TroopManager.troops and TroopManager.troops[self.party]
end
--- Gets the path matrix of the current character.
function TurnManager:pathMatrix()
  return self.pathMatrixes and self.pathMatrixes[self.characterIndex]
end
--- Recalculates the distance matrix.
function TurnManager:updatePathMatrix()
  local moveAction = BattleMoveAction()
  local path = PathFinder.dijkstra(moveAction, self:currentCharacter())
  self.pathMatrixes[self.characterIndex] = path
end
--- Gets the current battle state to save the game mid-battle.
-- @treturn table Turn state data.
function TurnManager:getState()
  if not self.initialTurnCharacters then
    return nil
  end
  local initialCharacters = util.table.deepCopy(self.initialTurnCharacters)
  local characters = {}
  for i = 1, #self.turnCharacters do
    characters[i] = self.turnCharacters[i].key
  end
  return {
    party = self.party,
    characters = characters,
    initialCharacters = initialCharacters }
end

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- [COROUTINE] Executes turn and returns when the turn finishes.
-- @treturn number Result code (nil if battle is still running).
-- @treturn number The party that won or escaped (nil if battle is still running).
function TurnManager:runTurn(skipStart)
  local winner = TroopManager:winnerParty()
  if winner then
    if winner == TroopManager.playerParty then
      -- Player wins.
      return 1, winner
    elseif winner == -1 then
      -- Draw.
      return 0, -1
    else
      -- Enemy wins.
      return -1, winner
    end
  end
  self:startTurn(skipStart)
  if not self:hasActiveCharacters() then
    return
  end
  local troop = TroopManager.troops[self.party]
  local result = troop.AI and troop.AI(troop) or self:runPlayerTurn()
  _G.Fiber:wait(self.finishTime)
  if result.escaped then
    local winner = TroopManager:winnerParty()
    if winner then
      if self.party == TroopManager.playerParty then
        return -2, winner
      else
        return 2, winner
      end
    end
  end
  self:endTurn(result)
  self.turns = self.turns + 1
end
--- [COROUTINE] Runs the player's turn.
-- @treturn table The action result table of the turn.
function TurnManager:runPlayerTurn()
  while true do
    if #self.turnCharacters == 0 then
      return { escaped = false }
    end
    if not self:currentCharacter().battler:isActive() then
      self.characterIndex = self:nextCharacterIndex(nil, false) or self:nextCharacterIndex(nil, true) 
      if not self.characterIndex then
        return { endTurn = true }
      end
    end
    self:characterTurnStart()
    local AI = self:currentCharacter().battler:getAI()
    local result = AI and AI:runTurn() or GUIManager:showGUIForResult(BattleGUI(nil))
    if result.characterIndex then
      self.characterIndex = result.characterIndex
    else
      self:characterTurnEnd(result)
      if result.endTurn then
        return result
      end
      local winner = TroopManager:winnerParty()
      if winner then
        return result
      end
    end
  end
end
--- Gets the next active character in the current party.
-- @tparam number i 1 or -1 to indicate direction.
-- @tparam boolean controllable True to exclude NPC, false to ONLY include NPC (nil by default).
-- @treturn number Next character index, or nil if there's no active character.
function TurnManager:nextCharacterIndex(i, controllable)
  i = i or 1
  local count = #self.turnCharacters
  if count == 0 then
    return nil
  end
  local index = math.mod1(self.characterIndex + i, count)
  while not self.turnCharacters[index].battler:isActive() or
      (controllable and self.turnCharacters[index].battler:getAI()) or
      (controllable == false and not self.turnCharacters[index].battler:getAI())  do
    if index == self.characterIndex then
      return nil
    end
    index = math.mod1(index + i, count)
  end
  return index
end
-- @treturn boolean Whether there are characters on battle that can act, either by input or AI.
function TurnManager:hasActiveCharacters()
  for i = 1, #self.turnCharacters do
    if self.turnCharacters[i].battler:isActive() then
      return true
    end
  end
  return false
end

-- ------------------------------------------------------------------------------------------------
-- Party Turn
-- ------------------------------------------------------------------------------------------------

--- Prepares for turn.
function TurnManager:startTurn(skipStart)
  while #self.turnCharacters == 0 do
    self:nextParty()
  end 
  self.pathMatrixes = {}
  if not skipStart then
    self.initialTurnCharacters = {}
  end
  for i = 1, #self.turnCharacters do
    local char = self.turnCharacters[i]
    self.initialTurnCharacters[char.key] = true
    char.battler:onTurnStart(char, skipStart)
  end
  for char in TroopManager.characterList:iterator() do
    if not self.initialTurnCharacters[char.key] then
      char.battler:onTurnStart(char, skipStart)
    end
  end
end
--- Closes turn.
-- @tparam table result Result info for the current turn.
function TurnManager:endTurn(result)
  for char in TroopManager.characterList:iterator() do
    char.battler:onTurnEnd(char)
  end
end
--- Gets the next party.
function TurnManager:nextParty()
  self.party = math.mod(self.party + 1, TroopManager.partyCount)
  self.turnCharacters = {}
  for char in TroopManager.characterList:iterator() do
    if char.party == self.party and char.battler:isActive() then
      table.insert(self.turnCharacters, char)
    end
  end
  self.characterIndex = self:nextCharacterIndex(nil, false) or self:nextCharacterIndex(nil, true)
end

-- ------------------------------------------------------------------------------------------------
-- Character Turn
-- ------------------------------------------------------------------------------------------------

--- Called when a character is selected so it's their turn.
function TurnManager:characterTurnStart()
  local char = self:currentCharacter()
  char.battler:onSelfTurnStart(char)
  self:updatePathMatrix()
  FieldManager.renderer:moveToObject(char, nil, true)
end
-- Called the character's turn ended
-- @tparam table result The action result returned by the BattleAction (or wait action).
function TurnManager:characterTurnEnd(result)
  local char = self:currentCharacter()
  char.battler:onSelfTurnEnd(char, result)
  table.remove(self.turnCharacters, self.characterIndex)
  if self.characterIndex > #self.turnCharacters then
    self.characterIndex = 1
  end
  local index = self:nextCharacterIndex(nil, false)
  if index then
    -- Select NPC, if any.
    self.characterIndex = index
  end
end

return TurnManager
