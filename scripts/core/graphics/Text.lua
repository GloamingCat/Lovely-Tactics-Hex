
--[[===============================================================================================

Text
---------------------------------------------------------------------------------------------------
A special type of Sprite which texture if a rendered text.

=================================================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')
local TextParser = require('core/graphics/TextParser')
local TextRenderer = require('core/graphics/TextRenderer')

-- Alias
local lgraphics = love.graphics
local Quad = lgraphics.newQuad
local max = math.max
local min = math.min
local round = math.round

-- Constants
local defaultFont = Fonts.gui_default

local Text = class(Sprite)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(text : string) The rich text.
-- @param(resources : table) Table of resources used in text.
-- @param(renderer : Renderer) The destination renderer of the sprite.
-- @param(properties : table) The table with text properties:
--  (properties[1] : number) The width of the text box;
--  (properties[2] : string) The align type (left, right or center) 
--    (optional, left by default);
--  (properties[3] : number) The initial font 
--    (if nil, uses defaultFont).
function Text:init(text, properties, renderer)
  Sprite.init(self, renderer)
  assert(text, 'Nil text')
  self.maxWidth = properties[1]
  self.alignX = properties[2] or 'left'
  self.alignY = 'top'
  self.defaultFont = properties[3] or defaultFont
  self.plainText = properties[4]
  self.wrap = false
  self:setText(text)
end
-- Sets/changes the text content.
-- @param(text : string) The rich text.
function Text:setText(text)
  assert(text, 'Nil text')
  if text == '' then
    self.text = text
    self.lines = nil
    self.events = nil
    return
  end
  local maxWidth = self.wrap and (self.maxWidth / self.scaleX)
  local fragments = TextParser.parse(text, self.plainText)
  local lines, events = TextParser.createLines(fragments, self.defaultFont, maxWidth)
  self.parsedLines = lines
  self.events = events
  self:redrawBuffers()
end
-- Redraws each line buffer.
function Text:redrawBuffers()
  local lines = self.parsedLines
  if self.cutPoint then
    lines = TextParser.cutText(lines, self.cutPoint)
  end
  self.lines = TextRenderer.createLineBuffers(lines)
  local width, height = 0, 0
  for i = 1, #self.lines do
    width = max(self.lines[i].buffer:getWidth(), width)
    height = height + self.lines[i].height
  end
  self.quad = Quad(0, 0, width, height, width, height)
  self:recalculateBox()
  self.renderer.needsRedraw = true
end

---------------------------------------------------------------------------------------------------
-- Visibility
---------------------------------------------------------------------------------------------------

-- Checks if sprite is visible on screen.
-- @ret(boolean)
function Text:isVisible()
  return self.lines and self.visible
end

---------------------------------------------------------------------------------------------------
-- Bounds
---------------------------------------------------------------------------------------------------

-- @ret(number) The total width in world coordinates.
function Text:getWidth()
  local w = 0
  for i = 1, #self.lines do
    local line = self.lines[i]
    w = max(w, line.buffer:getWidth() / Fonts.scale)
  end
  return w
end
-- @ret(number) The total height in world coordinates.
function Text:getHeight()
  local h = 0
  for i = 1, #self.lines do
    local line = self.lines[i]
    h = h + line.buffer:getHeight() / 1.5 / Fonts.scale
  end
  return h
end
-- Total bounds in world coordinates.
-- @ret(number) Width.
-- @ret(number) Height.
function Text:quadBounds()
  return self:getWidth(), self:getHeight()
end

---------------------------------------------------------------------------------------------------
-- Alignment
---------------------------------------------------------------------------------------------------

-- Sets maximum line width. If wrap is set as true, new lines will be created to accomodate text 
-- out of width limit. Else, the line that surpasses width limit is shrinked horizontally to fit.
-- @param(w : number) Maximum width in GUI pixel coordinates.
function Text:setMaxWidth(w)
  if self.maxWidth ~= w then
    self.maxWidth = w
    if self.alignX ~= 'left' then
      self.renderer.needsRedraw = true
    end
  end
end
-- Sets maximum text box height. It is used only to set vertical alignment.
-- @param(h : number) Maximum height in GUI pixel coordinates.
function Text:setMaxHeight(h)
  if self.maxHeight ~= h then
    self.maxHeight = h
    if self.alignY ~= 'top' then
      self.renderer.needsRedraw = true
    end
  end
end
-- Sets text alingment relative to its maximum width.
-- @param(align : string) Horizontal alignment type (left, right, center).
function Text:setAlignX(align)
  if self.alignX ~= align then
    self.alignX = align
    self.renderer.needsRedraw = true
  end
end
-- Sets text alignment relative to its maximum height.
-- @param(align : string) Vertical alignment type (top, bottom, center).
function Text:setAlignY(align)
  if self.alignY ~= align then
    self.alignY = align
    self.renderer.needsRedraw = true
  end
end
-- Gets the line offset in x according to the alignment.
-- @param(w : number) Line's width in GUI pixels.
-- @ret(number) The x offset in GUI pixels.
function Text:alignOffsetX(w)
  if self.maxWidth then
    if self.alignX == 'right' then
      return self.maxWidth - w
    elseif self.alignX == 'center' then
      return (self.maxWidth - w) / 2
    end
  end
  return 0
end
-- Gets the text box offset in y according to the alingment.
-- @param(h : number) Text's height in GUI pixels (optional, sum of all lines' heights by default).
-- @ret(number) The y offset in GUI pixels.
function Text:alignOffsetY(h)
  h = h or self:getHeight()
  if self.maxHeight then
    if self.alignY == 'bottom' then
      return self.maxHeight - h
    elseif self.alignY == 'center' then
      return (self.maxHeight - h) / 2
    end
  end
  return 0
end

---------------------------------------------------------------------------------------------------
-- Draw in screen
---------------------------------------------------------------------------------------------------

-- Called when renderer is iterating through its rendering list.
-- @param(renderer : Renderer)
function Text:draw(renderer)
  renderer:clearBatch()
  local sx, sy, lsx = self.scaleX / Fonts.scale, self.scaleY / Fonts.scale
  local rsx = ScreenManager.scaleX * renderer.scaleX
  local rsy = ScreenManager.scaleY * renderer.scaleY
  local x, y = 0, self:alignOffsetY() - 0.5
  local r, g, b, a
  for i = 1, #self.lines do
    local line = self.lines[i]
    local w = line.buffer:getWidth() * sx
    if self.maxWidth and w > self.maxWidth then
      lsx = self.maxWidth / line.buffer:getWidth()
      x = 0
    else
      lsx = sx
      x = self:alignOffsetX(w)
    end
    local shader = lgraphics.getShader()
    lgraphics.setShader()
    r, g, b, a = lgraphics.getColor()
    lgraphics.setColor(self.color.red, self.color.green, self.color.blue, self.color.alpha)
    lgraphics.draw(line.buffer, line.quad, 
      round((self.position.x + x) * rsx), round((self.position.y + y) * rsy), 
      self.rotation, lsx * rsx, sy * rsy, self.offsetX, self.offsetY)
    lgraphics.setColor(r, g, b, a)
    y = y + line.height * sy
    lgraphics.setShader(shader)
  end
end
-- Called when the scale of screen changes.
-- @param(renderer : Renderer) The renderer that is drawing this text.
function Text:rescale(renderer)
  self:redrawBuffers()
end

return Text
