
--[[===============================================================================================

@script Text Outline
---------------------------------------------------------------------------------------------------
-- Renders text with a black outline.
-- 
-- Plugin parameters:
--  * Use <width> to set the outline thickness (in pixels).

=================================================================================================]]

-- Imports
local Text = require('core/graphics/Text')
local TextRenderer = require('core/graphics/TextRenderer')

-- Alias
local lgraphics = love.graphics
local Quad = lgraphics.newQuad
local max = math.max
local round = math.round

-- Parameters
local outlineSize = args.width or 1

local textShader = lgraphics.newShader('shaders/Text.glsl')

-- ------------------------------------------------------------------------------------------------
-- Redraw
-- ------------------------------------------------------------------------------------------------

local Text_setText = Text.setText
function Text:setText(...)
  self.bufferLines = nil
  self.needsRedraw = true
  Text_setText(self, ...)
end
local Text_rescale = Text.rescale
function Text:rescale(...)
  self.needsRedraw = true
  Text_rescale(self, ...)
end
local Text_setCutPoint = Text.setCutPoint
function Text:setCutPoint(...)
  self.bufferLines = nil
  self.needsRedraw = true
  Text_setCutPoint(self, ...)
end

-- ------------------------------------------------------------------------------------------------
-- Visibility
-- ------------------------------------------------------------------------------------------------

--- Override. Include bufferLines.
function Text:isVisible()
  return (self.bufferLines or self.lines) and self.visible
end

-- ------------------------------------------------------------------------------------------------
-- Draw in screen
-- ------------------------------------------------------------------------------------------------

--- Called when renderer is iterating through its rendering list.
-- @tparam number sx Scale X.
-- @tparam number sy Scale Y.
function Text:drawLines(sx, sy)
  if self.needsRedraw then
    local drawCalls = self:redrawBuffers(sx, sy)
    self.renderer.textDraws = self.renderer.textDraws + drawCalls
  end
  local h = self:getHeight()
  local y = self:alignOffsetY(h) * sy
  local shrink = 1
  for i = 1, #self.bufferLines do
    local line = self.bufferLines[i]
    local w = line.width / sx
    local x = 0
    if self.maxWidth and w > self.maxWidth then
      shrink = self.maxWidth / w
    else
      shrink = 1
      x = self:alignOffsetX(w) * sx
    end
    lgraphics.draw(line.buffer, 
      round(x - (line.buffer:getWidth() - line.width) / 2), 
      round(y - (line.buffer:getHeight() / 1.5 - line.height) / 2), 
      0, shrink, 1)
    y = y + line.height
    self.renderer.textDraws = self.renderer.textDraws + 1
  end
end
--- Redraws each line buffer.
-- @tparam number sx Scale X.
-- @tparam number sy Scale Y.
function Text:redrawBuffers(sx, sy)
  lgraphics.push()
  lgraphics.origin()
  local drawCalls = 0
  self.bufferLines, drawCalls = TextRenderer.createLineBuffers(self.lines, sx, sy)
  local width, height = 0, 0
  for i = 1, #self.bufferLines do
    width = max(self.bufferLines[i].buffer:getWidth(), width)
    height = height + self.bufferLines[i].height
  end
  self.needsRedraw = false
  lgraphics.pop()
  return drawCalls
end

-- ------------------------------------------------------------------------------------------------
-- Text Renderer
-- ------------------------------------------------------------------------------------------------

--- Creates the image buffers of each line.
-- @tparam table lines Array of parsed lines.
-- @tparam number sx Scale X.
-- @tparam number sy Scale Y.
-- @treturn table Array of line image buffers.
-- @treturn number Draw calls (for debugginf).
function TextRenderer.createLineBuffers(lines, sx, sy)
  -- Previous graphics state
  local r, g, b, a = lgraphics.getColor()
  local shader = lgraphics.getShader()
  local canvas = lgraphics.getCanvas()
  local font = lgraphics.getFont()
  -- Render lines individually
  lgraphics.setColor(1, 1, 1, 1)
  TextRenderer.underlined = false
  local drawCalls = 0
	local renderedLines = {}
  for i = 1, #lines do
    lgraphics.setShader()
    local buffer = lgraphics.newCanvas(lines[i].width + outlineSize * sx * 2, lines[i].height * 1.5 + outlineSize * sy * 2)
    buffer:setFilter('linear', 'linear')
    lgraphics.setCanvas(buffer)
    lgraphics.setLineWidth(sy)
    drawCalls = drawCalls + TextRenderer.drawLine(lines[i], outlineSize * sx, lines[i].height + outlineSize * sy, Color.white)
    lgraphics.setShader(textShader)
    local shadedBuffer = TextRenderer.shadeBuffer(buffer, sx, sy)
    drawCalls = drawCalls + 1
    renderedLines[i] = {
      buffer = shadedBuffer,
      height = lines[i].height,
      width = lines[i].width }
	end
  -- Reset graphics state
  lgraphics.setColor(r, g, b, a)
  lgraphics.setFont(font)
  lgraphics.setShader(shader)
  lgraphics.setCanvas(canvas)
  return renderedLines, drawCalls
end
--- Renders texture with the shader in a buffer with the correct size.
-- @tparam Canvas texture Unshaded rendered text.
-- @tparam number sx Scale X.
-- @tparam number sy Scale Y.
-- @treturn Canvas Pre-shaded texture.
function TextRenderer.shadeBuffer(texture, sx, sy)
  local r, g, b, a = lgraphics.getColor()
  lgraphics.setColor(1, 1, 1, 1)
  local shader = lgraphics.getShader()
  local w, h = texture:getWidth(), texture:getHeight()
  local newTexture = lgraphics.newCanvas(w, h)
  newTexture:setFilter('linear', 'linear')
  lgraphics.setCanvas(newTexture)
  local stepX = 1 / (sx * sx)
  local stepY = 1 / (sy * sy)
  textShader:send('stepSize', { stepX, stepY })
  textShader:send('pixelSize', { outlineSize * 0.8 * sx / w, outlineSize * 0.8 * sy / h })
  textShader:send('outlineSize', { outlineSize * 0.8, outlineSize * 0.8 })
  --lgraphics.setBlendMode('alpha', 'premultiplied')
  lgraphics.draw(texture)
  --lgraphics.rectangle('line', 0, 0, w-1, h-1)
  --lgraphics.setBlendMode('alpha')
  lgraphics.setColor(r, g, b, a)
  return newTexture
end
