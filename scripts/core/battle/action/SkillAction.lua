
-- ================================================================================================

--- Makes the current character use a skill.
-- It is executed when players chooses the "Attack" or Skill" buttons during battle.
---------------------------------------------------------------------------------------------------
-- @battlemod SkillAction
-- @extend BattleAction

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local BattleAction = require('core/battle/action/BattleAction')
local List = require('core/datastruct/List')
local BattleMoveAction = require('core/battle/action/BattleMoveAction')
local PopText = require('core/graphics/PopText')
local Vector = require('core/math/Vector')
local BattleAnimations = require('core/battle/BattleAnimations')

-- Alias
local expectation = math.randomExpectation
local max = math.max
local isnan = math.isnan
local mathf = math.field
local now = love.timer.getTime
local random = math.random
local round = math.round
local newArray = util.array.new

-- Constants
local elementCount = #Config.elements

-- Class table.
local SkillAction = class(BattleAction)

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Info table returned when a skill effect is applied to a target character.
-- @table EffectResult
-- @tfield number value The absolute value of the effect.
-- @tfield string key The key of the attribute that with be damaged/healed. Typically `"hp"` or `"sp"`.
-- @tfield boolean heal Indicates if the value should be added or substracted from the attribute.
-- @tfield boolean absorb Indicates if the value should be transfered to/taken from the skill's user.
SkillAction.emptyEffectResult = {
  value = 0,
  key = 'hp',
  heal = false,
  absorb = false
}
--- Info table returned when the skill is executed on a target character.
-- @table SkillResult
-- @tfield boolean damage Indicates if the skills caused damage to the character.
-- @tfield boolean kill Indicates if the skill killed the character.
-- @tfield table points Array of `EffectResult` entries.
-- @tfield table status Array of entries with a number `"id"` indicating the status's ID and
--  a boolean `"add"` indicating whether the status should be added or removed from the target battler.
SkillAction.emptySkillResult = {
  damage = true,
  kill = false,
  points = {},
  status = {}
}

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. Creates the action from a skill ID.
-- @tparam number skillID The skill's ID from database.
function SkillAction:init(skillID)
  local data = Database.skills[skillID]
  self.data = data
  BattleAction.init(self, nil, data.castMask, data.effectMask)
  self.moveAction = BattleMoveAction(self.range)
  self.allParties = data.allParties
  self.affectedOnly = data.selection % 2 == 1
  self.reachableOnly = data.selection >= 2
  self.freeNavigation = data.freeNavigation
  self.autoPath = data.autoPath
  self.rotateEffect = data.rotateEffect
  self.useCondition = data.condition ~= '' and 
    loadformula(data.condition, 'action, user')
  self.effectCondition = data.effectCondition ~= '' and 
    loadformula(data.effectCondition, 'action, user, target')
  self:setType(data.type)
  -- Time before initial animation starts.
  self.introTime = math.replace(data.animInfo.introTime, 20, -1)
  -- Time after cast animation starts and before user steps back to tile.
  self.castTime = math.replace(data.animInfo.castTime, 15, -1)
  -- Time after cast animation starts and before starting individual target animations.
  self.centerTime = math.replace(data.animInfo.centerTime, 5, -1)
  -- Time between start of each individual target animation.
  self.targetTime = math.replace(data.animInfo.targetTime, 0, -1)
  -- Time after all animations finished.
  self.finishTime = math.replace(data.animInfo.finishTime, 20, -1)
  -- Cost formulas
  self.costs = {}
  for i = 1, #data.costs do
    self.costs[i] = {
      cost = loadformula(data.costs[i].value, 'action, att'),
      key = data.costs[i].key }
  end
  -- Effect formulas
  self.effects = {}
  self.status = {}
  for i = 1, #data.effects do
    self:addEffect(data.effects[i])
  end
  -- Store elements
  local e = newArray(elementCount, 0)
  for i = 1, #data.elements do
    e[data.elements[i].id + 1] = data.elements[i].value / 100
  end
  self.elements = e
  -- Tags
  self.tags = Database.loadTags(data.tags)
end
--- Creates an SkillAction given the skill's ID in the database, depending on the skill's script.
-- @tparam number skillID The skill's ID in database.
function SkillAction:fromData(skillID, ...)
  local data = Database.skills[skillID]
  if data.script ~= '' then
    local class = require('custom/' .. data.script)
    return class(skillID, ...)
  else
    return self(skillID, ...)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Damage / Status
-- ------------------------------------------------------------------------------------------------

