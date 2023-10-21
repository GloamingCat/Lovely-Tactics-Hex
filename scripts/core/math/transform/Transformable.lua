
-- ================================================================================================

--- An object with physical properties (position, rotation, scale) and color.
---------------------------------------------------------------------------------------------------
-- @classmod Transformable
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
function Transformable:init(initPos, initScaleX, initScaleY, initRot, initColor)
  self:initMovement(initPos)
  self:initScale(initScaleX, initScaleY)
  self:initRotation(initRot)
  self:initColor(initColor)
end
--- Called each frame.
function Transformable:update(dt)
  self:updateMovement(dt)
  self:updateScaling(dt)
  self:updateRotation(dt)
  self:updateColor(dt)
end

return Transformable
