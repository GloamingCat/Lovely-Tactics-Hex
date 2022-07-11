
--[[===============================================================================================

TextRenderer
---------------------------------------------------------------------------------------------------
Module to create each rendered line of text.

=================================================================================================]]

-- Alias
local lgraphics = love.graphics
local Quad = lgraphics.newQuad

-- Constants
local textShader = love.graphics.newShader('shaders/Text.glsl')
textShader:send('outlineSize', Fonts.outlineSize / Fonts.scale)

local TextRenderer = {}

---------------------------------------------------------------------------------------------------
-- Final Buffer
---------------------------------------------------------------------------------------------------

-- Creates the image buffers of each line.
-- @param(lines : table) Array of parsed lines.
function TextRenderer.createLineBuffers(lines)
  -- Previous graphics state
  local r, g, b, a = lgraphics.getColor()
  local shader = lgraphics.getShader()
  local canvas = lgraphics.getCanvas()
  local font = lgraphics.getFont()
  -- Render lines individually
  lgraphics.setColor(1, 1, 1, 1)
  TextRenderer.underlined = false
	local renderedLines = {}
  for i = 1, #lines do
    lgraphics.setShader()
    local buffer = TextRenderer.createLineBuffer(lines[i])
    lgraphics.setShader(textShader)
    local shadedBuffer = TextRenderer.shadeBuffer(buffer)
    local w, h = shadedBuffer:getWidth(), shadedBuffer:getHeight()
    renderedLines[i] = {
      buffer = shadedBuffer,
      height = lines[i].height,
      quad = Quad(0, 0, w, h, w, h) }
	end
  -- Reset graphics state
  lgraphics.setColor(r, g, b, a)
  lgraphics.setFont(font)
  lgraphics.setShader(shader)
  lgraphics.setCanvas(canvas)
  return renderedLines
end
-- Renders texture with the shader in a buffer with the correct size.
-- @param(texture : Canvas) Unshaded rendered text.
-- @ret(Canvas) Pre-shaded texture.
function TextRenderer.shadeBuffer(texture)
  local w, h = texture:getWidth(), texture:getHeight()
  local newTexture = lgraphics.newCanvas(w, h)
  newTexture:setFilter('linear', 'linear')
  lgraphics.setCanvas(newTexture)
  local stepX = 1 / math.pow(2, ScreenManager.scaleX - 1)
  local stepY = 1 / math.pow(2, ScreenManager.scaleY)
  textShader:send('stepSize', { stepX, stepY })
  textShader:send('pixelSize', { Fonts.outlineSize / w, Fonts.outlineSize / h })
  --lgraphics.setBlendMode('alpha', 'premultiplied')
  lgraphics.draw(texture)
  --lgraphics.setBlendMode('alpha')
  return newTexture
end

---------------------------------------------------------------------------------------------------
-- Individual buffers
---------------------------------------------------------------------------------------------------

-- Draw the image buffer of a single line.
-- The size of the buffer image is Fonts.scale * size of the text in-game.
-- @param(line : table) A list of text fragments.
-- @ret(Canvas) Rendered line.
function TextRenderer.createLineBuffer(line)
  local buffer = lgraphics.newCanvas(line.width + Fonts.outlineSize * 2, line.height * 1.5)
  buffer:setFilter('linear', 'linear')
  lgraphics.setCanvas(buffer)
  lgraphics.setLineWidth(Fonts.scale)
  local x, y = Fonts.outlineSize, line.height
  for j = 1, #line do
    local fragment = line[j]
    local t = type(fragment.content)
    if fragment.width then
      -- Drawable
      if t == 'string' then
        -- Print text
        if fragment.content ~= '' then
          lgraphics.print(fragment.content, x, y - fragment.height)
          if TextRenderer.underlined then
            lgraphics.line(x, y, x + fragment.width, y)
          end
        end
      elseif t == 'userdata' then
        -- Print sprite
        lgraphics.draw(fragment.content, fragment.quad, x, y - fragment.height, 0, Fonts.scale, Fonts.scale)
      end
      x = x + fragment.width
    else
      -- Settings
      if t == 'string' then
        -- Flags
        if fragment.content == 'underline' then
          TextRenderer.underlined = not TextRenderer.underlined
        end
      elseif t == 'table' then
        -- Color
        local c = fragment.content
        lgraphics.setColor(c.red, c.green, c.blue, c.alpha)
      elseif t == 'userdata' then
        -- Font
        lgraphics.setFont(fragment.content)
      end
    end
  end
  return buffer
end

return TextRenderer
