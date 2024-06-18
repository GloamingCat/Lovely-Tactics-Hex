
-- ================================================================================================

--- A texture with position, transformation information. 
-- The image may be scaled, rotated, translated and coloured.
-- Its position determines where on the screen it's going to be rendered (x and y axis, relative to 
-- the world's coordinate system) and the depth/render order (z axis).
---------------------------------------------------------------------------------------------------
-- @animmod Sprite
-- @extend Colorable

-- ================================================================================================

-- Imports
local Affine = require('core/math/Affine')
local Colorable = require('core/math/transform/Colorable')
local Vector = require('core/math/Vector')

-- Alias
local abs = math.abs
local Quad = love.graphics.newQuad
local round = math.round
local insert = table.insert
local remove = table.remove

-- Class table.
local Sprite = class(Colorable)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Renderer renderer The renderer that is going to handle this sprite.
-- @tparam Texture texture Sprite's texture.
-- @tparam Quad quad The piece of the texture to render.
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
--- Creates a deep copy of this sprite (does not clone texture).
-- @tparam[opt] Renderer renderer The renderer of the copy.
-- @treturn Sprite The newly created copy.
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

-- ------------------------------------------------------------------------------------------------
-- Quad and Texture
-- ------------------------------------------------------------------------------------------------

--- Sets the texture and updates quad.
-- @tparam Texture texture The new texture.
function Sprite:setTexture(texture)
  if texture ~= self.texture then
    self.texture = texture
    if self.quad then
      self:setQuad(self.quad:getViewport())
    end
    self.renderer.needsRedraw = true
  end
end
--- Sets the quad based on texture.
-- @tparam number|Quad x Quad's new x, or a quad user data.
-- @tparam[opt] number y Quad's new y.
-- @tparam[opt] number w Quad's new width.
-- @tparam[opt] number h Quad's new height.
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

-- ------------------------------------------------------------------------------------------------
-- Bounding box
-- ------------------------------------------------------------------------------------------------

--- Updates bound diagonal.
function Sprite:recalculateBox()
  local x, y, w, h = self:getQuadBox()
  local dx = abs(self.offsetX * self.scaleX - w / 2)
  local dy = abs(self.offsetY * self.scaleY - h / 2)
  self.diag = dx + dy
  self.needsRecalcBox = false
end
--- Gets the extreme values for the bounding box.
-- @treturn number Transformed min x.
-- @treturn number Transformed min y.
-- @treturn number Transformed width.
-- @treturn number Transformed height.
function Sprite:getBoundingBox()
  local _, _, w, h = self:getQuadBox()
  return Affine.getBoundingBox(self, w, h)
end
--- Gets the bounds of the texture quad, in the coordinates of the texture.
-- @treturn number Quad's x.
-- @treturn number Quad's y.
-- @treturn number Quad's width.
-- @treturn number Quad's height.
function Sprite:getQuadBox()
  if self.quad then
    return self.quad:getViewport()
  else
    return 0, 0, 0, 0
  end
end

-- ------------------------------------------------------------------------------------------------
-- Visibility
-- ------------------------------------------------------------------------------------------------

--- Checks for visiblity.
-- @treturn boolean True if the visibility flag is on and there's a texture and quad for the sprite.
function Sprite:isVisible()
  return self.visible and self.quad and self.texture
end
--- Sets sprite's visibility flag.
-- @tparam boolean value
function Sprite:setVisible(value)
  if value ~= self.visible then
    self.renderer.needsRedraw = true
  end
  self.visible = value
end
--- Checks for an intersection with a rectangle. Uses `position` and `diag` fields
-- to calculate bounds both in world coordinates.
-- @tparam number minx Rectangle's minimum x.
-- @tparam number miny Rectangle's minimum y.
-- @tparam number maxx Rectangle's maximum x.
-- @tparam number maxy Rectangle's maximum y.
-- @treturn boolean Whether the sprite intersects a given rectangle
function Sprite:intersects(minx, miny, maxx, maxy)
  if self.needsRecalcBox then
    self:recalculateBox()
  end
  local diagX = self.diag + self.offsetX * self.scaleX
  local diagY = self.diag + self.offsetY * self.scaleY
  return self.position.x - diagX <= maxx and 
      self.position.x + diagX >= minx and
      self.position.y - diagY <= maxy and 
      self.position.y + diagY >= miny
