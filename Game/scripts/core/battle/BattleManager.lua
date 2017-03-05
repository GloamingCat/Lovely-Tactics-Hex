
local PathFinder = require('core/algorithm/PathFinder')
local CallbackTree = require('core/callback/CallbackTree')
local MoveAction = require('core/battle/action/MoveAction')
local Random = love.math.random
local turnLimit = Config.battle.turnLimit

--[[===========================================================================

The BattleManager controls battle flow.

=============================================================================]]

local BattleManager = require('core/class'):new()

function BattleManager:init()
  self.turnLimit = turnLimit
  self.onBattle = false
  self.currentCharacter = nil
  self.currentAction = nil
end

-- Start a battle.
function BattleManager:startBattle()
  return self:battleLoop()
end

-- Runs until battle finishes.
function BattleManager:battleLoop()
  while true do
    self:nextTurn()
    local winner = TroopManager:winnerParty()
    if winner then
      self:clear()
      return winner
    end
  end
end

-- Clears batte information from characters and field.
function BattleManager:clear()
  for _, bc in TroopManager.characterList:iterator() do
    bc.battler = nil
  end
  if self.cursor then
    self.cursor:destroy()
  end
end

-------------------------------------------------------------------------------
-- Turn
-------------------------------------------------------------------------------

-- [COROUTINE] Searchs for the next character turn and starts.
function BattleManager:nextTurn()
  local iterations = 0
  if Config.battle.instantTurnTransition then
    while not self.currentCharacter and iterations < turnLimit do
      self.currentCharacter = TroopManager:incrementTurnCount(turnLimit)
      iterations = iterations + 1
    end
  else
    while not self.currentCharacter do
      self.currentCharacter = TroopManager:incrementTurnCount(turnLimit)
      iterations = iterations + 1
      coroutine.yield()
    end
  end
  for i, bc in TroopManager.characterList:iterator() do
    bc.battler:onTurnStart(iterations)
  end
  print('Turn started in: ' .. iterations)
  self:startTurn()
  for i, bc in TroopManager.characterList:iterator() do
    bc.battler:onTurnEnd(iterations)
  end
  self.currentCharacter = nil
end

-- [COROUTINE] Executes turn and returns when the turn finishes.
function BattleManager:startTurn()
  self:updateDistanceMatrix()
  local AI = self.currentCharacter.battler.AI
  if AI then
    local char = self.currentCharacter
    FieldManager.renderer:moveTo(char.position.x, char.position.y)
    AI.nextAction(self.currentCharacter)
  else
    repeat
      print(self.currentCharacter:toString())
      local result = GUIManager:showGUIForResult('battle/BattleGUI')
    until result == 1
  end
end

-- Re-calculates the distance matrix.
function BattleManager:updateDistanceMatrix()
  local moveAction = MoveAction()
  self.distanceMatrix = PathFinder.dijkstra(moveAction)
end

-- [COROUTINE] Start a new action.
-- @param(action : BattleAction) the new action
function BattleManager:selectAction(action)
  self.currentAction = action
  if action then
    action:onSelect()
  end
end

-- Focus on given tile.
function BattleManager:selectTarget(tile)
  self.currentAction:selectTarget(tile)
  FieldManager.callbackTree:fork(function()
      FieldManager.renderer:moveToTile(tile)
    end)
end

return BattleManager
