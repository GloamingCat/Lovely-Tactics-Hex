
local Sprite = require('core/graphics/Sprite')
local textShader = love.graphics.newShader('shaders/text.glsl')
local lgraphics = love.graphics
local log2 = 1/math.log(2)

--[[===========================================================================

A text with dynamic fonts, colors and middle-text icons.
Adapted from Robin Wellner and Florian Fischer's original code:

Copyright (c) 2010 Robin Wellner
Copyright (c) 2014 Florian Fischer (class changes, initial color, ...)
This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.
Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:
   1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
   2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
   3. This notice may not be removed or altered from any source
   distribution.

=============================================================================]]

local Text = Sprite:inherit()

local old_init = Text.init
function Text:init(data, renderer)
  old_init(self, renderer)
  self.isText = true
  self:setText(data)
end

function Text:setText(data)
  self.width = data[2] * Font.size
  self.align = data[3] or self.align
  self.maxchar = data[4] or self.maxchar
  self.hardwrap = false
  self.resources = {}
  self.parsedtext = {}
  self:extract(data)
  self:parse(data)
  local f = self:renderFrame()
  self.texture = f
  self.quad = lgraphics.newQuad(0, 0, f:getWidth(), f:getHeight(), f:getWidth(), f:getHeight())
  self.renderer.needsRedraw = true
end

-------------------------------------------------------------------------------
-- Draw in screen
-------------------------------------------------------------------------------

function Text:draw(x, y)
  local sx = self.scaleX * ScreenManager.scaleX * self.renderer.zoom
  local sy = self.scaleY * ScreenManager.scaleY * self.renderer.zoom
  local w, h = self.texture:getWidth(), self.texture:getHeight()
  local firstShader = lgraphics.getShader()
  lgraphics.setShader(textShader)
  textShader:send('stepSize', {1 / w, 1 / h})
  textShader:send('scale', {sx, sy})
  lgraphics.setBlendMode('alpha', 'premultiplied')
  lgraphics.draw(self.texture, self.quad, self.position.x, self.position.y, self.rotation, 
    1 / sx, 1 / sy, self.offsetX, self.offsetY)
  lgraphics.setBlendMode('alpha')
  lgraphics.setShader(firstShader)
end

-------------------------------------------------------------------------------
-- Text parsing
-------------------------------------------------------------------------------

function Text:extract(t)
	if t[3] and type(t[3]) == 'table' then
		for key,value in pairs(t[3]) do
			local meta = type(value) == 'table' and value or {value}
			self.resources[key] = self:initmeta(meta) -- sets default values, does a PO2 fix...
		end
	else
		for key,value in pairs(t) do
			if type(key) == 'string' then
				local meta = type(value) == 'table' and value or {value}
				self.resources[key] = self:initmeta(meta) -- sets default values, does a PO2 fix...
			end
		end
	end
end

local function parsefragment(parsedtext, textfragment)
	-- break up fragments with newlines
	local n = textfragment:find('\n', 1, true)
	while n do
		table.insert(parsedtext, textfragment:sub(1, n-1))
		table.insert(parsedtext, {type='nl'})
		textfragment = textfragment:sub(n + 1)
		n = textfragment:find('\n', 1, true)
	end
	table.insert(parsedtext, textfragment)
end

function Text:parse(t)
	local text = t[1]
	if string.len(text) > 0 then 
		-- look for {tags} or [tags]
		for textfragment, foundtag in text:gmatch'([^{]*){(.-)}' do
			parsefragment(self.parsedtext, textfragment)
			table.insert(self.parsedtext, self.resources[foundtag] or foundtag)
		end
		parsefragment(self.parsedtext, text:match('[^}]+$'))
	end
end

local function nextpo2(n)
	return math.pow(2, math.ceil(math.log(n)*log2))
end

local metainit = {}
function metainit.Image(res, meta)
	meta.type = 'img'
	local w, h = res:getWidth(), res:getHeight()
	meta.width = meta.width or w
	meta.height = meta.height or h
end
function metainit.Font(res, meta)
	meta.type = 'font'
end
function metainit.number(res, meta)
	meta.type = 'color'
end

function Text:initmeta(meta)
	local res = meta[1]
	local type = (type(res) == 'userdata') and res:type() or type(res)
	if metainit[type] then
		metainit[type](res, meta)
	else
		error('Unsupported type')
	end
	return meta
end

-------------------------------------------------------------------------------
-- Draw in buffer
-------------------------------------------------------------------------------

