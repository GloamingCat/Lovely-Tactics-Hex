
--[[===============================================================================================

Transformable
---------------------------------------------------------------------------------------------------
An object with physical properties (position, rotation, scale) and color.

=================================================================================================]]

-- Imports
local Movable = require('core/transform/Movable')
local Scalable = require('core/transform/Scalable')
local Rotatable = require('core/transform/Rotatable')
local Colorable = require('core/transform/Colorable')

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
  self:updateScale()
  self:updateRotation()
  self:updateColor()
end

return Transformable
