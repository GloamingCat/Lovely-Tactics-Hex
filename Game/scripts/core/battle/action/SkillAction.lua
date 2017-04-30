
--[[===============================================================================================

SkillAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players chooses a skill to use.

=================================================================================================]]

-- Imports
local List = require('core/algorithm/List')
local BattleAction = require('core/battle/action/BattleAction')
local MoveAction = require('core/battle/action/MoveAction')
local PathFinder = require('core/algorithm/PathFinder')
local PopupText = require('core/battle/PopupText')

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

local SkillAction = class(BattleAction)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(skill : Skill) the skill's data
local old_init = SkillAction.init
function SkillAction:init(skillID)
  old_init(self)
  local data = Database.skills[skillID + 1]
  self.data = data
  self.id = skillID
  -- Skill type
  if data.type == 0 then
    self.type = 'general'
  elseif data.type == 1 then
    self.type = 'attack'
  elseif data.type == 2 then
    self.type = 'support'
  end
  -- Formulae
  if data.basicResult ~= '' then
    self.calculateBasicResult = self:loadFormulae(data.basicResult, 
      'action, a, b, rand')
  end
  if data.successRate ~= '' then
    self.calculateSuccessRate = self:loadFormulae(data.successRate, 
      'action, a, b, rand')
  end
  -- Store elements
  local e = {}
  for i = 1, #data.elements do
    e[data.elements[i].id + 1] = data.elements[i].value
  end
  for i = 1, elementCount do
    if not e[i] then
      e[i] = 0
    end
  end
  self.elementFactors = e
end

-- Creates an SkillAction given the skill's ID in the database.
function SkillAction.fromData(skillID)
  local data = Database.skills[skillID + 1]
  if data.script.path ~= '' then
    local class = require('custom/' .. data.script.path)
    return class(skillID, data.script.param)
  else
    return SkillAction(skillID)
  end
end

-- Converting to string.
-- @ret(string) a string representation
function SkillAction:__tostring()
  return 'SkillAction: ' .. self.skillID .. ' (' .. self.data.name .. ')'
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

---------------------------------------------------------------------------------------------------
-- Grid navigation
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:selectTarget.
function SkillAction:selectTarget(GUI, tile)
  if GUI then
    FieldManager.renderer:moveToTile(tile)
    if self.currentTargets then
      for i = #self.currentTargets, 1, -1 do
        self.currentTargets[i].gui:setSelected(false)
      end
    end
  end
  self.currentTarget = tile
  self.currentTargets = self:getAllAffectedTiles(tile)
  if GUI then
    for i = #self.currentTargets, 1, -1 do
      self.currentTargets[i].gui:setSelected(true)
    end
  end
end

-- Sets the given tile as the current target.
function SkillAction:setCurrentTarget(tile)

end

---------------------------------------------------------------------------------------------------
-- Selectable Tiles
---------------------------------------------------------------------------------------------------

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
  local range = self.data.range
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
          n.gui:setColor(self.type)
        end
      end
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Effect
---------------------------------------------------------------------------------------------------

-- The effect applied when the user is prepared to use the skill.
-- It executes animations and applies damage/heal to the targets.
function SkillAction:onUse(user)
  -- Intro time.
  _G.Fiber:wait(introTime)
  
  -- User's initial animation.
  local originTile = user:getTile()
  local dir = user:turnToTile(self.currentTarget.x, self.currentTarget.y)
  user:loadSkill(self.data, dir, true)
  
  -- Cast animation
  FieldManager.renderer:moveToTile(self.currentTarget)
  user:castSkill(self.data, dir)
  
  -- Minimum time to wait (initially, a frame).
  local minTime = 1
  
  -- Animation in center target tile 
  --  (does not wait full animation, only the minimum time).
  if self.data.centerAnimID >= 0 then
    local mirror = user.direction > 90 and user.direction <= 270
    local x, y, z = mathf.tile2Pixel(self.currentTarget:coordinates())
    local animation = BattleManager:playAnimation(self.data.centerAnimID,
      x, y, z - 1, mirror)
    _G.Fiber:wait(centerTime)
  end
  
  -- Animation for each of affected tiles.
  self:allTargetsAnimation(user, originTile)
  
  -- Return user to original position and animation.
  user:finishSkill(originTile, self.data)
  
  -- Wait until everything finishes.
  _G.Fiber:wait(max (0, minTime - now()) + 60)
