
-- ================================================================================================

--- Hides window cursor and button highlight when on mobile.
---------------------------------------------------------------------------------------------------
-- @plugin HideCursorOnMobile

--- Plugin parameters.
-- @tags Plugin
-- @tfield Visibility cursor sets the visibility type of the button cursor. The default type is `"list"`.
-- @tfield Visibility highlight sets the visibility type of the button highlight. The default type is `"hide"`.

-- ================================================================================================

-- Imports
local Highlight = require('core/gui/widget/Highlight')
local WindowCursor = require('core/gui/widget/WindowCursor')

-- Rewrites
local WindowCursor_setVisible = WindowCursor.setVisible
local Highlight_setVisible = Highlight.setVisible

-- Parameters
local cursor = args.cursor or 'list'
local hl = args.highlight or 'hide'


-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Visibility types for cursors.
-- @enum Visibility
-- @field hide Always invisible.
-- @field list Visible on windows of type `ListWindow` only.
-- @field show Always visible.
local Visibility = {
  HIDE = 'hide',
  LIST = 'list',
  SHOW = 'show'
} 

-- ------------------------------------------------------------------------------------------------
-- WindowCursor
-- ------------------------------------------------------------------------------------------------

--- Rewrites `WindowCursor:setVisible`. Hide window cursor.
-- @rewrite
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

--- Rewrites `Highlight:setVisible`. Hide button highlight.
-- @rewrite
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