--- Inserts a new effect in this skill.
-- @tparam table effect Effect's properties (key, basicResult, successRate, heal and absorb).
function SkillAction:addEffect(effect)
  self.effects[#self.effects + 1] = { key = effect.key,
    basicResult = loadformula(effect.basicResult, 'action, user, target, a, b, rand'),
    successRate = loadformula(effect.successRate, 'action, user, target, a, b, rand'),
    heal = effect.heal,
    absorb = effect.absorb,
    statusID = effect.statusID }
end
--- Default basic result formula for physical attack skills.
-- @tparam Battler user User battler.
-- @tparam Battler target Target battler.
-- @tparam table a Attributes of user battler.
-- @tparam table b Attributes of target battler.
-- @tparam[opt] function rand Random number generator.
-- @treturn number Base damage.
function SkillAction:defaultPhysicalDamage(user, target, a, b, rand)
  rand = rand or self.rand or random
  return (a.atk() * 2 - b.def()) * rand(80, 120) / 100
end
--- Default basic result formula for magical attack skills.
-- @tparam Battler user User battler.
-- @tparam Battler target Target battler.
-- @tparam table a Attributes of user battler.
-- @tparam table b Attributes of target battler.
-- @tparam[opt] function rand Random number generator.
-- @treturn number Base damage.
function SkillAction:defaultMagicalDamage(user, target, a, b, rand)
  rand = rand or self.rand or random
  return (a.atk() * 2 - b.spr()) * rand(80, 120) / 100
end
--- Default success rate formula for attack skills.
-- @tparam Battler user User battler.
-- @tparam Battler target Target battler.
-- @tparam table a Attributes of user battler.
-- @tparam table b Attributes of target battler.
-- @treturn number Base chance.
function SkillAction:defaultSuccessRate(user, target, a, b)
  return ((a.pre() * 2 - b.evd()) / b.evd()) * 50 + 50
end
--- Default success rate formula for status.
-- @tparam Battler user User battler.
-- @tparam Battler target Target battler.
-- @tparam table a Attributes of user battler.
-- @tparam table b Attributes of target battler.
-- @treturn number Base chance.
function SkillAction:defaultStatusChance(user, target, a, b)
  return ((a.dex() * 2 - b.evd()) / b.evd()) * 50
end

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Overrides `FieldAction:canExecute`.
-- @override
function SkillAction:canExecute(input)
  return self:canBattleUse(input.user)
end
--- Overrides `FieldAction:onConfirm`. Executes the movement action and the skill's effect.
-- @override
function SkillAction:execute(input)
  if input.moveResult.executed then
    -- Skill use
    self:battleUse(input)
    return BattleAction.execute(self, input)
  else
    return { executed = false, endCharacterTurn = true }
  end
end
--- Checks if the given character can use the skill, considering skill's costs and condition.
-- @tparam Battler user The user of the skill.
-- @treturn boolean True if this skill may be selected to be used.
function SkillAction:canUse(user)
  if self.useCondition then
    local char = TroopManager:getBattlerCharacter(user)
    if not self:useCondition(user, char) then
      return false
    end
  end
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

-- ------------------------------------------------------------------------------------------------
-- Battle Use
-- ------------------------------------------------------------------------------------------------

--- Checks if the skill can be used in the battle field.
-- @tparam Character user The user of the skill.
-- @treturn boolean True if this skill may be selected to be used in battle field.
function SkillAction:canBattleUse(user)
  return self:canUse(user.battler, user) and self.data.restriction <= 1
end
--- The effect applied when the user is prepared to use the skill.
-- It executes animations and applies damage/heal to the targets.
-- @coroutine
-- @tparam ActionInput input User's input.
function SkillAction:battleUse(input)
  -- Intro time.
  _G.Fiber:wait(self.introTime)
  -- User animation.
  local originTile = input.user:getTile()
  local endFrame = self:userEffects(input) + GameManager.frame
  -- Target animations.
  _G.Fiber:wait(self.centerTime)
  self:allTargetsEffect(input, originTile)
  -- Wait until everything finishes.
  _G.Fiber:wait(max(endFrame - GameManager.frame, 0) + self.finishTime)
end
--- Plays user's load and cast animations.
-- @coroutine
-- @tparam ActionInput input User's input.
function SkillAction:userEffects(input)
  -- Apply costs.
  input.user.battler:damageCosts(self.costs)
  -- User's initial animation.
  local originTile = input.user:getTile()
  local dir = input.user:turnToTile(input.target.x, input.target.y)
  dir = math.field.angle2Row(dir) * 45
  _G.Fiber:wait(math.max(
    input.user:loadSkill(self.data), 
    BattleAnimations.loadEffect(self.data, input.user.position, dir)))
  -- Cast animation.
  FieldManager.renderer:moveToTile(input.target)
  local minTime = math.max(
    input.user:castSkill(self.data, dir, input.target),
    BattleAnimations.castEffect(self.data, input.target, dir))
  input.user.battler:onSkillUse(input, input.user)
  -- Return user to original position and animation.
  _G.Fiber:fork(function()
    _G.Fiber:wait(self.castTime)
    if not input.user:moving() then
      input.user:finishSkill(originTile, self.data)
    end
  end)
  return minTime
