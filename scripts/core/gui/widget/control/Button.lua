
-- ================================================================================================

--- A window button. It may have a text and an animated icon.
---------------------------------------------------------------------------------------------------
-- @uimod Button
-- @extend GridWidget

-- ================================================================================================

-- Imports
local Animation = require('core/graphics/Animation')
local GridWidget = require('core/gui/widget/control/GridWidget')
local ImageComponent = require('core/gui/widget/ImageComponent')
local Sprite = require('core/graphics/Sprite')
local TextComponent = require('core/gui/widget/TextComponent')
local Vector = require('core/math/Vector')

-- Class table.
local Button = class(GridWidget)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam GridWindow window The window that this button is component of.
-- @tparam[opt] function onConfirm The function called when player confirms.
-- @tparam[opt] function enableCondition The function that tells if 
--  this button is enabled.
function Button:init(window, onConfirm, enableCondition)
  GridWidget.init(self, window)
  self.enableCondition = enableCondition or self.enableCondition or window.buttonEnabled
  self.onConfirm = onConfirm or self.onConfirm or window.onButtonConfirm
  self.onCancel = self.onCancel or window.onButtonCancel
  self.onError = self.onError or window.onButtonError
  self.onSelect = self.onSelect or window.onButtonSelect
  self.onMove = self.onMove or window.onButtonMove
  self.onClick = self.onClick or self.onConfirm
  self.iconPos = 0
end
--- Creates a button for the action represented by the given key.
-- @tparam GridWindow window The window that this button is component of.
-- @tparam string key Action's key.
-- @treturn Button New button.
function Button:fromKey(window, key)
  local button = self(window, window[key .. 'Confirm'], window[key .. 'Enabled'])
  button:setIcon(Config.icons[key])
  if key and Vocab[key] then
    button:createText("{%" .. key .. "}", key, window.buttonFont, window.buttonAlign)
    if Vocab.manual[key] then
      button.tooltipTerm = key
    end
  end
  button.key = key
  return button
end
--- Creates the main text.
-- @tparam string term The text term to be localized.
-- @tparam[opt] string fallback If no localization is found, use this text.
-- @tparam[opt] string fontName The text's font, from `Fonts` folder.
-- @tparam[opt="left"] string align The text's horizontal alignment.
-- @tparam[opt=inf] number w The text's maximum width, in pixels.
-- @tparam[opt] Vector pos The text's top left.
function Button:createText(term, fallback, fontName, align, w, pos)
  if self.text then
    self.text:destroy()
  end
  fontName = fontName or 'menu_button'
  w = (w or self.window:cellWidth()) - self:iconWidth()
  if self.iconPos < 0.25 then
    pos = pos or Vector(self:iconWidth(), 0, 0)
  else
    pos = pos or Vector(0, 0, 0)
  end
  local text = TextComponent('', pos, w, align or 'left', Fonts[fontName])
  text:setTerm(term, fallback)
  text.sprite.alignY = 'center'
  text.sprite.maxHeight = self.window:cellHeight()
  text.sprite:setColor(Color.menu_text_enabled)
  text:redraw()
  self.text = text
  self.content:add(text)
  return self.text
end
--- Creates the secondary text.
-- @tparam string term The text term to be localized.
-- @tparam[opt] string fallback If no localization is found, use this text.
-- @tparam[opt=menu_button] string fontName The text's font, from `Fonts` folder.
-- @tparam[opt="right"] string align The text's horizontal alignment.
-- @tparam[opt=inf] number w The text's maximum width, in pixels.
-- @tparam[opt] Vector pos The text's top left.
function Button:createInfoText(term, fallback, fontName, align, w, pos)
  if self.infoText then
    self.infoText:destroy()
  end
  w = (w or self.window:cellWidth()) - self:iconWidth()
  if self.iconPos > 0.5 then
    -- Icon on the right.
    pos = pos or Vector(self.window:cellWidth() - w - self:iconWidth(), 0, 0)
  else
    -- Icon on the left.
    pos = pos or Vector(self.window:cellWidth() - w, 0, 0)
  end
  fontName = fontName or 'menu_button'
  local text = TextComponent('', pos, w, align or 'right', Fonts[fontName])
  text:setTerm(term, fallback)
  text.sprite.alignY = 'center'
  text.sprite.maxHeight = self.window:cellHeight()
  text.sprite:setColor(Color.menu_text_enabled)
  text:redraw()
  self.infoText = text
  self.content:add(text)
  return text
