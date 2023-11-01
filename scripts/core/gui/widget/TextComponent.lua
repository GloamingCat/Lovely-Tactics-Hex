
-- ================================================================================================

--- A simple content element for Menu window containing just a text.
-- It's a type of window content.
---------------------------------------------------------------------------------------------------
-- @uimod TextComponent
-- @extend Component

-- ================================================================================================

-- Imports
local Component = require('core/gui/Component')
local Sprite = require('core/graphics/Sprite')
local Text = require('core/graphics/Text')

-- Class table.
local TextComponent = class(Component)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam string text The text content (not rich text).
-- @tparam Vector position Position relative to its window (optional).
-- @tparam number width The max width for texto box (optional).
-- @tparam string align Alignment inside the box (optional, left by default).
-- @tparam Fonts.Info font Font of the text (optional).
-- @tparam boolean plainText Disable text commands (optional, false by default).
function TextComponent:init(text, position, width, align, font, plainText)
  assert(text, 'Nil text')
  local properties = { width, align or 'left', font or Fonts.menu_default, plainText}
  Component.init(self, position, text, properties)
end
--- Implements `Component:createContent`.
-- @implement
-- @tparam string text Initial text, in raw form.
-- @tparam Text.Properties properties Array with text properties.
function TextComponent:createContent(text, properties)
  self.sprite = Text(text .. '', properties, MenuManager.renderer)
  self.text = text
  self.content:add(self.sprite)
  self:updatePosition()
end

-- ------------------------------------------------------------------------------------------------
-- Position
-- ------------------------------------------------------------------------------------------------

--- Sets the position relative to window's center.
-- @tparam number x Pixel x.
-- @tparam number y Pixel y.
-- @tparam number z Depth.
function TextComponent:setRelativeXYZ(x, y, z)
  local pos = self.position
  pos.x = pos.x or x
  pos.y = pos.y or y
  pos.z = pos.z or z
end
--- Overrides `Component:updatePosition`. 
-- @override
-- @tparam Vector pos Window position.
function TextComponent:updatePosition(pos)
  local rpos = self.position
  if pos then
    self.sprite:setXYZ(pos.x + rpos.x, pos.y + rpos.y, pos.z + rpos.z)
  else
    self.sprite:setXYZ(rpos.x, rpos.y, rpos.z)
  end
end
--- Gets the center of the text sprite, considering alignment.
-- @treturn number Pixel x of the center.
-- @treturn number Pixel y of the center.
function TextComponent:getCenter()
  local w, h = self.sprite:quadBounds()
  local x = self.sprite:alignOffsetX(w)
  local y = self.sprite:alignOffsetY(h)
  return self.position.x + x + w / 2, self.position.y + y + h / 2
end

-- ------------------------------------------------------------------------------------------------
-- Text
-- ------------------------------------------------------------------------------------------------

--- Changes text content (must be redrawn later).
-- @tparam string text The new text content.
function TextComponent:setText(text)
  self.term = nil
  self.fallback = nil
  self.text = text
end
--- Changes text content from a given localization term (must be redrawn later).
-- @tparam string term The localization term.
-- @tparam string fallback The text shown if localization fails (optional, uses term by default).
function TextComponent:setTerm(term, fallback)
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
--- Sets max width (must be redrawn later).
-- @tparam number w
function TextComponent:setMaxWidth(w)
  self.sprite.maxWidth = w
end
--- Sets max height (must be redrawn later).
-- @tparam number h
function TextComponent:setMaxHeight(h)
  self.sprite.maxHeight = h
end
--- Sets text alignment (must be redrawn later).
-- @tparam string h Horizontal alignment.
-- @tparam string v Vertical alignment.
function TextComponent:setAlign(h, v)
  self.sprite.alignX = h or 'left'
  self.sprite.alignY = v or 'top'
end
--- Redraws text buffer.
function TextComponent:redraw()
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
--- Redraws text buffer.
function TextComponent:refresh()
  Component.refresh(self)
  if self.term then
    self:redraw()
  end
end

return TextComponent
