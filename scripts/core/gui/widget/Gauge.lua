
--[[===============================================================================================

Gauge
---------------------------------------------------------------------------------------------------
A variable meter that shows the variable state in a bar and in text.

=================================================================================================]]

-- Imports
local Bar = require('core/gui/widget/Bar')
local Component = require('core/gui/Component')
local SimpleText = require('core/gui/widget/SimpleText')
local Vector = require('core/math/Vector')

local Gauge = class(Component)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(topLeft : Vector) The position of the top left corner.
-- @param(width : number) The width of the bar.
-- @param(color : table) The color of the bar.
-- @param(x : number) Displacement of the bar (optional).
function Gauge:init(topLeft, width, color, x)
  if x then
    topLeft = topLeft:clone()
    topLeft.x = topLeft.x + x
    width = width - x
  end
  Component.init(self, topLeft, width, color)
end
-- Overrides Component:createContent.
function Gauge:createContent(width, color)
  self.width = width
  self.bar = Bar(Vector(0, 3, 1), width, 6, 1)
  self.bar:setColor(color)
  self.text = SimpleText('', Vector(0, 0, 0), width, 'right', Fonts.gui_tiny)
  self.percentage = false
  self.content:add(self.text)
  self.content:add(self.bar)
end

---------------------------------------------------------------------------------------------------
-- Values
---------------------------------------------------------------------------------------------------

-- Updates the value of the gauge.
-- @param(current : number) The current value.
-- @param(max : number) The maximum value.
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
