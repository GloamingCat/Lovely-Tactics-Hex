
--[[===============================================================================================

BattleManager
---------------------------------------------------------------------------------------------------
Controls battle flow (initializes troops, runs loop, checks victory and game over).
Parameters:
  gameOverCondition: 0 => no gameover, 1 => only when lost, 2 => only lost or draw
  skipAnimations: for debugging purposes (skips battle/character animations)
  escapeEnabled: enable Escape action
Results: 1 => win, 0 => draw, -1 => lost

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')
local TileGraphics = require('core/field/TileGUI')

-- Constants
local defaultParams = { 
  gameOverCondition = 2, 
  escapeEnabled = true }

local BattleManager = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function BattleManager:init()
  self.onBattle = false
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
-- @ret(number) the winner party
function BattleManager:runBattle()
  self.onBattle = true
  self.result = nil
  self.winner = nil
  self:battleStart()
  TurnManager:introTurn()
  repeat
    self.result, self.winner = TurnManager:runTurn()
  until self.result
  self:battleEnd()
  self.onBattle = false
  return self.winner, self.result
end
-- Runs before battle loop.
function BattleManager:battleStart()
  --[[FieldManager.renderer:fadeout(0)
  FieldManager.renderer:fadein(nil, true)
  local centers = TroopManager:getPartyCenters()
  local speed = 50
  for i = 1, #centers do
    if i ~= TroopManager.playerParty then
      local p = centers[i]
      FieldManager.renderer:moveToPoint(p.x, p.y, speed, true)
      _G.Fiber:wait(45)
    end
  end
  local p = centers[TroopManager.playerParty]
  FieldManager.renderer:moveToPoint(p.x, p.y, speed, true)
  _G.Fiber:wait(60)]]
  for char in TroopManager.characterList:iterator() do
    char.battler:onBattleStart(char)
  end
end
-- Runs after winner was determined and battle loop ends.
function BattleManager:battleEnd()
  if self.result == 1 then
    PartyManager:addRewards()
  elseif self.result == 0 then
    if self.params.gameOverCondition >= 2 then
      return self:gameOver()
    end
  elseif self.result == -1 then
    if self.params.gameOverCondition >= 1 then
      return self:gameOver()
    end
  end
  for char in TroopManager.characterList:iterator() do
    char.battler:onBattleEnd(char)
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
-- Checks if player won battle.
function BattleManager:playerWon()
  return self.result == 1
end
-- Checks if player escaped.
function BattleManager:playerEscaped()
  return self.result == -2 and self.winner == TroopManager.playerParty
end
-- Checks if enemy won battle.
function BattleManager:enemyWon()
  return self.result == -1
end
-- Checks if enemy escaped.
function BattleManager:enemyEscaped()
  return self.result == -2 and self.winner ~= TroopManager.playerParty
end
-- Checks if there was a draw.
function BattleManager:drawed()
  return self.result == 0
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
  local animData = Database.animations[animID]
  local animation = ResourceManager:loadAnimation(animData, FieldManager.renderer)
  animation.sprite:setXYZ(x, y, z)
  animation.sprite:setTransformation(animData.transform)
  if mirror then
    animation.sprite:setScale(-animation.sprite.scaleX, animation.sprite.scaleY)
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
