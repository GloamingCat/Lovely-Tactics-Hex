
-- ================================================================================================

--- A simple content element for Menu window containing just a text.
-- It's a type of window content.
---------------------------------------------------------------------------------------------------
-- @uimod TextComponent
-- @extend Component

-- ================================================================================================

-- Imports
local ImageComponent = require('core/gui/widget/ImageComponent')
local Text = require('core/graphics/Text')

-- Class table.
local TextComponent = class(ImageComponent)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam string text The text content (not rich text).
-- @tparam[opt] Vector position Position relative to its window. If nil, sets at the center of the window.
-- @tparam[opt=inf] number width The max width for text box.
-- @tparam[opt="left"] string align Alignment inside the box.
-- @tparam[opt=menu_default] Fonts.Info font Font of the text.
-- @tparam[opt] boolean plainText Flag to disable text commands.
function TextComponent:init(text, position, width, align, font, plainText)
  assert(text, 'Nil text')
  local properties = { width, align or 'left', font or Fonts.menu_default, plainText}
  ImageComponent.init(self, text, position, nil, nil, properties)
end
--- Overrides `ImageComponent:createContent`.
-- @implement
-- @tparam string text Initial text, in raw form.
-- @tparam Text.Properties properties Array with text properties.
function TextComponent:createContent(text, properties)
  self.sprite = Text(text .. '', properties, MenuManager.renderer)
  self.text = text
  self:updatePosition()
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
--- Gets the current sprite's text.
-- @treturn string
function TextComponent:getText()
  return self.sprite.text
end
--- Changes text content from a given localization term (must be redrawn later).
-- @tparam string term The localization term.
-- @tparam[opt=term] string fallback The text shown if localization fails.
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
--- Gets the center of the text sprite, considering alignment.
-- @treturn number Pixel x of the center.
-- @treturn number Pixel y of the center.
function TextComponent:getTextCenter()
  local _, _, w, h = self.sprite:getQuadBox()
  local x = self.sprite:alignOffsetX(w)
  local y = self.sprite:alignOffsetY(h)
  return self.position.x + x + w / 2, self.position.y + y + h / 2
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
  ImageComponent.refresh(self)
  if self.term then
    self:redraw()
  end
end

return TextComponent
