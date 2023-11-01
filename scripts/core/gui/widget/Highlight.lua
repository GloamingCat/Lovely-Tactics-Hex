
-- ================================================================================================

--- The light background box that is visible behind the selected widget.
---------------------------------------------------------------------------------------------------
-- @uimod Highlight
-- @extend Component
-- @extend Transformable

-- ================================================================================================

-- Imports
local Component = require('core/gui/Component')
local SpriteGrid = require('core/graphics/SpriteGrid')
local Transformable = require('core/math/transform/Transformable')
local Vector = require('core/math/Vector')

-- Class table.
local Highlight = class(Component, Transformable)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GridWindow window Parent window.
-- @tparam number width The width of the box in pixels.
-- @tparam number height The height of the box in pixels.
-- @tparam Vector pos The position of the top left corner of the box
--  (optional, only used if the window parent is nil).
function Highlight:init(window, width, height, pos)
  if window then
    local mx = window:colMargin() / 2 + 6
    local my = window:rowMargin() / 2 + 4
    width = width or window:cellWidth() + mx
    height = height or window:cellHeight() + my
    self.displacement = Vector(width / 2 - mx / 2, height / 2 - my / 2)
    self.window = window
    window.content:add(self)
  else
    self.displacement = pos
  end
  Transformable.init(self, self.displacement:clone())
  Component.init(self, self.position, width, height)
end
--- Overrides `Component:createContent`. 
-- @override
function Highlight:createContent(width, height)
  self.spriteGrid = SpriteGrid(self:getSkin(), Vector(0, 0, 1))
  self.spriteGrid:createGrid(MenuManager.renderer, width, height)
  self.spriteGrid:updateTransform(self)
  self.content:add(self.spriteGrid)
end
--- Window's skin.
-- @treturn table Animation data.
function Highlight:getSkin()
  return Database.animations[Config.animations.highlight]
end

-- ------------------------------------------------------------------------------------------------
-- Content methods
-- ------------------------------------------------------------------------------------------------

--- Overrides `Component:updatePosition`. Updates position to the selected button.
-- @override
function Highlight:updatePosition(wpos)
  if self.window then
    local button = self.window:currentWidget()
    if button then
      local pos = button:relativePosition()
      pos:add(wpos)
      pos:add(self.displacement)
      self:setPosition(pos)
      self.spriteGrid:updateTransform(self)
    else
      self.spriteGrid:setVisible(false)
    end
  else
    local pos = wpos + self.displacement
    self:setPosition(pos)
    self.spriteGrid:updateTransform(self)
  end
end
--- Overrides `Component:setVisible`. Shows sprite grid.
-- @override
function Highlight:setVisible(value)
  local active = (not self.hideOnDeactive or self.window.active)
  Component.setVisible(self, value and active and (not self.window or #self.window.matrix > 0))
end

return Highlight
