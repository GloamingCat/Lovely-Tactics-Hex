
-- ================================================================================================

--- A `Renderer` with some general methods for camera effects.
---------------------------------------------------------------------------------------------------
-- @fieldmod FieldCamera
-- @extend Renderer

-- ================================================================================================

-- Imports
local Renderer = require('core/graphics/Renderer')

-- Alias
local pixelCenter = math.field.pixelCenter
local minDepth = math.field.minDepth
local maxDepth = math.field.maxDepth
local sqrt = math.sqrt

-- Class table.
local FieldCamera = class(Renderer)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. Initialized from field data.
-- @tparam table fieldData Field data.
-- @tparam[opt] Color.RGBA color Initial color. If nil, startss as black.
function FieldCamera:init(fieldData, color)
  local width = ScreenManager.canvas:getWidth()
  local height = ScreenManager.canvas:getHeight()
  local h = fieldData.prefs.maxHeight
  local l = 4 * #fieldData.layers.terrain + #fieldData.layers.obstacle + #fieldData.characters
  local mind = minDepth(fieldData.sizeX, fieldData.sizeY, h)
  local maxd = maxDepth(fieldData.sizeX, fieldData.sizeY, h)
  self.images = {}
  Renderer.init(self, mind, maxd, fieldData.sizeX * fieldData.sizeY * l)
  self.fadeSpeed = 100 / 60
  self.cameraSpeed = Config.screen.defaultSpeed or 75
  self.cropMovement = true
  self:resizeCanvas(width, height)
  self:setXYZ(pixelCenter(fieldData.sizeX, fieldData.sizeY))
  if color then
    self:setColor(color)
  else
    self:setRGBA(0, 0, 0, 1)
  end
end
--- Initializes field's foreground and background images.
-- @tparam table images Array of field's images.
function FieldCamera:addImages(images)
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
-- @coroutine
-- @tparam ObjectTile tile The destionation tile.
-- @tparam[opt=cameraSpeed] number speed The speed of the movement.
-- @tparam[opt] boolean wait Flag to wait until the move finishes.
function FieldCamera:moveToTile(tile, speed, wait)
  local x, y = tile.center:coordinates()
  self:moveToPoint(x, y, speed, wait)
end
--- Movec camera to the given object.
-- @coroutine
-- @tparam Object obj The destination object.
-- @tparam[opt=cameraSpeed] number speed The speed of the movement.
-- @tparam[opt] boolean wait Flag to wait until the move finishes.
function FieldCamera:moveToObject(obj, speed, wait)
  self:moveToPoint(obj.position.x, obj.position.y, speed, wait)
end
--- Moves camera to the given pixel point.
-- @tparam number x The pixel x.
-- @tparam nubmer y The pixel y.
-- @tparam[opt=cameraSpeed] number speed The speed of the movement, in pixels per second.
-- @tparam[opt] boolean wait Flag to wait until the move finishes.
function FieldCamera:moveToPoint(x, y, speed, wait)
  self.focusObject = nil
  if speed and speed <= 0 then
    speed = nil
  else
    local dx = self.position.x - x
    local dy = self.position.y - y
    local distance = sqrt(dx * dx + dy * dy)
    speed = ((speed or self.cameraSpeed) + distance * 3) / distance
    if distance < 0.2 then
      return
    end
  end
  self:moveTo(x, y, 0, speed, wait)
end
--- Moves the camera to each party in the field.
-- This must be called during battle.
-- @tparam[opt] number speed The camera speed.
-- @tparam[opt=30] number time The time to wait at each party.
function FieldCamera:showParties(speed, time)
  speed = speed or self.defaultSpeed
  for i = 1, #TroopManager.centers do
    if i ~= TroopManager.playerParty then
      local p = TroopManager.centers[i]
      FieldManager.renderer:moveToPoint(p.x, p.y, speed, true)
      _G.Fiber:wait(time or 30)
    end
  end
  local p = TroopManager.centers[TroopManager.playerParty]
  FieldManager.renderer:moveToPoint(p.x, p.y, speed, true)
end

-- ------------------------------------------------------------------------------------------------
-- Camera Color
-- ------------------------------------------------------------------------------------------------

--- Fades the screen out (changes color multiplier to black). 
-- @tparam[opt] number time The duration of the fading in frames.
--  If nil, uses default fading speed. If 0, the change is instantaneous.
-- @tparam[opt] boolean wait Flag to wait until the fading finishes.
function FieldCamera:fadeout(time, wait)
  local speed = self.fadeSpeed
  if time then
    speed = (time > 0) and (60 / time) or nil
  end
  self:colorizeTo(0, 0, 0, 1, speed, wait)
end
--- Fades the screen in (changes color multiplier to white). 
-- @tparam[opt] number time The duration of the fading in frames.
--  If nil, uses default fading speed. If 0, the change is instantaneous.
-- @tparam[opt] boolean wait Flag to wait until the fading finishes.
function FieldCamera:fadein(time, wait)
  local speed = self.fadeSpeed
  if time then
    speed = (time > 0) and (60 / time) or nil
  end
  self:colorizeTo(1, 1, 1, 1, speed, wait)
end

return FieldCamera
