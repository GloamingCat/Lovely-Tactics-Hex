
--[[===============================================================================================

SkillAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players chooses a skill to use.

=================================================================================================]]

-- Imports
local List = require('core/datastruct/List')
local BattleAction = require('core/battle/action/BattleAction')
local MoveAction = require('core/battle/action/MoveAction')
local ActionInput = require('core/battle/action/ActionInput')
local PathFinder = require('core/battle/ai/PathFinder')
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
local battlerVariables = Database.variables.battler
local elementCount = #Config.elements
local introTime = 22.5
local centerTime = 7.5
local targetTime = 2.2
local useTime = 2
local maxDeadLocks = 100

-- Static
local deadLockCount = 0

local SkillAction = class(BattleAction)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor. Creates the action from a skill ID.
-- @param(skillID : number) the skill's ID from database
function SkillAction:init(skillID)
  local data = Database.skills[skillID + 1]
  self.data = data
  self.skillID = skillID
  local color = nil
  -- Skill type
  if data.type == 0 then
    color = 'general'
  elseif data.type == 1 then
    color = 'attack'
  elseif data.type == 2 then
    color = 'support'
  end
  BattleAction.init(self, data.timeCost, data.range, data.radius, color)
  -- Effect formulas
  self.effects = {}
  for i = 1, #data.effects do
    self.effects[i] = {
      basicResult = loadformula(data.effects[i].basicResult, 'action, a, b, rand'),
      successRate = loadformula(data.effects[i].successRate, 'action, a, b, rand'),
      attName = battlerVariables[data.effects[i].id + 1].shortName
    }
  end
  -- Cost formulas
  self.costs = {}
  for i = 1, #data.costs do
    self.costs[i] = {
      cost = loadformula(data.costs[i].value, 'action, att'),
      name = battlerVariables[data.costs[i].id + 1].shortName
    }
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
-- Creates an SkillAction given the skill's ID in the database, depending on the skill's script.
-- @param(skillID : number) the skill's ID in database
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
-- @ret(string) a string with skill's ID and name
function SkillAction:__tostring()
  return 'SkillAction (' .. self.skillID .. ': ' .. self.data.name .. ')'
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Checks if the given character can use the skill, considering skill's costs
-- @param(user : Character)
-- @ret(boolean)
function SkillAction:canExecute(input)
  local att = input.user.battler.att
  local state = input.user.battler.state
  for i = 1, #self.costs do
    local cost = self.costs[i].cost(self, att)
    local name = self.costs[i].name
    if self.costs[i].reward == 2 then
      if cost > SaveManager.current.partyData[name] then
        return false
      end
    else
      if cost > state[name] then
        return false
      end
    end
  end
  return true
end
-- Overrides BattleAction:onConfirm.
-- Executes the movement action and the skill's effect.
function SkillAction:execute(input)
  local moveAction = MoveAction(self.data.range)
  local moveInput = ActionInput(moveAction, input.user, input.target)
  moveInput.skipAnimations = input.skipAnimations
  local result = moveInput:execute(moveInput)
  if result.executed then    
    -- Deadlock detection (for simulation)
    deadLockCount = deadLockCount + 1
    if deadLockCount > maxDeadLocks then
      BattleManager:deadLock()
    end
    -- Skill use
    if input.skipAnimations then
      self:applyEffects(input)
    else
      self:applyAnimatedEffects(input)
    end
    input.user.battler:onSkillUse(self)
    return BattleAction.execute(self, input)
  else
    deadLockCount = 0
    return { timeCost = 0 }
  end
end

---------------------------------------------------------------------------------------------------
-- Simulate
---------------------------------------------------------------------------------------------------

-- Applies skill's effect with no animations.
-- By default, just applies the damage result in the affected characters.
-- @param(input : ActionInput)
function SkillAction:applyEffects(input)
  local tiles = self:getAllAffectedTiles(input)
  for i = #tiles, 1, -1 do
    for char in tiles[i].characterList:iterator() do
      self:applyEffect(input, char)
    end
  end
end
-- Applies skill's effect with no animations in a single character.
-- @param(input : ActionInput)
function SkillAction:applyEffect(input, char)
  if not self:receivesEffect(char) then
    return
  end
  local results, dmg = self:calculateEffectResults(input, char, input.random)
  for i = 1, #results do
    char.battler:damage(results[i][1], results[i][2])
  end
end

---------------------------------------------------------------------------------------------------
-- Effect result
---------------------------------------------------------------------------------------------------

-- Tells if a character may receive the skill's effects.
-- @param(char : Character)
function SkillAction:receivesEffect(char)
  return char.battler and char.battler:isAlive()
