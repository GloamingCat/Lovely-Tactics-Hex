
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
local expectation = math.randomExpectation

-- Constants
local elementCount = #Config.elements
local introTime = 22.5
local centerTime = 7.5
local targetTime = 2.2
local useTime = 2

local SkillAction = class(BattleAction)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(skillID : number) the skill's ID from database
local old_init = SkillAction.init
function SkillAction:init(skillID)
  local data = Database.skills[skillID + 1]
  self.data = data
  local color = nil
  -- Skill type
  if data.type == 0 then
    color = 'general'
  elseif data.type == 1 then
    color = 'attack'
  elseif data.type == 2 then
    color = 'support'
  end
  old_init(self, data.timeCost, data.range, data.radius, color)
  -- Formulae
  if data.basicResult ~= '' then
    self.calculateBasicResult = loadformula(data.basicResult, 
      'action, a, b, rand')
  end
  if data.successRate ~= '' then
    self.calculateSuccessRate = loadformula(data.successRate, 
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
  return 'SkillAction: ' .. self.data.id
end

---------------------------------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:onConfirm.
-- Executes the movement action and the skill's effect.
function SkillAction:onConfirm(input)
  local moveAction = MoveAction(self.data.range, input.target)
  local path = PathFinder.findPath(moveAction, input.user, input.target)
  if input.skipAnimations then
    if path then
      input.user:moveToTile(path.lastStep)
      self:applyEffects(input)
    else
      path = PathFinder.findPathToUnreachable(moveAction, input.user, input.target)
      input.user:moveToTile(path.lastStep)
    end
  else
    FieldManager.renderer:moveToObject(input.user, nil, true)
    FieldManager.renderer.focusObject = input.user
    if input.GUI then
      input.GUI:endGridSelecting()
    end
    if path then
      input.user:walkPath(path)
      self:use(input)
    else
      path = PathFinder.findPathToUnreachable(moveAction, input.user, input.target)
      input.user:walkPath(path)
    end
  end
  input.user.battler:onMove(path)
  return self.timeCost
end

---------------------------------------------------------------------------------------------------
-- Effect
---------------------------------------------------------------------------------------------------

-- The effect applied when the user is prepared to use the skill.
-- It executes animations and applies damage/heal to the targets.
function SkillAction:use(input)
  -- Intro time.
  _G.Fiber:wait(introTime)
  
  -- User's initial animation.
  local originTile = input.user:getTile()
  local dir = input.user:turnToTile(input.target.x, input.target.y)
  input.user:loadSkill(self.data, dir, true)
  
  -- Cast animation
  FieldManager.renderer:moveToTile(input.target)
  input.user:castSkill(self.data, dir)
  
  -- Minimum time to wait (initially, a frame).
  local minTime = 1
  
  -- Animation in center target tile 
  --  (does not wait full animation, only the minimum time).
  if self.data.centerAnimID >= 0 then
    local mirror = input.user.direction > 90 and input.user.direction <= 270
    local x, y, z = mathf.tile2Pixel(input.target:coordinates())
    local animation = BattleManager:playAnimation(self.data.centerAnimID,
      x, y, z - 1, mirror)
    _G.Fiber:wait(centerTime)
  end
  
  -- Animation for each of affected tiles.
  self:allTargetsAnimation(input, originTile)
  
  -- Return user to original position and animation.
  input.user:finishSkill(originTile, self.data)
  
  -- Wait until everything finishes.
  _G.Fiber:wait(max (0, minTime - now()) + 60)
end

-- Calculates the final damage / heal for the target.
-- It considers all element bonuses provided by the skill data.
-- @param(input : ActionInput) the target character
-- @ret(number) the final value (nil if miss)
function SkillAction:calculateEffectResult(input, targetChar, rand)
  rand = rand or random
  local rate = self:calculateSuccessRate(input.user.battler.att, 
    targetChar.battler.att, random)
  if rand() + rand(1, 99) > rate then
    return nil
  end
  local result = self:calculateBasicResult(input.user.battler.att, 
    targetChar.battler.att, rand)
  local bonus = 0
  local skillElementFactors = self.elementFactors
  local targetElementFactors = targetChar.battler.elementFactors
  for i = 1, elementCount do
    bonus = bonus + skillElementFactors[i] * targetElementFactors[i]
  end
  bonus = result * bonus
  return round(bonus + result)
end

-- Gets the total damage caused. 
-- Increases if affected an enemy, decreases if affected an ally.
-- @param(input : ActionInput)
-- @param(tile : ObjectTile)
-- @ret(number) the result effect
function SkillAction:calculateTotalEffectResult(input, tile, rand)
  local sum = 0
  for n in mathf.radiusIterator(self.range, tile.x, tile.y) do
    for char in n.characterList:iterator() do
      input.target = tile
      local effect = self:calculateEffectResult(input, char, rand)
      if char.battler.party ~= input.user.battler.party then
        sum = sum + effect
      else
        sum = sum - effect
      end
    end
  end
  return sum
end

---------------------------------------------------------------------------------------------------
-- Target Animations
---------------------------------------------------------------------------------------------------

-- Executes individual animation for all the affected tiles.
function SkillAction:allTargetsAnimation(input, originTile)
  local allTargets = self:getAllAffectedTiles(input)
  for i = #allTargets, 1, -1 do
    local tile = allTargets[i]
    for targetChar in tile.characterList:iterator() do
      self:singleTargetAnimation(input, targetChar, originTile)
    end
  end
end

-- Executes individual animation for a single tile.
function SkillAction:singleTargetAnimation(input, targetChar, originTile)
  local result = self:calculateEffectResult(input, targetChar)
  if not result then
    -- Miss
    local pos = targetChar.position
    local popupText = PopupText(pos.x, pos.y - 20, pos.z - 10)
    popupText:addLine(Vocab.miss, Color.popup_miss, Font.popup_miss)
    popupText:popup()
  elseif result >= 0 then
    -- Damage
    if self.data.radius > 1 then
      originTile = input.target
    end
    _G.Fiber:fork(function()
      targetChar:damage(self.data, result, originTile)
    end)
  else
    -- Heal
    _G.Fiber:fork(function()
      targetChar:heal(self.data, -result)
    end)
  end
  _G.Fiber:wait(targetTime)
end

---------------------------------------------------------------------------------------------------
-- Simulation
---------------------------------------------------------------------------------------------------

-- Applies skill's effect with animations.
-- By default, just applies the damage result in the affected characters.
function SkillAction:applyEffects(input)
  local tiles = self:getAllAffectedTiles(input)
  for i = #tiles, 1, -1 do
    for char in tiles[i].characterList:iterator() do
      if char.battler then
        local effect = self:calculateEffectResult(input, char, expectation)
        if effect then
          char.battler:damageHP(effect)
        end
      end
    end
  end
end

return SkillAction
