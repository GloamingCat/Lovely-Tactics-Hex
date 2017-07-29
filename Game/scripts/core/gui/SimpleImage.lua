
--[[===========================================================================

SimpleImage
-------------------------------------------------------------------------------
A generic window content that stores a sprite with a given viewport.

=============================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')

-- Alias
local max = math.max
local min = math.min

local SimpleImage = class()

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

-- @param(sprite : Sprite) image's sprite
-- @param(x : number) the x position of the top-left corner inside window
-- @param(y : number) the y position of the top-left corner inside window
-- @param(depth : number) the depth of the image relative to window
-- @param(w : number) max width of the image
-- @param(h : number) max height of the image
function SimpleImage:init(sprite, x, y, depth, w, h)
  self.sprite = sprite
  if w then
    assert(h, 'Image height is null.')
    self:centerSpriteQuad(x, y, w, h)
  elseif h then
    assert(w, 'Image width is null.')
    self:centerSpriteQuad(x, y, w, h)
  else
    self.x = x
    self.y = y
  end
  self.sprite:setCenterOffset(depth or -1)
end
-- Creates a SimpleImage from quad data
-- @param(quadData : table) quad's data from database
-- @param(...) params from SimpleImage.init
-- @ret(SimpleImage) the newly created component 
function SimpleImage.fromQuad(quad, ...)
  return SimpleImage(Sprite.fromQuad(quad, GUIManager.renderer), ...)
end
-- Centers sprite inside the given rectangle.
function SimpleImage:centerSpriteQuad(x, y, w, h)
  local px, py, pw, ph = self.sprite.quad:getViewport()
  local mw, mh = min(pw, w), min(ph, h)
  local mx, my = px + (pw - mw) / 2, py + (ph - mh) / 2
  self.sprite:setQuad(mx, my, mw, mh)
  self.x = x + w / 2
  self.y = y + h / 2
end

-------------------------------------------------------------------------------
-- Window Content methods
-------------------------------------------------------------------------------

-- Sets image position.
function SimpleImage:updatePosition(pos)
  self.sprite:setXYZ(pos.x + self.x, pos.y + self.y, pos.z)
end
-- Shows image.
function SimpleImage:show()
  self.sprite:setVisible(true)
end
-- Hides image.
function SimpleImage:hide()
  self.sprite:setVisible(false)
end
-- Destroys sprite.
function SimpleImage:destroy()
  self.sprite:destroy()
end

return SimpleImage
