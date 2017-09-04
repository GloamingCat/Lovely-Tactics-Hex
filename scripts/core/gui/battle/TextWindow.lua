
--[[===============================================================================================

TextWindow
---------------------------------------------------------------------------------------------------
Window that shows a static text.

=================================================================================================]]

-- Imports
local SimpleText = require('core/gui/SimpleText')
local Window = require('core/gui/Window')

local TextWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(line : string) the text content of the window
function TextWindow:init(GUI, width, height, text, align)
  self.text = text
  self.align = align or 'left'
  Window.init(self, GUI, width, height)
end
-- Creates the text sprite.
function TextWindow:createContent()
  Window.createContent(self)
  self.simpleText = SimpleText(self.line, self:hPadding() - self.width / 2, 
    self:vpadding() - self.height / 2, self.width - self:hPadding() * 2, self.align)
  self.content:add(self.simpleText)
end

return TextWindow
