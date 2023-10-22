
-- ================================================================================================

--- Provides methods for battle's turn management.
-- At the end of each turn, an `ActionResult` table must be returned by either the GUI (player) or
-- the AI (enemies). 
---------------------------------------------------------------------------------------------------
-- @manager TurnManager

-- ================================================================================================

-- Imports
local BattleMoveAction = require('core/battle/action/BattleMoveAction')
local PathFinder = require('core/battle/ai/PathFinder')
local BattleGUI = require('core/gui/battle/BattleGUI')

-- Alias
local indexOf = util.arrayIndexOf

-- Class table.
local TurnManager = class()

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Result codes.
-- @enum BattleResult
-- @field WIN Code for when player wins. Equals to 1.
-- @field DRAW Code for when no one wins. Equals to 0.
-- @field LOSE Code for when player loses. Equals to -1.
-- @field WALKOVER Code for when the enemy escapes. Equals to 2.
-- @field ESCAPE Code for when the player escapes. Equals to -2.
TurnManager.BattleResult = {
  WIN = 1,
  DRAW = 0,
  LOSE = -1,
  WALKOVER = 2,
  ESCAPE = -2
}
--- Info table returned when a BattleAction is concluded.
-- @tfield boolean endTurn Tells the TurnManager to pass turn to next party.
-- @tfield boolean endCharacterTurn Tells the TurnWindow to close and pass turn to the next character.
-- @tfield number|nil characterIndex Indicates the next turn's character (from same party).
-- @tfield boolean executed Is true if the chosen action was entirely executed (usually true, unless it was a
--  move action to an unreachable tile, or the action could not be executed for some reason).
-- @tfield boolean escaped Is true if all members of the current party have escaped.
TurnManager.ActionResult = {
  endTurn = false,
  endCharacterTurn = true,
  characterIndex = nil,
  executed = true,
  escaped = false
}

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

--- Executes turn and returns when the turn finishes.
-- @coroutine runTurn
-- @treturn number Result code (nil if battle is still running).
-- @treturn number The party that won or escaped (nil if battle is still running).
function TurnManager:runTurn(skipStart)
  local winner = TroopManager:winnerParty()
  if winner then
    if winner == TroopManager.playerParty then
      -- Player wins.
      return self.BattleResult.WIN, winner
    elseif winner == -1 then
      -- Draw.
      return self.BattleResult.DRAW, -1
    else
      -- Enemy wins.
      return self.BattleResult.LOSE, winner
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
        return self.BattleResult.ESCAPE, winner
      else
        return self.BattleResult.WALKOVER, winner
      end
    end
  end
  self:endTurn(result)
  self.turns = self.turns + 1
end
--- Runs the player's turn.
-- @coroutine runPlayerTurn
-- @treturn ActionResult result Result info for the current turn.
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
--- Whether there are characters on battle that can act, either by input or AI.
-- @treturn boolean
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
-- @tparam boolean skipStart True to skip any `onTurnStart` callbacks.
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
-- @tparam ActionResult result Result info for the current turn.
function TurnManager:endTurn(result)
  for char in TroopManager.characterList:iterator() do
    char.battler:onTurnEnd(char)
  end
end
--- Sets the next party.
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
-- @tparam ActionResult result Result info for the current turn.
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
