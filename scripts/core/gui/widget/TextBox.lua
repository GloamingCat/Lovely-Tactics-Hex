
-- ================================================================================================

--- Box to input a one-line string. 
---------------------------------------------------------------------------------------------------
-- @uimod TextBox
-- @extend TextComponent

-- ================================================================================================

-- Imports
local Highlight = require('core/gui/widget/Highlight')
local Sprite = require('core/graphics/Sprite')
local TextComponent = require('core/gui/widget/TextComponent')
local Vector = require('core/math/Vector')

-- Class table.
local TextBox = class(TextComponent)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GridWindow window The window this text box belongs to.
-- @tparam string initStr The initial text in the box.
-- @tparam Vector pos The position of the box's top left corner in pixels, relative to the window.
-- @tparam number width The width of the box in pixels.
function TextBox:init(window, initStr, pos, width)
  self.input = initStr
  self.cursorPoint = #initStr + 1
  self.cursorVisible = true
  self.confirmSound = Config.sounds.buttonConfirm
  self.clickSound = Config.sounds.buttonConfirm
  self.cancelSound = Config.sounds.buttonCancel
  self.errorSound = Config.sounds.buttonError
  self.window = window
  TextComponent.init(self, initStr .. '{u} {u}', pos, width, 'left', Fonts.menu_button)
end
--- Overrides `TextComponent:createContent`. Creates highlight.
-- @override
function TextBox:createContent(...)
  TextComponent.createContent(self, ...)
  local width = self.window.width - self.window:colMargin() / 2 - 4
  local height = self.window:cellHeight() + self.window:rowMargin() / 2 + 4
  self.highlight = Highlight(nil, width, height, Vector(0, 0, 0))
  self.content:add(self.highlight)
end

-- ------------------------------------------------------------------------------------------------
-- Operations
-- ------------------------------------------------------------------------------------------------

--- Insert character in the position pointed by cursor.
-- @tparam string c Character to be inserted.
function TextBox:insertCharacter(c)
  if #c > 1 then
    c = '?'
  end
  local part1 = self.input:sub(1, self.cursorPoint - 1) .. c
  local part2 = self.input:sub(self.cursorPoint)
  self.input = part1 .. part2
  self:moveCursor(1)
end
--- Erase character pointed by cursor.
function TextBox:eraseCharacter()
  if #self.input == 0 then
    return
  end
  local part1 = self.input:sub(1, self.cursorPoint - 2)
  local part2 = self.input:sub(self.cursorPoint)
  self.input = part1 .. part2
  self:moveCursor(-1)
end

-- ------------------------------------------------------------------------------------------------
-- Cursor
-- ------------------------------------------------------------------------------------------------

--- Overrides `TextComponent:updatePosition`. Updates highlight position.
-- @override
function TextBox:updatePosition(...)
  if self.highlight then
    local my = self.window:rowMargin() / 2 + 4
    local height = self.window:cellHeight() + my
    self.highlight.displacement.x = 0
    self.highlight.displacement.y = -self.window.height / 2 + height / 2 - my / 2 + self.window:paddingY()
    TextComponent.updatePosition(self, ...)
    self.highlight:updatePosition(...)
  else
    TextComponent.updatePosition(self, ...)
  end
end
--- Hides or redraws cursor according to its position and visibility.
function TextBox:refreshCursor()
  if self.cursorVisible then
    local input = self.input .. ' '
    local pos = self.cursorPoint
    local part1 = input:sub(1, pos - 1)
    local char = input:sub(pos, pos)
    local part2 = input:sub(pos + 1)
    self:setText(part1 .. '{u}' .. char .. '{u}' .. part2)
  else
    self:setText(self.input)
  end
  self:redraw()
end
--- Updates cursor point and redraws texts accordingly.
-- @tparam number dx The direction in which the cursor was moved (-1 is left, 1 is right).
function TextBox:moveCursor(dx)
  local pos = self.cursorPoint + dx
  pos = math.min(pos, #self.input + 1)
  pos = math.max(pos, 1)
  if pos ~= self.cursorPoint then
    self.cursorPoint = pos
    self:refreshCursor()
  end
end
--- Sets cursor visibility.
-- @tparam boolean value
function TextBox:setCursorVisible(value)
  if self.cursorVisible ~= value then
    self.highlight:setVisible(value)
    self.cursorVisible = value
    self:refreshCursor()
  end
end

return TextBox