local function wrapText(parsedtext, fragment, lines, maxheight, x, width, i, fnt, hardwrap)
	if not hardwrap or (hardwrap and x > 0) then
		-- find first space, split again later if necessary
		local n = fragment:find(' ', 1, true)
		local lastn = n
		while n do
			local newx = x + fnt:getWidth(fragment:sub(1, n-1))
			if newx > width then
				break
			end
			lastn = n
			n = fragment:find(' ', n + 1, true)
		end
		n = lastn or (#fragment + 1)
		-- wrapping
		parsedtext[i] = fragment:sub(1, n-1)
		table.insert(parsedtext, i+1, fragment:sub((fragment:find('[^ ]', n) or (n+1)) - 1))
		lines[#lines].height = maxheight
		maxheight = 0
		x = 0
		lines[#lines + 1] = {}
	end
	
	return maxheight, 0
end

local function renderText(parsedtext, fragment, lines, maxheight, x, width, i, hardwrap)
	local fnt = lgraphics.getFont() or lgraphics.newFont(12)
	if x + fnt:getWidth(fragment) > width then -- oh oh! split the text
		maxheight, x = wrapText(parsedtext, fragment, lines, maxheight, x, width, i, fnt, hardwrap)
	end

	-- hardwrap long words
	if hardwrap and x + fnt:getWidth(parsedtext[i]) > width then
		local n = #parsedtext[i]
		while x + fnt:getWidth(parsedtext[i]:sub(1, n)) > width do
			n = n - 1
		end
		local p1, p2 = parsedtext[i]:sub(1, n - 1), parsedtext[i]:sub(n)
		parsedtext[i] = p1
		if not parsedtext[i + 1] then
			parsedtext[i + 1] = p2
		elseif type(parsedtext[i + 1]) == 'string' then
			parsedtext[i + 1] = p2 .. parsedtext[i + 1]
		elseif type(parsedtext[i + 1]) == 'table' then
			table.insert(parsedtext, i + 2, p2)
			table.insert(parsedtext, i + 3, {type='nl'})
		end
		lines[#lines].height = maxheight
		maxheight = 0
		x = 0
    lines[#lines + 1] = {}
	end

	local h = math.floor(fnt:getHeight(parsedtext[i]) * fnt:getLineHeight())
	maxheight = math.max(maxheight, h)
	return maxheight, x + fnt:getWidth(parsedtext[i]), {parsedtext[i], x = x > 0 and x or 0, type = 'string', height = h, width = fnt:getWidth(parsedtext[i])}
end

local function renderImage(fragment, lines, maxheight, x, width)
	local newx = x + fragment.width
	if newx > width and x > 0 then -- wrapping
		lines[#lines].height = maxheight
		maxheight = 0
		x = 0
    lines[#lines + 1] = {}
		table.insert(lines, {})
	end
	maxheight = math.max(maxheight, fragment.height)
	return maxheight, newx, {fragment, x = x, type = 'img'}
end

local function doRender(parsedtext, width, hardwrap)
	local x = 0
	local lines = {{}}
	local maxheight = 0
	for i = 1, #parsedtext do -- prepare rendering
    local fragment = parsedtext[i]
		if type(fragment) == 'string' then
			maxheight, x, fragment = renderText(parsedtext, fragment, lines, maxheight, x, width, i, hardwrap)
		elseif fragment.type == 'img' then
			maxheight, x, fragment = renderImage(fragment, lines, maxheight, x, width)
		elseif fragment.type == 'font' then
			lgraphics.setFont(fragment[1])
		elseif fragment.type == 'nl' then
			-- move onto next line, reset x and maxheight
			lines[#lines].height = maxheight
			maxheight = 0
			x = 0
      lines[#lines + 1] = {}
			-- don't want nl inserted into line
			fragment = ''
		end
		table.insert(lines[#lines], fragment)
	end
	lines[#lines].height = maxheight
	return lines
end

local function doDraw(lines, limit, align)
	local y = 0
	local colorr,colorg,colorb,colora = lgraphics.getColor()
  for i = 1, #lines do -- do the actual rendering
    local line = lines[i]
		y = y + line.height
		for j = 1, #line do
      local fragment = line[j]
			if fragment.type == 'string' then
				-- remove leading spaces, but only at the begin of a new line
				-- Note: the check for fragment 2 (j==2) is to avoid a sub for leading line space
				if j==2 and string.sub(fragment[1], 1, 1) == ' ' then
					fragment[1] = string.sub(fragment[1], 2)
				end
        if limit then
          lgraphics.printf(fragment[1], fragment.x, 
            y - fragment.height, limit - 1, align)
        else
          lgraphics.print(fragment[1], fragment.x, 
            y - fragment.height)
        end
			elseif fragment.type == 'img' then
				lgraphics.setColor(255,255,255)
				lgraphics.draw(fragment[1][1], fragment.x, 
          y - fragment[1].height)
				if rich.debug then
					lgraphics.rectangle('line', fragment.x, 
            y - fragment[1].height, fragment[1].width, fragment[1].height)
				end
				lgraphics.setColor(colorr,colorg,colorb,colora)
			elseif fragment.type == 'font' then
				lgraphics.setFont(fragment[1])
			elseif fragment.type == 'color' then
				lgraphics.setColor(unpack(fragment))
				colorr,colorg,colorb,colora = lgraphics.getColor()
			end
		end
	end
end

function Text:calcHeight(lines)
	local h = 0
	for _, line in ipairs(lines) do
		h = h + line.height
	end
	return h
end

function Text:renderFrame()
	local renderWidth = (self.width + 1) * Font.size
	local lines = doRender(self.parsedtext, renderWidth, self.hardwrap)
  local halfHeight = math.floor((lines[#lines].height / 2) + 0.5)
	self.height = (self:calcHeight(lines) + halfHeight ) * Font.size
  local fbWidth = self.width * ScreenManager.scaleX
  local fbHeight = self.height * ScreenManager.scaleY
  local frame = lgraphics.newCanvas(fbWidth, fbHeight)
  lgraphics.push()
  lgraphics.scale(ScreenManager.scaleX * self.scaleX / Font.size, 
                  ScreenManager.scaleY * self.scaleY / Font.size)
  lgraphics.translate(Font.size, -2 * Font.size)
  frame:setFilter('linear', 'nearest')
  frame:renderTo(function () doDraw(lines, self.width, self.align) end)
  lgraphics.pop()
  lgraphics.setFont(Font.fps)
  return frame
end

return Text
