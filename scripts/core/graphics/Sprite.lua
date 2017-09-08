
--[[===============================================================================================

Sprite
---------------------------------------------------------------------------------------------------
A Sprite is a group of information the determines the way an image should be rendered. 
The image may be scaled, rotated, translated and coloured.
Its position determines where on the screen it's going to be rendered (x and y axis, relative to 
the world's coordinate system) and the depth/render order (z axis).

=================================================================================================]]

-- Imports
local Affine = require('core/math/Affine')
local Vector = require('core/math/Vector')
local Colorable = require('core/transform/Colorable')

-- Alias
local Quad = love.graphics.newQuad
local round = math.round
local insert = table.insert
local remove = table.remove

local Sprite = class(Colorable)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(renderer : Renderer) the renderer that is going to handle this sprite
-- @param(texture : Texture) sprite's texture
-- @param(quad : Quad) the piece of the texture to render
function Sprite:init(renderer, texture, quad)
  Colorable.initColor(self)
  self.texture = texture
  self.quad = quad
  self.position = Vector(0, 0, 1)
  self.rotation = 0
  self.scaleX = 1
  self.scaleY = 1
  self.offsetX = 0
  self.offsetY = 0
  self.offsetDepth = 0
  self.renderer = renderer
  self:insertSelf(1)
  self.visible = true
end
-- Creates a new Sprite from quad data.
-- @param(quadData : table) data from database
-- @param(renderer : Renderer) the renderer of the sprite
-- @ret(Sprite) the newly created Sprite
function Sprite.fromQuad(quadData, renderer)
  local texture = love.graphics.newImage('images/' .. quadData.imagePath)
  local w, h = texture:getWidth(), texture:getHeight()
  local quad = Quad(quadData.x, quadData.y, quadData.width, quadData.height, w, h)
  return Sprite(renderer, texture, quad)
end
-- Creates a deep copy of this sprite (does not clone texture).
-- @param(renderer : Renderer) the renderer of the copy (optional)
-- @ret(Sprite) the newly created copy
function Sprite:clone(renderer)
  local sw, sh = self.quad:getTextureDimensions()
  local x, y, w, h = self.quad:getViewport()
  local copy = Sprite(renderer or self.renderer, self.texture, Quad(x, y, w, h, sw, sh))
  copy:setOffset(self.offsetX, self.offsetY, self.offsetDepth)
  copy:setScale(self.scaleX, self.scaleY)
  copy:setColor(self.color)
  copy:setHSV(self.hsv)
  copy:setPosition(self.position)
  copy:setRotation(self.rotation)
  copy:setVisible(self.visible)
  return copy
end

---------------------------------------------------------------------------------------------------
-- Visibility
---------------------------------------------------------------------------------------------------

-- Checks if sprite is visible on screen.
-- @ret(boolean) true if visible, false otherwise
function Sprite:isVisible()
  return self.visible
end
-- Sets if sprite is visible
-- @param(value : boolean) if visible
function Sprite:setVisible(value)
  if value ~= self.visible then
    self.renderer.needsRedraw = true
  end
  self.visible = value
end

---------------------------------------------------------------------------------------------------
-- Quad and Texture
---------------------------------------------------------------------------------------------------

-- Sets the texture and updates quad.
-- @param(texture : Texture) the new texture
function Sprite:setTexture(texture)
  if texture ~= self.texture then
    self.texture = texture
    if self.quad then
      self:setQuad(self.quad:getViewport())
    end
  end
end
-- Sets the quad based on texture.
-- @param(x : number) quad's new x
-- @param(y : number) quad's new y
-- @param(w : number) quad's new width
-- @param(h : number) quad's new height
function Sprite:setQuad(x, y, w, h)
  self.quad:setViewport(x or 0, y or 0, 
    w or self.texture:getWidth(), h or self.texture:getHeight())
  self.renderer.needsRedraw = true
end

---------------------------------------------------------------------------------------------------
-- Transformations
---------------------------------------------------------------------------------------------------

-- Sets sprite's offset, scale, rotation and color
-- @param(data : table) transformation data
function Sprite:setTransformation(data)
  local x, y, w, h = self.quad:getViewport()
  self:setOffset(data.offsetX, data.offsetY, data.offsetDepth)
  self:setScale(data.scaleX / 100, data.scaleY / 100)
  self:setRotation(math.rad(data.rotation or 0))
  self:setRGBA(data.red, data.green, data.blue, data.alpha)
  self:setHSV(data.hue / 360, data.saturation / 100, data.brightness / 100)
end
-- Merges sprite's current transformation with a new one.
-- @param(data : table) transformation data
function Sprite:applyTransformation(data)
  local x, y, w, h = self.quad:getViewport()
  self:setOffset(data.offsetX + self.offsetX, self.offsetY + data.offsetY, 
    data.offsetDepth + self.offsetDepth)
  self:setScale(data.scaleX / 100 * self.scaleX, data.scaleY / 100 * self.scaleY)
  self:setRotation(math.rad(data.rotation or 0 + self.rotation))
  self:setRGBA(data.red * self.color.red / 255, data.green * self.color.green / 255, 
    data.blue * self.color.blue / 255, data.alpha * self.color.alpha / 255)
  self:setHSV(data.hue / 360 + self.hsv.h, data.saturation / 100 * self.hsv.s, 
    data.brightness / 100 * self.hsv.v)
