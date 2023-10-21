
-- ================================================================================================

--- Makes a skill reflect to the user.
---------------------------------------------------------------------------------------------------
-- @plugin Reflect

-- ================================================================================================

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local Battler = require('core/battle/battler/Battler')
local SkillAction = require('core/battle/action/SkillAction')
local BattleAnimations = require('core/battle/BattleAnimations')

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Self-reflection types. It determines what happens when a user casts a skills on oneself.
-- @enum SelfReflection
-- @field none It passes through the reflection without activating it.
-- @field offensive Only offensive skills activate the reflection, but with no changes on target/user.
-- @field all All skills activate the reflection, but with no changes on target/user.
local SelfReflection = {
  NONE = 'none',
  OFFENSIVE = 'offensive',
  ALL = 'all'
}

-- ------------------------------------------------------------------------------------------------
-- Parameters
-- ------------------------------------------------------------------------------------------------

local anim = args.anim
local selfReflect = args.selfReflect or SelfReflection.NONE

--- Plugin parameters.
-- @tags Plugin
-- @tfield number|string anim The ID or key of the animation that is played in the character's
--  tile when it reflects a skill. No skill is played if the parameter is not set.
-- @tfield SelfReflection selfReflect It determines what happens when a user casts a skills on oneself.

--- Skill tags.
-- @tags Skill
-- @tfield booelan reflectable Only the skills with this tag can be reflected.

--- Status tags.
-- @tags Status
-- @tfield boolean reflect Makes the characters reflect the next receiving skill.
-- @tfield boolean removeOnUse Flag to remove the status if the reflection is activated.

-- ------------------------------------------------------------------------------------------------
-- Skill Action
-- ------------------------------------------------------------------------------------------------

--- Rewrites `SkillAction:singleTargetEffect`.
-- @override SkillAction_singleTargetEffect
local SkillAction_singleTargetEffect = SkillAction.singleTargetEffect
function SkillAction:singleTargetEffect(results, input, target, originTile)
  local minTime = 0
  if originTile and self.tags.reflectable and (#results.points > 0 or #results.status > 0) and
      (input.user ~= target or selfReflect == SelfReflection.ALL or
      selfReflect == SelfReflection.OFFENSIVE and self.offensive) then
    local targetChar = TroopManager:getBattlerCharacter(target)
    if targetChar then
      local status = target:reflects()
      if status then
        -- Reflect Animation
        FieldManager.renderer:moveToTile(targetChar:getTile())
        if anim then
          local dir = targetChar:tileToAngle(originTile.x, originTile.y)
          local mirror = self.data.mirror and dir > 90 and dir <= 270
          local x, y, z = targetChar.position:coordinates()
          BattleAnimations.playOnField(anim, x, y, z, mirror, true)
        end
        -- Original skill's animation
        FieldManager.renderer:moveToTile(input.user:getTile())
        if self.data.castAnimID >= 0 and self.data.individualAnimID < 0 then
          minTime = BattleAnimations.playOnField(self.data.castAnimID,
            input.user.position:coordinates()).duration + GameManager.frame
          _G.Fiber:wait(self.centerTime)
        end
        -- Remove reflect status
        if status.tags.removeOnUse and not status.equip then
          input.user.battler.statusList:removeStatus(status, targetChar)
        end
        -- Change target
        originTile = targetChar:getTile()
        target = input.user.battler
        results = self:calculateEffectResults(target, target)
      end
    end
  end
  return SkillAction_singleTargetEffect(self, results, input, target, originTile)
end

-- ------------------------------------------------------------------------------------------------
-- Battler
-- ------------------------------------------------------------------------------------------------

--- Checks if the battler has a reflect status.
function Battler:reflects()
  for status in self.statusList:iterator() do
    if status.tags.reflect then
      return status
    end
  end
  return nil
end
