
--[[===============================================================================================

@classmod DescriptionWindow
---------------------------------------------------------------------------------------------------
A window that shows a description text.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local SimpleText = require('core/gui/widget/SimpleText')
local Window = require('core/gui/Window')

-- Alias
local round = math.round

-- Class table.
local DescriptionWindow = class(Window)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam number width Window's total width.
-- @tparam number height Window's total height.
function DescriptionWindow:createContent(width, height)
  Window.createContent(self, width, height)
  local textPosition = Vector(self:paddingX() - width / 2, self:paddingY() - height / 2, -1)
  local textWidth = width - self:paddingX() * 2
  self.text = SimpleText('', textPosition, textWidth, 'left', Fonts.gui_medium)
  self.text:setMaxHeight(height - self:paddingY() * 2)
  self.content:add(self.text)
end
--- Sets text to be shown.
-- @tparam string txt The text that will be shown in the window.
function DescriptionWindow:updateText(txt)
  self.text:setText(txt or '')
  self.text:updatePosition(self.position)
  self.text:redraw()
end
--- Sets text to be translated and showb according to its key.
-- @tparam string term The text's key in the Vocab table.
-- @tparam string fb The fallback text for when the key in not found in Vocab.
function DescriptionWindow:updateTerm(term, fb)
  self.text:setTerm(term, fb)
  self.text:updatePosition(self.position)
  self.text:redraw()
end
--- Gets the text the is being shown in the window.
-- @treturn string The text currently being shown in the window.
function DescriptionWindow:getText()
  return self.text.sprite.text
end
--- Resizes the window to the minimum size that includes the text.
function DescriptionWindow:packText()
  local w, h = self.text.sprite:quadBounds()
  w, h = round(w), round(h)
  self.text.position = Vector(-w / 2, -h / 2, -1)
  self:resize(w + self:paddingX() * 2, h + self:paddingY() * 2)
end
-- @treturn string String representation (for debugging).
function DescriptionWindow:__tostring()
  return 'Description Window'
end

return DescriptionWindow