end

-- ------------------------------------------------------------------------------------------------
-- Transformations
-- ------------------------------------------------------------------------------------------------

--- Sets sprite's offset, scale, rotation and color.
-- @tparam Affine.Transform data Transformation data.
function Sprite:setTransformation(data)
  self:setOffset(data.offsetX, data.offsetY, data.offsetDepth)
  self:setScale(data.scaleX / 100, data.scaleY / 100)
  self:setRotation(math.rad(data.rotation))
  self:setRGBA(data.red / 255, data.green / 255, data.blue / 255, data.alpha / 255)
  self:setHSV(data.hue / 360, data.saturation / 100, data.brightness / 100)
end
--- Merges sprite's current transformation with a new one.
-- @tparam Affine.Transform data Transformation data.
function Sprite:applyTransformation(data)
  self:setOffset(data.offsetX + self.offsetX, self.offsetY + data.offsetY, 
    data.offsetDepth + self.offsetDepth)
  self:setScale(data.scaleX / 100 * self.scaleX, data.scaleY / 100 * self.scaleY)
  self:setRotation(math.rad(data.rotation) + self.rotation)
  self:setRGBA(data.red / 255 * self.color.r, data.green / 255 * self.color.g, 
    data.blue / 255 * self.color.b, data.alpha / 255 * self.color.a)
  self:setHSV(data.hue / 360 + self.hsv.h, data.saturation / 100 * self.hsv.s, 
    data.brightness / 100 * self.hsv.v)
end
--- Sets the quad's scale.
-- If an argument is nil, the field is left unchanged.
-- @tparam number sx The X-axis scale.
-- @tparam number sy The Y-axis scale.
function Sprite:setScale(sx, sy)
  sx = sx or self.scaleX
  sy = sy or self.scaleY
  if self.scaleX ~= sx or self.scaleY ~= sy then
    self.renderer.needsRedraw = true
    self.needsRecalcBox = true
  end
  self.scaleX = sx
  self.scaleY = sy
end
--- Sets que quad's rotation.
-- @tparam number angle The rotation's angle in degrees.
function Sprite:setRotation(angle)
  if self.rotation ~= angle then
    self.renderer.needsRedraw = true
  end
  self.rotation = angle
end

-- ------------------------------------------------------------------------------------------------
-- Offset
-- ------------------------------------------------------------------------------------------------

--- Sets the quad's offset from the top left corner.
-- If an argument is nil, the field is left unchanged.
-- @tparam[opt] number ox The X-axis offset.
-- @tparam[opt] number oy The Y-axis offset.
-- @tparam[opt] number depth The sprite's depth in world coordinates.
function Sprite:setOffset(ox, oy, depth)
  if ox ~= nil and ox ~= self.offsetX then
    self.offsetX = ox
    self.needsRecalcBox = true
    self.renderer.needsRedraw = true
  end
  if oy ~= nil and oy ~= self.offsetY then
    self.offsetY = oy
    self.needsRecalcBox = true
    self.renderer.needsRedraw = true
  end
  depth = math.round(depth or self.offsetDepth)
  if self.offsetDepth ~= depth then
    self:removeSelf()
    self.offsetDepth = depth
    self:insertSelf(self.position.z)
  end
end
--- Sets the offset as the center of the image.
-- @tparam number offsetDepth
function Sprite:setCenterOffset(offsetDepth)
  local _, _, w, h = self.quad:getViewport()
  self:setOffset(round(w / 2), round(h / 2), offsetDepth)
end

-- ------------------------------------------------------------------------------------------------
-- Color
-- ------------------------------------------------------------------------------------------------

--- Overrides `Colorable:setRGBA`. 
-- @override
function Sprite:setRGBA(newr, newg, newb, newa)
  local r, g, b, a = self:getRGBA()
  Colorable.setRGBA(self, newr, newg, newb, newa)
  if r ~= newr or g ~= newg or b ~= newb or a ~= newa then
    self.renderer.needsRedraw = true
  end
