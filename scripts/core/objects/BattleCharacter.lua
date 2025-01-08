
-- ================================================================================================

--- An instance of a character from `Database`.
-- The instance details are defined by the character instance in a field.
---------------------------------------------------------------------------------------------------
-- @fieldmod BattleCharacter
-- @extend AnimatedInteractable

-- ================================================================================================

-- Imports
local BattleAnimations = require('core/battle/BattleAnimations')
local Character = require('core/objects/Character')

-- Class table.
local BattleCharacter = class(Character)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. Overrides `Character:init`.
-- Initialized battle info.
-- @override
function BattleCharacter:init(instData, save)
  Character.init(self, instData, save)
  -- Battle info
  self.party = instData.party or -1
  self.battlerID = instData.battlerID or -1
  if self.battlerID == -1 then
    self.battlerID = self.charData.battlerID or -1
  end
end
--- Overrides `Character:initProperties`.
-- Sets damage/KO animation names.
-- @override
function BattleCharacter:initProperties(instData, save)
  Character.initProperties(self, instData, save)
  self.damageAnim = 'Damage'
  self.koAnim = 'KO'
end

-- ------------------------------------------------------------------------------------------------
-- KO
-- ------------------------------------------------------------------------------------------------

--- Plays animation for when character is knocked out.
-- @treturn Animation The animation that started playing.
function BattleCharacter:playKOAnimation()
  if self.party == TroopManager.playerParty then
    if Config.sounds.allyKO then
      AudioManager:playSFX(Config.sounds.allyKO)
    end
  else
    if Config.sounds.enemyKO then
      AudioManager:playSFX(Config.sounds.enemyKO)
    end
  end
  return self:playAnimation(self.koAnim)
end
--- Removes character from battle.
-- @tparam[opt] number fade The duration of the fadeout animation.
-- @tparam boolean hide Flag to make the character inacessible instead of moving it to back-up.
function BattleCharacter:removeFromBattle(fade, hide)
  if fade and fade >= 0 then
    self:colorizeTo(nil, nil, nil, 0, 60 / fade, true)
  end
  local troop = TroopManager.troops[self.party]
  local member = troop:moveMember(self.key, hide and 2 or 1)
  TroopManager:deleteCharacter(self)
end

-- ------------------------------------------------------------------------------------------------
-- Skill (user)
-- ------------------------------------------------------------------------------------------------

--- Play load animation.
-- @coroutine
-- @tparam table skill Skill data from database.
-- @treturn number The duration of the animation.
function BattleCharacter:loadSkill(skill)
  -- Load animation (user)
  local minTime = 0
  if skill.animInfo.userLoad ~= '' then
    local anim = self:playAnimation(skill.animInfo.userLoad)
    anim:reset()
    local waitTime = tonumber(anim.tags and anim.tags.skillTime)
    if waitTime then
      _G.Fiber:wait(waitTime)
      return math.max(anim.duration, waitTime) - waitTime
    end
  end
  return 0
end
--- Plays cast animation.
-- @coroutine
-- @tparam table skill Skill's data.
-- @tparam number dir The direction of the cast.
-- @tparam ObjectTile target Target of the skill.
-- @treturn number The duration of the animation.
function BattleCharacter:castSkill(skill, dir, target)
  -- Forward step
  if skill.animInfo.stepOnCast then
    self:playMoveAnimation()
    self:walkInAngle(self.castStep or 6, dir)
    self:playIdleAnimation()
  end
  -- Cast animation (user)
  local minTime = 0
  if skill.animInfo.userCast ~= '' then
    local anim = self:playAnimation(skill.animInfo.userCast)
    anim:reset()
    local waitTime = tonumber(anim.tags and anim.tags.skillTime)
    if waitTime then
      minTime = math.max(anim.duration, waitTime) - waitTime
    end
    _G.Fiber:wait(waitTime)
  end
  return minTime
end
--- Returns to original tile and stays idle.
-- @coroutine
-- @tparam ObjectTile origin The original tile of the character.
-- @tparam table skill Skill data from database.
function BattleCharacter:finishSkill(origin, skill)
  if skill.animInfo.stepOnCast then
    local x, y, z = origin.center:coordinates()
    if self.position:almostEquals(x, y, z) then
      return
    end
    if self.autoAnim then
      self:playMoveAnimation()
    end
    self:walkToPoint(x, y, z)
    self:setXYZ(x, y, z)
  end
  if self.autoAnim then
    self:playIdleAnimation()
  end
end

-- ------------------------------------------------------------------------------------------------
-- Skill (target)
-- ------------------------------------------------------------------------------------------------

--- Plays damage and KO (if died) animation.
-- @coroutine
-- @tparam Skill skill The skill used.
-- @tparam ObjectTile origin The tile of the skill user.
-- @tparam table results Results of the skill.
function BattleCharacter:skillDamage(skill, origin, results)
  local currentTile = self:getTile()
  if currentTile ~= origin then
    self:turnToTile(origin.x, origin.y)
  end
  local anim = self:playAnimation(self.damageAnim)
  anim:reset()
  _G.Fiber:wait(anim.duration)
  if self.battler:isAlive() then
    self:playIdleAnimation()
  else
    self:playKOAnimation(fadeout)
    BattleAnimations.dieEffect(self)
    if self.charData.koFadeout and self.charData.koFadeout >= 0 then
      self:removeFromBattle(self.charData.koFadeout)
    end
  end
end

return BattleCharacter