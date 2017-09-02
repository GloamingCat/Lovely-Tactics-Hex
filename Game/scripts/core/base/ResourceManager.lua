
-- Imports
local Sprite = require('core/graphics/Sprite')
local Animation = require('core/graphics/Animation')
local Static = require('custom/animation/Static')

-- Alias
local newImage = love.graphics.newImage
local newFont = love.graphics.newFont
local newQuad = love.graphics.newQuad

-- Cache
local ImageCache = {}
local FontCache = {}

local ResourceManager = class()

---------------------------------------------------------------------------------------------------
-- Image
---------------------------------------------------------------------------------------------------

function ResourceManager:loadQuad(data, texture)
  texture = texture or self:loadTexture(data.path)
  local w = data.width / data.cols
  local h = data.height / data.rows
  local quad = newQuad(data.x, data.y, w, h, texture:getWidth(), texture:getHeight())
  return quad, texture
end
-- Creates an animation from an animation data.
-- @param(data : table or string or number) animation's data or its ID or its image path
-- @param(dest : Renderer or Sprite)
-- @ret(Animation)
function ResourceManager:loadAnimation(data, dest)
  if type(data) == 'string' then
    if not dest.renderer then
      local texture = self:loadTexture(data)
      local w, h = texture:getWidth(), texture:getHeight()
      local quad = newQuad(0, 0, w, h, w, h)
      dest = Sprite(dest, texture, quad)
    end
    return Animation(dest)
  elseif type(data) == 'number' then
    data = Database.animations[data]
  end
  if not dest.renderer then
    local quad, texture = self:loadQuad(data)
    dest = Sprite(dest, texture, quad)
    dest:setTransformation(data.transform)
  end
  local AnimClass = Animation
  if data.animation.script.path ~= '' then
    AnimClass = require('custom/' .. data.animation.script.path)
  end
  return AnimClass(dest, data)
end
-- Overrides LÖVE's newImage function to use cache.
-- @param(path : string) image's path relative to main path
-- @ret(Image) to image store in the path
function ResourceManager:loadTexture(path)
  if type(path) == 'string' then
    path = 'images/' .. string.gsub(path, '\\', '/')
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

function ResourceManager:clearImageCache()
  for k in pairs(ImageCache) do
    ImageCache[k] = nil
  end
end

---------------------------------------------------------------------------------------------------
-- Font
---------------------------------------------------------------------------------------------------

-- Overrides LÖVE's newFont function to use cache.
-- @param(size : number) the font's size
-- @param(path : string) font's path relative to main path (optional)
-- @ret(Image) to image store in the path
function ResourceManager:loadFont(path, size)
  local key = '' .. size
  if not path then
    key = key .. '.' .. path
  end
  local font = newFont[key]
  if not font then
    font = newFont(path, size)
    FontCache[key] = font
  end
  return font
end

return ResourceManager