end
-- Sets the quad's scale.
-- @param(sx : number) the X-axis scale
-- @param(sy : number) the Y-axis scale
function Sprite:setScale(sx, sy)
  sx = sx or 1
  sy = sy or 1
  if self.scaleX ~= sx or self.scaleY ~= sy then
    self.renderer.needsRedraw = true
  end
  self.scaleX = sx
  self.scaleY = sy
end
-- Sets que quad's rotation
-- @param(angle : number) the rotation's angle in degrees
function Sprite:setRotation(angle)
  if self.rotation ~= angle then
    self.renderer.needsRedraw = true
  end
  self.rotation = angle
end
-- Gets the extreme values for the bounding box.
function Sprite:totalBounds()
  local _, _, w, h = self.quad:getViewport()
  return Affine.getBoundingBox(self, w, h)
end

---------------------------------------------------------------------------------------------------
-- Offset
---------------------------------------------------------------------------------------------------

-- Sets the quad's offset from the top left corner.
-- @param(ox : number) the X-axis offset
-- @param(oy : number) the Y-axis offset
function Sprite:setOffset(ox, oy, depth)
  if ox ~= nil and ox ~= self.offsetX then
    self.offsetX = ox
    self.renderer.needsRedraw = true
  end
  if oy ~= nil and oy ~= self.offsetY then
    self.offsetY = oy
    self.renderer.needsRedraw = true
  end
  depth = math.round(depth or self.offsetDepth)
  if self.offsetDepth ~= depth then
    self:removeSelf()
    self.offsetDepth = depth
    self:insertSelf(self.position.z)
  end
end
-- Sets the offset as the center of the image.
function Sprite:setCenterOffset(offsetDepth)
  local _, _, w, h = self.quad:getViewport()
  self:setOffset(round(w / 2), round(h / 2), offsetDepth)
end

---------------------------------------------------------------------------------------------------
-- Color
---------------------------------------------------------------------------------------------------

-- Overrides Colorable:setRGBA.
function Sprite:setRGBA(newr, newg, newb, newa)
  local r, g, b, a = self:getRGBA()
  Colorable.setRGBA(self, newr, newg, newb, newa)
  if r ~= newr or g ~= newg or b ~= newb or a ~= newa then
    self.renderer.needsRedraw = true
  end
end

---------------------------------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------------------------------

-- Sets the sprite's pixel position the update's its position in the sprite list.
-- @param(x : number) the pixel x of the image
-- @param(y : number) the pixel y of the image
-- @param(z : number) the pixel depth of the image
function Sprite:setXYZ(x, y, z)
  x = round(x or self.position.x)
  y = round(y or self.position.y)
  z = round(z or self.position.z)
  if z ~= self.position.z then
    self:removeSelf()
    self:insertSelf(z)
    self.position.z = z
  end
  if self.position.x ~= x or self.position.y ~= y then
    self.position.x = x
    self.position.y = y
    self.renderer.needsRedraw = true
  end
end
-- Sets the sprite's pixel position the update's its position in the sprite list.
-- @param(pos : Vector) the pixel position of the image
function Sprite:setPosition(pos)
  self:setXYZ(pos.x, pos.y, pos.z)
end

---------------------------------------------------------------------------------------------------
-- Renderer
---------------------------------------------------------------------------------------------------

-- Changes the sprite's renderer.
-- @param(renderer : Renderer)
function Sprite:setRenderer(renderer)
  self.renderer.needsRedraw = true
  self:removeSelf()
  self.renderer = renderer
  self:insertSelf()
  self.renderer.needsRedraw = true
end
-- Inserts sprite from its list.
-- @param(i : number) the position in the list
function Sprite:insertSelf(i)
  i = (i or self.position.z) + self.offsetDepth
  if self.renderer.list[i] then
    insert(self.renderer.list[i], self)
  else
    self.renderer.list[i] = {}
    self.renderer.list[i][1] = self
  end
  self.renderer.needsRedraw = true
end
-- Removes sprite from its list.
function Sprite:removeSelf()
  local depth = self.position.z + self.offsetDepth
  local list = self.renderer.list[depth]
  local n = #list
  for i = 1, n do
    if list[i] == self then
      if n == 1 then
        self.renderer.list[depth] = nil
      else
        remove(list, i)
      end
      return
    end
  end
  self.renderer.needsRedraw = true
end
-- Called when the renderer needs to draw this sprite.
-- @param(renderer : Renderer) the renderer that is drawing this sprite
function Sprite:draw(renderer)
  if self.texture == nil then
    return
  end
  if self.texture ~= renderer.batch:getTexture() then
    renderer:clearBatch()
    renderer.batch:setTexture(self.texture)
  end
  renderer.batch:setColor(self.color.red, self.color.green, self.color.blue, self.color.alpha)
  renderer.batch:add(self.quad, self.position.x, self.position.y, 
    self.rotation, self.scaleX, self.scaleY, self.offsetX, self.offsetY)
  renderer.toDraw:add(self)
end
-- Deletes this sprite.
function Sprite:destroy()
  self:removeSelf()
  self.quad = nil
  self.texture = nil
  self.renderer.needsRedraw = true
end
-- String representation.
-- @ret(string)
function Sprite:__tostring()
  return 'Sprite'
end

return Sprite
