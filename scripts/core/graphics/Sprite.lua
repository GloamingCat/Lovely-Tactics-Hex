
--[[===============================================================================================

Sprite
---------------------------------------------------------------------------------------------------
A Sprite is a group of information the determines the way an image should be rendered. 
The image may be scaled, rotated, translated and coloured.
Its position determines where on the screen it's going to be rendered (x and y axis, relative to 
the world's coordinate system) and the depth/render order (z axis).

Transform table values:
- offsetX, offsetY: center pixel coordinates of the quad, relative to top left corner;
- offsetYDepth: value added to sprite's depth;
- scaleX, scaleY: scale values from 0 to 100;
- rotation: rotation angle in degrees, from 0 to 360;
- red: color red component, from 0 to 255;
- green: color green component, from 0 to 255;
- blue: color blue component, from 0 to 255;
- alpha: color alpha component, from 0 to 255;
- hue: color hue offset, from 0 to 360;
- saturation: color saturation multiplier, from 0 to 100;
- brightness: color value multiplier, from 0 to 100.

=================================================================================================]]

-- Imports
local Affine = require('core/math/Affine')
local Vector = require('core/math/Vector')
local Colorable = require('core/math/transform/Colorable')

-- Alias
local abs = math.abs
local Quad = love.graphics.newQuad
local round = math.round
local insert = table.insert
local remove = table.remove

local Sprite = class(Colorable)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(renderer : Renderer) The renderer that is going to handle this sprite.
-- @param(texture : Texture) Sprite's texture.
-- @param(quad : Quad) The piece of the texture to render.
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
  self:recalculateBox()
  self.renderer = renderer
  self:insertSelf(1)
  self.visible = true
end
-- Creates a deep copy of this sprite (does not clone texture).
-- @param(renderer : Renderer) The renderer of the copy (optional).
-- @ret(Sprite) The newly created copy.
function Sprite:clone(renderer)
  local sw, sh = self.quad:getTextureDimensions()
  local x, y, w, h = self.quad:getViewport()
  local copy = Sprite(renderer or self.renderer, self.texture, Quad(x, y, w, h, sw, sh))
  copy:setOffset(self.offsetX, self.offsetY, self.offsetDepth)
  copy:setScale(self.scaleX, self.scaleY)
  copy:setColor(self.color, self.hsv)
  copy:setPosition(self.position)
  copy:setRotation(self.rotation)
  copy:setVisible(self.visible)
  return copy
end

---------------------------------------------------------------------------------------------------
-- Visibility
---------------------------------------------------------------------------------------------------

-- Checks if sprite is visible on screen.
-- @ret(boolean)
function Sprite:isVisible()
  return self.visible and self.quad and self.texture
end
-- Sets sprite's visibility.
-- @param(value : boolean)
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
-- @param(texture : Texture) The new texture.
function Sprite:setTexture(texture)
  if texture ~= self.texture then
    self.texture = texture
    if self.quad then
      self:setQuad(self.quad:getViewport())
    end
    self.renderer.needsRedraw = true
  end
end
-- Sets the quad based on texture.
-- @param(x : number) Quad's new x.
-- @param(y : number) Quad's new y.
-- @param(w : number) Quad's new width.
-- @param(h : number) Quad's new height.
function Sprite:setQuad(x, y, w, h)
  self.renderer.needsRedraw = true
  self.needsRecalcBox = true
  if type(x) == 'userdata' then
    self.quad = x
    return
  end
  if self.quad then
    self.quad:setViewport(x or 0, y or 0, 
      w or self.texture:getWidth(), h or self.texture:getHeight())
  else
    local tw, th = self.texture:getWidth(), self.texture:getHeight()
    self.quad = Quad(x or 0, y or 0, w or tw, h or th, tw, th)
  end
end

---------------------------------------------------------------------------------------------------
-- Transformations
---------------------------------------------------------------------------------------------------

-- Sets sprite's offset, scale, rotation and color
-- @param(data : table) Transformation data.
function Sprite:setTransformation(data)
  self:setOffset(data.offsetX, data.offsetY, data.offsetDepth)
  self:setScale(data.scaleX / 100, data.scaleY / 100)
  self:setRotation(math.rad(data.rotation))
  self:setRGBA(data.red / 255, data.green / 255, data.blue / 255, data.alpha / 255)
  self:setHSV(data.hue / 360, data.saturation / 100, data.brightness / 100)
end
-- Merges sprite's current transformation with a new one.
-- @param(data : table) Transformation data.
function Sprite:applyTransformation(data)
  self:setOffset(data.offsetX + self.offsetX, self.offsetY + data.offsetY, 
    data.offsetDepth + self.offsetDepth)
  self:setScale(data.scaleX / 100 * self.scaleX, data.scaleY / 100 * self.scaleY)
  self:setRotation(math.rad(data.rotation) + self.rotation)
  self:setRGBA(data.red / 255 * self.color.red, data.green / 255 * self.color.green, 
    data.blue / 255 * self.color.blue, data.alpha / 255 * self.color.alpha)
  self:setHSV(data.hue / 360 + self.hsv.h, data.saturation / 100 * self.hsv.s, 
    data.brightness / 100 * self.hsv.v)
