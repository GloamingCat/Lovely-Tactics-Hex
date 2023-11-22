
-- ================================================================================================

--- A bar meter.
---------------------------------------------------------------------------------------------------
-- @uimod Bar
-- @extend Component

-- ================================================================================================

-- Imports
local Component = require('core/gui/Component')
local SpriteGrid = require('core/graphics/SpriteGrid')
local Vector = require('core/math/Vector')

-- Alias
local round = math.round

-- Class table.
local Bar = class(Component)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Vector topLeft The position of the frame's top left corner.
-- @tparam number width Total width of the frame.
-- @tparam number height Height of the frame.
-- @tparam number value Initial width of the bar (multiplier of frame width).
function Bar:init(topLeft, width, height, value)
  Component.init(self, topLeft, width, height)
  self.width = width - self:padding() * 2
  self.height = height - self:padding() * 2
  self:setValue(value or 1)
end
--- Overrides `Component:createContent`. 
-- @override
function Bar:createContent(width, height)
  self.frame = SpriteGrid(self:getFrame())
  self.frame:createGrid(MenuManager.renderer, width, height)
  self.bar = ResourceManager:loadAnimation(self:getBar(), MenuManager.renderer)
  self.bar.sprite.texture:setFilter('linear', 'linear')
  local x, y, w, h = self.bar.sprite:getQuadBox()
  self.quadWidth, self.quadHeight = w, h
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Sets the width of the bar.
-- @tparam number value Value from 0 to 1.
function Bar:setValue(value)
  local w = self.quadWidth * value
  local h = self.quadHeight
  self.bar.sprite:setQuad(0, 0, w, h)
  self.bar.sprite:setScale(value * self.width / w, self.height / h)
end
--- Overrides `Component:updatePosition`. 
-- @override
function Bar:updatePosition(pos)
  local x = round(pos.x + self.position.x + self:padding())
  local y = round(pos.y + self.position.y + self:padding())
  local z = pos.z + self.position.z
  self.bar.sprite:setXYZ(x, y, z)
  self.frame:setXYZ(x + self.width / 2, y + self.height / 2, z + 1)
end
--- Overrides `Component:update`. 
-- @override
function Bar:update(dt)
  self.bar:update(dt)
  self.frame:update(dt)
end
--- Overrides `Component:setVisible`. 
-- @override
function Bar:setVisible(value)
  self.bar.sprite:setVisible(value)
  self.frame:setVisible(value)
end

-- ------------------------------------------------------------------------------------------------
-- Graphics
-- ------------------------------------------------------------------------------------------------

--- Sets the color of the bar.
-- @tparam Color.RGBA color New color.
function Bar:setColor(color)
  self.bar.sprite:setColor(color)
end
--- The frame padding.
-- @treturn number
function Bar:padding()
  return 1
end
--- The frame spritesheet from Database.
-- @treturn table
function Bar:getFrame()
  return Database.animations[Config.animations.gaugeFrame]
end
--- The bar spritesheet from Database.
-- @treturn table
function Bar:getBar()
  return Database.animations[Config.animations.gaugeBar]
end

return Bar
