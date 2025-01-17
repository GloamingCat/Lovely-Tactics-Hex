
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
-- @tparam[opt] GridWindow window Parent window.
-- @tparam[opt] number width The width of the box in pixels. If nil, uses `window:cellWidth()`.
-- @tparam[opt] number height The height of the box in pixels. If nil, uses `window:cellHeight()`.
-- @tparam[opt] Vector pos The position of the top left corner of the box. It's only used if the
--  window parent is nil, otherwise the position is calculated from `window`.
function Highlight:init(window, width, height, pos)
  if window then
    local mx = window:colMargin() / 4 + self:paddingX()
    local my = window:rowMargin() / 4 + self:paddingY()
    width = width or window:cellWidth() + mx * 2
    height = height or window:cellHeight() + my * 2
    self.displacement = Vector(width / 2 - mx, height / 2 - my, 2)
    self.window = window
    window.content:add(self)
  else
    self.displacement = pos
  end
  Transformable.init(self, self.displacement:clone())
  Component.init(self, self.position, width, height)
end
--- Implements `Component:createContent`. 
-- @implement
function Highlight:createContent(width, height)
  self.spriteGrid = SpriteGrid(self:getSkin())
  self.spriteGrid:createGrid(MenuManager.renderer, width, height)
  self.spriteGrid:updateTransform(self)
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Window's skin.
-- @treturn table Animation data.
function Highlight:getSkin()
  return Database.animations[Config.animations.highlight]
end
--- Distance between the highlight border and the neighbor column.
-- @treturn number Padding in pixels.
function Highlight:paddingX()
  return 3
end
--- Distance between the highlight border and the neighbor row.
-- @treturn number Padding in pixels.
function Highlight:paddingY()
  return 2
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
  local visible = value and active and (not self.window or #self.window.matrix > 0)
  Component.setVisible(self, visible)
  self.spriteGrid:setVisible(visible)
end

return Highlight
