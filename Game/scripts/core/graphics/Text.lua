
--[[===========================================================================

Text
-------------------------------------------------------------------------------
A special type of Sprite which texture if a rendered text.

=============================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')
local TextParser = require('core/graphics/TextParser')

-- Alias
local lgraphics = love.graphics
local Quad = lgraphics.newQuad
local max = math.max
local round = math.round

-- Constants
local textShader = love.graphics.newShader('shaders/text.glsl')
local log2 = 1/math.log(2)
local defaultFont = Font.gui_default
local colorf = Color.toFloat

local Text = Sprite:inherit()

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

-- @param(text : string) the rich text
-- @param(resources : table) table of resources used in text
-- @param(renderer : Renderer) the destination renderer of the sprite
-- @param(properties : table) the table with text properties:
--  (properties[1] : number) the width of the text box
--  (properties[2] : string) the align type (left, right or center) 
--    (optional, left by default)
--  (properties[3] : number) the max number of characters that will be shown 
--    (optional, no limit by default)
--  (properties[4] : Font) the initial font (optional, sets default font)
local old_init = Text.init
function Text:init(text, resources, properties, renderer)
  old_init(self, renderer)
  --self.isText = true
  self.maxWidth = properties[1] and (properties[1] + 1)
  self.align = properties[2] or self.align or 'left'
  self.maxchar = properties[3] or self.maxchar
  self.resources = resources
  self.text = text
  self.scaleX = 1 / Font.scale
  self.scaleY = 1 / Font.scale
  self.offsetX = 0
  self.offsetY = 0
  self:setText(text, resources)
end

-- Sets/changes the text content.
-- @param(text : string) the rich text
-- @param(resources : table) table of resources used in text
function Text:setText(text, resources)
  local fragments = TextParser.parse(text, resources)
	local lines = TextParser.createLines(fragments, defaultFont, self.maxWidth)
  self:createTexture(lines)
  self.quad = lgraphics.newQuad(0, 0, self.texture:getWidth(), 
    self.texture:getHeight(), self.texture:getWidth(), self.texture:getHeight())
  self.renderer.needsRedraw = true
end

local old_setXYZ = Text.setXYZ
function Text:setXYZ(x, y, z)
  if x then
    x = x + self:alignDisplacement(self.totalWidth, self.maxWidth)
  end
  old_setXYZ(self, x, y, z)
end

-------------------------------------------------------------------------------
-- Draw in screen
-------------------------------------------------------------------------------

function Text:alignDisplacement(w, maxWidth)
  if maxWidth then
    if self.align == 'right' then
      return maxWidth - w - Font.outlineSize
    elseif self.aling == 'center' then
      return (maxWidth - w) / 2
    end
  end
  return Font.outlineSize
end

-------------------------------------------------------------------------------
-- Rendering
-------------------------------------------------------------------------------

function Text:createTexture(lines)
  -- Debug
  local fbWidth, fbHeight = 0, 0
  for i = 1, #lines do
    local l = ''
    for j = 1, #lines[i] do
      if type(lines[i][j].content) == 'string' then
        l = l .. lines[i][j].content
      end
      if lines[i][j].width == 0 then
        print(lines[i][j].width)
      end
    end
    fbWidth = max(fbWidth, lines[i].width)
    fbHeight = fbHeight + lines[i].height
  end
  fbWidth = fbWidth
  fbHeight = fbHeight + round(lines[#lines].height / 2)
  local buffer = lgraphics.newCanvas(round(fbWidth / self.scaleX), round(fbHeight / self.scaleY))
  local r, g, b, a = lgraphics.getColor()
  local firstFont = lgraphics.getFont()
  local firstShader = lgraphics.getShader()
  local firstCanvas = lgraphics.getCanvas()
  buffer:setFilter('linear', 'nearest')
  lgraphics.setCanvas(buffer)
  self:renderLines(lines, fbWidth / self.scaleX)
  self.texture = self:preRender(buffer)
  lgraphics.setColor(r, g, b, a)
  lgraphics.setFont(firstFont)
  lgraphics.setShader(firstShader)
  lgraphics.setCanvas(firstCanvas)
  self.totalWidth = fbWidth
  self.totalHeight = fbHeight
end

-- Renders all lines content.
function Text:renderLines(lines, maxWidth)
  lgraphics.setFont(defaultFont)
  lgraphics.setColor(255, 255, 255, 255)
	local x, y = 0, -1 / self.scaleY
  for i = 1, #lines do
    local line = lines[i]
		y = y + line.height
    x = self:alignDisplacement(line.width, maxWidth)
		for j = 1, #line do
      local fragment = line[j]
      local t = type(fragment.content)
      if t == 'table' then
        local c = fragment.content
        lgraphics.setColor(c.red, c.green, c.blue, c.alpha)
      elseif t == 'userdata' then
        lgraphics.setFont(fragment.content)
      else
        local fy = y - fragment.height
        if t == 'string' then
          lgraphics.print(fragment.content, x, fy)
        else
          local r, g, b, a = lgraphics.getColor()
          lgraphics.setColor(255, 255, 255, 255)
          lgraphics.draw(fragment.content, x, fy)
          lgraphics.setColor(r, g, b, a)
        end
        x = x + fragment.width
			end
		end
	end
end

function Text:preRender(texture)
  local w, h = texture:getWidth(), texture:getHeight()
  local quad = Quad(0, 0, w, h, w, h)
  local newTexture = lgraphics.newCanvas(w, h)
  newTexture:setFilter('linear', 'nearest')
  lgraphics.setCanvas(newTexture)
  lgraphics.setShader(textShader)
  textShader:send('stepSize', { Font.outlineSize / self.scaleX / w, 
      Font.outlineSize / self.scaleY / h })
  textShader:send('scale', { self.scaleX, self.scaleY })
  lgraphics.setBlendMode('alpha', 'premultiplied')
  lgraphics.draw(texture)
  lgraphics.setBlendMode('alpha')
  return newTexture
end

return Text
