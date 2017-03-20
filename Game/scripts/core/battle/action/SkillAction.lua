
--[[===========================================================================

The BattleAction that is executed when players chooses a skill to use.

=============================================================================]]

-- Imports
local Callback = require('core/callback/Callback')
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

local SkillAction = BattleAction:inherit()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

local old_init = SkillAction.init
function SkillAction:init(initialTile, user, skill)
  old_init(self, initialTile, user)
  self.data = skill
  -- Skill type
  if skill.type == 0 then
    self.type = 'general'
  elseif skill.type == 1 then
    self.type = 'attack'
  elseif skill.type == 2 then
    self.type = 'support'
  end
  -- Formulae
  if self.data.basicResult ~= '' then
    self.calculateBasicResult = self:loadFormulae(self.data.basicResult, 
      'action, a, b')
  end
  if self.data.successRate ~= '' then
    self.calculateSuccessRate = self:loadFormulae(self.data.successRate, 
      'action, a, b')
  end
  -- Store elements
  local e = {}
  for i = 1, #skill.elements do
    e[skill.elements[i].id + 1] = skill.elements[i].value
  end
  for i = 1, elementCount do
    if not e[i] then
      e[i] = 0
    end
  end
  self.elementFactors = e
end

-- Generates a function from a formulae in string.
-- @param(formulae : string) the formulae expression
-- @param(param : string) the param needed for the function (optional)
-- @ret(function) the function that evaluates the formulae
function SkillAction:loadFormulae(formulae, param)
  formulae = 'return ' .. formulae
  if param and param ~= '' then
    local funcString = 
      'function(' .. param .. ') ' ..
        formulae ..
      ' end'
    return loadstring('return ' .. funcString)()
  else
    return loadstring(formulae)
  end
end

-------------------------------------------------------------------------------
-- Grid navigation
-------------------------------------------------------------------------------

-- Overrides BattleAction:selectTarget.
function SkillAction:selectTarget(tile)
  if self.currentTargets then
    for i = #self.currentTargets, 1, -1 do
      self.currentTargets[i]:setSelected(false)
    end
    print('not null')
  end
  self.currentTarget = tile
  self.currentTargets = self:getAllAffectedTiles(tile)
  for i = #self.currentTargets, 1, -1 do
    self.currentTargets[i]:setSelected(true)
  end
end

-------------------------------------------------------------------------------
-- Selectable Tiles
-------------------------------------------------------------------------------

function SkillAction:resetTargetTiles(selectMovable, selectBorder)
  self:resetAllTiles(false)
  self:resetMovableTiles(selectMovable)
  local matrix = BattleManager.distanceMatrix
  local field = FieldManager.currentField
  local charTile = BattleManager.currentCharacter:getTile()
  local h = charTile.layer.height
  for i = 1, self.field.sizeX do
    for j = 1, self.field.sizeY do
       -- If this tile is reachable
      if not isnan(matrix:get(i, j)) then
        
        local tile = self.field:getObjectTile(i, j, h)
        local isBorder = false
        for neighbor in tile.neighborList:iterator() do
          -- If this tile has any non-reachable neighbors
          if isnan(matrix:get(neighbor.x, neighbor.y)) then
            isBorder = true
            break
          end
        end
        if isBorder then
          for i, j in mathf.radiusIterator(self.data.range + 1, 
              tile.x, tile.y, field.sizeX, field.sizeY) do
            local n = field:getObjectTile(i, j, h) 
            if isnan(matrix:get(n.x, n.y)) then
              n.selectable = selectBorder and self:isSelectable(n)
              n:setColor(self.type)
            end
          end
        end
        
      end
    end
    for i, j in mathf.radiusIterator(self.data.range + 1, 
        charTile.x, charTile.y, field.sizeX, field.sizeY) do
      if isnan(matrix:get(i, j)) then
        local n = field:getObjectTile(i, j, h)
        n.selectable = selectBorder and self:isSelectable(n)
        n:setColor(self.type)
      end
    end
  end
  
end

