
-- ================================================================================================

--- A special type of Sprite which texture if a rendered text.
---------------------------------------------------------------------------------------------------
-- @classmod Text

-- ================================================================================================

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

-- Class table.
local Text = class(Sprite)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam string text The rich text.
-- @tparam table properties The table with text properties:
--  (properties[1] : number) The width of the text box;
--  (properties[2] : string) The align type (left, right or center) 
--    (optional, left by default);
--  (properties[3] : number) The initial font 
---    (if nil, uses defaultFont).
-- @tparam Renderer renderer The destination renderer of the sprite.
function Text:init(text, properties, renderer)
  Sprite.init(self, renderer)
  assert(text, 'Nil text')
  self.maxWidth = properties[1]
  self.alignX = properties[2] or 'left'
  self.alignY = 'top'
  self.defaultFont = properties[3] or Fonts.gui_default
  self.plainText = properties[4]
  self.wrap = false
  self:setText(text)
end
--- Sets/changes the text content.
-- @tparam string text The rich text.
function Text:setText(text)
  assert(text, 'Nil text')
  self.text = text
  self.renderer.needsRedraw = true
  if text == '' then
    self.lines = ''
    self.events = nil
    self.parsedLines = nil
  else
    local sx = ScreenManager.scaleX * self.renderer.scaleX
    local maxWidth = self.wrap and (self.maxWidth / self.scaleX)
    local fragments = TextParser.parse(text, self.plainText)
    local lines, events = TextParser.createLines(fragments, self.defaultFont, maxWidth, sx)
    assert(lines, "Couldn't parse lines: " .. tostring(text))
    self.parsedLines = lines
    self.lines = lines
    self.events = events
    self:recalculateBox()
  end
end
--- Sets the point in which the text is cut (not rendered).
-- @tparam number cutPoint The index of the last character.
function Text:setCutPoint(cutPoint)
  self.renderer.needsRedraw = true
  self.cutPoint = cutPoint
  if self.cutPoint and self.parsedLines then
    self.lines = TextParser.cutText(self.parsedLines, self.cutPoint - 1)
  else
    self.lines = self.parsedLines
  end
end
--- Called when the scale of screen changes.
-- @tparam Renderer renderer The renderer that is drawing this text.
function Text:rescale(renderer)
  if not self.parsedLines then
    return
  end
  local s = ScreenManager.scaleX * renderer.scaleX
  for _, line in ipairs(self.parsedLines) do
    for _, f in ipairs(line) do
      if f.info then
        f.content = ResourceManager:loadFont(f.info, s)
      end
      if f.width then
        f.width = f.width / self.parsedLines.scale * s
      end
      if f.height then
        f.height = f.height / self.parsedLines.scale * s
      end
    end
    line.width = line.width / self.parsedLines.scale * s
    line.height = line.height / self.parsedLines.scale * s
  end
  self.parsedLines.scale = s
  self:recalculateBox()
end

-- ------------------------------------------------------------------------------------------------
-- Visibility
-- ------------------------------------------------------------------------------------------------

--- Checks if sprite is visible on screen.
-- @treturn boolean
function Text:isVisible()
  return self.lines and self.visible
end

-- ------------------------------------------------------------------------------------------------
-- Bounds
-- ------------------------------------------------------------------------------------------------

-- @treturn number The total width in world coordinates.
function Text:getWidth()
  local w = 0
  if self.parsedLines then
    for i, line in ipairs(self.parsedLines) do
      w = max(w, line.width)
    end
    w = w / self.parsedLines.scale
  end
  return w
end
-- @treturn number The total height in world coordinates.
function Text:getHeight()
  local h = 0
  if self.parsedLines then
    for i, line in ipairs(self.parsedLines) do
      h = h + line.height
    end
    h = h / self.parsedLines.scale
  end
  return h
end
--- Total bounds in world coordinates.
-- @treturn number Width.
-- @treturn number Height.
function Text:quadBounds()
  return self:getWidth(), self:getHeight()
end

-- ------------------------------------------------------------------------------------------------
-- Alignment
-- ------------------------------------------------------------------------------------------------

