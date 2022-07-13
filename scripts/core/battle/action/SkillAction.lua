
--[[===============================================================================================

SkillAction
---------------------------------------------------------------------------------------------------
The BattleAction that is executed when players chooses a skill to use.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local BattleAction = require('core/battle/action/BattleAction')
local List = require('core/datastruct/List')
local BattleMoveAction = require('core/battle/action/BattleMoveAction')
local PathFinder = require('core/battle/ai/PathFinder')
local PopupText = require('core/battle/PopupText')

-- Alias
local max = math.max
local isnan = math.isnan
local mathf = math.field
local now = love.timer.getTime
local random = math.random
local round = math.round
local newArray = util.array.new

-- Constants
local elementCount = #Config.elements

local SkillAction = class(BattleAction)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor. Creates the action from a skill ID.
-- @param(skillID : number) the skill's ID from database
function SkillAction:init(skillID)
  local data = Database.skills[skillID]
  self.data = data
  BattleAction.init(self, nil, data.castMask, data.effectMask)
  self.moveAction = BattleMoveAction(self.range)
  self.autoPath = data.autoPath
  self.wholeField = data.wholeField
  self:setType(data.type)
  self:setTargetType(data.targetType)
  -- Time before initial animation starts.
  self.introTime = tonumber(data.introTime) or 20
  -- Time after cast animation starts and before user steps back to tile.
  self.castTime = tonumber(data.castTime) or 10
  -- Time after cast animation starts and before starting individual target animations.
  self.centerTime = tonumber(data.centerTime) or 10
  -- Time between start of each individual target animation.
  self.targetTime = tonumber(data.targetTime) or 0
  -- Time after all animations finished.
  self.finishTime = tonumber(data.finishTime) or 0
  -- Cost formulas
  self.costs = {}
  for i = 1, #data.costs do
    self.costs[i] = {
      cost = loadformula(data.costs[i].value, 'action, att'),
      key = data.costs[i].key }
  end
  -- Effect formulas
  self.effects = {}
  for i = 1, #data.effects do
    self:addEffect(data.effects[i])
  end
  -- Status to add
  self.status = {}
  self:addStatus(data.statusAdd, true)
  self:addStatus(data.statusRemove, false)
  -- Store elements
  local e = newArray(elementCount, 0)
  for i = 1, #data.elements do
    e[data.elements[i].id + 1] = data.elements[i].value / 100
  end
  self.elements = e
  -- Tags
  self.tags = Database.loadTags(data.tags)
end
-- Creates an SkillAction given the skill's ID in the database, depending on the skill's script.
-- @param(skillID : number) the skill's ID in database
function SkillAction:fromData(skillID, ...)
  local data = Database.skills[skillID]
  if data.script ~= '' then
    local class = require('custom/' .. data.script)
    return class(skillID, ...)
  else
    return self(skillID, ...)
  end
end
-- @ret(string) A string with skill's ID and name.
function SkillAction:__tostring()
  return 'SkillAction (' .. self.data.id .. ': ' .. self.data.name .. ')'
end

---------------------------------------------------------------------------------------------------
-- Damage / Status
---------------------------------------------------------------------------------------------------

-- Inserts a new effect in this skill.
-- @param(key : string) The name of the effect's destination (hp or sp).
-- @param(effect : table) Effect's properties (basicResult, successRate, heal and absorb).
function SkillAction:addEffect(effect)
  self.effects[#self.effects + 1] = { key = effect.key,
    basicResult = loadformula(effect.basicResult, 'action, user, target, a, b, rand'),
    successRate = loadformula(effect.successRate, 'action, user, target, a, b, rand'),
    heal = effect.heal,
    absorb = effect.absorb }
end
-- Inserts a new status in this skill.
-- @param(status : table) Array with each status (id, rate, add).
function SkillAction:addStatus(status, add)
  local last = #self.status
  for i = 1, #status do
    self.status[last + i] = { id = status[i].id, add = add,
      rate = loadformula(status[i].rate, 'action, a, b, rand') }
  end
end
-- Default basic result formula for physical attack skills.
-- @param(user : Battler) User battler.
-- @param(target : Battler) Target battler.
-- @param(a : table) Attributes of user battler.
-- @param(b : table) Attributes of target battler.
-- @ret(string) Damage formula.
function SkillAction:defaultPhysicalDamage(user, target, a, b)
  local rand = self.rand or random
  return (a.atk() * 2 - b.def()) * rand(80, 120) / 100
end
-- Default basic result formula for magical attack skills.
-- @param(user : Battler) User battler.
-- @param(target : Battler) Target battler.
-- @param(a : table) Attributes of user battler.
-- @param(b : table) Attributes of target battler.
-- @ret(string) Damage formula.
function SkillAction:defaultMagicalDamage(user, target, a, b)
  local rand = self.rand or random
  return (a.atk() * 2 - b.spr()) * rand(80, 120) / 100
end
-- Default success rate formula for attack skills.
-- @param(user : Battler) User battler.
-- @param(target : Battler) Target battler.
-- @param(a : table) Attributes of user battler.
-- @param(b : table) Attributes of target battler.
-- @ret(string) Success formula.
function SkillAction:defaultSuccessRate(user, target, a, b)
  return ((a.pre() * 2 - b.evd()) / b.evd()) * 50
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Overrides BattleAction:canExecute.
-- @param(input : ActionInput)
-- @ret(boolean)
function SkillAction:canExecute(input)
  return self:canBattleUse(input.user)
end
-- Overrides BattleAction:onConfirm.
-- Executes the movement action and the skill's effect.
function SkillAction:execute(input)
  if input.moveResult.executed then
    -- Skill use
    self:battleUse(input)
    return BattleAction.execute(self, input)
  else
    return { executed = false, endCharacterTurn = true }
  end
end
-- Checks if the given character can use the skill, considering skill's costs.
-- @param(user : Battler)
-- @ret(boolean) True if this skill may be selected to be used.
function SkillAction:canUse(user)
  local att = user.att
  local state = user.state
  for i = 1, #self.costs do
    local cost = self.costs[i].cost(self, att)
    local key = self.costs[i].key
    if cost > state[key] then
      return false
    end
  end
  return true
end

---------------------------------------------------------------------------------------------------
-- Battle Use
---------------------------------------------------------------------------------------------------

-- Checks if the skill can be used in the battle field.
-- @param(user : Character)
-- @ret(boolean) True if this skill may be selected to be used in battle field.
function SkillAction:canBattleUse(user)
  return self:canUse(user.battler)
end
-- The effect applied when the user is prepared to use the skill.
-- It executes animations and applies damage/heal to the targets.
function SkillAction:battleUse(input)
  -- Apply costs.
  input.user.battler:damageCosts(self.costs)
  -- Intro time.
  _G.Fiber:wait(self.introTime)
  -- User's initial animation.
  local originTile = input.user:getTile()
  local dir = input.user:turnToTile(input.target.x, input.target.y)
  dir = math.field.angle2Row(dir) * 45
  _G.Fiber:wait(input.user:loadSkill(self.data, dir))
  -- Cast animation.
  FieldManager.renderer:moveToTile(input.target)
  local minTime = input.user:castSkill(self.data, dir, input.target) + GameManager.frame
  input.user.battler:onSkillUse(input, input.user)
  -- Return user to original position and animation.
  _G.Fiber:fork(function()
    _G.Fiber:wait(self.castTime)
    if not input.user:moving() then
      input.user:finishSkill(originTile, self.data)
    end
  end)
  -- Target animations.
  _G.Fiber:wait(self.centerTime)
  self:allTargetsEffect(input, originTile)
  -- Wait until everything finishes.
  _G.Fiber:wait(max(minTime - GameManager.frame, 0) + self.finishTime)
end
-- Applies the effects of the skill to the given battler.
-- @param(results : table) Skill result table.
-- @param(char : Character) Battler's character.
function SkillAction:applyResults(input, results, battler, char)
  battler:onSkillEffect(input, results, char)
  battler:applyResults(results, char)
  battler:onSkillResult(input, results, char)
  if char then
    if battler:isAlive() then
      char:playAnimation(char.idleAnim)
    else
      char:playAnimation(char.koAnim)
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Menu Use
---------------------------------------------------------------------------------------------------

-- Checks if the skill can be used out of battle.
-- @param(user : Battler)
-- @ret(boolean) True if this skill may be selected to use out of battle.
function SkillAction:canMenuUse(user)
  return self:canUse(user) and self.support
end
-- Executes the skill in the menu, out of the battle field.
-- @param(user : Battler)
-- @param(target : Battler)
function SkillAction:menuUse(input)
  if input.target then
    local results = self:calculateEffectResults(input.user, input.target)
    local char = TroopManager:getBattlerCharacter(input.target)
    self:applyResults(input, results, input.target, char)
  elseif input.targets then
    for i = 1, #input.targets do
      local results = self:calculateEffectResults(input.user, input.targets[i])
      local char = TroopManager:getBattlerCharacter(input.targets[i])
      self:applyResults(input, results, input.targets[i], char)
    end
  else
    return { executed = false }
  end
  input.user:damageCosts(self.costs)
  if self.data.castAnimID >= 0 then
    BattleManager:playMenuAnimation(self.data.castAnimID, false)
  end
  input.user:onSkillUse(input, TroopManager:getBattlerCharacter(input.user))
  return BattleAction.execute(self, input)
end

---------------------------------------------------------------------------------------------------
-- Effect result
---------------------------------------------------------------------------------------------------

-- Tells if a character may receive the skill's effects.
-- @param(char : Character)
function SkillAction:receivesEffect(input, char)
  return char.battler ~= nil
end
-- Calculates the final damage / heal for the target.
-- It considers all element bonuses provided by the skill data.
-- @param(user : Battler)
-- @param(target : Battler)
function SkillAction:calculateEffectResults(user, target)
  local points = {}
  local dmg = false
  for i = 1, #self.effects do
    local r = self:calculateEffectResult(self.effects[i], user, target)
    if r then
      points[#points + 1] = { value = r,
        key = self.effects[i].key,
        heal = self.effects[i].heal,
        absorb = self.effects[i].absorb }
      dmg = dmg or not self.effects[i].heal
    end
  end
  local status, sdmg = self:calculateStatusResult(user, target)
  local results = { damage = dmg or sdmg,
    points = points,
    status = status }
  return results
end
-- Calculates the final damage / heal for the target from an specific effect.
-- It considers all element bonuses provided by the skill data.
-- @param(effect : table) Effect's info (successRate and basicResult).
-- @param(user : Battler) User of the skill.
-- @param(target : Battler) Receiver of the effect. 
-- @ret(number) Total value of the damage. Nil if miss.
function SkillAction:calculateEffectResult(effect, user, target)
  local rand = self.rand or random
  local rate = effect.successRate(self, user, target, user.att, target.att, rand)
  if rand() * 100 > rate then
    return nil
  end
  local result = max(effect.basicResult(self, user, target, user.att, target.att, rand), 0)
  local immunity = 1
  local bonus = 1
  for i = 1, elementCount do
    -- 0 if user is neutral on element i.
    local userFactor = self.data.userElement and user:elementAtk(i) or 0
    -- 0 if skill does not have element i.
    local skillFactor = max(0, self.elements[i] + userFactor)
    -- 0 if target is neutral on element i, negative if immune and positive if weak.
    local targetFactor = target:elementDef(i)
    -- 0 if no bonus if applied.
    local buffFactor = user:elementBuff(i)
    -- If target is neutral or skill does not have this element, result does not change.
    immunity = immunity * (targetFactor * skillFactor + 1)
    -- If user has no buff or skill does not have this element, result does not change.
    bonus = bonus + buffFactor * skillFactor
  end
  return round(result * immunity * bonus)
end
-- @param(status : table) Array with skill's status info.
-- @param(user : Battler) User of the skill.
-- @param(target : Battler) Receiver of the status effects.
-- @ret(table) Array with status results.
-- @ret(boolean) True if the effect was damage, false otherwise.
function SkillAction:calculateStatusResult(user, target)
  local rand = self.rand or random
  local result = {}
  local dmg = false
  for i = 1, #self.status do
    local s = self.status[i]
    local r = s.rate(self, user.att, target.att, rand)
    if rand() * 100 <= r then
      result[#result + 1] = {
        id = s.id,
        add = s.add,
        caster = user.key }
      dmg = dmg or s.add
    end
  end
  return result, dmg
end

---------------------------------------------------------------------------------------------------
-- Target Animations
---------------------------------------------------------------------------------------------------

-- Executes individual animation for all the affected tiles.
-- @param(originTile : ObjectTile) the user's original tile
function SkillAction:allTargetsEffect(input, originTile)
  local allTargets = self:getAllAffectedTiles(input)
  for i = #allTargets, 1, -1 do
    for targetChar in allTargets[i].characterList:iterator() do
      if self:receivesEffect(input, targetChar) then
        local results = self:calculateEffectResults(input.user.battler, targetChar.battler)
        self:singleTargetEffect(results, input, targetChar, originTile)
      end
    end
  end
  return allTargets
end
-- Executes individual animation for a single tile.
-- @param(targetChar : Character) the character that will be affected
-- @param(originTile : ObjectTile) the user's original tile
function SkillAction:singleTargetEffect(results, input, targetChar, originTile)
  targetChar.battler:onSkillEffect(input, results, targetChar)
  local wasAlive = targetChar.battler.state.hp > 0
  if #results.points == 0 and #results.status == 0 then
    -- Miss
    if wasAlive then
      local pos = targetChar.position
      local popupText = PopupText(pos.x, pos.y - 10, pos.z - 60)
      popupText:addLine(Vocab.miss, 'popup_miss', 'popup_miss')
      popupText:popup()
    end
  elseif wasAlive or not results.damage then
    targetChar.battler:popupResults(targetChar.position, results, targetChar)
    if self.data.individualAnimID >= 0 then
      local dir = targetChar:tileToAngle(originTile.x, originTile.y)
      local mirror = dir > 90 and dir <= 270
      local pos = targetChar.position
      BattleManager:playBattleAnimation(self.data.individualAnimID,
        pos.x, pos.y, pos.z - 10, mirror)
    end
    if results.damage and self.data.damageAnim and wasAlive then
      if self:isArea() then
        originTile = input.target
      end
      _G.Fiber:fork(targetChar.damage, targetChar, self.data, originTile, results)
    end
    targetChar.battler:onSkillResult(input, results, targetChar)
    if targetChar.battler.state.hp > 0 then
      targetChar:playAnimation(targetChar.idleAnim)
    end
  end
  _G.Fiber:wait(self.targetTime)
  return results
end

return SkillAction
