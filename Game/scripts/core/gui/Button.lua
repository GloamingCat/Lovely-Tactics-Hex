
--[[===============================================================================================

Button
---------------------------------------------------------------------------------------------------
A window button. It may have a text and an animated icon.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Animation = require('core/graphics/Animation')
local SimpleText = require('core/gui/SimpleText')
local GridWidget = require('core/gui/GridWidget')

local Button = class(GridWidget)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(window : GridWindow) the window that this button is component of
-- @param(index : number) the index of the button in the window
-- @param(col : number) the column of the button in the window
-- @param(row : number) the row of the button in the window
-- @param(text : string) the text shown in the button
-- @param(fontName : string) the text's font (from Fonts folder)
-- @param(iconAnim : Animation | string) the icon graphics or the path to the icon
-- @param(onConfirm : function) the function called when
--  player confirms (optinal)
-- @param(onCancel : function) the function called when
--  player cancels (optinal)
-- @param(onMove : function) the function called when 
--  player moves cursor (optional)
-- @param(enableCondition : function) the function that tells if 
--  this button is enabled (optional)
function Button:init(window, text, iconAnim, onConfirm, enableCondition, fontName)
  GridWidget.init(self, window, index)
  self.onConfirm = onConfirm or self.onConfirm
  self.enableCondition = enableCondition
  self:initializeContent(text, iconAnim, fontName)
end
-- Creates button basic content (text and icon).
function Button:initializeContent(text, iconAnim, fontName)
  if text ~= '' then
    local width = self.window:buttonWidth()
    self.textSprite = SimpleText(text, nil, width, nil, Font.gui_button)
    self.textSprite.sprite:setColor(Color.gui_text_default)
    self.content:add(self.textSprite)
  end
  if iconAnim ~= nil then
    if type(iconAnim) == 'string' then
      local img = love.graphics.newImage('images/' .. iconAnim)
      iconAnim = Animation.fromImage(img, GUIManager.renderer)
    end
    self.icon = iconAnim
    iconAnim.sprite:setColor(Color.gui_icon_default)
    self.content:add(iconAnim)
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

function Button:setText(text)
  self.textSprite:setText(text)
  self.textSprite:redraw()
end
-- Converting to string.
function Button:__tostring()
  if not self.textSprite then
    return '' .. self.index
  end
  return self.index .. ': ' .. self.textSprite.text
end

---------------------------------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------------------------------

-- Called when player presses "Confirm" on this button.
function Button.onConfirm(window, button)
  window.result = button.index
end
-- Called when player presses "Cancel" on this button.
function Button.onCancel(window, button)
  window.result = 0
end

---------------------------------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------------------------------

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

---------------------------------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------------------------------

-- Updates position based on window's position.
function Button:updatePosition(windowPos)
  local pos = self:relativePosition()
  pos:add(windowPos)
  if self.icon then
    self.icon.sprite:setPosition(pos)
    local x, y, w, h = self.icon.sprite:totalBounds()
    self.icon.sprite:setXYZ(nil, pos.y + (self.window:buttonHeight() - h) / 2)
    pos:add(Vector(w - (self.icon.sprite.position.x - x), 0))
  end
  if self.textSprite then
    pos.y = pos.y + 1
    self.textSprite.sprite:setPosition(pos)
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
    if not enabled then
      self:setEnabled(false)
    end
  end
  GridWidget.show(self)
end

return Button
