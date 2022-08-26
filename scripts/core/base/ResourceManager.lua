
--[[===============================================================================================

ResourceManager
---------------------------------------------------------------------------------------------------
Stores images, fonts and shaders to be reused.

=================================================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')
local Animation = require('core/graphics/Animation')
local Static = require('custom/animation/Static')

-- Alias
local newImage = love.graphics.newImage
local newImageData = love.image.newImageData
local newFont = love.graphics.newFont
local newQuad = love.graphics.newQuad
local newSource = love.audio.newSource
local newSoundData = love.sound.newSoundData
local fileInfo = love.filesystem.getInfo

-- Cache
local ImageCache = {}
local FontCache = {}
local ShaderCache = {}
local AudioCache = {}

local ResourceManager = class()

---------------------------------------------------------------------------------------------------
-- Image
---------------------------------------------------------------------------------------------------

-- Overrides LÖVE's newImage function to use cache.
-- @param(path : string) image's path relative to main path
-- @ret(Image) to image store in the path
function ResourceManager:loadTexture(path)
  if type(path) == 'string' then
    path = Project.imagePath .. path:gsub('\\', '/')
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
-- Creates a Quad for given animation data.
-- @param(data : table) Table with spritesheet's x, y, width, height, cols, rows and image path.
-- @param(texture : Image) (optional, may be loaded from data's image path)
-- @param(col : number) Initial column (optional, 0 by default).
-- @param(row : number) Initial row (optional, 0 by default).
-- @ret(Quad) Newly created Quad.
-- @ret(Image) Texture associated to this Quad.
function ResourceManager:loadQuad(data, texture, cols, rows, col, row)
  texture = texture or self:loadTexture(data.path)
  cols, rows = cols or 1, rows or 1
  local w = (data.width > 0 and data.width or texture:getWidth()) / cols
  local h = (data.height > 0 and data.height or texture:getHeight()) / rows
  col, row = col or 0, row or 0
  local quad = newQuad(data.x + col * w, data.y + row * h, w, h, 
    texture:getWidth(), texture:getHeight())
  return quad, texture
end
-- Creates an animation from an animation data table.
-- @param(data : table | string | number) Animation's data or its ID or its image path.
-- @param(dest : Renderer | Sprite) Where animation will be shown.
-- @ret(Animation) Animation object created from given data.
function ResourceManager:loadAnimation(data, dest)
  assert(data, 'Null animation')
  if type(data) == 'string' then
    if not dest.renderer then -- If dest is a Renderer
      local texture = self:loadTexture(data)
      local w, h = texture:getWidth(), texture:getHeight()
      local quad = newQuad(0, 0, w, h, w, h)
      dest = Sprite(dest, texture, quad)
    end
    return Static(dest)
  elseif type(data) == 'number' then
    assert(Database.animations[data], 'Animation does not exist: ' .. data)
    data = Database.animations[data]
  end
  if not dest.renderer then -- If dest is a Renderer
    if data.quad.path == '' then
      dest = nil
    else
      local quad, texture = self:loadQuad(data.quad, nil, data.cols, data.rows)
      dest = Sprite(dest, texture, quad)
      dest:setTransformation(data.transform)
    end
  end
  local AnimClass = Animation
  if data.script ~= '' then
    AnimClass = require('custom/' .. data.script)
  end
  return AnimClass(dest, data)
end
-- Loads a sprite.
-- @param(data : table | number | string) Animation's data or id, or path to texture.
-- @param(renderer : Renderer) Renderer of the icon (FieldManager's or GUIManager's).
-- @ret(Sprite) New Sprite object.
function ResourceManager:loadSprite(data, renderer, col, row)
  if type(data) == 'number' then
    data = Database.animations[data]
  elseif type(data) == 'string' then
    local texture = self:loadTexture(data)
    local w, h = texture:getWidth(), texture:getHeight()
    local quad = newQuad(0, 0, w, h, w, h)
    return Sprite(renderer, texture, quad)
  end
  local quad, texture = self:loadQuad(data.quad, nil, data.cols, data.rows, col, row)
  local sprite = Sprite(renderer, texture, quad)
  sprite:setTransformation(data.transform)
  return sprite
end
-- Loads a sprite for an icon.
-- @param(icon : table) Icon's data (animation ID, col and row).
-- @param(renderer : Renderer) Renderer of the icon (FieldManager's or GUIManager's).
-- @ret(Sprite) New Sprite Object.
function ResourceManager:loadIcon(icon, renderer)
  local data = Database.animations[icon.id]
  return self:loadSprite(data, renderer, icon.col, icon.row)
end
-- Loads an icon as a single-sprite animation.
-- @param(icon : table) Icon's data (animation ID, col and row).
-- @param(renderer : Renderer) Renderer of the icon (FieldManager's or GUIManager's).
-- @ret(Animation) Newly created Animation for the given icon.
function ResourceManager:loadIconAnimation(icon, renderer)
  local sprite = self:loadIcon(icon, renderer)
  return Static(sprite)
end
-- Loads the quad and texture of the given icon.
-- @param(icon : table) Icon's data (animation ID, col and row).
-- @ret(Quad) Newly created Quad.
-- @ret(Image) Texture associated to this Quad.
function ResourceManager:loadIconQuad(icon)
  local data = Database.animations[icon.id]
  return self:loadQuad(data.quad, nil, data.cols, data.rows, icon.col, icon.row)
end
-- Clears Image cache table.
-- Only use this if there is no other reference to the images.
function ResourceManager:clearImageCache()
  for k in pairs(ImageCache) do
    ImageCache[k] = nil
  end
end
-- Reloads all images in the cache.
function ResourceManager:refreshImages() 
  for k, v in pairs(ImageCache) do
    local data = newImageData(k)
    v:replacePixels(data)
  end
end

---------------------------------------------------------------------------------------------------
-- Font
---------------------------------------------------------------------------------------------------

-- Uses LÖVE's newFont to load a new font's data, or gets it from the cache.
-- @param(data : table) Array with options in order: name, format, size, italic, bold.
-- @ret(Font) Font data.
function ResourceManager:loadFont(data)
  local path = data[1]
  if data[4] then
    path = path .. '_i'
  end
  if data[5] then
    path = path .. '_b'
  end
  path = path .. '.' .. data[2]
  local size = data[3]
  local key = path .. size
  local font = FontCache[key]
  if not font then
    font = newFont('fonts/' .. path, size * Fonts.scale)
    FontCache[key] = font
  end
  return font
end
-- Clears Font cache table.
-- Only use this if there is no other reference to the fonts.
function ResourceManager:clearFontCache()
  for k in pairs(FontCache) do
    FontCache[k] = nil
  end
end

---------------------------------------------------------------------------------------------------
-- Shader
---------------------------------------------------------------------------------------------------

-- Loads a GLSL shader.
-- @param(name : string) Name of the shader file, from "shaders" folder.
-- @ret(Shader) Shader loaded from the file.
function ResourceManager:loadShader(name)
  local shader = ShaderCache[name]
  if not shader then
    shader = love.graphics.newShader('shaders/' .. name .. '.glsl')
    ShaderCache[name] = shader
  end
  return shader
end
-- Clears Shader cache table.
-- Only use this if there is no other reference to the shaders.
function ResourceManager:clearShaderCache()
  for k in pairs(ShaderCache) do
    ShaderCache[k] = nil
  end
end

---------------------------------------------------------------------------------------------------
-- Audio
---------------------------------------------------------------------------------------------------

-- Loads intro and loop audio sources for BGM.
-- @param(name : string) Name of the file from the audio folder.
-- @param(intro : Source) Intro source (optional).
-- @param(loop : Source) Loop source (optional).
-- @ret(Source) Intro audio source (if any).
-- @ret(Source) Looping audio source.
function ResourceManager:loadBGM(name, intro, loop)
  name = Project.audioPath .. name
  if not loop then
    if not intro then
      local introName = name:gsub('%.', '_intro.', 1)
      if fileInfo(introName) then
        intro = newSource(introName, 'static')
        intro:setLooping(false)
      end
    end
    loop = newSource(name, 'static')
    assert(loop, 'Could not load music file ' .. name)
    loop:setLooping(true)
  end
  return intro, loop
end
-- Loads source for the given sound's name.
-- @param(name : string) Name of the file from the audio folder.
-- @ret(Source)
function ResourceManager:loadSFX(name)
  if AudioCache[name] then
    return newSource(AudioCache[name])
  end
  AudioCache[name] = newSoundData(Project.audioPath .. name)
  assert(AudioCache[name], 'Could not load Sound ' .. name)
  return newSource(AudioCache[name])
end
-- Clears Font cache table.
-- Only use this if there is no other reference to the fonts.
function ResourceManager:clearAudioCache()
  for k in pairs(AudioCache) do
    AudioCache[k] = nil
  end
end

return ResourceManager
