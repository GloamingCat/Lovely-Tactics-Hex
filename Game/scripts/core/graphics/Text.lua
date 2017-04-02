
--[[===========================================================================

Text
-------------------------------------------------------------------------------
A special type of Sprite which texture if a rendered text.

=============================================================================]]

-- Imports
local Sprite = require('core/graphics/Sprite')

-- Alias
local lgraphics = love.graphics
local insert = table.insert
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
  local fragments = self:parse(text, resources)
	local lines = self:createLines(fragments)
  self.texture = self:createTexture(lines)
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
  local x = self:alignDisplacement(w / sx, self.maxWidth)
  local firstShader = lgraphics.getShader()
  lgraphics.setShader(textShader)
  textShader:send('stepSize', { Font.size / w, Font.size / h})
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
-- Text parsing
-------------------------------------------------------------------------------

-- Creates a list of text fragments (not wrapped).
function Text:parse(text, resources)
  local fragments = {}
	if text ~= '' then 
		for textFragment, resourceKey in text:gmatch('([^{]*){(.-)}') do
      self:addFragment(fragments, textFragment)
			local resource = resources[resourceKey] or resourceKey
      local t = type(resource)
      if t == 'string' or t == 'number' then
        self:parseFragment(fragments, '' .. resource)
      else
        insert(self.fragments, resource)
      end
		end
		self:parseFragment(fragments, text:match('[^}]+$'))
	end
  return fragments
end

-- Parse and insert new fragment(s).
function Text:parseFragment(fragments, textFragment)
	-- break up fragments with newlines
	local n = textFragment:find('\n', 1, true)
	while n do
		insert(fragments, textFragment:sub(1, n-1))
		insert(fragments, '\n')
		textFragment = textFragment:sub(n + 1)
		n = textFragment:find('\n', 1, true)
	end
	insert(fragments, textFragment)
end

-------------------------------------------------------------------------------
-- Lines
-------------------------------------------------------------------------------

-- Creates line list. Each line contains a list of fragments, 
--  a height and a width.
-- @ret(table) the array of lines
function Text:createLines(fragments)
  local currentLine = { width = 0, height = 0 }
  local lines = {currentLine}
  local currentFont = defaultFont
	for i = 1, #fragments do
    local fragment = fragments[i]
    local t = type(fragment)
		if t == 'string' then
      currentLine = self:addTextFragment(lines, currentLine, fragment)
		elseif t == 'Image' then
			currentLine = self:addImageFragment(lines, currentLine, fragment)
		elseif t == 'Font' then
			currentFont = fragment
		end
	end
	return lines
end

-------------------------------------------------------------------------------
-- Text Fragments
-------------------------------------------------------------------------------

-- Inserts new text fragment to the given line (may have to add new lines).
-- @param(lines : table) the array of lines
-- @param(currentLine : table) the line of the fragment
-- @param(fragment : string) the text fragment
-- @ret(table) the new current line
function Text:addTextFragment(lines, currentLine, fragment)
  if fragment == '\n' then
    -- New line
    currentLine = { width = 0, height = 0 }
    insert(lines, currentLine)
    return currentLine
  end
  if self.maxWidth then
    return self:wrapText(lines, currentLine, fragment)
  else
    insert(currentLine, fragment)
    return currentLine
  end
end

-- Wraps text fragment (may have to add new lines).
-- @param(lines : table) the array of lines
-- @param(currentLine : table) the line of the fragment
-- @param(fragment : string) the text fragment
-- @ret(table) the new current line
function Text:wrapText(lines, currentLine, fragment)
  local x = currentLine.width
  local font = lgraphics.getFont()
  local breakPoint = nil
  local nextBreakPoint = fragment:find(' ', 1, true)
  while nextBreakPoint do
    print(fragment)
    local nextx = x + font:getWidth(fragment:sub(1, nextBreakPoint - 1))
    if nextx > self.maxWidth then
      print(fragment)
      break
    end
    breakPoint = nextBreakPoint
    nextBreakPoint = fragment:find(' ', nextBreakPoint + 1, true)
  end
  if nextBreakPoint then
    local wrappedFragment = fragment:sub(1, breakPoint - 1)
    local fw = font:getWidth(wrappedFragment)
    local fh = font:getHeight(wrappedFragment) * font:getLineHeight()
    insert(currentLine, { content = wrappedFragment, width = fw, height = fh })
    currentLine.width = currentLine.width + fw
    currentLine.height = max(currentLine.height, fh)
    currentLine = { width = 0, height = 0 }
    insert(lines, currentLine)
    return self:wrapText(lines, currentLine, fragment:sub(breakPoint + 1))
  else
    local fw = font:getWidth(fragment)
    local fh = font:getHeight(fragment) * font:getLineHeight()
    currentLine.width = currentLine.width + fw
    currentLine.height = max(currentLine.height, fh)
    insert(currentLine, { content = fragment, width = fw, height = fh })
    return currentLine
  end
end

-------------------------------------------------------------------------------
-- Image Fragments
-------------------------------------------------------------------------------

-- Wraps image fragment (may have to add a new line).
-- @param(lines : table) the array of lines
-- @param(currentLine : table) the line of the fragment
-- @param(fragment : Image) the image fragment
-- @ret(table) the new current line
function Text:addImageFragment(lines, currentLine, fragment)
	if self.maxWidth and currentLine.width > 0 then 
    local newx = currentLine.width + fragment:getWidth()
    if newx > self.maxWidth  then
      currentLine = { width = fragment:getWidth(), 
        height = fragment:getHeight() }
      insert(lines, currentLine)
    end
  end
  insert(currentLine, {content = fragment, width = fragment:getWidth(),
      height = fragment:getHeight() })
  return currentLine
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
  local buffer = lgraphics.newCanvas(round(fbWidth * Font.size), round(fbHeight * Font.size))
  local r, g, b, a = lgraphics.getColor()
  local font = lgraphics.getFont()
  buffer:setFilter('linear', 'nearest')
  buffer:renderTo(function () self:renderLines(lines, fbWidth) end)
  lgraphics.setColor(r, g, b, a)
  lgraphics.setFont(font)
  return buffer
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
      if t == 'string' then
        local font = lgraphics.getFont()
        lgraphics.print(fragment.content, x + Font.size, y - fragment.height)
        x = x + fragment.width
      elseif t == 'Font' then
        lgraphics.setFont(fragment.content)
      elseif t == 'Image' then
        local r, g, b, a = lgraphics.getColor()
				lgraphics.setColor(255, 255, 255, 255)
				lgraphics.draw(fragment.content, x, y - fragment.height)
        lgraphics.setColor(r, g, b, a)
        x = x + fragment.width
      else
        local c = fragment.content
        lgraphics.setColor(c.red, c.green, c.blue, c.alpha)
			end
		end
	end
end

return Text
