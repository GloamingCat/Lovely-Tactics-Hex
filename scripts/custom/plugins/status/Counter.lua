
-- ================================================================================================

--- Makes a character attack back if hit.
---------------------------------------------------------------------------------------------------
-- @plugin Counter

--- Plugin parameters.
-- @tags Plugin
-- @tfield number maxCounters The max number of counter-attacks alternating in a row.

--- Parameters in the Status tags.
-- @tags Status
-- @tfield string|number counterID The skill used when character counter-attacks when it has
--  this status.

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local Battler = require('core/battle/battler/Battler')
local SkillAction = require('core/battle/action/SkillAction')
local BattleMoveAction = require('core/battle/action/BattleMoveAction')

-- Parameters
local maxCounters = args.maxCounters or 1

-- ------------------------------------------------------------------------------------------------
-- Skill Action
-- ------------------------------------------------------------------------------------------------

--- Rewrites `Battler:initState`.
-- @override Battler_initState
local Battler_initState = Battler.initState
function Battler:initState(data, save)
  Battler_initState(self, data, save)
  if self.tags.counterID then
    self.counterSkill = SkillAction:fromData(self.tags.counterID)
  else
    self.counterSkill = nil
  end
end

-- ------------------------------------------------------------------------------------------------
-- Skill Action
-- ------------------------------------------------------------------------------------------------

--- Rewrites `SkillAction:allTargetsEffect`.
-- @override SkillAction_allTargetsEffect
local SkillAction_allTargetsEffect = SkillAction.allTargetsEffect
function SkillAction:allTargetsEffect(input, originTile)
  local allTargets = SkillAction_allTargetsEffect(self, input, originTile)
  if not self.offensive or (self.counter and self.counter >= maxCounters) then
    return allTargets
  end
  local userTile = input.user:getTile()
  for i = #allTargets, 1, -1 do
    for targetChar in allTargets[i].characterList:iterator() do
      if targetChar.battler and targetChar.battler:isActive() and input.user.battler:isAlive() 
          and targetChar.party ~= input.user.party and targetChar.battler:counters() then
        targetChar.battler:counterAttack(targetChar, userTile, self.counter)
      end
    end
  end
  return allTargets
end

-- ------------------------------------------------------------------------------------------------
-- Battler
-- ------------------------------------------------------------------------------------------------

--- Checks if this character counter-attacks.
function Battler:counters()
  for status in self.statusList:iterator() do
    if status.tags.counter then
      return status
    end
  end
  return nil
end
--- Attacks the given character.
function Battler:counterAttack(user, target, counter)
  local skill = self.counterSkill or self:getAttackSkill()
  if self.tags.counter then
    skill = SkillAction(self.tags.counter)
  end
  local input = ActionInput(skill, user, target)
  input.moveAction = BattleMoveAction()
  skill:onSelect(input)
  if input:canExecute() then
    skill.counter = (counter or 0) + 1
    local result = input:execute()
    skill.counter = nil
    return result
  end
end
