
--[[===========================================================================

FieldCamera
-------------------------------------------------------------------------------
The FieldCamera is a renderer with transform properties.

=============================================================================]]

-- Imports
local Renderer = require('core/graphics/Renderer')

-- Alias
local tile2Pixel = math.field.tile2Pixel
local sqrt = math.sqrt

-- Constants
local cameraSpeed = 75

local FieldCamera = class(Renderer)

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

-- Updates position and movement.
local old_updatePosition = FieldCamera.updatePosition
function FieldCamera:updatePosition()
  if self.focusObject then
    self:setXYZ(self.focusObject.position.x, self.focusObject.position.y)
  else
    old_updatePosition(self)
  end
end

-------------------------------------------------------------------------------
-- Camera Movement
-------------------------------------------------------------------------------

-- [COROUTINE] Moves camera to the given tile.
-- @param(tile : ObjectTile) the destionation tile
-- @param(wait : boolean) flag to wait until the move finishes
function FieldCamera:moveToTile(tile, wait)
  local x, y = tile2Pixel(tile:coordinates())
  self:moveToPoint(x, y, wait)
end

-- [COROUTINE] Movec camera to the given object.
-- @param(obj : Object) the destination object
-- @param(wait : boolean) flag to wait until the move finishes
-- @param(speed : number) the speed of the movement
function FieldCamera:moveToObject(obj, wait, speed)
  self:moveToPoint(obj.position.x, obj.position.y, wait, speed)
end

-- Moves camera to the given pixel point.
-- @param(x : number) the pixel x
-- @param(y : nubmer) the pixel y
-- @param(wait : boolean) flag to wait until the move finishes
-- @param(speed : number) the speed of the movement
function FieldCamera:moveToPoint(x, y, wait, speed)
  self.focusObject = nil
  local dx = self.position.x - x
  local dy = self.position.y - y
  local distance = sqrt(dx * dx + dy * dy)
  speed = ((speed or cameraSpeed) + distance * 3)
  self:moveTo(x, y, 0, speed / distance, wait)
end

return FieldCamera
