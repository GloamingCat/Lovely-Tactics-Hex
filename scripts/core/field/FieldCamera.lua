
-- ================================================================================================

--- The FieldCamera is a renderer with transform properties.
---------------------------------------------------------------------------------------------------
-- @classmod FieldCamera
-- @extend Renderer

-- ================================================================================================

-- Imports
local Renderer = require('core/graphics/Renderer')

-- Alias
local pixelCenter = math.field.pixelCenter
local sqrt = math.sqrt

-- Class table.
local FieldCamera = class(Renderer)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function FieldCamera:init(...)
  self.images = {}
  Renderer.init(self, ...)
  self.fadeSpeed = 100 / 60
  self.cameraSpeed = 75
  self.cropMovement = true
end
--- Initializes field's foreground and background images.
-- @tparam table images Array of field's images.
function FieldCamera:initializeImages(images)
  for _, data in ipairs(images) do
    self:addImage(data.name, data, data.foreground, data.visible, data.glued)
  end
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Overrides `Movable:updateMovement`. 
-- @override
function FieldCamera:updateMovement(dt)
  if self.focusObject then
    self:setXYZ(self.focusObject.position.x, self.focusObject.position.y)
  else
    Renderer.updateMovement(self, dt)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Images
-- ------------------------------------------------------------------------------------------------

--- Overrides `Movable:setXYZ`. 
-- @override
function FieldCamera:setXYZ(x, y, ...)
  Renderer.setXYZ(self, x, y, ...)
  for _, img in pairs(self.images) do
    if img.glued then
      img:setXYZ(x, y)
    end
  end
end
--- Add a background or foreground image.
-- @tparam string name Image's identifier.
-- @tparam data icon Image's animation ID, column and row.
-- @tparam boolean foreground True if image appears above field, false if behind..
-- @tparam boolean visible True if initialize visible..
-- @tparam boolean glued True if image follows camera..
-- @treturn Sprite Sprite of new image.
function FieldCamera:addImage(name, icon, foreground, visible, glued)
  local sprite = ResourceManager:loadIcon(icon, self)
  sprite.texture:setFilter('linear', 'linear')
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
--- Gets the persistent data of each image.
-- @treturn table Array of data tables.
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

-- ------------------------------------------------------------------------------------------------
-- Camera Movement
-- ------------------------------------------------------------------------------------------------

--- Moves camera to the given tile.
-- @coroutine moveToTile
-- @tparam ObjectTile tile The destionation tile.
-- @tparam number speed The speed of the movement (optional, uses default speed).
-- @tparam boolean wait Flag to wait until the move finishes (optional, false by default).
function FieldCamera:moveToTile(tile, speed, wait)
  local x, y = tile.center:coordinates()
  self:moveToPoint(x, y, speed, wait)
end
--- Movec camera to the given object.
-- @coroutine moveToObject
-- @tparam Object obj The destination object.
-- @tparam number speed The speed of the movement (optional, uses default speed).
-- @tparam boolean wait Flag to wait until the move finishes (optional, false by default).
function FieldCamera:moveToObject(obj, speed, wait)
  self:moveToPoint(obj.position.x, obj.position.y, speed, wait)
end
--- Moves camera to the given pixel point.
-- @tparam number x The pixel x.
-- @tparam nubmer y The pixel y.
-- @tparam number speed The speed of the movement (optional, uses default speed).
-- @tparam boolean wait Flag to wait until the move finishes (optional, false by default).
function FieldCamera:moveToPoint(x, y, speed, wait)
  self.focusObject = nil
  if speed == 0 then
    speed = nil
  else
    local dx = self.position.x - x
    local dy = self.position.y - y
    local distance = sqrt(dx * dx + dy * dy)
    speed = ((speed or self.cameraSpeed) + distance * 3) / distance
  end
  self:moveTo(x, y, 0, speed, wait)
end

-- ------------------------------------------------------------------------------------------------
-- Camera Color
-- ------------------------------------------------------------------------------------------------

--- Fades the screen out (changes color multiplier to black). 
-- @tparam number time The duration of the fading in frames.
-- @tparam boolean wait Flag to wait until the fading finishes (optional, false by default).
function FieldCamera:fadeout(time, wait)
  local speed = self.fadeSpeed
  if time then
    speed = (time > 0) and (60 / time) or nil
  end
  self:colorizeTo(0, 0, 0, 0, speed, wait)
end
--- Fades the screen in (changes color multiplier to white). 
-- @tparam number time The duration of the fading in frames.
-- @tparam boolean wait Flag to wait until the fading finishes (optional, false by default).
function FieldCamera:fadein(time, wait)
  local speed = self.fadeSpeed
  if time then
    speed = (time > 0) and (60 / time) or nil
  end
  self:colorizeTo(1, 1, 1, 1, speed, wait)
end

-- ------------------------------------------------------------------------------------------------
-- Camera State
-- ------------------------------------------------------------------------------------------------

-- @treturn table Current camera state.
function FieldCamera:getState()
  return self.color
end
-- @tparam table state Saved camera state.
function FieldCamera:setState(state)
  self:setColor(state)
end

return FieldCamera
