
--[[===============================================================================================

FieldCamera
---------------------------------------------------------------------------------------------------
The FieldCamera is a renderer with transform properties.

=================================================================================================]]

-- Imports
local Renderer = require('core/graphics/Renderer')

-- Alias
local tile2Pixel = math.field.tile2Pixel
local sqrt = math.sqrt

-- Constants
local cameraSpeed = 75
local fadeSpeed = 100 / 60

local FieldCamera = class(Renderer)

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Updates position and movement.
local old_updateMovement = FieldCamera.updateMovement
function FieldCamera:updateMovement()
  if self.focusObject then
    self:setXYZ(self.focusObject.position.x, self.focusObject.position.y)
  else
    old_updateMovement(self)
  end
end

---------------------------------------------------------------------------------------------------
-- Camera Movement
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Moves camera to the given tile.
-- @param(tile : ObjectTile) the destionation tile
-- @param(wait : boolean) flag to wait until the move finishes
function FieldCamera:moveToTile(tile, speed, wait)
  local x, y = tile2Pixel(tile:coordinates())
  self:moveToPoint(x, y, speed, wait)
end

-- [COROUTINE] Movec camera to the given object.
-- @param(obj : Object) the destination object
-- @param(speed : number) the speed of the movement
-- @param(wait : boolean) flag to wait until the move finishes
function FieldCamera:moveToObject(obj, speed, wait)
  self:moveToPoint(obj.position.x, obj.position.y, speed, wait)
end

-- Moves camera to the given pixel point.
-- @param(x : number) the pixel x
-- @param(y : nubmer) the pixel y
-- @param(speed : number) the speed of the movement
-- @param(wait : boolean) flag to wait until the move finishes
function FieldCamera:moveToPoint(x, y, speed, wait)
  self.focusObject = nil
  local dx = self.position.x - x
  local dy = self.position.y - y
  local distance = sqrt(dx * dx + dy * dy)
  speed = ((speed or cameraSpeed) + distance * 3)
  self:moveTo(x, y, 0, speed / distance, wait)
end

---------------------------------------------------------------------------------------------------
-- Camera Color
---------------------------------------------------------------------------------------------------

function FieldCamera:fadeout(speed, wait)
  self:colorizeTo(0, 0, 0, 0, speed or fadeSpeed, wait)
end

function FieldCamera:fadein(speed, wait)
  self:colorizeTo(100, 100, 100, 100, speed or fadeSpeed, wait)
end

return FieldCamera
