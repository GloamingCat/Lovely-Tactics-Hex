
--[[===============================================================================================

SimpleText
---------------------------------------------------------------------------------------------------
A simple content element for GUI window containing just a text.
It's a type of window content.

=================================================================================================]]

-- Imports
local Component = require('core/gui/Component')
local Sprite = require('core/graphics/Sprite')
local Text = require('core/graphics/Text')

local SimpleText = class(Component)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(text : string) The text content (not rich text).
-- @param(position : Vector) Position relative to its window (optional).
-- @param(width : number) The max width for texto box (optional).
-- @param(align : string) Alignment inside the box (optional, left by default).
-- @param(font : string) Font of the text (optional).
-- @param(plainText : boolean) Disable text commands (optional, false by default).
function SimpleText:init(text, position, width, align, font, plainText)
  assert(text, 'Nil text')
  local properties = { width, align or 'left', font or Fonts.gui_default, plainText}
  Component.init(self, position, text, properties)
end
-- Implements Component:createContent.
-- @param(text : string) Initial text, in raw form.
-- @param(properties : table) Array with text properties in order:
--  Maximum width, horizontal alignment, initial font.
function SimpleText:createContent(text, properties)
  self.sprite = Text(text .. '', properties, GUIManager.renderer)
  self.text = text
  self.content:add(self.sprite)
end

---------------------------------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------------------------------

-- Sets the position relative to window's center.
-- @param(x : number) Pixel x.
-- @param(y : number) Pixel y.
-- @param(z : number) Depth.
function SimpleText:setRelativeXYZ(x, y, z)
  local pos = self.position
  pos.x = pos.x or x
  pos.y = pos.y or y
  pos.z = pos.z or z
end
-- Overrides Component:updatePosition.
-- @param(pos : Vector) Window position.
function SimpleText:updatePosition(pos)
  local rpos = self.position
  self.sprite:setXYZ(pos.x + rpos.x, pos.y + rpos.y, pos.z + rpos.z)
end
-- Gets the center of the text sprite, considering alignment.
-- @ret(number) Pixel x of the center.
-- @ret(number) Pixel y of the center.
function SimpleText:getCenter()
  local w, h = self.sprite:quadBounds()
  local x = self.sprite:alignOffsetX(w)
  local y = self.sprite:alignOffsetY(h)
  return self.position.x + x + w / 2, self.position.y + y + h / 2
end

---------------------------------------------------------------------------------------------------
-- Text
---------------------------------------------------------------------------------------------------

-- Changes text content (must be redrawn later).
-- @param(text : string) The new text content.
function SimpleText:setText(text)
  self.term = nil
  self.fallback = nil
  self.text = text
end
-- Changes text content from a given localization term (must be redrawn later).
-- @param(term : string) The localization term.
-- @param(fallback : string) The text shown if localization fails (optional, uses term by default).
function SimpleText:setTerm(term, fallback)
  if fallback then
    self.fallback = fallback
    if not term:find("%%") then    
      self.term = "{%" .. term .. "}"
    else
      self.term = term
    end
  else
    self:setText(term)
  end
end
-- Sets max width (must be redrawn later).
-- @param(w : number)
function SimpleText:setMaxWidth(w)
  self.sprite.maxWidth = w
end
-- Sets max height (must be redrawn later).
-- @param(h : number)
function SimpleText:setMaxHeight(h)
  self.sprite.maxHeight = h
end
-- Sets text alignment (must be redrawn later).
-- @param(h : string) Horizontal alignment.
-- @param(v : string) Vertical alignment.
function SimpleText:setAlign(h, v)
  self.sprite.alignX = h or 'left'
  self.sprite.alignY = v or 'top'
end
-- Redraws text buffer.
function SimpleText:redraw()
  if self.term then
    if pcall(self.sprite.setText, self.sprite, self.term) then
      self.text = self.term
    else
      self.text = self.fallback
      self.sprite:setText(self.fallback)
    end
  else
    self.sprite:setText(self.text)
  end
end
-- Redraws text buffer.
function SimpleText:refresh()
  Component.refresh(self)
  if self.term then
    self:redraw()
  end
end

return SimpleText
