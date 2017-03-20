
--[[===========================================================================

Stores font cache.

=============================================================================]]

local FontCache = {}
local newFont = love.graphics.newFont

-- Overrides LÖVE's newFont function to use cache.
-- @param(size : number) the font's size
-- @param(path : string) font's path relative to main path (optional)
-- @ret(Image) to image store in the path
function love.graphics.newFont(size, path)
  local key = '' .. size
  if not path then
    key = key .. '.' .. path
  end
  local font = FontCache[key]
  if not font then
    font = newFont(size, path)
    FontCache[key] = font
  end
  return font
end
