
--[[===============================================================================================

TextRenderer
---------------------------------------------------------------------------------------------------
Module to create each rendered line of text.

=================================================================================================]]

-- Alias
local lgraphics = love.graphics
local Quad = lgraphics.newQuad

local TextRenderer = {}

---------------------------------------------------------------------------------------------------
-- Individual buffers
---------------------------------------------------------------------------------------------------

-- Draw the image buffer of a single line.
-- The size of the buffer image is Fonts.scale * size of the text in-game.
-- @param(line : table) A list of text fragments.
-- @ret(Canvas) Rendered line.
function TextRenderer.drawLine(line, x, y, color)
  for j = 1, #line do
    local fragment = line[j]
    local t = type(fragment.content)
    if fragment.width then
      -- Drawable
      if t == 'string' then
        -- Print text
        TextRenderer.drawText(fragment, x, y)
      elseif t == 'userdata' then
        -- Print sprite
        TextRenderer.drawSprite(fragment, x, y)
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
end
-- Prints a text fragment in the current graphic context.
-- @param(fragment : table)
-- @param(x : number)
-- @param(y : number)
function TextRenderer.drawText(fragment, x, y)
  if fragment.content ~= '' then
    lgraphics.print(fragment.content, x, y - fragment.height)
    if TextRenderer.underlined then
      lgraphics.line(x, y, x + fragment.width, y)
    end
  end
end
-- Prints a sprite fragment in the current graphic context.
-- @param(fragment : table)
-- @param(x : number)
-- @param(y : number)
function TextRenderer.drawSprite(fragment, x, y)
  local _, _, w, h = fragment.quad:getViewport()
  lgraphics.draw(fragment.content, fragment.quad, x, y - fragment.height, 0, fragment.width / w, fragment.height / h)
end

return TextRenderer