end

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Gets the width of the space reserved for the icon.
-- @treturn number
function Button:iconWidth()
  if self.icon then
    local x1, y1, x2, y2 = self.icon.sprite:getBoundingBox()
    return x2 - x1
  else
    return 0
  end
end
--- Sets the main text.
-- @param ... Parameters from TextComponent:setText.
function Button:setText(...)
  self.text:setText(...)
  self.text:redraw()
end
--- Sets the main text's term.
-- @param ... Parameters from TextComponent:setTerm.
function Button:setTerm(...)
  self.text:setTerm(...)
  self.text:redraw()
end
--- Sets the secondary text.
-- @param ... Parameters from TextComponent:setText.
function Button:setInfoText(...)
  self.infoText:setText(...)
  self.infoText:redraw()
end
--- Sets the secondary text's term.
-- @param ... Parameters from TextComponent:setTerm.
function Button:setInfoTerm(...)
  self.infoText:setTerm(...)
  self.infoText:redraw()
end
--- Sets the button's icon.
-- @tparam table|Animation icon Icon's data (with `id`, `row` and `col`) or the Animation.
function Button:setIcon(icon)
  if self.icon then
    self.icon:destroy()
    self.icon = nil
  end
  if not icon then
    return
  end
  if icon.id then
    if icon.id < 0 then
      return
    end
    icon = ResourceManager:loadIconAnimation(icon, MenuManager.renderer)
  end
  icon.sprite:setXYZ(0, 0)
  local x, y, x2, y2 = icon.sprite:getBoundingBox()
  x = -x + (self.window:cellWidth() - (x2 - x)) * self.iconPos
  if self.text then
    _, y = self.text:getTextCenter()
  else
    y = self.window:cellHeight() / 2
  end
  self.icon = ImageComponent(icon, Vector(x, y))
  self.icon:setColor(Color.menu_icon_enabled)
  self.content:add(self.icon)
end

-- ------------------------------------------------------------------------------------------------
-- State
-- ------------------------------------------------------------------------------------------------

--- Refreshes color, position and visibility.
function Button:refreshState()
  self:refreshColor()
  self:updatePosition(self.window.position)
  self:hide()
  if self.window.open then
    self:show()
  end
end
--- Updates text and icon color based on button state.
function Button:refreshColor()
  local name = self.enabled and 'enabled' or 'disabled'
  if self.text then
    local color = Color['menu_text_' .. name]
    self.text.sprite:setColor(color)
  end
  if self.infoText then
    local color = Color['menu_text_' .. name]
    self.infoText.sprite:setColor(color)
  end
  if self.icon then
    local color = Color['menu_icon_' .. name]
    self.icon:setColor(color)
  end
end
--- Updates enabled state based on the enable condition function.
function Button:refreshEnabled()
  if self.enableCondition then
    self:setEnabled(self.enableCondition(self.window, self))
  end
end
--- Enables/disables this button.
-- @tparam boolean value True to enable, false to disable.
function Button:setEnabled(value)
  if value ~= self.enabled then
    self.enabled = value
    self:refreshColor()
  end
end
--- Selects/deselects this button.
-- @tparam boolean value
function Button:setSelected(value)
  if value ~= self.selected then
    self.selected = value
    if self.enabled then
      self:refreshColor()
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Visibility
-- ------------------------------------------------------------------------------------------------

function Button:setVisible(value)
  if self.icon then
    self.icon:setVisible(value)
  end
  Component.setVisible(self, value)
end
--- Shows button's text and icon.
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
-- For debugging.
function Button:__tostring()
  if not self.text then
    return '' .. self.index
  end
  return self.index .. ': ' .. self.text.text
end

return Button
