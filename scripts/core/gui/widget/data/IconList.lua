
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
  self.frameWidth = frameWidth or self.defaultFrameWidth
  self.frameHeight = frameHeight or self.defaultFrameHeight
  self.iconWidth = self.frameWidth
  self.iconHeight = self.frameHeight
  self.visible = true
  self:setVisible(false)
end
--- Implements `Component:setProperties`.
-- @implement
function IconList:setProperties()
  self.horizontal = true
  self.defaultFrameWidth = 16
  self.defaultFrameHeight = 16
  self.frameId = Config.animations.frame
end
--- Sets the content of this list.
-- @tparam table icons Array of sprites.
function IconList:setSprites(icons)
  self:destroy()
  local frameSkin = self.frameId >= 0 and Database.animations[self.frameId]
  self.icons = {}
  self.frames = frameSkin and {}
  if not icons then
    return
  end
  local v = not self.horizontal
  local x, y = 0, 0
  for i = 1, #icons do
    local sprite = icons[i]
    if self.horizontal then
      if self.width and x + self.frameWidth > self.width then
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
    else
      if self.height and y + self.frameHeight > self.height then
        if x + self.frameWidth > self.width then
          for j = i, icons do
            icons[j]:destroy()
          end
          break
        end
        if y > 0 then
          y = 0
          x = x + self.frameWidth - 1
        end
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
    if self.horizontal then
      x = x + self.frameWidth - 1
    else
      y = y + self.frameHeight - 1
    end
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