--- Sets maximum line width. If wrap is set as true, new lines will be created to accomodate text 
-- out of width limit. Else, the line that surpasses width limit is shrinked horizontally to fit.
-- @tparam number w Maximum width in GUI pixel coordinates.
function Text:setMaxWidth(w)
  if self.maxWidth ~= w then
    self.maxWidth = w
    if self.alignX ~= 'left' then
      self.renderer.needsRedraw = true
    end
  end
end
--- Sets maximum text box height. It is used only to set vertical alignment.
-- @tparam number h Maximum height in GUI pixel coordinates.
function Text:setMaxHeight(h)
  if self.maxHeight ~= h then
    self.maxHeight = h
    if self.alignY ~= 'top' then
      self.renderer.needsRedraw = true
    end
  end
end
--- Sets text alingment relative to its maximum width.
-- @tparam string align Horizontal alignment type (left, right, center).
function Text:setAlignX(align)
  if self.alignX ~= align then
    self.alignX = align
    self.renderer.needsRedraw = true
  end
end
--- Sets text alignment relative to its maximum height.
-- @tparam string align Vertical alignment type (top, bottom, center).
function Text:setAlignY(align)
  if self.alignY ~= align then
    self.alignY = align
    self.renderer.needsRedraw = true
  end
end
--- Gets the line offset in x according to the alignment.
-- @tparam number w Line's width in GUI pixels.
-- @treturn number The x offset in GUI pixels.
function Text:alignOffsetX(w)
  w = w or self:getWidth()
  if self.maxWidth then
    if self.alignX == 'right' then
      return self.maxWidth - w
    elseif self.alignX == 'center' then
      return (self.maxWidth - w) / 2
    end
  end
  return 0
end
--- Gets the text box offset in y according to the alingment.
-- @tparam number h Text's height in GUI pixels (optional, sum of all lines' heights by default).
-- @treturn number The y offset in GUI pixels.
function Text:alignOffsetY(h)
  h = h or self:getHeight()
  if self.maxHeight then
    if self.alignY == 'bottom' then
      return self.maxHeight - h
    elseif self.alignY == 'center' then
      return (self.maxHeight - h) / 2 - 1
    end
  end
  return 0
end

-- ------------------------------------------------------------------------------------------------
-- Draw in screen
-- ------------------------------------------------------------------------------------------------

--- Called when renderer is iterating through its rendering list.
-- @tparam Renderer renderer
function Text:draw(renderer)
  renderer:clearBatch()
  local r, g, b, a = lgraphics.getColor()
  local shader = lgraphics.getShader()
  lgraphics.setColor(self.color.red, self.color.green, self.color.blue, self.color.alpha)
  lgraphics.setShader()
  lgraphics.push()
  local sx = ScreenManager.scaleX * renderer.scaleX
  local sy = ScreenManager.scaleY * renderer.scaleY
  lgraphics.translate(-self.offsetX, -self.offsetY)
  lgraphics.scale(self.scaleX, self.scaleY)
  lgraphics.rotate(self.rotation)
  lgraphics.translate(self.position.x * sx, self.position.y * sy)
  self:drawLines(sx, sy)
  lgraphics.pop()
  lgraphics.setColor(r, g, b, a)
  lgraphics.setShader(shader)
end
--- Prints parsed lines in the current graphics context.
-- All fragments are assumed to have pre-multiplied width/height.
-- @tparam number sx Scale x.
-- @tparam number sy Scale y.
function Text:drawLines(sx, sy)
  local w, h = self:quadBounds()
  local y = self:alignOffsetY(h) * sy
  local shrink = 1
  for i, line in ipairs(self.lines) do
    y = y + line.height
    local x = 0
    if self.maxWidth and w > self.maxWidth then
      shrink = self.maxWidth / w
    else
      shrink = 1
      x = self:alignOffsetX(w) * sx
    end
    local drawCalls = TextRenderer.drawLine(line, x, y, self.color)
    self.renderer.textDraws = self.renderer.textDraws + drawCalls
  end
end

return Text
