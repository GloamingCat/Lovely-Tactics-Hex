
--[[===============================================================================================

IconList
---------------------------------------------------------------------------------------------------
A list of icons to the drawn in a given rectangle.
Commonly used to show status icons in windows.

=================================================================================================]]

-- Imports
local Component = require('core/gui/Component')
local SimpleImage = require('core/gui/widget/SimpleImage')
local SpriteGrid = require('core/graphics/SpriteGrid')
local Vector = require('core/math/Vector')

local IconList = class(Component)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(topLeft : Vector) Position of the top left corner.
-- @param(width : number) The max width.
-- @param(height : number) The max height.
-- @param(frameWidth : number) The width of each icon (optional, 16 by default).
-- @param(frameHeight : number) The height of each icon (optional, 16 by default).
function IconList:init(topLeft, width, height, frameWidth, frameHeight)
  Component.init(self, topLeft)
  self.icons = {}
  self.frames = {}
  self.width = width
  self.height = height
  self.frameWidth = frameWidth or 16
  self.frameHeight = frameHeight or 16
  self.iconWidth = self.frameWidth
  self.iconHeight = self.frameHeight
  self.frameID = Config.animations.frame
  self.visible = true
end
-- Sets the content of this list.
-- @param(icons : table) Array of sprites.
function IconList:setSprites(icons)
  self:destroy()
  local frameSkin = self.frameID >= 0 and Database.animations[self.frameID]
  self.icons = {}
  self.frames = frameSkin and {}
  if not icons then
    return
  end
  local x, y = 0, 0
  for i = 1, #icons do
    local sprite = icons[i]
    if x + self.frameWidth > self.width then
      if y + self.frameHeight > self.height then
        for j = i, icons do
          icons[j]:destroy()
        end
        break
      end
      if x > 0 then
        x = 0
        y = y + self.frameHeight - 1
      end
    end
    if sprite then
      sprite:setVisible(self.visible)
      self.icons[i] = SimpleImage(sprite, x - self.iconWidth / 2, y - self.iconHeight / 2, -1, 
        self.iconWidth, self.iconHeight)
    else
      self.icons[i] = SimpleImage(nil, x, y, -1, self.iconWidth, self.iconHeight)
    end
    self.content:add(self.icons[i])
    if frameSkin then
      self.frames[i] = SpriteGrid(frameSkin, Vector(x, y, -1))
      self.frames[i]:createGrid(GUIManager.renderer, self.frameWidth, self.frameHeight)
      self.content:add(self.frames[i])
    end
    x = x + self.frameWidth - 1
  end
end
-- Sets the content of this list.
-- @param(icons : table) Array of icon tables (id, col and row).
function IconList:setIcons(icons)
  local sprites = {}
  for i = 1, #icons do
    sprites[i] = ResourceManager:loadIcon(icons[i], GUIManager.renderer)
  end
  self:setSprites(sprites)
end

return IconList
