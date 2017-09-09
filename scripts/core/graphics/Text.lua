
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
local round = math.round

-- Constants
local defaultFont = Font.gui_default

local Text = class(Sprite)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(text : string) the rich text
-- @param(resources : table) table of resources used in text
-- @param(renderer : Renderer) the destination renderer of the sprite
-- @param(properties : table) the table with text properties:
--  (properties[1] : number) the width of the text box
--  (properties[2] : string) the align type (left, right or center) 
--    (optional, left by default)
--  (properties[3] : number) the max number of characters that will be shown 
--    (optional, no limit by default)
local old_init = Text.init
function Text:init(text, resources, properties, renderer)
  old_init(self, renderer)
  self.maxWidth = properties[1] and (properties[1] + 1)
  self.align = properties[2] or self.align or 'left'
  self.maxchar = properties[3] or self.maxchar
  self.text = text
  self.scaleX = 1 / Font.scale
  self.scaleY = 1 / Font.scale
  self.offsetX = 0
  self.offsetY = 0

  self:setHSV(1, 1, 1)

  if text == nil or text == '' then
    self.lines = {}
  else
    self:setText(text, resources)
  end
end
-- Sets/changes the text content.
-- @param(text : string) the rich text
-- @param(resources : table) table of resources used in text
function Text:setText(text, resources)
  local fragments = TextParser.parse(text, resources)
	local lines = TextParser.createLines(fragments, defaultFont, self.maxWidth)
  self.lines = TextRenderer.createLineBuffers(lines, defaultFont)
  local width, height = 0, 0
  for i = 1, #self.lines do
    width = max(self.lines[i].buffer:getWidth(), width)
    height = height + self.lines[i].height
  end
  self.quad = Quad(0, 0, width, height, width, height)
  self.renderer.needsRedraw = true
end

---------------------------------------------------------------------------------------------------
-- Draw in screen
---------------------------------------------------------------------------------------------------

-- Gets the line offset in x according to the alingment.
-- @param(w : number) line's width
-- @ret(number) the x offset
function Text:alignOffset(w)
  if self.maxWidth then
    if self.align == 'right' then
      return self.maxWidth - w
    elseif self.align == 'center' then
      return (self.maxWidth - w) / 2
    end
  end
  return 0
end
-- Called when renderer is iterating through its rendering list.
-- @param(renderer : Renderer)
function Text:draw(renderer)
  renderer:clearBatch()
  local ox, oy = 0, -Font.scale
  local r, g, b, a
  for i = 1, #self.lines do
    local line = self.lines[i]
    local shader = lgraphics.getShader()
    r, g, b, a = lgraphics.getColor()
    lgraphics.setShader()
    ox = self:alignOffset(line.buffer:getWidth() / Font.scale) * Font.scale
    lgraphics.setColor(self.color.red, self.color.green, self.color.blue, self.color.alpha)
    lgraphics.draw(line.buffer, line.quad, self.position.x, self.position.y, 
      self.rotation, self.scaleX, self.scaleY, self.offsetX - ox, self.offsetY - oy)
    lgraphics.setColor(r, g, b, a)
    lgraphics.setShader(shader)
    oy = oy + line.height
  end
end

return Text
