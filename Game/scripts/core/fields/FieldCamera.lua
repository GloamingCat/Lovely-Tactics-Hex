
--[[===========================================================================

FieldCamera
-------------------------------------------------------------------------------
The FieldCamera is a renderer with transform properties.

=============================================================================]]

-- Imports
local Renderer = require('core/graphics/Renderer')

-- Alias
local tile2Pixel = math.field.tile2Pixel

local FieldCamera = Renderer:inherit()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

-- Updates position and movement.
local old_updatePosition = FieldCamera.updatePosition
function FieldCamera:updatePosition()
  if self.focusObject then
    self:setXYZ(self.focusObject.position.x, self.focusObject.position.y)
  elseif self.moveDistance then
    local s = self.moveSpeed
    self.moveSpeed = (self.moveSpeed / 6 + self.moveDistance * 3)
    old_updatePosition(self)
    self.moveSpeed = s
  end
end

-------------------------------------------------------------------------------
-- Camera Movement
-------------------------------------------------------------------------------

-- [COROUTINE] Moves camera to the given tile.
-- @param(tile : ObjectTile) the destionation tile
-- @param(wait : boolean) flag to wait until the move finishes
function FieldCamera:moveToTile(tile, wait)
  self.focusObject = nil
  local x, y, z = tile2Pixel(tile:coordinates())
  self:moveTo(x, y, self.position.y - y, wait)
end

-- [COROUTINE] Movec camera to the given object.
-- @param(obj : Object) the destination object
-- @param(wait : boolean) flag to wait until the move finishes
function FieldCamera:moveToObject(obj, wait)
  self.focusObject = nil
  local p = obj.position
  self:moveTo(p.x, p.y, p.y - self.position.y, wait)
end

return FieldCamera
