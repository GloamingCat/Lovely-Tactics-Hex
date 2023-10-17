
-- ================================================================================================

--- Hides window cursor and button highlight when on mobile.
-- Possible values for visibility type:
--  * 'hide' -> always invisible;
--  * 'list' -> visible on windows of type ListWindow only;
--  * 'show' -> always visible.
-- 
-- Plugin parameters:
--  * Tag <cursor> sets the visibility type of the button cursor. The default type is 'list'.
--  * Tag <highlight> sets the visibility type of the button highlight. The default type is 'hide'.
-- ------------------------------------------------------------------------------------------------
-- @plugin HideCursorOnMobile

-- ================================================================================================

-- Imports
local Highlight = require('core/gui/widget/Highlight')
local WindowCursor = require('core/gui/widget/WindowCursor')

-- Arguments
local cursor = args.cursor or 'list'
local hl = args.highlight or 'hide'

-- ------------------------------------------------------------------------------------------------
-- WindowCursor
-- ------------------------------------------------------------------------------------------------

--- Hide window cursor.
local WindowCursor_setVisible = WindowCursor.setVisible
function WindowCursor:setVisible(value)
  if cursor == 'hide' then
    value = value and InputManager:hasKeyboard()
  elseif cursor == 'list' then
    if not self.window or not self.window.list then
      value = value and InputManager:hasKeyboard()
    end
  end
  WindowCursor_setVisible(self, value)
end

-- ------------------------------------------------------------------------------------------------
-- Highlight
-- ------------------------------------------------------------------------------------------------

--- Hide button highlight.
local Highlight_setVisible = Highlight.setVisible
function Highlight:setVisible(value)
  if hl == 'hide' then
    value = value and InputManager:hasKeyboard()
  elseif hl == 'list' then
    if not self.window or not self.window.list then
      value = value and InputManager:hasKeyboard()
    end
  end
  Highlight_setVisible(self, value)
end
