
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
  self.width = width - self.margin * 2
  self.height = height - self.margin * 2
  self:setValue(value or 1)
end
--- Implements `Component:setProperties`.
-- @implement
function Bar:setProperties()
  self.frameAnim = Database.animations[Config.animations.gaugeFrame]
  self.barAnim = Database.animations[Config.animations.gaugeBar]
  self.margin = 1
end
--- Overrides `Component:createContent`. 
-- @override
function Bar:createContent(width, height)
  self.frame = SpriteGrid(self.frameAnim)
  self.frame:createGrid(MenuManager.renderer, width, height)
  self.bar = ResourceManager:loadAnimation(self.barAnim, MenuManager.renderer)
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
  Component.updatePosition(self, pos)
  local x = round(pos.x + self.position.x + self.margin)
  local y = round(pos.y + self.position.y + self.margin)
  local z = pos.z + self.position.z
  self.bar.sprite:setXYZ(x, y, z)
  self.frame:setXYZ(x + self.width / 2, y + self.height / 2, z + 1)
end
--- Overrides `Component:update`. 
-- @override
function Bar:update(dt)
  Component.update(self, dt)
  self.bar:update(dt)
  self.frame:update(dt)
end
--- Overrides `Component:setVisible`. 
-- @override
function Bar:setVisible(value)
  Component.setVisible(self, value)
  self.bar.sprite:setVisible(value)
  self.frame:setVisible(value)
end
--- Overrides `Component:destroy`.
-- @override
function Bar:destroy()
  Component.destroy(self)
  self.bar:destroy()
  self.frame:destroy()
end

-- ------------------------------------------------------------------------------------------------
-- Color
-- ------------------------------------------------------------------------------------------------

--- Sets the color of the bar.
-- @tparam Color.RGBA color New color.
function Bar:setColor(color)
  self.bar.sprite:setColor(color)
end

return Bar