end
-- Sets the quad's scale.
-- @param(sx : number) The X-axis scale.
-- @param(sy : number) The Y-axis scale.
function Sprite:setScale(sx, sy)
  sx = sx or 1
  sy = sy or 1
  if self.scaleX ~= sx or self.scaleY ~= sy then
    self.renderer.needsRedraw = true
    self.needsRecalcBox = true
  end
  self.scaleX = sx
  self.scaleY = sy
end
-- Sets que quad's rotation
-- @param(angle : number) The rotation's angle in degrees.
function Sprite:setRotation(angle)
  if self.rotation ~= angle then
    self.renderer.needsRedraw = true
  end
  self.rotation = angle
end

---------------------------------------------------------------------------------------------------
-- Bounding box
---------------------------------------------------------------------------------------------------

-- Updates bound diagonal.
function Sprite:recalculateBox()
  local w, h = self:quadBounds()
  local dx = (abs(w / 2 - self.offsetX) + w / 2) * self.scaleX
  local dy = (abs(h / 2 - self.offsetY) + h / 2) * self.scaleY
  self.diag = dx + dy
  self.needsRecalcBox = false
end
-- Gets the bounds of the texture quad.
-- @ret(number) Quad's width.
-- @ret(number) Quad's height.
function Sprite:quadBounds()
  if not self.quad then
    return 0, 0
  end
  local _, _, w, h = self.quad:getViewport()
  return w, h
end
-- Gets the quad bounds considering the scale.
-- @ret(number) Quad's scaled width.
-- @ret(number) Quad's scaled height.
function Sprite:scaledBounds()
  local w, h = self:quadBounds()
  return w * self.scaleX, h * self.scaleY
end
-- Gets the extreme values for the bounding box.
-- @ret(number) Transformed min x.
-- @ret(number) Transformed min y.
-- @ret(number) Transformed width.
-- @ret(number) Transformed height.
function Sprite:totalBounds()
  local w, h = self:quadBounds()
  return Affine.getBoundingBox(self, w, h)
end

---------------------------------------------------------------------------------------------------
-- Offset
---------------------------------------------------------------------------------------------------

-- Sets the quad's offset from the top left corner.
-- @param(ox : number) The X-axis offset.
-- @param(oy : number) The Y-axis offset.
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
-- @param(offsetDepth : number)
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
-- Overrides Colorable:setHSV.
function Sprite:setHSV(newh, news, newv)
  local h, s, v = self:getHSV()
  Colorable.setHSV(self, newh, news, newv)
  if h ~= newh or s ~= news or v ~= newv then
    self.renderer.needsRedraw = true
  end
end

---------------------------------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------------------------------

-- Sets the sprite's pixel position the update's its position in the sprite list.
-- @param(x : number) The pixel x of the image.
-- @param(y : number) The pixel y of the image.
-- @param(z : number) The pixel depth of the image.
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
-- @param(pos : Vector) The pixel position of the image.
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
-- @param(i : number) The position in the list.
function Sprite:insertSelf(i)
  i = (i or self.position.z) + self.offsetDepth
  if self.renderer.spriteList[i] then
    insert(self.renderer.spriteList[i], self)
  else
    self.renderer.spriteList[i] = {}
    self.renderer.spriteList[i][1] = self
  end
  self.renderer.needsRedraw = true
end
-- Removes sprite from its list.
function Sprite:removeSelf()
  local depth = self.position.z + self.offsetDepth
  local list = self.renderer.spriteList[depth]
  local n = #list
  for i = 1, n do
    if list[i] == self then
      if n == 1 then
        self.renderer.spriteList[depth] = nil
      else
        remove(list, i)
      end
      return
    end
  end
  self.renderer.needsRedraw = true
end
-- Called when the renderer needs to draw this sprite.
-- @param(renderer : Renderer) The renderer that is drawing this sprite.
function Sprite:draw(renderer)
  if self.texture == nil then
    return
  end
  if not renderer:batchPossible(self) then
    renderer:clearBatch()
    renderer.batchTexture = self.texture
    local hsv = renderer.batchHSV
    hsv[1], hsv[2], hsv[3] = self.hsv.h, self.hsv.s, self.hsv.v
  end
  local sx = ScreenManager.scaleX * renderer.scaleX
  local sy = ScreenManager.scaleY * renderer.scaleY
  renderer.batch:setColor(self.color.red, self.color.green, self.color.blue, self.color.alpha)
  renderer.batch:add(self.quad, round(self.position.x * sx), round(self.position.y * sy), 
    self.rotation, self.scaleX * sx, self.scaleY * sy, self.offsetX, self.offsetY)
  renderer.toDraw:add(self)
end
-- Called when the scale of screen changes.
-- @param(renderer : Renderer) The renderer that is drawing this sprite.
function Sprite:rescale(renderer)
  -- Nothing.
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
