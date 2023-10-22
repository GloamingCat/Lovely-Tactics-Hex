
-- ================================================================================================

--- Module to create each rendered line of text.
---------------------------------------------------------------------------------------------------
-- @module TextRenderer

-- ================================================================================================

-- Alias
local lgraphics = love.graphics
local Quad = lgraphics.newQuad

local TextRenderer = {}

-- ------------------------------------------------------------------------------------------------
-- Individual buffers
-- ------------------------------------------------------------------------------------------------

--- Draws a line of text in the current graphics context.
-- The size of the buffer image is Fonts.scale * size of the text in-game.
-- @tparam table line A list of text fragments.
-- @tparam number x The x position of the top left corner of the line.
-- @tparam number y The y position of the top left corner of the line.
-- @tparam Color.RGBA color The RGBA multiplier for this line.
-- @treturn number Number of draw calls (for profiling).
function TextRenderer.drawLine(line, x, y, color)
  local drawCalls = 0
  for j = 1, #line do
    local fragment = line[j]
    local t = type(fragment.content)
    if fragment.width then
      -- Drawable
      if t == 'string' then
        -- Print text
        drawCalls = drawCalls + TextRenderer.drawText(fragment, x, y)
      elseif t == 'userdata' then
        -- Print sprite
        drawCalls = drawCalls + TextRenderer.drawSprite(fragment, x, y)
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
        lgraphics.setColor(c.red * color.red, c.green * color.green, c.blue * color.blue, c.alpha * color.alpha)
      elseif t == 'userdata' then
        -- Font
        lgraphics.setFont(fragment.content)
      end
    end
  end
  return drawCalls
end
--- Prints a text fragment in the current graphic context.
-- @tparam table fragment
-- @tparam number x The x position of the top left corner of the line.
-- @tparam number y The y position of the top left corner of the line.
-- @treturn number Number of draw calls (for profiling).
function TextRenderer.drawText(fragment, x, y)
  if fragment.content ~= '' then
    lgraphics.print(fragment.content, x, y - fragment.height)
    if TextRenderer.underlined then
      lgraphics.line(x, y, x + fragment.width, y)
      return 2
    else
      return 1
    end
  end
  return 0
end
--- Prints a sprite fragment in the current graphic context.
-- @tparam table fragment
-- @tparam number x The x position of the top left corner of the line.
-- @tparam number y The y position of the top left corner of the line.
-- @treturn number Number of draw calls (for profiling).
function TextRenderer.drawSprite(fragment, x, y)
  local _, _, w, h = fragment.quad:getViewport()
  lgraphics.draw(fragment.content, fragment.quad, x, y - fragment.height, 0, fragment.width / w, fragment.height / h)
  return 1
end

return TextRenderer