end

-- ------------------------------------------------------------------------------------------------
-- Menu Use
-- ------------------------------------------------------------------------------------------------

--- Checks if the skill can be used out of battle.
-- @tparam Battler user The user of the skill.
-- @treturn boolean True if this skill may be selected to use out of battle.
function SkillAction:canMenuUse(user)
  return self:canUse(user) and self.support and self.data.restriction % 2 == 0
end
--- Executes the skill in the menu, out of the battle field.
-- @coroutine
-- @tparam ActionInput input User's input.
function SkillAction:menuUse(input)
  if input.target then
    self:menuTargetsEffect(input, {input.target})
  elseif input.targets then
    self:menuTargetsEffect(input, input.targets)
  else
    return { executed = false }
  end
  input.user:damageCosts(self.costs)
  input.user:onSkillUse(input, TroopManager:getBattlerCharacter(input.user))
  return BattleAction.execute(self, input)
end
--- Applies the the skill's effect when used from a menu.
-- @tparam ActionInput input User's input.
-- @tparam table targets Array of Battlers.
function SkillAction:menuTargetsEffect(input, targets)
  for i = 1, #targets do
    local results = self:calculateEffectResults(input.user, targets[i])
    local popText = self:singleTargetEffect(results, input, targets[i])
    if popText then
      popText:popUp()
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Affected Tiles
-- ------------------------------------------------------------------------------------------------

--- Overrides `BattleAction:isCharacterAffected`. 
-- @override
function SkillAction:isCharacterAffected(input, char)
  if not BattleAction.isCharacterAffected(self, input, char) then
    return false
  end
  if self.effectCondition then
    return self:effectCondition(input.user.battler, char.battler)
  else
    return true
  end
end

-- ------------------------------------------------------------------------------------------------
-- Effect result
-- ------------------------------------------------------------------------------------------------

--- Calculates the final damage / heal for the target.
-- It considers all element bonuses provided by the skill data.
-- @tparam Battler user The user of the skill.
-- @tparam Battler target The target of the skill.
-- @tparam[opt] function rand Random number generator.
-- @treturn SkillResult Result data.
function SkillAction:calculateEffectResults(user, target, rand)
  local points = {}
  local status = {}
  local dmg = false
  local kill = false
  for _, effect in ipairs(self.effects) do  
    rand = rand or self.rand or random
    local rate = effect.successRate(self, user, target, user.att, target.att, rand)
    if effect.statusID then
      rate = rate * user:statusBuff(effect.statusID) * target:statusDef(effect.statusID)
    end
    if rand() * 100 <= rate then
      if effect.statusID >= 0 then
        status[#status + 1] = {
          id = effect.statusID,
          add = not effect.heal,
          caster = user.key }
        dmg = dmg or not effect.heal
      end
      local p = effect.key ~= '' and self:calculateEffectPoints(effect, user, target, rand)
      if p then
        points[#points + 1] = { value = p,
          key = effect.key,
          heal = effect.heal,
          absorb = effect.absorb }
        dmg = dmg or not effect.heal
        if not effect.heal and effect.key == 'hp' and p >= target.state.hp and target.state.hp > 0 then
          kill = true
        end
      end
    end
  end
  return { damage = dmg,
    kill = kill,
    points = points,
    status = status }
end
--- Calculates the final damage / heal for the target from an specific effect.
-- It considers all element bonuses provided by the skill data.
-- @tparam table effect Effect's info (successRate and basicResult).
-- @tparam Battler user User of the skill.
-- @tparam Battler target Receiver of the effect.
-- @tparam[opt] function rand Random number generator.
-- @treturn EffectResult Total value of the damage. Nil if miss.
function SkillAction:calculateEffectPoints(effect, user, target, rand)
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
    -- 0 if no bonus is applied.
    local buffFactor = user:elementBuff(i)
    -- If target is neutral or skill does not have this element, result does not change.
    immunity = immunity * (targetFactor * skillFactor + 1)
    -- If user has no buff or skill does not have this element, result does not change.
    bonus = bonus + buffFactor * skillFactor
  end
  return round(result * immunity * bonus)
end

