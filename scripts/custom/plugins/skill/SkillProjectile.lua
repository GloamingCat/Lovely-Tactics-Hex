
--[[===============================================================================================

SkillProjectile
---------------------------------------------------------------------------------------------------
Abstraction of a projectile thrown during the use of a skill.

-- Skill parameters:
Set <projectileID> tag as projectile animation ID. Must the an animation with "Projectile" script.

=================================================================================================]]

-- Imports
local Character = require('core/objects/Character')

-- Alias
local max = math.max
local tile2Pixel = math.field.tile2Pixel

---------------------------------------------------------------------------------------------------
-- Cast
---------------------------------------------------------------------------------------------------

-- Overrides. Change throw projectile before skill animation.
local Character_castSkill = Character.castSkill
function Character:castSkill(skill, dir, target)
  -- Forward step
  if skill.stepOnCast then
    self:walkInAngle(self.castStep or 6, dir)
  end
  -- Cast animation (user)
  local minTime = 0
  if skill.userCastAnim ~= '' then
    local anim = self:playAnimation(skill.userCastAnim)
    anim:reset()
    minTime = anim.duration
  end
  -- Projectile
  local projectileTag = util.array.findByKey(skill.tags, 'projectileID')
  if projectileTag then
    _G.Fiber:wait(minTime)
    self:throwSkillProjectile(tonumber(projectileTag.value), target, true)
    minTime = 0
  end
  -- Cast animation (effect on tile)
  if skill.castAnimID >= 0 then
    local mirror = skill.mirror and dir > 90 and dir <= 270
    local x, y, z = tile2Pixel(target:coordinates())
    local anim = BattleManager:playBattleAnimation(skill.castAnimID,
      x, y, z - 1, mirror)
    minTime = max(minTime, anim.duration)
  end
  return minTime
end

---------------------------------------------------------------------------------------------------
-- Projectile
---------------------------------------------------------------------------------------------------

-- Instantiates new projectile animation in the user's current tile.
-- @param(animID : number) Animation ID.
-- @param(target : ObjectTile) Destination tile.
-- @param(wait : boolean) True to wait until movement finishes.
-- @ret(number) The duration of the movement in frames.
function Character:throwSkillProjectile(animID, target, wait)
  local animation = ResourceManager:loadAnimation(animID, FieldManager.renderer)
  assert(animation.throw, 'Animation is not of type Projectile: ' .. tostring(animation.throw))
  return animation:throw(self, target, 600, true)
end
