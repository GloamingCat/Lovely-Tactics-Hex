
--[[===========================================================================

Stores image cache.

=============================================================================]]

local ImageCache = {}
local newImage = love.graphics.newImage
love.graphics.setDefaultFilter("nearest", "nearest")

-- Overrides LÖVE's newImage function to use cache.
-- @param(path : string) image's path relative to main path
-- @ret(Image) to image store in the path
function love.graphics.newImage(path)
  if type(path) == 'string' then
    path = string.gsub(path, '\\', '/')
    local img = ImageCache[path]
    if img then
      return img
    else
      img = newImage(path)
      img:setFilter('linear', 'nearest')
      ImageCache[path] = img
    end
  end
  return newImage(path)
end
