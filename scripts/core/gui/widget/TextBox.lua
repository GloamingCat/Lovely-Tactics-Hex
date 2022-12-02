
--[[===============================================================================================

TextBox
---------------------------------------------------------------------------------------------------
Box to input a one-line string. 

=================================================================================================]]

-- Imports
local Highlight = require('core/gui/widget/Highlight')
local Sprite = require('core/graphics/Sprite')
local SimpleText = require('core/gui/widget/SimpleText')
local Vector = require('core/math/Vector')

local TextBox = class(SimpleText)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(window : GridWindow) the window this spinner belongs to.
function TextBox:init(window, initStr, position, width)
  self.input = initStr
  self.cursorPoint = #initStr + 1
  self.cursorVisible = true
  self.confirmSound = Config.sounds.buttonConfirm
  self.clickSound = Config.sounds.buttonConfirm
  self.cancelSound = Config.sounds.buttonCancel
  self.errorSound = Config.sounds.buttonError
  self.window = window
  SimpleText.init(self, initStr .. '{u} {u}', position, width, 'left', Fonts.gui_button)
end
-- Overrides SimpleText:createContent.
-- Creates highlight.
function TextBox:createContent(...)
  SimpleText.createContent(self, ...)
  local width = self.window.width - self.window:colMargin() / 2 - 4
  local height = self.window:cellHeight() + self.window:rowMargin() / 2 + 4
  self.highlight = Highlight(nil, width, height, Vector(0, 0, 0))
  self.content:add(self.highlight)
end

---------------------------------------------------------------------------------------------------
-- Operations
---------------------------------------------------------------------------------------------------

-- Insert character in the position pointed by cursor.
-- @param(c : string) Character to be inserted.
function TextBox:insertCharacter(c)
  local part1 = self.input:sub(1, self.cursorPoint - 1) .. c
  local part2 = self.input:sub(self.cursorPoint)
  self.input = part1 .. part2
  self:moveCursor(1)
end
-- Erase character pointed by cursor.
function TextBox:eraseCharacter()
  if #self.input == 0 then
    return
  end
  local part1 = self.input:sub(1, self.cursorPoint - 2)
  local part2 = self.input:sub(self.cursorPoint)
  self.input = part1 .. part2
  self:moveCursor(-1)
end

---------------------------------------------------------------------------------------------------
-- Cursor
---------------------------------------------------------------------------------------------------

function TextBox:updatePosition(...)
  local my = self.window:rowMargin() / 2 + 4
  local height = self.window:cellHeight() + my
  self.highlight.displacement.x = 0
  self.highlight.displacement.y = -self.window.height / 2 + height / 2 - my / 2 + self.window:paddingY()
  SimpleText.updatePosition(self, ...)
  self.highlight:updatePosition(...)
end
-- Hides or redraws cursor according to its position and visibility.
function TextBox:refreshCursor()
  if self.cursorVisible then
    local input = self.input .. ' '
    local pos = self.cursorPoint
    local part1 = input:sub(1, pos - 1)
    local char = input:sub(pos, pos)
    local part2 = input:sub(pos + 1)
    self.text = part1 .. '{u}' .. char .. '{u}' .. part2
  else
    self.text = self.input
  end
  self:redraw()
end
-- Updates cursor point and redraws texts accordingly.
-- @param(pos : number) Index of the character the cursor is pointing.
function TextBox:moveCursor(dx)
  local pos = self.cursorPoint + dx
  pos = math.min(pos, #self.input + 1)
  pos = math.max(pos, 1)
  if pos ~= self.cursorPoint then
    self.cursorPoint = pos
    self:refreshCursor()
  end
end
-- Sets cursor visibility.
-- @param(value : boolean)
function TextBox:setCursorVisible(value)
  if self.cursorVisible ~= value then
    self.highlight:setVisible(value)
    self.cursorVisible = value
    self:refreshCursor()
  end
end

return TextBox