end
--- Overrides `Colorable:setHSV`. 
-- @override
function Sprite:setHSV(newh, news, newv)
  local h, s, v = self:getHSV()
  Colorable.setHSV(self, newh, news, newv)
  if h ~= newh or s ~= news or v ~= newv then
    self.renderer.needsRedraw = true
  end
end

-- ------------------------------------------------------------------------------------------------
-- Position
-- ------------------------------------------------------------------------------------------------

--- Sets the sprite's pixel position the update's its position in the sprite list.
-- If an argument is nil, the field is left unchanged.
-- @tparam[opt] number x The pixel x of the image.
-- @tparam[opt] number y The pixel y of the image.
-- @tparam[opt] number z The pixel depth of the image.
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
--- Sets the sprite's pixel position the update's its position in the sprite list.
-- @tparam Vector pos The pixel position of the image.
function Sprite:setPosition(pos)
  self:setXYZ(pos.x, pos.y, pos.z)
end

-- ------------------------------------------------------------------------------------------------
-- Effects
-- ------------------------------------------------------------------------------------------------

--- Fades the sprite's transparency.
-- @tparam[opt] number time The duration of the fading in frames.
--  If nil, uses default fading speed.
function Sprite:fadeout(time, wait)
  if time and time > 0 then
    local speed = 60 / time
    local alpha = self.sprite.color.a
    self:setVisible(true)
    self:colorizeTo(nil, nil, nil, 0, speed)
    self:waitForColor()
    self:setVisible(false)
    self:setRGBA(nil, nil, nil, alpha)
  else
    self:setVisible(false)
  end
end
--- Fades the sprite's transparency.
-- @tparam[opt] number time The duration of the fading in frames.
--  If nil, uses default fading speed.
function Sprite:fadein(time, wait)
  if time and time > 0 then
    local speed = 60 / time
    local alpha = self.sprite.color.a
    self:setVisible(true)
    self:setRGBA(nil, nil, nil, 0)
    self:colorizeTo(nil, nil, nil, alpha, speed)
    self:waitForColor()
  else
    self:setVisible(true)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Renderer
-- ------------------------------------------------------------------------------------------------

--- Changes the sprite's renderer.
-- @tparam Renderer renderer
function Sprite:setRenderer(renderer)
  self.renderer.needsRedraw = true
  self:removeSelf()
  self.renderer = renderer
  self:insertSelf()
  self.renderer.needsRedraw = true
end
--- Inserts sprite from its list.
-- @tparam number i The position in the list.
function Sprite:insertSelf(i)
  i = (i or self.position.z) + self.offsetDepth
  if self.renderer.layers[i] then
    insert(self.renderer.layers[i], self)
  else
    self.renderer.layers[i] = {}
    self.renderer.layers[i][1] = self
  end
  self.renderer.needsRedraw = true
end
--- Removes sprite from its list.
function Sprite:removeSelf()
  local depth = self.position.z + self.offsetDepth
  local list = self.renderer.layers[depth]
  local n = #list
  for i = 1, n do
    if list[i] == self then
      if n == 1 then
        self.renderer.layers[depth] = nil
      else
        remove(list, i)
      end
      return
    end
  end
  self.renderer.needsRedraw = true
end
--- Called when the renderer needs to draw this sprite.
-- @tparam Renderer renderer The renderer that is drawing this sprite.
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
  renderer.batch:setColor(self.color.r, self.color.g, self.color.b, self.color.a)
  renderer.batch:add(self.quad, round(self.position.x * sx), round(self.position.y * sy), 
    self.rotation, self.scaleX * sx, self.scaleY * sy, self.offsetX, self.offsetY)
  renderer.toDraw:add(self)
end
--- Called when the scale of screen changes.
-- @tparam Renderer renderer The renderer that is drawing this sprite.
function Sprite:rescale(renderer)
  -- Nothing.
end
--- Deletes this sprite.
function Sprite:destroy()
  self:removeSelf()
  self.quad = nil
  self.texture = nil
  self.renderer.needsRedraw = true
end
-- For debugging.
function Sprite:__tostring()
  return 'Sprite'
end

return Sprite
