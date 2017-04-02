
--[[===========================================================================

SkillAction
-------------------------------------------------------------------------------
The BattleAction that is executed when players chooses a skill to use.

=============================================================================]]

-- Imports
local List = require('core/algorithm/List')
local BattleAction = require('core/battle/action/BattleAction')
local MoveAction = require('core/battle/action/MoveAction')
local PathFinder = require('core/algorithm/PathFinder')

-- Alias
local max = math.max
local isnan = math.isnan
local mathf = math.field
local time = love.timer.getDelta
local now = love.timer.getTime
local random = math.random
local round = math.round
local ceil = math.ceil

-- Constants
local elementCount = #Config.elements
local introTime = 22.5
local centerTime = 7.5
local targetTime = 2.2
local useTime = 2

local SkillAction = BattleAction:inherit()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

-- Overrides BattleAction:init.
-- @param(skill : Skill) the skill's data
local old_init = SkillAction.init
function SkillAction:init(initialTile, user, skill)
  old_init(self, initialTile, user)
  self.skill = skill
end

-------------------------------------------------------------------------------
-- Grid navigation
-------------------------------------------------------------------------------

-- Overrides BattleAction:selectTarget.
function SkillAction:selectTarget(tile)
  if self.currentTargets then
    for i = #self.currentTargets, 1, -1 do
      self.currentTargets[i].gui:setSelected(false)
    end
  end
  self.currentTarget = tile
  self.currentTargets = self:getAllAffectedTiles(tile)
  for i = #self.currentTargets, 1, -1 do
    self.currentTargets[i].gui:setSelected(true)
  end
end

-------------------------------------------------------------------------------
-- Selectable Tiles
-------------------------------------------------------------------------------

