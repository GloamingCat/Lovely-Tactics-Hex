
--[[===============================================================================================

BattleManager
---------------------------------------------------------------------------------------------------
Controls battle flow (initializes troops, coordenates turns, checks victory
and game over).

=================================================================================================]]

-- Imports
local PathFinder = require('core/algorithm/PathFinder')
local MoveAction = require('core/battle/action/MoveAction')
local Animation = require('core/graphics/Animation')
local TileGraphics = require('core/fields/TileGUI')

-- Alias
local Random = love.math.random
local ceil = math.ceil
local yield = coroutine.yield
local time = love.timer.getDelta

-- Constants
local turnLimit = Battle.turnLimit

local BattleManager = require('core/class'):new()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
function BattleManager:init()
  self.turnLimit = turnLimit
  self.onBattle = false
  self.currentCharacter = nil
  self.currentAction = nil
end

-- Creates battle characters.
function BattleManager:setUpCharacters()
  TroopManager:createTroops()
end

-- Creates tiles' GUI components.
function BattleManager:setUpTiles()
  for tile in FieldManager.currentField:gridIterator() do
    tile.gui = TileGraphics(tile)
    tile.gui:updateDepth()
  end
end

-- Start a battle.
function BattleManager:runBattle()
  self.onBattle = true
  self:battleIntro()
  local winner = self:battleLoop()
  self:battleEnd()
  self.onBattle = false
  return winner
end

-- Runs before battle loop.
function BattleManager:battleIntro()
  local centers = TroopManager:getPartyCenters()
  local speed = 50
  for i = #centers, 0, -1 do
    local p = centers[i]
    if p then
      FieldManager.renderer:moveToPoint(p.x, p.y, true, speed)
      _G.Fiber:wait(30)
    end
  end
  _G.Fiber:wait(30)
end

-- Runs until battle finishes.
function BattleManager:battleLoop()
  while true do
    local char, it = self:getNextTurn()
    self:runTurn(char, it)
    local winner = TroopManager:winnerParty()
    if winner then
      return winner
    end
  end
end

-- Runs after winner was determined and battle loop ends.
function BattleManager:battleEnd()
  for char in TroopManager.characterList:iterator() do
    char.battler:onBattleEnd()
  end
  self:clear()
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

---------------------------------------------------------------------------------------------------
-- Turn
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Searchs for the next character turn and starts.
-- @ret(Character) the next turn's character
-- @ret(number) the number of iterations it took from the previous turn
function BattleManager:getNextTurn()
  self.turnQueue = TroopManager:getTurnQueue(turnLimit)
  local currentCharacter, iterations = self.turnQueue:front()
  if Battle.turnBar then
    local i = 0
    while i < iterations do
      i = i + time() * 60
      TroopManager:incrementTurnCount(turnLimit, time() * 60)
      yield()
    end
  else
    TroopManager:incrementTurnCount(turnLimit, iterations)
  end
  return currentCharacter, iterations
end

-- [COROUTINE] Executes turn and returns when the turn finishes.
-- @param(char : Character) turn's character
-- @param(iterations : number) the time since the last turn
function BattleManager:runTurn(char, iterations)
  -- Start turn
  self.currentCharacter = char
  char.battler.currentSteps = char.battler.steps()
  self:updateDistanceMatrix()
  for bc in TroopManager.characterList:iterator() do
    bc.battler:onTurnStart(iterations)
  end
  local actionCost = 0
  local AI = self.currentCharacter.battler.AI
  FieldManager.renderer:moveToObject(char, true)
  if AI and not self.training then
    actionCost = AI:nextAction(self.currentCharacter)
  else
    actionCost = GUIManager:showGUIForResult('battle/BattleGUI')
  end
  -- End Turn
  local battler = self.currentCharacter.battler
  local stepCost = battler.currentSteps / battler.steps()
  battler:decrementTurnCount(ceil((stepCost + actionCost) * turnLimit / 2))
  for bc in TroopManager.characterList:iterator() do
    bc.battler:onTurnEnd(iterations)
  end
  self.currentCharacter = nil
  self.currentAction = nil
end

-- Recalculates the distance matrix.
function BattleManager:updateDistanceMatrix()
  local moveAction = MoveAction()
  self.distanceMatrix = PathFinder.dijkstra(moveAction, self.currentCharacter)
end

---------------------------------------------------------------------------------------------------
-- User input
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Start a new action.
-- @param(action : BattleAction) the new action
function BattleManager:selectAction(action)
  self.currentAction = action
  if action then
    action:onSelect(self.currentCharacter)
  end
end

-- Focus on given tile.
-- @param(tile : ObjectTile) the new target tile
function BattleManager:selectTarget(tile)
  self.currentAction:selectTarget(tile, self.currentCharacter)
  FieldManager.renderer:moveToTile(tile)
end

---------------------------------------------------------------------------------------------------
-- Auxiliary functions
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Plays a battle animation.
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
  FieldManager.fiberList:fork(function()
    _G.Fiber:wait(animation.duration)
    FieldManager.updateList:removeElement(animation)
    animation.sprite:removeSelf()
  end)
  if wait then
    _G.Fiber:wait(animation.duration)
  end
  return animation
end

return BattleManager
