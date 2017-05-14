
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
  local color
  -- Skill type
  if data.type == 0 then
    color = 'general'
  elseif data.type == 1 then
    color = 'attack'
  elseif data.type == 2 then
    color = 'support'
  end
  old_init(self, data.range, data.radius, color)
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
  return 'SkillAction: ' .. self.skillID .. ' (' .. self.data.name .. ')'
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
-- Event handlers
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:onConfirm.
-- Executes the movement action and the skill's effect, 
-- and then decrements battler's turn count and steps.
function SkillAction:onConfirm(input)
  if input.GUI then
    input.GUI:endGridSelecting()
  end
  FieldManager.renderer:moveToObject(input.user, true)
  FieldManager.renderer.focusObject = input.user
  local moveAction = MoveAction(self.data.range, input.target)
  local path = PathFinder.findPath(moveAction, input.user, input.target)
  if path then -- Target was reached
    input.user:walkPath(path)
    self:use(input)
  else -- Target was not reached
    path = PathFinder.findPathToUnreachable(moveAction, input.user, input.target)
    --path = path or PathFinder.estimateBestPath(moveAction, input.user, input.target)
    input.user:walkPath(path)
  end
  local battler = input.user.battler
  if path.lastStep:isControlZone(battler) then
    battler.currentSteps = 0
  else
    battler.currentSteps = battler.currentSteps - path.totalCost
  end
  local cost = self.data.timeCost * BattleManager.turnLimit / 200
  battler:decrementTurnCount(ceil(cost))
  return 1
end

---------------------------------------------------------------------------------------------------
-- Simulation
---------------------------------------------------------------------------------------------------

-- Executes the action in the given state. 
-- By default, just applies the effect result in the affected characters.
-- @param(state : BattleSimulation) the current battle simulation
-- @param(input : ActionInput)
-- @param(BattleSimulation) the modified state (the same state if nothing changed)
function SkillAction:simulate(state, input)
  local tiles = self:getAllAffectedTiles(input)
  state = state:shallowCopy({}, nil)
  for i = #tiles, 1, -1 do
    for char in tiles[i].characterList:iterator() do
      if char.battler then
        local effect = self:calculateEffectResult(input, char, expectation)
        if effect then
          local charState = state.characters[char]
          local newState = {}
          if charState and charState.hp then
            newState.hp = charState.hp - effect
          else
            newState.hp = char.battler.currentHP - effect
          end
        end
      end
    end
  end
  return state
end

-- Action identifier.
-- @ret(string)
function SkillAction:getCode()
  return 'Skill' .. self.data.id
end

return SkillAction
