
--[[===============================================================================================

Button
---------------------------------------------------------------------------------------------------
A window button. It may have a text and an animated icon.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Animation = require('core/graphics/Animation')
local SimpleText = require('core/gui/widget/SimpleText')
local GridWidget = require('core/gui/widget/control/GridWidget')

local Button = class(GridWidget)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(window : GridWindow) The window that this button is component of.
-- @param(onConfirm : function) The function called when player confirms (optinal).
-- @param(onSelects : function) The function called when player selects this button (optinal).
-- @param(enableCondition : function) The function that tells if 
--  this button is enabled (optional)
-- @param(onMove : function) The function called when player presses arrows (optinal).
function Button:init(window, onConfirm, enableCondition)
  GridWidget.init(self, window)
  self.enableCondition = enableCondition or self.enableCondition or window.buttonEnabled
  self.onConfirm = onConfirm or self.onConfirm or window.onButtonConfirm
  self.onCancel = self.onCancel or window.onButtonCancel
  self.onSelect = self.onSelect or window.onButtonSelect
  self.onMove = self.onMove or window.onButtonMove
  self.onClick = self.onClick or self.onConfirm
  self.iconPos = 0
end
-- Creates a button for the action represented by the given key.
-- @param(window : GridWindow) The window that this button is component of.
-- @param(key : string) Action's key.
-- @ret(Button) New button.
function Button:fromKey(window, key)
  local button = self(window, window[key .. 'Confirm'], window[key .. 'Enabled'])
  local icon = Config.icons[key]
  if icon then
    icon = ResourceManager:loadIconAnimation(icon, GUIManager.renderer)
    button:createIcon(icon)
  end
  if key and Vocab[key] then
    button:createText(key, key, window.buttonFont)
  end
  button.key = key
  return button
end
-- @param(term : string) The text term to be localized.
-- @param(fallback : string) If no localization is found, use this text (optional).
-- @param(fontName : string) The text's font, from Fonts folder (optional, uses default).
-- @param(align : string) The text's horizontal alignment (optional, left by default).
-- @param(w : number) The text's maximum width (optional, uses all empty space by default).
-- @param(pos : Vector) The text's maximum width (optional, top left by default).
function Button:createText(term, fallback, fontName, align, w, pos)
  if self.text then
    self.text:destroy()
  end
  fontName = fontName or 'gui_button'
  w = (w or self.window:cellWidth()) - self:iconWidth()
  if self.iconPos < 0.25 then
    pos = pos or Vector(self:iconWidth(), 0, 0)
  else
    pos = pos or Vector(0, 0, 0)
  end
  local text = SimpleText('', pos, w, align or 'left', Fonts[fontName])
  text:setTerm(term, fallback)
  text.sprite.alignY = 'center'
  text.sprite.maxHeight = self.window:cellHeight()
  text.sprite:setColor(Color.gui_text_enabled)
  text:redraw()
  self.text = text
  self.content:add(text)
  return self.text
end
-- @param(term : string) The text term to be localized.
-- @param(fallback : string) If no localization is found, use this text (optional).
-- @param(fontName : string) The text's font, from Fonts folder (optional, uses default).
function Button:createInfoText(term, fallback, fontName, align, w, pos)
  if self.infoText then
    self.infoText:destroy()
  end
  w = (w or self.window:cellWidth()) - self:iconWidth()
  if self.iconPos > 0.5 then
    pos = pos or Vector(self.window:cellWidth() - w - self:iconWidth(), 0, 0)
  else
    pos = pos or Vector(self.window:cellWidth() - w, 0, 0)
  end
  fontName = fontName or 'gui_button'
  local text = SimpleText('', pos, w, align or 'right', Fonts[fontName])
  text:setTerm(term, fallback)
  text.sprite.alignY = 'center'
  text.sprite.maxHeight = self.window:cellHeight()
  text.sprite:setColor(Color.gui_text_enabled)
  text:redraw()
  self.infoText = text
  self.content:add(text)
  return text
end
-- @param(icon : Animation) The icon graphics or the path to the icon.
function Button:createIcon(icon)
  if not icon then
    return
  end
  icon.sprite:setColor(Color.gui_icon_enabled)
  self.icon = icon
  self.content:add(icon)
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- @ret(number)
function Button:iconWidth()
  if self.icon then
    local x, y, w, h = self.icon.sprite:totalBounds()
    return w
  else
    return 0
  end
end
-- @param(text : string)
function Button:setText(...)
  self.text:setText(...)
  self.text:redraw()
end
-- @param(text : string)
function Button:setTerm(...)
  self.text:setTerm(...)
  self.text:redraw()
end
-- @param(text : string)
function Button:setInfoText(...)
  self.infoText:setText(...)
  self.infoText:redraw()
end
-- @param(text : string)
function Button:setInfoTerm(...)
  self.infoText:setTerm(...)
  self.infoText:redraw()
end
-- @param(icon : table) Icon data.
function Button:setIcon(icon)
  if self.icon then
    self.icon:destroy()
    self.icon = nil
  end
  if icon and icon.id >= 0 then
    icon = ResourceManager:loadIconAnimation(icon, GUIManager.renderer)
    self:createIcon(icon)
  end
end
-- Converting to string.
function Button:__tostring()
  if not self.text then
    return '' .. self.index
  end
  return self.index .. ': ' .. self.text.text
end

---------------------------------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------------------------------

-- Refreshes color, position and visibility.
function Button:refreshState()
  self:refreshColor()
  self:updatePosition(self.window.position)
  self:hide()
  if self.window.open then
    self:show()
  end
end
-- Updates text and icon color based on button state.
function Button:refreshColor()
  local name = self.enabled and 'enabled' or 'disabled'
  if self.text then
    local color = Color['gui_text_' .. name]
    self.text.sprite:setColor(color)
  end
  if self.infoText then
    local color = Color['gui_text_' .. name]
    self.infoText.sprite:setColor(color)
  end
  if self.icon then
    local color = Color['gui_icon_' .. name]
    self.icon.sprite:setColor(color)
  end
end
-- Updates enabled state based on the enable condition function.
function Button:refreshEnabled()
  if self.enableCondition then
    self:setEnabled(self.enableCondition(self.window, self))
  end
end
-- Enables/disables this button.
-- @param(value : boolean) true to enable, false to disable
function Button:setEnabled(value)
  if value ~= self.enabled then
    self.enabled = value
    self:refreshColor()
  end
end
-- Selects/deselects this button.
-- @param(value : boolean)
function Button:setSelected(value)
  if value ~= self.selected then
    self.selected = value
    if self.enabled then
      self:refreshColor()
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------------------------------

-- Updates position based on window's position.
function Button:updatePosition(windowPos)
  local pos = self:relativePosition()
  pos:add(windowPos)
  for i = 1, #self.content do
    local c = self.content[i]
    if c.updatePosition then
      c:updatePosition(pos)
    end
  end
  if self.icon then
    self.icon.sprite:setXYZ(0, 0)
    local x, y, w, h, _ = self.icon.sprite:totalBounds()
    x = -x + (self.window:cellWidth() - w) * self.iconPos
    _, y = self.text:getCenter()
    self.icon.sprite:setXYZ(pos.x + x, pos.y + y, pos.z)
  end
end

---------------------------------------------------------------------------------------------------
-- Show/hide
---------------------------------------------------------------------------------------------------

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
    self:setEnabled(enabled)
  end
  GridWidget.show(self)
end

return Button
