
-- ================================================================================================

--- Doubles damage for critical hits.
---------------------------------------------------------------------------------------------------
-- @plugin Critical

--- Plugin parameters.
-- @tags Plugin
-- @tfield string attName The attribute used to calculate the chance of a critical hit.
-- @tfield number ratio The multiplier of the base damage when a critical hit occurs.
-- @tfield[opt] string sound The name of the SFX played when a critical hit occurs.
-- @tfield[opt] number pitch The pitch of the SFX played when a critical hit occurs.
-- @tfield[opt] number volume The volume of the SFX played when a critical hit occurs.

--- Parameters in the Skill tags.
-- @tags Skill
-- @tfield boolean critical Flag to allow a critical hit to occur when this skill is used.

-- ================================================================================================

-- Imports
local Battler = require('core/battle/battler/Battler')
local PopText = require('core/graphics/PopText')
local SkillAction = require('core/battle/action/SkillAction')

-- Rewrites
local SkillAction_calculateEffectResults = SkillAction.calculateEffectResults
local PopText_addDamage = PopText.addDamage
local PopText_addHeal = PopText.addHeal
local Battler_popResults = Battler.popResults

-- Parameters
local attName = args.attName
local ratio = args.ratio or 2

-- ------------------------------------------------------------------------------------------------
-- Rate
-- ------------------------------------------------------------------------------------------------

--- Rewrites `SkillAction:calculateEffectResults`. Calculates critical hit rate.
-- @rewrite
function SkillAction:calculateEffectResults(user, target)
  local results = SkillAction_calculateEffectResults(self, user, target)
   if self.tags.critical then
    local crit = user.att[attName]()
    local rand = self.rand or love.math.random
    if rand() * 100 <= crit then
      results.critical = true
      for i = 1, #results.points do
        results.points[i].value = math.floor(results.points[i].value * ratio)
        results.points[i].critical = true
      end
    end
  end
  return results
end

-- ------------------------------------------------------------------------------------------------
-- Pop-up
-- ------------------------------------------------------------------------------------------------

--- Rewrites `PopText:addDamage`. Changes font and show text when critical.
-- @rewrite
function PopText:addDamage(points)  
  local crit = points.critical and '_crit' or ''
  local popupName = 'popup_dmg' .. points.key
  if points.critical then
    self:addLine(Vocab.critical, popupName, popupName) 
  end
  self:addLine(points.value, popupName, popupName .. crit)
end
--- Rewrites `PopText:addHeal`. Changes font and show text when critical.
-- @rewrite
function PopText:addHeal(points)
  local crit = points.critical and '_crit' or ''
  local popupName = 'popup_heal' .. points.key
  if points.critical then
    self:addLine(Vocab.critical, popupName, popupName) 
  end
  self:addLine(points.value, popupName, popupName .. crit)
end

-- ------------------------------------------------------------------------------------------------
-- Sound
-- ------------------------------------------------------------------------------------------------

--- Rewrites `Battler:popResults`. Plays sound before pop-up.
-- @rewrite
function Battler:popResults(popText, results, character)
  if Config.sounds.critical and results.critical then
    AudioManager:playSFX(Config.sounds.critical)
  end
  Battler_popResults(self, popText, results, character)
end
