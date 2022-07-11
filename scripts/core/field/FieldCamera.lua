
--[[===============================================================================================

FieldCamera
---------------------------------------------------------------------------------------------------
The FieldCamera is a renderer with transform properties.

=================================================================================================]]

-- Imports
local Renderer = require('core/graphics/Renderer')

-- Alias
local tile2Pixel = math.field.tile2Pixel
local pixelCenter = math.field.pixelCenter
local sqrt = math.sqrt

local FieldCamera = class(Renderer)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function FieldCamera:init(...)
  self.images = {}
  Renderer.init(self, ...)
  self.fadeSpeed = 100 / 60
  self.cameraSpeed = 75
  self.cropMovement = true
end
-- Initializes field's foreground and background images.
-- @param(field : Field) Current field.
-- @param(images : table) Array of field's images.
function FieldCamera:initializeImages(images)
  for _, data in ipairs(images) do
    self:addImage(data.name, data, data.foreground, data.visible, data.glued)
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides Movable:updateMovement.
function FieldCamera:updateMovement()
  if self.focusObject then
    self:setXYZ(self.focusObject.position.x, self.focusObject.position.y)
  else
    Renderer.updateMovement(self)
  end
end

---------------------------------------------------------------------------------------------------
-- Images
---------------------------------------------------------------------------------------------------

-- Overrides Movable:setXYZ.
function FieldCamera:setXYZ(x, y, ...)
  Renderer.setXYZ(self, x, y, ...)
  for _, img in pairs(self.images) do
    if img.glued then
      img:setXYZ(x, y)
    end
  end
end
-- Add a background or foreground image.
-- @param(name : string) Image's identifier.
-- @param(icon : data) Image's animation ID, column and row.
-- @param(foreground : boolean) True if image appears above field, false if behind.
-- @param(visible : boolean) True if initialize visible.
-- @param(glued : boolean) True if image follows camera.
-- @ret(Sprite) Sprite of new image.
function FieldCamera:addImage(name, icon, foreground, visible, glued)
  local sprite = ResourceManager:loadIcon(icon, self)
  self.images[name] = sprite
  sprite:setVisible(visible)
  local field = FieldManager.currentField
  if foreground then
    sprite:setXYZ(field.centerX, field.centerY, self.minDepth)
  else
    sprite:setXYZ(field.centerX, field.centerY, self.maxDepth)
  end
  sprite.glued = glued
  sprite.id, sprite.col, sprite.row = icon.id, icon.col, icon.row
  return sprite
end
-- Gets the persistent data of each image.
-- @ret(table) Array of data tables.
function FieldCamera:getImageData()
  local arr = {}
  for k, v in pairs(self.images) do
    arr[#arr + 1] = { name = k,
      id = v.id,
      col = v.col,
      row = v.row,
      glued = v.glued,
      visible = v.visible,
      foreground = v.position.z == self.minDepth }
  end
  return arr
end

---------------------------------------------------------------------------------------------------
-- Camera Movement
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Moves camera to the given tile.
-- @param(tile : ObjectTile) the destionation tile
-- @param(speed : number) the speed of the movement (optional, uses default speed)
-- @param(wait : boolean) flag to wait until the move finishes (optional, false by default)
function FieldCamera:moveToTile(tile, speed, wait)
  local x, y = tile2Pixel(tile:coordinates())
  self:moveToPoint(x, y, speed, wait)
end
-- [COROUTINE] Movec camera to the given object.
-- @param(obj : Object) the destination object
-- @param(speed : number) the speed of the movement (optional, uses default speed)
-- @param(wait : boolean) flag to wait until the move finishes (optional, false by default)
function FieldCamera:moveToObject(obj, speed, wait)
  self:moveToPoint(obj.position.x, obj.position.y, speed, wait)
end
-- Moves camera to the given pixel point.
-- @param(x : number) the pixel x
-- @param(y : nubmer) the pixel y
-- @param(obj : Object) the destination object
-- @param(speed : number) the speed of the movement (optional, uses default speed)
-- @param(wait : boolean) flag to wait until the move finishes (optional, false by default)
function FieldCamera:moveToPoint(x, y, speed, wait)
  self.focusObject = nil
  local dx = self.position.x - x
  local dy = self.position.y - y
  local distance = sqrt(dx * dx + dy * dy)
  speed = ((speed or self.cameraSpeed) + distance * 3)
  self:moveTo(x, y, 0, speed / distance, wait)
end

---------------------------------------------------------------------------------------------------
-- Camera Color
---------------------------------------------------------------------------------------------------

-- Fades the screen out (changes color multiplier to black). 
-- @param(time : number) The duration of the fading in frames.
-- @param(wait : boolean) Flag to wait until the fading finishes (optional, false by default).
function FieldCamera:fadeout(time, wait)
  local speed = self.fadeSpeed
  if time then
    speed = (time > 0) and (60 / time) or nil
  end
  self:colorizeTo(0, 0, 0, 0, speed, wait)
end
-- Fades the screen in (changes color multiplier to white). 
-- @param(time : number) The duration of the fading in frames.
-- @param(wait : boolean) Flag to wait until the fading finishes (optional, false by default).
function FieldCamera:fadein(time, wait)
  local speed = self.fadeSpeed
  if time then
    speed = (time > 0) and (60 / time) or nil
  end
  self:colorizeTo(1, 1, 1, 1, speed, wait)
end

return FieldCamera
