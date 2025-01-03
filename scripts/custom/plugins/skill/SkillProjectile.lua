
-- ================================================================================================

--- Add projectile animation for skills.
---------------------------------------------------------------------------------------------------
-- @plugin SkillProjectile

--- Plugin parameters.
-- @tags Plugin
-- @tfield number defaultSpeed The speed of a projectile if not specified. 500 by default.

--- Parameters in the Animation tags.
-- @tags Animation
-- @tfield boolean rotate Whether the sprite should rotate according to the user's direction.
-- @tfield number moveSpeed Projectile's speed in pixels per second.

--- Parameters in the Skill tags.
-- @tags Skill
-- @tfield number|string projectileID The ID or key of the projectile's animation.

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')
local BattleCharacter = require('core/objects/BattleCharacter')
local BattleAnimations = require('core/battle/BattleAnimations')
local Vector = require('core/math/Vector')

-- Alias
local max = math.max
local min = math.min
local nextCoordDir = math.field.nextCoordDir
local pixel2Tile = math.field.pixel2Tile
local tile2Pixel = math.field.tile2Pixel

-- Parameters
local defaultSpeed = args.defaultSpeed or 500

-- Rewrites
local Animation_update = Animation.update
local BattleCharacter_castSkill = BattleCharacter.castSkill

-- ------------------------------------------------------------------------------------------------
-- Animation
-- ------------------------------------------------------------------------------------------------

--- Sets origin position.
-- @tparam Character user
function Animation:setUser(user)
  self.userHeight = user:getHeight(0, 0) / 2
  local di, dj = nextCoordDir(user:getRoundedDirection())
  local i, j, h = user:getTile():coordinates()
  local x, y, z = tile2Pixel(i + di, j + dj, h + self.userHeight)
  local row = self.tags and self.tags.rotate and user.animation.row or 0
  self.sprite:setXYZ(x, y, z)
  self.origin = Vector(x, y, z)
  self:setRow(row)
end
--- Sets target position.
-- @tparam ObjectTile target
-- @treturn number The distance from the current position to the target position.
function Animation:setTarget(target)
  local i, j, h = target:coordinates()
  self.target = Vector(tile2Pixel(i, j, h + (self.userHeight or 0)))
  self.moveTime = 0
  return self.sprite.position:distance2DTo(self.target:coordinates())
end
--- Starts the movement towards the target tile.
-- @coroutine
-- @tparam Character user
-- @tparam ObjectTile target The target tile.
-- @tparam[opt] number speed Speed in pixels per second. If nil, gets speed from tags.
-- @tparam[opt] boolean wait Flag to wait until the end of movement.
-- @treturn number Duration of the movement in frames.
function Animation:throw(user, target, speed, wait)
  self:setUser(user)
  local d = self:setTarget(target)
  speed = speed or self.tags and self.tags.moveSpeed
  self.moveSpeed = speed / d
  local time = d * 60 / speed
  FieldManager.updateList:add(self)
  local fiber = FieldManager.fiberList:fork(function()
    _G.Fiber:wait(time)
    FieldManager.updateList:removeElement(self)
    self:destroy()
  end)
  if wait then
    fiber:waitForEnd()
  end
  return time
end
--- Rewrites `Animation:update`.
-- @rewrite
function Animation:update(dt)
  Animation_update(self, dt)
  if self.moveSpeed then
    self.moveTime = min(self.moveTime + dt * self.moveSpeed, 1)
    self.sprite:setPosition(self.origin:lerp(self.target, self.moveTime))
  end
end

-- ------------------------------------------------------------------------------------------------
-- BattleCharacter
-- ------------------------------------------------------------------------------------------------

--- Rewrites `BattleCharacter:castSkill`.
-- @rewrite
function BattleCharacter:castSkill(skill, dir, target)
  local minTime = BattleCharacter_castSkill(self, skill, dir, target)
  -- Projectile
  local projectileTag = util.array.findByKey(skill.tags, 'projectileID')
  if projectileTag then
    _G.Fiber:wait(minTime)
    local animID = tonumber(projectileTag.value) or projectileTag.value
    local anim = ResourceManager:loadAnimation(animID, FieldManager.renderer)
    local speed = anim.tags and anim.tags.moveSpeed or defaultSpeed
    minTime = minTime - math.min(minTime, anim:throw(self, target, speed, true))
  end
  return minTime
end
