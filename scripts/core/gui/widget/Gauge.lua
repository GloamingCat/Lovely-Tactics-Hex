
-- ================================================================================================

--- A variable meter that shows the variable state in a bar and in text.
---------------------------------------------------------------------------------------------------
-- @classmod Gauge
-- @extend Component

-- ================================================================================================

-- Imports
local Bar = require('core/gui/widget/Bar')
local Component = require('core/gui/Component')
local SimpleText = require('core/gui/widget/SimpleText')
local Vector = require('core/math/Vector')

-- Class table.
local Gauge = class(Component)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Vector topLeft The position of the top left corner.
-- @tparam number width The width of the bar.
-- @tparam table color The color of the bar.
-- @tparam number x Displacement of the bar (optional).
function Gauge:init(topLeft, width, color, x)
  if x then
    topLeft = topLeft:clone()
    topLeft.x = topLeft.x + x
    width = width - x
  end
  Component.init(self, topLeft, width, color)
end
--- Overrides `Component:createContent`. 
-- @override
function Gauge:createContent(width, color)
  self.width = width
  self.bar = Bar(Vector(0, 3, 1), width, 6, 1)
  self.bar:setColor(color)
  self.text = SimpleText('', Vector(0, 0, 0), width, 'right', Fonts.gui_tiny)
  self.percentage = false
  self.content:add(self.text)
  self.content:add(self.bar)
end

-- ------------------------------------------------------------------------------------------------
-- Values
-- ------------------------------------------------------------------------------------------------

--- Updates the value of the gauge.
-- @tparam number current The current value.
-- @tparam number max The maximum value.
function Gauge:setValues(current, max)
  local k = current / max
  self.bar:setValue(k)
  if self.percentage then
    self.text:setText(string.format( '%3.0f', k * 100 ) .. '%')
  else
    self.text:setText(current .. '/' .. max)
  end
  self.text:redraw()
end

return Gauge
