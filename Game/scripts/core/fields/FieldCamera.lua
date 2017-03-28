
--[[===========================================================================

FieldCamera
-------------------------------------------------------------------------------
The FieldCamera implements basic movement, zoom and rotation animations.

=============================================================================]]

-- Imports
local Renderer = require('core/graphics/Renderer')
local Vector = require('core/math/Vector')
local Queue = require('core/algorithm/Queue')

-- Alias
local mathf = math.field
local sqrt = math.sqrt
local time = love.timer.getDelta

-- Constants
local sqrt2 = sqrt(2)

local FieldCamera = Renderer:inherit()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

local old_init = FieldCamera.init
function FieldCamera:init(size, minDepth, maxDepth)
  old_init(self, size, minDepth, maxDepth)
  self.focusObject = nil
  self.moveSpeed = 400
  self.moveOrigX = nil
  self.moveOrigY = nil
  self.moveDestX = nil
  self.moveDestY = nil
  self.moveDistance = nil
  self.moveTime = 1
end

-- Updates position and movement.
function FieldCamera:update()
  if self.focusObject then
    self:setPosition(self.focusObject.position.x, self.focusObject.position.y)
  elseif self.moveTime < 1 then
    local speed = (self.moveSpeed / 6 + self.moveDistance * 3)
    self.moveTime = self.moveTime + speed * time() / self.moveDistance
    if self.moveTime >= 1 then
      self:setPosition(self.moveDestX, self.moveDestY)
      self.moveTime = 1
    else
      self:setPosition(self.moveOrigX * (1 - self.moveTime) + self.moveDestX * self.moveTime, 
        self.moveOrigY * (1 - self.moveTime) + self.moveDestY * self.moveTime)
    end
  end
end

-------------------------------------------------------------------------------
-- Camera Movement
-------------------------------------------------------------------------------

-- [COROUTINE] Moves camera to the given tile.
-- @param(tile : ObjectTile) the destionation tile
-- @param(wait : boolean) flag to wait until the move finishes
function FieldCamera:moveToTile(tile, wait)
  local x, y, z = mathf.tile2Pixel(tile:coordinates())
  self:moveTo(x, y, wait)
end

-- [COROUTINE] Movec camera to the given object.
-- @param(obj : Object) the destination object
-- @param(wait : boolean) flag to wait until the move finishes
function FieldCamera:moveToObject(obj, wait)
  self:moveTo(obj.position.x, obj.position.y, wait)
end

-- [COROUTINE] Moves camera to (x, y).
-- @param(x : number) the x coordinate in pixels
-- @param(y : number) the y coordinate in pixels
-- @param(wait : boolean) flag to wait until the move finishes
function FieldCamera:moveTo(x, y, wait)
  self.focusObject = nil
  self.moveOrigX, self.moveOrigY = self.x, self.y
  self.moveDestX, self.moveDestY = x, y
  self.moveDistance = Vector(x - self.x, y - self.y):len()
  self.moveTime = 0
  if wait then
    self:waitForMovement()
  end
end

-- Waits until the move time is 1.
function FieldCamera:waitForMovement()
  while self.moveTime < 1 do
    coroutine.yield()
  end
end

-------------------------------------------------------------------------------
-- Camera State
-------------------------------------------------------------------------------

-- Creates a table with camera's current state.
-- @ret(table) the state data
function FieldCamera:getState()
  return { 
    renderer = self.renderer
  }
end

-- Sets camera's state from data table.
-- @param(state : table) the state's data
function FieldCamera:setState(state)
  self.renderer = state.renderer
end

return FieldCamera
