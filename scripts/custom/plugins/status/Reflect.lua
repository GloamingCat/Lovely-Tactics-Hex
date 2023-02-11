
--[[===============================================================================================

Reflect
---------------------------------------------------------------------------------------------------
Makes a skill reflect to the user.

-- Plugin parameters:
When a character reflects a skill, the animation given by <anim> is played in the character's
tile. No skill is played if the parameter is not set.
<self> determines what happens when a user casts a skills on oneself. If 'all', it's reflected 
and consumes one reflection use, but with no changes on target/user. If 'none' (default), it
passes through the reflection. If 'offensive', only offensive skills will be reflected.

-- Skill parameters:
Only the skills with <reflectable> tags may be reflected.

-- Status parameters:
Status with <reflect> tag makes the characters reflect the next skill. The status is removed if a
skill is reflected.
Set <removeOnUse> to true to limit the reflection to one use.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local Battler = require('core/battle/battler/Battler')
local SkillAction = require('core/battle/action/SkillAction')
local BattleAnimations = require('core/battle/BattleAnimations')

-- Parameters
local anim = args.anim
local selfReflect = args.selfReflect or 'none'

---------------------------------------------------------------------------------------------------
-- Skill Action
---------------------------------------------------------------------------------------------------

-- Overrides. Changes targets if reflect.
local SkillAction_singleTargetEffect = SkillAction.singleTargetEffect
function SkillAction:singleTargetEffect(results, input, target, originTile)
  local minTime = 0
  if originTile and self.tags.reflectable and (#results.points > 0 or #results.status > 0) and
      (input.user ~= target or selfReflect == 'all' or selfReflect == 'offensive' and self.offensive) then
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

---------------------------------------------------------------------------------------------------
-- Battler
---------------------------------------------------------------------------------------------------

-- Checks if the battler has a reflect status.
function Battler:reflects()
  for status in self.statusList:iterator() do
    if status.tags.reflect then
      return status
    end
  end
  return nil
end
