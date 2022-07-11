
--[[===============================================================================================

Reflect
---------------------------------------------------------------------------------------------------
Makes a skill reflect to the user.

-- Plugin parameters:
When a character reflects a skill, the animation given by <animID> is played in the character's
tile. No skill is played if the parameter is not set.

-- Skill parameters:
Only the skills with <reflectable> tags may be reflected.

-- Status parameters:
Status with <reflect> tag makes the characters reflect the next skill. The status is removed if a
skill is reflected.

=================================================================================================]]

-- Imports
local ActionInput = require('core/battle/action/ActionInput')
local Battler = require('core/battle/battler/Battler')
local SkillAction = require('core/battle/action/SkillAction')

-- Parameters
local animID = tonumber(args.animID)

---------------------------------------------------------------------------------------------------
-- Skill Action
---------------------------------------------------------------------------------------------------

-- Overrides. Changes targets if reflect.
local SkillAction_singleTargetEffect = SkillAction.singleTargetEffect
function SkillAction:singleTargetEffect(results, input, targetChar, originTile)
  local minTime = 0
  if #results.points > 0 or #results.status > 0 then
    if self.tags.reflectable then
      local status = input.user.battler:reflects()
      if status then
        -- Animation
        FieldManager.renderer:moveToTile(targetChar:getTile())
        if animID then
          local x, y, z = targetChar.position:coordinates()
          BattleManager:playBattleAnimation(animID, x, y, z, false, true)
        end
        FieldManager.renderer:moveToTile(input.user:getTile())
        if self.data.castAnimID >= 0 and self.data.individuaAnimlID < 0 then
          minTime = BattleManager:playBattleAnimation(self.data.castAnimID,
            input.user.position:coordinates()).duration + GameManager.frame
          _G.Fiber:wait(self.centerTime)
        end
        -- Change target
        originTile = targetChar:getTile()
        targetChar = input.user
        results = self:calculateEffectResults(input.user.battler, targetChar.battler)
        -- Remove reflect status
        input.user.battler.statusList:removeStatus(status, input.user)
      end
    end
  end
  SkillAction_singleTargetEffect(self, results, input, targetChar, originTile)
  _G.Fiber:wait(math.max(minTime - GameManager.frame, 0))
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
