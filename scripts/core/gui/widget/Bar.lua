
--[[===============================================================================================

Bar
---------------------------------------------------------------------------------------------------
A bar meter.

=================================================================================================]]

-- Imports
local Component = require('core/gui/Component')
local SpriteGrid = require('core/graphics/SpriteGrid')
local Vector = require('core/math/Vector')

-- Alias
local round = math.round

local Bar = class(Component)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(topLeft : Vector) The position of the frame's top left corner.
-- @param(width : number) Total width of the frame.
-- @param(height : number) Height of the frame.
-- @param(value : number) Initial width of the bar (multiplier of frame width).
function Bar:init(topLeft, width, height, value)
  Component.init(self, topLeft, width, height)
  self.width = width - self:padding() * 2
  self.height = height - self:padding() * 2
  self:setValue(value or 1)
end
-- Overrides Component:createContent.
function Bar:createContent(width, height)
  local pos = Vector(width / 2, height / 2, 1)
  pos:add(self.position)
  self.frame = SpriteGrid(self:getFrame(), pos)
  self.frame:createGrid(GUIManager.renderer, width, height)
  self.bar = ResourceManager:loadAnimation(self:getBar(), GUIManager.renderer)
  self.bar.sprite.texture:setFilter('linear', 'linear')
  self.quadWidth, self.quadHeight = self.bar.sprite:quadBounds()
  self.content:add(self.frame)
  self.content:add(self.bar)
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Sets the width of the bar.
-- @param(value : number) Value from 0 to 1.
function Bar:setValue(value)
  local w = self.quadWidth * value
  local h = self.quadHeight
  self.bar.sprite:setQuad(0, 0, w, h)
  self.bar.sprite:setScale(value * self.width / w, self.height / h)
end
-- Overrides Component:updatePosition.
function Bar:updatePosition(pos)
  self.bar.sprite:setXYZ(round(pos.x + self.position.x + self:padding()),
    round(pos.y + self.position.y + self:padding()),
    pos.z + self.position.z)
  self.frame:updatePosition(pos)
end

---------------------------------------------------------------------------------------------------
-- Graphics
---------------------------------------------------------------------------------------------------

-- Sets the color of the bar.
-- @param(color : table) New color.
function Bar:setColor(color)
  self.bar.sprite:setColor(color)
end
-- @ret(table) The frame padding.
function Bar:padding()
  return 1
end
-- @ret(table) The frame spritesheet from Database.
function Bar:getFrame()
  return Database.animations[Config.animations.gaugeFrame]
end
-- @ret(table) The bar spritesheet from Database.
function Bar:getBar()
  return Database.animations[Config.animations.gaugeBar]
end

return Bar
