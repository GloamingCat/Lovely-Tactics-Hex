
--[[===============================================================================================

Critical
---------------------------------------------------------------------------------------------------
Doubles damage for critical hits.

-- Plugin parameters:
The attribute used to calculate the chance of critical hit is given by <attName>.
When critical hit occurs, the base result is multiplied by <ratio>.
When critical hit occurs, an SFX may be played, with its path, volume and pitch being defined by
<sound>, <volume> and <pitch>, respectively.

-- Skill parameters:
If the skill allows critical hit to occur, then the tag <critical> must be set.

=================================================================================================]]

-- Imports
local Battler = require('core/battle/battler/Battler')
local PopupText = require('core/battle/PopupText')
local SkillAction = require('core/battle/action/SkillAction')

-- Parameters
local attName = args.attName
local ratio = tonumber(args.ratio) or 2

---------------------------------------------------------------------------------------------------
-- Rate
---------------------------------------------------------------------------------------------------

-- Calculates critical hit rate.
local SkillAction_calculateEffectResults = SkillAction.calculateEffectResults
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

---------------------------------------------------------------------------------------------------
-- Pop-up
---------------------------------------------------------------------------------------------------

-- Changes font and show text when critical.
local PopupText_addDamage = PopupText.addDamage
function PopupText:addDamage(points)  
  local crit = points.critical and '_crit' or ''
  local popupName = 'popup_dmg' .. points.key
  if points.critical then
    self:addLine(Vocab.critical, popupName, popupName) 
  end
  self:addLine(points.value, popupName, popupName .. crit)
end
-- Changes font and show text when critical.
local PopupText_addHeal = PopupText.addHeal
function PopupText:addHeal(points)
  local crit = points.critical and '_crit' or ''
  local popupName = 'popup_heal' .. points.key
  if points.critical then
    self:addLine(Vocab.critical, popupName, popupName) 
  end
  self:addLine(points.value, popupName, popupName .. crit)
end

---------------------------------------------------------------------------------------------------
-- Sound
---------------------------------------------------------------------------------------------------

-- Plays sound before pop-up.
local Battler_popupResults = Battler.popupResults
function Battler:popupResults(popupText, results, character)
  if Config.sounds.critical and results.critical then
    AudioManager:playSFX(Config.sounds.critical)
  end
  Battler_popupResults(self, popupText, results, character)
end
