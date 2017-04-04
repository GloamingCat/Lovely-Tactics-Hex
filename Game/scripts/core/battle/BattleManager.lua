
--[[===========================================================================

BattleManager
-------------------------------------------------------------------------------
Controls battle flow (initializes troops, coordenates turns, checks victory
and game over).

=============================================================================]]

-- Imports
local PathFinder = require('core/algorithm/PathFinder')
local CallbackTree = require('core/callback/CallbackTree')
local MoveAction = require('core/battle/action/MoveAction')
local Animation = require('core/graphics/Animation')
local TileGraphics = require('core/fields/TileGUI')

-- Alias
local Random = love.math.random
local ceil = math.ceil

-- Constants
local turnLimit = Battle.turnLimit

local BattleManager = require('core/class'):new()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

function BattleManager:init()
  self.turnLimit = turnLimit
  self.onBattle = false
  self.currentCharacter = nil
  self.currentAction = nil
end

-- Start a battle.
function BattleManager:startBattle()
  for tile in FieldManager.currentField:gridIterator() do
    tile.gui = TileGraphics(tile)
    tile.gui:updateDepth()
  end
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
  for bc in TroopManager.characterList:iterator() do
    bc.battler = nil
  end
  for tile in FieldManager.currentField:gridIterator() do
    tile.gui = nil
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
  if Battle.turnBar then
    while not self.currentCharacter do
      self.currentCharacter = TroopManager:incrementTurnCount(turnLimit)
      iterations = iterations + 1
      coroutine.yield()
    end
  else
    while not self.currentCharacter and iterations < turnLimit do
      self.currentCharacter = TroopManager:incrementTurnCount(turnLimit)
      iterations = iterations + 1
    end
  end
  for bc in TroopManager.characterList:iterator() do
    bc.battler:onTurnStart(iterations)
  end
  print('Turn started in: ' .. iterations)
  self:startTurn()
  for bc in TroopManager.characterList:iterator() do
    bc.battler:onTurnEnd(iterations)
  end
  self.currentCharacter = nil
end

-- [COROUTINE] Executes turn and returns when the turn finishes.
function BattleManager:startTurn()
  local char = self.currentCharacter
  char.battler.currentSteps = char.battler.steps()
  self:updateDistanceMatrix()
  local actionCost = 0
  local AI = self.currentCharacter.battler.AI
  FieldManager.renderer:moveToObject(char, true)
  if AI then
    actionCost = AI.nextAction(self.currentCharacter)
  else
    actionCost = GUIManager:showGUIForResult('battle/BattleGUI')
  end
  -- Turn end
  local battler = self.currentCharacter.battler
  local stepCost = battler.currentSteps / battler.steps()
  battler:decrementTurnCount(ceil((stepCost + actionCost) * turnLimit / 2))
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
-- @param(tile : ObjectTile) the new target tile
function BattleManager:selectTarget(tile)
  self.currentAction:selectTarget(tile)
  FieldManager.renderer:moveToTile(tile)
end

-- Plays a battle animation.
-- @param(animID : number) the animation's ID from database
-- @param(x : number) pixel x of the animation
-- @param(y : number) pixel y of the animation
-- @param(z : number) pixel depth of the animation
-- @param(mirror : boolean) mirror the sprite in x-axis
-- @param(wait : boolean) true to wait until first loop finishes (optional)
-- @ret(Animation) the newly created animation
function BattleManager:playAnimation(animID, x, y, z, mirror, wait)
  local animationData = Database.animBattle[animID + 1]
  local animation = Animation.fromData(animationData, FieldManager.renderer)
  animation.sprite:setXYZ(x, y, z)
  animation.sprite:setTransformation(animationData.transform)
  if mirror then
    animation.sprite:setScale(-1)
  end
  FieldManager.updateList:add(animation)
  FieldManager.callbackTree:fork(function(callback)
    callback:wait(animation.duration)
    FieldManager.updateList:removeElement(animation)
    animation.sprite:removeSelf()
  end)
  if wait then
    _G.Callback:wait(animation.duration)
  end
  return animation
end

return BattleManager