-- Paints and resets properties for the target tiles.
-- By default, paints all movable tile with movable color, and non-movable but 
-- reachable (within skill's range) tiles with the skill's type color.
-- @param(selectMovable : boolean) true to paint movable tiles
-- @param(selectBorder : boolean) true to paint non-movable tile within skill's range
function SkillAction:resetTargetTiles(selectMovable, selectBorder)
  self:resetAllTiles(false)
  self:resetMovableTiles(selectMovable)
  local matrix = BattleManager.distanceMatrix
  local field = FieldManager.currentField
  local charTile = BattleManager.currentCharacter:getTile()
  local range = self.skill.data.range + 1
  local h = charTile.layer.height
  local borderTiles = List()
  -- Find all border tiles
  for i = 1, self.field.sizeX do
    for j = 1, self.field.sizeY do
       -- If this tile is reachable
      if not isnan(matrix:get(i, j)) then
        local tile = self.field:getObjectTile(i, j, h)
        local isBorder = false
        for neighbor in tile.neighborList:iterator() do
          -- If this tile has any non-reachable neighbors
          if isnan(matrix:get(neighbor.x, neighbor.y)) then
            borderTiles:add(tile)
            break
          end
        end
      end
    end
  end
  if borderTiles:isEmpty() then
    borderTiles:add(charTile)
  end
  -- Paint border tiles
  for tile in borderTiles:iterator() do
    for i, j in mathf.radiusIterator(range, tile.x, tile.y) do
      if i >= 1 and j >= 0 and i <= field.sizeX and j <= field.sizeY then
        local n = field:getObjectTile(i, j, h) 
        if isnan(matrix:get(i, j)) then -- If this neighbor is not reachable
          n.gui.selectable = selectBorder and self:isSelectable(n)
          n.gui:setColor(self.skill.type)
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- Effect
-------------------------------------------------------------------------------

-- The effect applied when the user is prepared to use the skill.
-- It executes animations and applies damage/heal to the targets.
function SkillAction:onUse()
  -- Intro time.
  _G.Callback:wait(introTime)
  
  -- User's initial animation.
  local originTile = self.user:getTile()
  local dir = self.user:turnToTile(self.currentTarget.x, self.currentTarget.y)
  self.user:loadSkill(self.skill.data, dir, true)
  
  -- Cast animation
  FieldManager.renderer:moveToTile(self.currentTarget)
  self.user:castSkill(self.skill.data, dir)
  
  -- Minimum time to wait (initially, a frame).
  local minTime = 1
  
  -- Animation in center target tile 
  --  (does not wait full animation, only the minimum time).
  if self.skill.data.centerAnimID >= 0 then
    local mirror = self.user.direction > 90 and self.user.direction <= 270
    local x, y, z = mathf.tile2Pixel(self.currentTarget:coordinates())
    local animation = BattleManager:playAnimation(self.skill.data.centerAnimID,
      x, y, z - 1, mirror)
    _G.Callback:wait(centerTime)
  end
  
  -- Animation for each of affected tiles.
  self:allTargetsAnimation(originTile)
  
  -- Return user to original position and animation.
  self.user:finishSkill(originTile, self.skill.data)
  
  -- Wait until everything finishes.
  _G.Callback:wait(max (0, minTime - now()) + 60)
end

-- Gets all tiles that will be affected by skill's effect.
-- @ret(table) an array of tiles
function SkillAction:getAllAffectedTiles()
  local tiles = {}
  local field = FieldManager.currentField
  local height = self.currentTarget.layer.height
  for i, j in mathf.radiusIterator(self.skill.data.radius, 
      self.currentTarget.x, self.currentTarget.y) do
    if i >= 1 and j >= 0 and i <= field.sizeX and j <= field.sizeY then
      tiles[#tiles + 1] = field:getObjectTile(i, j, height)
    end
  end
  return tiles
end

-- Calculates the final damage / heal for the target.
-- It considers all element bonuses provided by the skill data.
-- @param(target : Character) the target character
-- @ret(number) the final value (nil if miss)
function SkillAction:calculateEffectResult(target)
  local rate = self.skill:calculateSuccessRate(self.user.battler.att, 
    target.battler.att)
  if random() + random(1, 99) > rate then
    return nil
  end
  local result = self.skill:calculateBasicResult(self.user.battler.att, 
    target.battler.att)
  local bonus = 0
  local skillElementFactors = self.skill.elementFactors
  local targetElementFactors = target.battler.elementFactors
  for i = 1, elementCount do
    bonus = bonus + skillElementFactors[i] * targetElementFactors[i]
  end
  bonus = result * bonus
  return round(bonus + result)
end

-------------------------------------------------------------------------------
-- Target Animations
-------------------------------------------------------------------------------

-- Executes individual animation for all the affected tiles.
function SkillAction:allTargetsAnimation(originTile)
  local allTargets = self.currentTargets or 
    self:getAllAffectedTiles(self.currentTarget)
  for i = #allTargets, 1, -1 do
    local tile = allTargets[i]
    for char in tile.characterList:iterator() do
      self:singleTargetAnimation(char, originTile)
    end
  end
end

-- Executes individual animation for a single tile.
function SkillAction:singleTargetAnimation(char, originTile)
  local result = self:calculateEffectResult(char)
  if not result or result == 0 then
    -- Pop-up 'miss'
  elseif result > 0 then
    if self.skill.data.radius > 1 then
      originTile = self.currentTarget
    end
    _G.Callback.tree:fork(function()
      char:damage(self.skill.data, result, originTile)
    end)
  else
    _G.Callback.tree:fork(function()
      char:heal(self.skill.data, -result)
    end)
  end
  _G.Callback:wait(targetTime)
end

-------------------------------------------------------------------------------
-- Event handlers
-------------------------------------------------------------------------------

-- Overrides BattleAction:onActionGUI.
function SkillAction:onActionGUI(GUI)
  self:resetAllTiles(false)
  self:resetMovableTiles(true)
  GUI:createTargetWindow()
  GUI:startGridSelecting(self:firstTarget())
end

-- Overrides BattleAction:onConfirm.
-- Executes the movement action and the skill's effect, 
-- and then decrements battler's turn count and steps.
function SkillAction:onConfirm(GUI)
  GUI:endGridSelecting()
  FieldManager.renderer:moveToObject(self.user, true)
  FieldManager.renderer.focusObject = self.user
  local moveAction = MoveAction(self.currentTarget, self.user, self.skill.data.range)
  local path = PathFinder.findPath(moveAction)
  if path then -- Target was reached
    self.user:walkPath(path)
    self:onUse()
  else -- Target was not reached
    path = PathFinder.findPathToUnreachable(moveAction)
    path = path or PathFinder.estimateBestTile(moveAction)
    self.user:walkPath(path)
  end
  local battler = self.user.battler
  if path.lastStep:isControlZone(battler) then
    battler.currentSteps = 0
  else
    battler.currentSteps = battler.currentSteps - path.totalCost
  end
  local cost = self.skill.data.timeCost * BattleManager.turnLimit / 200
  battler:decrementTurnCount(ceil(cost))
  return 1
end

return SkillAction
