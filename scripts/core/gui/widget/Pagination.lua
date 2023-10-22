
-- ================================================================================================

--- A small text showing the current page of a window.
---------------------------------------------------------------------------------------------------
-- @uimod Pagination
-- @extend SimpleText

-- ================================================================================================

-- Imports
local SimpleText = require('core/gui/widget/SimpleText')
local Vector = require('core/math/Vector')

-- Class table.
local Pagination = class(SimpleText)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Window window Parent window.
-- @tparam string halign Horizontal alignment.
-- @tparam string valign Vertical alignment.
function Pagination:init(window, halign, valign)
  local pos = Vector(0, 0, -10)
  pos.x = -window.width / 2 + window:paddingX()
  if valign == 'top' then
    pos.y = -window.height / 2 + window:paddingY()
  else
    pos.y = window.height / 2 - window:paddingY() - 6
  end
  SimpleText.init(self, '', pos, window.width - window:paddingX() * 2, halign, Fonts.gui_tiny)
end
--- Sets the current page and the total number of pages and updates the text accordingly.
-- @tparam number current Current page.
-- @tparam number max Total number of pages.
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
