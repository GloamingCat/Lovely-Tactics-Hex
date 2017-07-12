
--[[===============================================================================================

BattleManager
---------------------------------------------------------------------------------------------------
Controls battle flow (initializes troops, coordenates turns, checks victory
and game over).

=================================================================================================]]

-- Imports
local PathFinder = require('core/battle/ai/PathFinder')
local MoveAction = require('core/battle/action/MoveAction')
local Animation = require('core/graphics/Animation')
local TileGraphics = require('core/fields/TileGUI')

-- Alias
local Random = love.math.random
local yield = coroutine.yield
local time = love.timer.getDelta

-- Constants
local turnLimit = Battle.turnLimit
local defaultParams = { gameOver = true, skipAnimations = false }

local BattleManager = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function BattleManager:init()
  self.turnLimit = turnLimit
  self.onBattle = false
  self.currentCharacter = nil
end
-- Creates battle elements.
-- @param(params : table) battle params to be used by custom scripts
function BattleManager:setUp(params)
  self.params = params or defaultParams
  self:setUpTiles()
  self:setUpCharacters()
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

---------------------------------------------------------------------------------------------------
-- Battle Loop
---------------------------------------------------------------------------------------------------

-- Runs until battle finishes.
function BattleManager:runBattle()
  self.onBattle = true
  self:battleIntro()
  local winner = nil
  repeat
    if InputManager.keys['kill']:isPressing() then
      self:killAll(TroopManager.playerParty)
      break
    end
    local char, it = self:getNextTurn()
    self:runTurn(char, it)
    winner = TroopManager:winnerParty()
  until winner
  if winner == TroopManager.playerParty then
    PartyManager:addRewards()
  elseif self.params.gameOver then
    self:gameOver()
  end
  self:battleEnd()
  self.onBattle = false
  return winner
end
-- Runs before battle loop.
function BattleManager:battleIntro()
  if self.params.skipAnimations then
    return
  end
  FieldManager.renderer:fadeout(0)
  FieldManager.renderer:fadein(nil, true)
  local centers = TroopManager:getPartyCenters()
  local speed = 50
  for i = #centers, 0, -1 do
    local p = centers[i]
    if p then
      FieldManager.renderer:moveToPoint(p.x, p.y, speed, true)
      _G.Fiber:wait(30)
    end
  end
  _G.Fiber:wait(30)
end
-- Runs after winner was determined and battle loop ends.
function BattleManager:battleEnd()
  for char in TroopManager.characterList:iterator() do
    local b = char.battler
    b:onBattleEnd()
    if b.data.persistent then
      SaveManager.current.battlerData[b.battlerID] = b.state
    end
  end
  FieldManager.renderer:fadeout(nil, true)
  self:clear()
end
-- Clears batte information from characters and field.
function BattleManager:clear()
  for tile in FieldManager.currentField:gridIterator() do
    tile.gui:destroy()
    tile.gui = nil
  end
  if self.cursor then
    self.cursor:destroy()
  end
  TroopManager:clear()
  self.pathMatrix = nil
end

---------------------------------------------------------------------------------------------------
-- Battle results
---------------------------------------------------------------------------------------------------

-- Called when player loses.
function BattleManager:gameOver()
  -- TODO: 
  -- fade out screen
  -- show game over GUI
end
-- Called to forcefully end battle by killing every battler which is not in the winner team.
-- @param(party : number) winner team (nil to kill everybody)
function BattleManager:killAll(party)
  for char in TroopManager.characterList:iterator() do
    if char.battler.party ~= party then
      char.battler:kill()
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Turn
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Searchs for the next character turn and starts.
-- @param(ignoreAnim : boolean) true to skip bar increasing animation
-- @ret(Character) the next turn's character
-- @ret(number) the number of iterations it took from the previous turn
function BattleManager:getNextTurn(ignoreAnim)
  self.turnQueue = TroopManager:getTurnQueue(turnLimit)
  local currentCharacter, iterations = self.turnQueue:front()
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
-- [COROUTINE] Executes turn and returns when the turn finishes.
-- @param(char : Character) turn's character
-- @param(iterations : number) the time since the last turn
function BattleManager:runTurn(char, iterations)
  self:startTurn(char, iterations)
  local actionCost = 0
  local AI = self.currentCharacter.battler.AI
  if not self.params.skipAnimations then
    FieldManager.renderer:moveToObject(char, nil, true)
  end
  if AI and not self.training then
    actionCost = AI:runTurn(iterations, char)
  else
    actionCost = GUIManager:showGUIForResult('battle/BattleGUI')
  end
  self:endTurn(actionCost, iterations)
end
-- Prepares for turn.
-- @param(char : Character) the new character of the turn
-- @param(iterations : number) the time since the last turn
function BattleManager:startTurn(char, iterations)
  self.currentCharacter = char
  char.battler:onSelfTurnStart(iterations)
  self:updatePathMatrix()
  for bc in TroopManager.characterList:iterator() do
    bc.battler:onTurnStart(iterations)
  end
end
-- Closes turn.
-- @param(actionCost : number) the time spend by the character of the turn
-- @param(iterations : number) the time since the last turn
function BattleManager:endTurn(actionCost, iterations)
  self.currentCharacter.battler:onSelfTurnEnd(iterations, actionCost + 1)
  for bc in TroopManager.characterList:iterator() do
    bc.battler:onTurnEnd(iterations)
  end
  self.currentCharacter = nil
end
-- Recalculates the distance matrix.
function BattleManager:updatePathMatrix()
  local moveAction = MoveAction()
  self.pathMatrix = PathFinder.dijkstra(moveAction, self.currentCharacter)
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
    animation:destroy()
  end)
  if wait then
    _G.Fiber:wait(animation.duration)
  end
  return animation
end

return BattleManager
