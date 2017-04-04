
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
  self.isText = true
  self.maxWidth = properties[1] and (properties[1] + 1)
  self.align = properties[2] or self.align or 'left'
  self.maxchar = properties[3] or self.maxchar
  self.resources = resources
  self.text = text
  self.scaleX = 1 / Font.size
  self.scaleY = 1 / Font.size
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

-------------------------------------------------------------------------------
-- Draw in screen
-------------------------------------------------------------------------------

-- Draws text in the given position.
function Text:draw()
  local sx = ScreenManager.scaleX * self.renderer.scaleX
  local sy = ScreenManager.scaleY * self.renderer.scaleY
  local w, h = self.texture:getWidth(), self.texture:getHeight()
  local x = self:alignDisplacement(self.totalWidth, self.maxWidth)
  local firstShader = lgraphics.getShader()
  lgraphics.setShader(textShader)
  textShader:send('stepSize', { 1 / (self.scaleX * w), 1 / (self.scaleY * h)})
  textShader:send('scale', { sx * self.scaleX, sy * self.scaleY })
  lgraphics.setBlendMode('alpha', 'premultiplied')
  lgraphics.draw(self.texture, self.quad, self.position.x + x, self.position.y, 
    self.rotation, self.scaleX, self.scaleY, self.offsetX, self.offsetY)
  lgraphics.setBlendMode('alpha')
  lgraphics.setShader(firstShader)
end

function Text:alignDisplacement(w, maxWidth)
  if maxWidth then
    if self.align == 'right' then
      return maxWidth - w
    elseif self.aling == 'center' then
      return (maxWidth - w) / 2
    end
  end
  return 0
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
      l = l .. lines[i][j].content
    end
    fbWidth = max(fbWidth, lines[i].width)
    fbHeight = fbHeight + lines[i].height
    --print(l)
  end
  fbHeight = fbHeight + round(lines[#lines].height / 2)
  local buffer = lgraphics.newCanvas(round((fbWidth + 2) / self.scaleX), round((fbHeight + 2) / self.scaleY))
  local r, g, b, a = lgraphics.getColor()
  local font = lgraphics.getFont()
  buffer:setFilter('linear', 'nearest')
  buffer:renderTo(function () self:renderLines(lines, fbWidth / self.scaleX) end)
  lgraphics.setColor(r, g, b, a)
  lgraphics.setFont(font)
  self.totalWidth = fbWidth
  self.totalHeight = fbHeight
  self.texture = buffer
end

-- Renders all lines content.
function Text:renderLines(lines, maxWidth)
  lgraphics.setFont(defaultFont)
  lgraphics.setColor(255, 255, 255, 255)
	local x, y = 0, -Font.size
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
      else
        local fx = x + 1 / self.scaleX
        local fy = y - fragment.height - self.scaleY
        if t == 'string' then
          lgraphics.print(fragment.content, fx, fy)
        else
          local r, g, b, a = lgraphics.getColor()
          lgraphics.setColor(255, 255, 255, 255)
          lgraphics.draw(fragment.content, fx, fy)
          lgraphics.setColor(r, g, b, a)
        end
        x = x + fragment.width
			end
		end
	end
end

return Text