-------------------------------------------------------------------------------
-- Effect
-------------------------------------------------------------------------------

-- The effect applied when the user is prepared to use the skill.
-- It executes animations and applies damage/heal to the targets.
function SkillAction:effect()
  local originTile = self.user:getTile()
  local startTime = now()
  local minTime = 0
  minTime = minTime + self:effectIntro(originTile)
  minTime = minTime + self:effectCenter(originTile)
  minTime = minTime + self:effectFinish(originTile)
  Callback.current:wait(max (0, startTime + minTime - now()) + 1)
end

-- Gets all tiles that will be affected by skill's effect.
-- @ret(table) an array of tiles
function SkillAction:getAllAffectedTiles()
  local tiles = {}
  local field = FieldManager.currentField
  local height = self.currentTarget.layer.height
  for i, j in mathf.radiusIterator(self.data.radius, self.currentTarget.x,
      self.currentTarget.y, field.sizeX, field.sizeY) do
    tiles[#tiles + 1] = field:getObjectTile(i, j, height)
  end
  return tiles
end

-- Calculates the final damage / heal for the target.
-- It considers all element bonuses provided by the skill data.
-- @param(target : Character) the target character
-- @ret(number) the final value (nil if miss)
function SkillAction:calculateEffectResult(target)
  local rate = self:calculateSuccessRate(self.user.battler.att, 
    target.battler.att)
  if random() + random(1, 99) > rate then
    return nil
  end
  local result = self:calculateBasicResult(self.user.battler.att, 
    target.battler.att)
  local bonus = 0
  local targetElementFactors = target.battler.elementFactors
  for i = 1, elementCount do
    bonus = bonus + self.elementFactors[i] * targetElementFactors[i]
  end
  bonus = result * bonus
  return round(bonus + result)
end

-------------------------------------------------------------------------------
-- Animation
-------------------------------------------------------------------------------

-- Animation for the start of the skill.
-- @ret(number) the total duration of the animation
function SkillAction:effectIntro()
  local start = now()
  local introTime = 22.5
  Callback.current:wait(introTime)
  self.user:startSkill(self.currentTarget, self.data)
  print(now() - start)
  return now() - start
end

-- Animation for the center of the targets.
-- @ret(number) the total duration of the animation
function SkillAction:effectCenter()
  FieldManager.renderer:moveToTile(self.currentTarget)
  if self.data.centerAnimID >= 0 then
    local targetTime = 7.5
    local mirror = self.user.direction > 90 and self.user.direction <= 270
    local x, y, z = mathf.tile2Pixel(self.currentTarget:coordinates())
    local animation = BattleManager:playAnimation(self.data.centerAnimID,
      x, y, z - 1, mirror)
    Callback.current:wait(targetTime)
    return animation.duration - targetTime
  end
  return 0
end

-- Animation for the end of the skill.
-- @ret(number) the total duration of the animation
function SkillAction:effectFinish(originTile)
  local start = now()
  self:allTargetsAnimation(originTile)
  self.user:finishSkill(originTile, self.data)
  return now() - start
end

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
    if self.data.radius > 0 then
      originTile = self.currentTarget
    end
    char:damage(self.data, result, originTile)
  else
    char:heal(self.data, -result)
  end
  local targetTime = 2
  Callback.current:wait(targetTime)
end

-------------------------------------------------------------------------------
-- Event handlers
-------------------------------------------------------------------------------

-- Overrides BattleAction:onConfirm.
-- Executes the movement action and the skill's effect, 
-- and then decrements battler's turn count and steps.
function SkillAction:onConfirm(GUI)
  GUI:endGridSelecting()
  FieldManager.renderer:moveToObject(self.user, true)
  FieldManager.renderer.focusObject = self.user
  local moveAction = MoveAction(self.currentTarget, self.user, self.data.range)
  local path = PathFinder.findPath(moveAction)
  if path then -- Target was reached
    self.user:walkPath(path)
    self:effect()
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
  battler:decrementTurnCount(ceil(self.data.timeCost * BattleManager.turnLimit / 200))
  return 1
end

return SkillAction
