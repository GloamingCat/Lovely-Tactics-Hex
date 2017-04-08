
--[[===========================================================================

Character - Battle
-------------------------------------------------------------------------------
Character methods that are called during a battle.

=============================================================================]]

-- Imports
local PopupText = require('core/battle/PopupText')

-- Alias
local tile2Pixel = math.field.tile2Pixel

-- Constants
local castStep = 6

local Character_Battle = require('core/class'):new()

-------------------------------------------------------------------------------
-- Skill (user)
-------------------------------------------------------------------------------

-- [COROUTINE] Executes the intro animations (load and cast) for skill use.
-- @param(target : ObjectTile) the target of the skill
-- @param(skill : table) skill data from database
function Character_Battle:loadSkill(skill, dir, wait)
  local minTime = 0
  
  -- Load animation (user)
  if skill.userLoadAnim ~= '' then
    local anim = self:playAnimation(skill.userLoadAnim)
    minTime = anim.duration
  end
  
  -- Load animation (effect on tile)
  if skill.loadAnimID >= 0 then
    local mirror = skill.mirror and dir > 90 and dir <= 270
    local pos = self.position
    local anim = BattleManager:playAnimation(skill.loadAnimID, 
      pos.x, pos.y, pos.z - 1, mirror)
    minTime = max(minTime, anim.duration)
  end
  
  if wait then
    _G.Fiber:wait(minTime)
  end
end

-- [COROUTINE] Plays cast animation.
-- @param(skill : Skill)
-- @param(dir : number) the direction of the cast
function Character_Battle:castSkill(skill, dir, wait)
  local minTime = 0
  
  -- Forward step
  if skill.stepOnCast then
    local oldAutoTurn = self.autoTurn
    self.autoTurn = false
    self:walkInAngle(castStep, dir)
    self.autoTurn = oldAutoTurn
  end
  
  -- Cast animation (user)
  if skill.userCastAnim ~= '' then
    local anim = self:playAnimation(skill.userCastAnim)
    minTime = anim.duration
  end
  
  -- Cast animation (effect on tile)
  if skill.castAnimID >= 0 then
    local mirror = skill.mirror and dir > 90 and dir <= 270
    local pos = self.position
    local anim = BattleManager:playAnimation(skill.castAnimID, 
      pos.x, pos.y, pos.z - 1, mirror)
    minTime = max(minTime, anim.duration)
  end
  
  if wait then
    _G.Fiber:wait(minTime)
  end
end

-- [COROUTINE] Returns to original tile and stays idle.
-- @param(origin : ObjectTile) the original tile of the character
-- @param(skill : table) skill data from database
function Character_Battle:finishSkill(origin, skill)
  local x, y, z = tile2Pixel(origin:coordinates())
  if skill.stepOnCast then
    local autoTurn = self.autoTurn
    self.autoTurn = false
    self:walkToPoint(x, y, z)
    self.autoTurn = autoTurn
  end
  self:playAnimation(self.idleAnim)
end

-------------------------------------------------------------------------------
-- Skill (target)
-------------------------------------------------------------------------------

-- [COROUTINE] Plays damage animation and shows the result in a pop-up.
-- @param(skill : Skill) the skill used
-- @param(result : number) the the damage caused
-- @param(origin : ObjectTile) the tile of the skill user
function Character_Battle:damage(skill, result, origin)
  local pos = self.position
  local popupText = PopupText(pos.x, pos.y - 20, pos.z - 10)
  local ko = false
  if skill.affectHP then
    popupText:addLine(result, Color.popup_dmgHP, Font.popup_dmgHP)
    ko = self.battler:damageHP(result)
  end
  if skill.affectSP then
    popupText:addLine(result, Color.popup_dmgSP, Font.popup_dmgSP)
    self.battler:damageSP(result)
  end
  local currentTile = self:getTile()
  local dir = self:turnToTile(origin.x, origin.y)
  if skill.individualAnimID >= 0 then
    local mirror = dir > 90 and dir <= 270
    BattleManager:playAnimation(skill.individualAnimID,
      pos.x, pos.y, pos.z - 10, mirror)
  end
  popupText:popup()
  self:playAnimation(self.damageAnim, true)
  self:playAnimation(self.idleAnim)
  if ko then
    self:playAnimation(self.koAnim, true)
  end
end

return Character_Battle
