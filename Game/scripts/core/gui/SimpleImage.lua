
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
-- @param(w : number) max width of the image
-- @param(h : number) max height of the image
function SimpleImage:init(sprite, x, y, w, h, depth)
  self.sprite = sprite
  local px, py, pw, ph = sprite.quad:getViewport()
  local mw, mh = min(pw, w), min(ph, h)
  local mx, my = px + (pw - mw) / 2, py + (ph - mh) / 2
  self.sprite:setQuad(mx, my, mw, mh)
  self.x = x + w / 2
  self.y = y + h / 2
  self.sprite:setCenterOffset(depth or 0)
end

-- Creates a SimpleImage from quad data
-- @param(quadData : table) quad's data from database
-- @param(...) params from SimpleImage.init
-- @ret(SimpleImage) the newly created component 
function SimpleImage.fromQuad(quad, ...)
  return SimpleImage(Sprite.fromQuad(quad, GUIManager.renderer), ...)
end

-------------------------------------------------------------------------------
-- Window Content methods
-------------------------------------------------------------------------------

function SimpleImage:updatePosition(pos)
  self.sprite:setXYZ(pos.x + self.x, pos.y + self.y, pos.z)
end

function SimpleImage:show()
  self.sprite:setVisible(true)
end

function SimpleImage:hide()
  self.sprite:setVisible(false)
end

function SimpleImage:destroy()
  self.sprite:destroy()
end

return SimpleImage