-- ------------------------------------------------------------------------------------------------
-- Target Animations
-- ------------------------------------------------------------------------------------------------

--- Executes individual animation for all the affected tiles.
-- @coroutine
-- @tparam ActionInput input User's input.
-- @tparam ObjectTile originTile The user's original tile.
function SkillAction:allTargetsEffect(input, originTile)
  local allTargets = self:getAllAffectedTiles(input)
  for i = #allTargets, 1, -1 do
    for targetChar in allTargets[i].characterList:iterator() do
      local results = self:calculateEffectResults(input.user.battler, targetChar.battler)
      self:singleTargetEffect(results, input, targetChar.battler, originTile)
      _G.Fiber:wait(self.targetTime)
    end
  end
  return allTargets
end
--- Executes individual animation for a single tile.
-- @coroutine
-- @tparam table results The results of the skill's effect.
-- @tparam ActionInput input User's input.
-- @tparam Battler target The battler that will be affected.
-- @tparam ObjectTile originTile The user's original tile.
-- @treturn PopText The pop-up text to be shown, with skill's results.
-- @treturn Character The target character (if any).
function SkillAction:singleTargetEffect(results, input, target, originTile)
  local targetChar = originTile and TroopManager:getBattlerCharacter(target)
  target:onSkillEffect(input, results, targetChar)
  local wasAlive = target.state.hp > 0
  if #results.points == 0 and #results.status == 0 then
    -- Miss
    if wasAlive then
      local pos = char and char.position
      local popText = pos and
        PopText(pos.x, pos.y - 10, FieldManager.renderer) or
        PopText(input.targetX or 0, input.targetY or 0, MenuManager.renderer)
      popText:addLine(Vocab.miss, 'popup_miss', 'popup_miss')
      popText:popUp()
    end
  elseif not targetChar then
    -- Animation on menu
    local popText = PopText(input.targetX or 0, input.targetY or 0, MenuManager.renderer)
    target:popResults(popText, results, targetChar)
    BattleAnimations.menuTargetEffect(self.data, input.targetX, input.targetY)
  else
    -- Popup results
    local pos = targetChar.position
    local popText = PopText(pos.x, pos.y - 10, FieldManager.renderer)
    target:popResults(popText, results, targetChar)
    BattleAnimations.targetEffect(self.data, targetChar, originTile)
    if not wasAlive then
      -- Character revived
      if targetChar.battler:isAlive() then
        targetChar:playIdleAnimation()
      end
    elseif results.damage and self.data.damageAnim then
      -- Character damage animation
      if self:isArea() then
        originTile = input.target
      end
      _G.Fiber:forkMethod(targetChar, 'skillDamage', self.data, originTile, results)
    end
    target:onSkillResult(input, results, targetChar)
  end
  return targetChar
end

-- ------------------------------------------------------------------------------------------------
-- AI
-- ------------------------------------------------------------------------------------------------

--- Uses random expectation to estimate average effect result.
-- @tparam ActionInput input User's input.
-- @tparam Character char Target character.
-- @tparam[opt] table eff Effect to check validity. If nil, uses the skill's first effect.
-- @treturn number How close the character is to being killed (0 to 1).
function SkillAction:estimateEffect(input, char, eff)
  eff = eff or self.effects[1]
  local rate = eff.successRate(self, input.user.battler, char.battler, input.user.battler.att, char.battler.att)
  local points = self:calculateEffectPoints(eff, input.user.battler, char.battler, expectation)
  return 1 - (char.battler.state[eff.key] - points * rate / 100) / char.battler['m' .. eff.key]()
end
--- Calculates the total damage of a skill in the given tile.
-- @tparam ActionInput input User's input.
-- @tparam ObjectTile target Possible target for the skill.
-- @tparam[opt] table eff Effect to check validity. If nil, uses the skill's first effect.
-- @treturn number The total damage caused to the character in this tile.
function SkillAction:estimateAreaEffect(input, target, eff)
  eff = eff or self.effects[1]
  local tiles = self:getAllAffectedTiles(input, target)
  local sum = 0
  for i = 1, #tiles do
    local tile = tiles[i]
    for targetChar in tile.characterList:iterator() do
      if input.action:isCharacterAffected(input, targetChar) then
        local result = input.action:estimateEffect(input, targetChar, eff)
        if (targetChar.party == input.user.party) ~= eff.heal then
          result = -result
        end
        sum = sum + result
      end
    end
  end
  return sum
end
-- For debugging.
function SkillAction:__tostring()
  return 'SkillAction (' .. self.data.id .. ': ' .. self.data.name .. ')'
end

return SkillAction
