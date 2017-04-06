
--[[===========================================================================

Button
-------------------------------------------------------------------------------
A window button. It may have a text and an animated icon.

=============================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')
local Vector = require('core/math/Vector')
local SimpleText = require('core/gui/SimpleText')

local Button = require('core/class'):new()

-------------------------------------------------------------------------------
-- General
-------------------------------------------------------------------------------

-- @param(window : ButtonWindow) the window that this button is component of
-- @param(index : number) the index of the button in the window
-- @param(col : number) the column of the button in the window
-- @param(row : number) the row of the button in the window
-- @param(text : string) the text shown in the button
-- @param(fontName : string) the text's font (from Fonts folder)
-- @param(iconAnim : Animation) the icon graphics
-- @param(onConfirm : function) the function called when
--  player confirms (optinal)
-- @param(onCancel : function) the function called when
--  player cancels (optinal)
-- @param(onMove : function) the function called when 
--  player moves cursor (optional)
-- @param(enableCondition : function) the function that tells if 
--  this button is enabled (optional)
function Button:init(window, index, col, row, text, fontName, iconAnim, 
    onConfirm, onCancel, onMove, enableCondition)
  self.window = window
  self.index = index
  self.col = col
  self.row = row
  self.enabled = true
  self.selected = false
  if text ~= '' then
    local width = window:buttonWidth()
    self.textSprite = SimpleText(text, nil, width, nil, Font.gui_button)
    self.textSprite.sprite:setColor(Color.gui_text_default)
  end
  if iconAnim ~= nil then
    self.icon = iconAnim
    iconAnim.sprite:setColor(Color.gui_icon_default)
  end
  self.onConfirm = onConfirm or self.onConfirm
  self.onCancel = onCancel or self.onCancel
  self.onMove = onMove or self.onMove
  self.enableCondition = enableCondition
  window.content:add(self)
end

-- Updates icon animation.
function Button:update()
  if self.icon then
    self.icon:update()
  end
end

-- Deletes text and icon sprites.
function Button:destroy()
  if self.textSprite then
    self.textSprite:destroy()
  end
  if self.icon then
    self.icon:removeSelf()
  end
end

-------------------------------------------------------------------------------
-- Input handlers
-------------------------------------------------------------------------------

-- Called when player presses "Confirm" on this button.
function Button.onConfirm(window, button)
  window.result = button.index
end

-- Called when player presses "Cancel" on this button.
function Button.onCancel(window, button)
  window.result = 0
end

-- Called when player presses arrows on this button.
function Button.onMove(window, button, dx, dy)
end

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

-- Updates text and icon color based on button state.
function Button:updateColor()
  local name = 'disabled'
  if self.enabled then
    if self.selected then
      name = 'highlight'
    else
      name = 'default'
    end
  end
  if self.textSprite then
    local color = Color['gui_text_' .. name]
    self.textSprite.sprite:setColor(color)
  end
  if self.icon then
    local color = Color['gui_icon_' .. name]
    self.icon.sprite:setColor(color)
  end
end

-- Enables/disables this button.
-- @param(value : boolean) true to enable, false to disable
function Button:setEnabled(value)
  if value ~= self.enabled then
    self.enabled = value
    self:updateColor()
  end
end

-- Selects/deselects this button.
-- @param(value : boolean) true to select, false to deselect
function Button:setSelected(value)
  if value ~= self.selected then
    self.selected = value
    if self.enabled then
      self:updateColor()
    end
  end
end

-------------------------------------------------------------------------------
-- Position
-------------------------------------------------------------------------------

-- @ret(Vector) the offset from the window's position.
function Button:relativePosition()
  local w = self.window
  local x = -(w.width / 2 - w.paddingw) + 
    (self.col - w.offsetCol - 1) * w:buttonWidth()
  local y = -(w.height / 2 - w.paddingh) + 
    (self.row - w.offsetRow - 1) * w:buttonHeight()
  return Vector(x, y, -1)
end

-- Updates position based on window's position.
function Button:updatePosition(pos)
  pos = pos + self:relativePosition()
  if self.textSprite then
    self.textSprite.sprite:setPosition(pos)
  end
  if self.icon then
    self.icon:setPosition(pos)
  end
end

-------------------------------------------------------------------------------
-- Show/hide
-------------------------------------------------------------------------------

-- Shows button's text and icon.
function Button:show()
  if self.col < self.window.offsetCol + 1 then
    return
  elseif self.row < self.window.offsetRow + 1 then
    return
  elseif self.col > self.window.offsetCol + self.window:colCount() then
    return
  elseif self.row > self.window.offsetRow + self.window:rowCount() then
    return
  end
  if self.enableCondition then
    local enabled = self.enableCondition(self.window, self)
    if not enabled then
      self:setEnabled(false)
    end
  end
  if self.textSprite then
    self.textSprite:show()
  end
  if self.icon then
    self.icon:setVisible(true)
  end
end

-- Hides button's text and icon.
function Button:hide()
  if self.textSprite then
    self.textSprite:hide()
  end
  if self.icon then
    self.icon.isVisible(false)
  end
end

-- Converting to string.
-- @ret(string) a string representation
function Button:toString()
  if not self.textSprite then
    return '' .. self.index
  end
  return self.index .. ': ' .. self.textSprite.text
end

return Button
