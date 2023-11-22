
-- ================================================================================================

--- A list of icons to the drawn in a given rectangle.
-- Commonly used to show status icons in windows.
---------------------------------------------------------------------------------------------------
-- @uimod IconList
-- @extend Component

-- ================================================================================================

-- Imports
local Component = require('core/gui/Component')
local ImageComponent = require('core/gui/widget/ImageComponent')
local SpriteGrid = require('core/graphics/SpriteGrid')
local Vector = require('core/math/Vector')

-- Class table.
local IconList = class(Component)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Vector topLeft Position of the top left corner.
-- @tparam number width The max width.
-- @tparam number height The max height.
-- @tparam[opt=16] number frameWidth The width of each icon.
-- @tparam[opt=16] number frameHeight The height of each icon.
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
  self:setVisible(false)
end
--- Sets the content of this list.
-- @tparam table icons Array of sprites.
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
      self.icons[i] = ImageComponent(sprite, Vector(x - self.iconWidth / 2, y - self.iconHeight / 2), 
        self.iconWidth, self.iconHeight)
    else
      self.icons[i] = ImageComponent(nil, Vector(x, y), self.iconWidth, self.iconHeight)
    end
    self.content:add(self.icons[i])
    self.icons[i]:setVisible(self.visible)
    if frameSkin then
      local frame = SpriteGrid(frameSkin)
      frame:createGrid(MenuManager.renderer, self.frameWidth, self.frameHeight)
      self.frames[i] = ImageComponent(frame, Vector(x - self.iconWidth / 2, y - self.iconHeight / 2, -1),
        self.iconWidth, self.iconHeight)
      self.content:add(self.frames[i])
      self.frames[i]:setVisible(self.visible)
    end
    x = x + self.frameWidth - 1
  end
end
--- Sets the content of this list.
-- @tparam table icons Array of icon tables (id, col and row).
function IconList:setIcons(icons)
  local sprites = {}
  for i = 1, #icons do
    sprites[i] = ResourceManager:loadIcon(icons[i], MenuManager.renderer)
  end
  self:setSprites(sprites)
end

return IconList
