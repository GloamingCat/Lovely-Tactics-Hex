
--[[===============================================================================================

Transformable
---------------------------------------------------------------------------------------------------
An object with physical properties (position, rotation, scale) and color.

=================================================================================================]]

-- Imports
local Movable = require('core/math/transform/Movable')
local Scalable = require('core/math/transform/Scalable')
local Rotatable = require('core/math/transform/Rotatable')
local Colorable = require('core/math/transform/Colorable')

local Transformable = class(Movable, Scalable, Rotatable, Colorable)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
function Transformable:init(initPos, initScaleX, initScaleY, initRot, initColor)
  self:initMovement(initPos)
  self:initScale(initScaleX, initScaleY)
  self:initRotation(initRot)
  self:initColor(initColor)
end
-- Called each frame.
function Transformable:update()
  self:updateMovement()
  self:updateScaling()
  self:updateRotation()
  self:updateColor()
end

return Transformable