end
-- Calculates the final damage / heal for the target.
-- It considers all element bonuses provided by the skill data.
-- @param(input : ActionInput) the target character
-- @param(targetChar : Character)
-- @param(rand : function) the random function (optional)
-- @ret(table) an array of result values { attributeName, value }
-- @ret(boolean) true if there's a damage
function SkillAction:calculateEffectResults(input, targetChar, rand)
  local dmg = false
  local results = {}
  for i = 1, #self.effects do
    local r = self:calculateEffectResult(self.effects[i], input, targetChar, rand)
    if r then
      dmg = dmg or r > 0
      results[#results + 1] = { self.effects[i].attName, r }
    end
  end
  return results, dmg
end
-- Calculates the final damage / heal for the target from an specific effect.
-- It considers all element bonuses provided by the skill data.
-- @param(effect : table) the effect data
-- @param(input : ActionInput) the target character
-- @param(targetChar : Character)
-- @param(rand : function) the random function (optional)
-- @ret(number) the result of the damage (nil if missed)
function SkillAction:calculateEffectResult(effect, input, targetChar, rand)
  rand = rand or random
  local rate = effect.successRate(self, input.user.battler.att, 
    targetChar.battler.att, random)
  if rand() + rand(1, 99) > rate then
    return nil
  end
  local result = effect.basicResult(self, input.user.battler.att, 
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
-- Animations
---------------------------------------------------------------------------------------------------

-- The effect applied when the user is prepared to use the skill.
-- It executes animations and applies damage/heal to the targets.
function SkillAction:applyAnimatedEffects(input)
  -- Intro time.
  _G.Fiber:wait(introTime)
  -- User's initial animation.
  local originTile = input.user:getTile()
  local dir = input.user:turnToTile(input.target.x, input.target.y)
  dir = math.angle2Row(dir) * 45
  input.user:loadSkill(self.data, dir)
  -- Cast animation
  FieldManager.renderer:moveToTile(input.target)
  _G.Fiber:fork(input.user.castSkill, input.user, self.data, dir)
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

---------------------------------------------------------------------------------------------------
-- Target Animations
---------------------------------------------------------------------------------------------------

-- Executes individual animation for all the affected tiles.
-- @param(originTile : ObjectTile) the user's original tile
function SkillAction:allTargetsAnimation(input, originTile)
  local allTargets = self:getAllAffectedTiles(input)
  for i = #allTargets, 1, -1 do
    local tile = allTargets[i]
    for targetChar in tile.characterList:iterator() do
      if self:receivesEffect(targetChar) then
        self:singleTargetAnimation(input, targetChar, originTile)
      end
    end
  end
end
-- Executes individual animation for a single tile.
-- @param(targetChar : Character) the character that will be affected
-- @param(originTile : ObjectTile) the user's original tile
function SkillAction:singleTargetAnimation(input, targetChar, originTile)
  local results, dmg = self:calculateEffectResults(input, targetChar)
  if #results == 0 then
    -- Miss
    local pos = targetChar.position
    local popupText = PopupText(pos.x, pos.y - 20, pos.z - 10)
    popupText:addLine(Vocab.miss, Color.popup_miss, Font.popup_miss)
    popupText:popup()
  else
    local wasAlive = targetChar.battler:isAlive()
    self:popupResults(targetChar.position, targetChar.battler, results)
    if self.data.individualAnimID >= 0 then
      local dir = targetChar:angleToPoint(originTile.x, originTile.y)
      local mirror = dir > 90 and dir <= 270
      local pos = targetChar.position
      BattleManager:playAnimation(self.data.individualAnimID,
        pos.x, pos.y, pos.z - 10, mirror)
    end
    if dmg and wasAlive then
      if self.data.radius > 1 then
        originTile = input.target
      end
      _G.Fiber:fork(function()
        targetChar:damage(self.data, results, originTile)
      end)
    end
    if targetChar.battler:isAlive() then
      targetChar:playAnimation(targetChar.idleAnim)
    end
  end
  _G.Fiber:wait(targetTime)
end
-- Applies results on the given battler and creates a popup for each value.
-- @param(pos : Vector) the character's position
-- @param(battler : Battler) the battler that will be affected
-- @param(results : table) the array of effect results
function SkillAction:popupResults(pos, battler, results)
  local popupText = PopupText(pos.x, pos.y - 20, pos.z - 10)
  for i = 1, #results do
    local popupName = results[i][1]
    if results[i][2] > 0 then
      popupName = 'popup_dmg' .. popupName
      popupText:addLine(results[i][2], Color[popupName], Font[popupName])
    else
      popupName = 'popup_heal' .. popupName
      popupText:addLine(-results[i][2], Color[popupName], Font[popupName])
    end
    battler:damage(results[i][1], results[i][2])
  end
  popupText:popup()
end

return SkillAction