end

-- Gets all tiles that will be affected by skill's effect.
-- @ret(table) an array of tiles
function SkillAction:getAllAffectedTiles()
  local tiles = {}
  local field = FieldManager.currentField
  local height = self.currentTarget.layer.height
  for i, j in mathf.radiusIterator(self.data.radius - 1, 
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
function SkillAction:calculateEffectResult(user, target, rand)
  rand = rand or random
  local rate = self:calculateSuccessRate(user.battler.att, 
    target.battler.att, random)
  if rand() + rand(1, 99) > rate then
    return nil
  end
  local result = self:calculateBasicResult(user.battler.att, 
    target.battler.att, rand)
  local bonus = 0
  local skillElementFactors = self.elementFactors
  local targetElementFactors = target.battler.elementFactors
  for i = 1, elementCount do
    bonus = bonus + skillElementFactors[i] * targetElementFactors[i]
  end
  bonus = result * bonus
  return round(bonus + result)
end

---------------------------------------------------------------------------------------------------
-- Target Animations
---------------------------------------------------------------------------------------------------

-- Executes individual animation for all the affected tiles.
function SkillAction:allTargetsAnimation(user, originTile)
  local allTargets = self.currentTargets or 
    self:getAllAffectedTiles(self.currentTarget)
  for i = #allTargets, 1, -1 do
    local tile = allTargets[i]
    for target in tile.characterList:iterator() do
      self:singleTargetAnimation(user, target, originTile)
    end
  end
end

-- Executes individual animation for a single tile.
function SkillAction:singleTargetAnimation(user, target, originTile)
  local result = self:calculateEffectResult(user, target)
  if not result then
    -- Miss
    local pos = target.position
    local popupText = PopupText(pos.x, pos.y - 20, pos.z - 10)
    popupText:addLine(Vocab.miss, Color.popup_miss, Font.popup_miss)
    popupText:popup()
  elseif result >= 0 then
    -- Damage
    if self.data.radius > 1 then
      originTile = self.currentTarget
    end
    _G.Fiber:fork(function()
      target:damage(self.data, result, originTile)
    end)
  else
    -- Heal
    _G.Fiber:fork(function()
      target:heal(self.data, -result)
    end)
  end
  _G.Fiber:wait(targetTime)
end

---------------------------------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:onActionGUI.
function SkillAction:onActionGUI(GUI, user)
  self:resetAllTiles(false)
  self:resetMovableTiles(true)
  GUI:createTargetWindow()
  GUI:startGridSelecting(self:firstTarget(user))
end

-- Overrides BattleAction:onConfirm.
-- Executes the movement action and the skill's effect, 
-- and then decrements battler's turn count and steps.
function SkillAction:onConfirm(GUI, user)
  if GUI then
    GUI:endGridSelecting()
  end
  FieldManager.renderer:moveToObject(user, true)
  FieldManager.renderer.focusObject = user
  local moveAction = MoveAction(self.data.range, self.currentTarget)
  local path = PathFinder.findPath(moveAction, user)
  if path then -- Target was reached
    user:walkPath(path)
    self:onUse(user)
  else -- Target was not reached
    path = PathFinder.findPathToUnreachable(moveAction, user)
    path = path or PathFinder.estimateBestTile(moveAction, user)
    user:walkPath(path)
  end
  local battler = user.battler
  if path.lastStep:isControlZone(battler) then
    battler.currentSteps = 0
  else
    battler.currentSteps = battler.currentSteps - path.totalCost
  end
  local cost = self.data.timeCost * BattleManager.turnLimit / 200
  battler:decrementTurnCount(ceil(cost))
  return 1
end

return SkillAction
