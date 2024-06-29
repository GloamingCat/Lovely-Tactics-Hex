
-- ================================================================================================

--- An object with physical properties (position, rotation, scale) and color.
---------------------------------------------------------------------------------------------------
-- @basemod Transformable
-- @extend Movable
-- @extend Scalable
-- @extend Rotatable
-- @extend Colorable

-- ================================================================================================

-- Imports
local Movable = require('core/math/transform/Movable')
local Scalable = require('core/math/transform/Scalable')
local Rotatable = require('core/math/transform/Rotatable')
local Colorable = require('core/math/transform/Colorable')

-- Class table.
local Transformable = class(Movable, Scalable, Rotatable, Colorable)

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam[opt=Vector(0,0,0)] Vector initPos Initial pixel position.
-- @tparam[opt=1] number initScaleX Initial horizontal scale multiplier.
-- @tparam[opt=1] number initScaleY Initial vertical scale multiplier.
-- @tparam[opt=0] number initRot Initial rotation, in degrees.
-- @tparam[opt] Color.RGBA initColor Initial color. The default value is `Color.white`.
function Transformable:init(initPos, initScaleX, initScaleY, initRot, initColor)
  self:initMovement(initPos)
  self:initScale(initScaleX, initScaleY)
  self:initRotation(initRot)
  self:initColor(initColor)
  self.offsetX = 0
  self.offsetY = 0
  self.offsetDepth = 0
end
--- Called each frame.
-- @tparam number dt The duration of the previous frame.
function Transformable:update(dt)
  self:updateMovement(dt)
  self:updateScaling(dt)
  self:updateRotation(dt)
  self:updateColor(dt)
end

return Transformable
