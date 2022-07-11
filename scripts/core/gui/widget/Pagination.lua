
--[[===============================================================================================

Pagination
---------------------------------------------------------------------------------------------------
A small text showing the current page of a window.

=================================================================================================]]

-- Imports
local SimpleText = require('core/gui/widget/SimpleText')
local Vector = require('core/math/Vector')

local Pagination = class(SimpleText)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(window : Window) Parent window.
-- @param(halign : string) Horizontal alignment.
-- @param(valign : string) Vertical alignment.
function Pagination:init(window, halign, valign)
  local pos = Vector(0, 0, -1)
  pos.x = -window.width / 2 + window:paddingX()
  if valign == 'top' then
    pos.y = -window.height / 2 + window:paddingY()
  else
    pos.y = window.height / 2 - window:paddingY() - 6
  end
  SimpleText.init(self, '', pos, window.width - window:paddingX() * 2, halign, Fonts.gui_tiny)
end
-- @param(current : number) Current page.
-- @param(max : number) Total number of pages.
function Pagination:set(current, max)
  local text = ''
  if current then
    if max then
      if max > 1 then
        text = current .. '/' .. max
      end
    else
      text = current .. ''
    end
  end
  self.current = current
  self.max = max
  self:setText(text)
  self:redraw()
end

return Pagination
