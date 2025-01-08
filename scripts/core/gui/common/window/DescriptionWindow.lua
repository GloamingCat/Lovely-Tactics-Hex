
-- ================================================================================================

--- A window that shows a description text.
---------------------------------------------------------------------------------------------------
-- @windowmod DescriptionWindow
-- @extend Window

-- ================================================================================================

-- Imports
local Vector = require('core/math/Vector')
local TextComponent = require('core/gui/widget/TextComponent')
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
  self.text = TextComponent('', nil, nil, 'left', Fonts.menu_medium)
  self.content:add(self.text)
  self:packToWindow()
end
--- Overrides `Window:resize`. Updates text.
-- @override
function DescriptionWindow:resize(...)
  Window.resize(self, ...)
  self:packToWindow()
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
  return self.text:getText()
end
--- Resizes the window to the minimum size that includes the text.
function DescriptionWindow:packToText()
  local x1, y1, x2, y2 = self.text.sprite:getBoundingBox()
  w, h = round(x2 - x1), round(y2 - y1)
  self.text.position = Vector(-w / 2, -h / 2, -1)
  self:resize(w + self:paddingX() * 2, h + self:paddingY() * 2)
end
--- Resizes the window to the minimum size that includes the text.
function DescriptionWindow:packToWindow()
  self.text:setMaxWidth(self.width - self:paddingX() * 2)
  self.text:setMaxHeight(self.height - self:paddingY() * 2)
  self.text.position = Vector(self:paddingX() - self.width / 2, self:paddingY() - self.height / 2, -1)
  self.text:updatePosition(self.position)
end
-- For debugging.
function DescriptionWindow:__tostring()
  return 'Description Window'
end

return DescriptionWindow
