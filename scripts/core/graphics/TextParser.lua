
--[[===============================================================================================

TextParser
---------------------------------------------------------------------------------------------------
Module to parse a rich text string to generate table of fragments.

=================================================================================================]]

-- Alias
local insert = table.insert
local max = math.max

local TextParser = {}

---------------------------------------------------------------------------------------------------
-- Fragments
---------------------------------------------------------------------------------------------------

-- Creates a list of text fragments (not wrapped).
function TextParser.parse(text, resources)
  local fragments = {}
	if text ~= '' then 
		for textFragment, resourceKey in text:gmatch('([^{]*){(.-)}') do
      TextParser.parseFragment(fragments, textFragment)
			local resource = resources[resourceKey] or resourceKey
      local t = type(resource)
      if t == 'string' or t == 'number' then
        TextParser.parseFragment(fragments, '' .. resource)
      else
        insert(fragments, resource)
      end
		end
		TextParser.parseFragment(fragments, text:match('[^}]+$'))
	end
  return fragments
end
-- Parse and insert new fragment(s).
function TextParser.parseFragment(fragments, textFragment)
	-- break up fragments with newlines
	local n = textFragment:find('\n', 1, true)
	while n do
		insert(fragments, textFragment:sub(1, n - 1))
		insert(fragments, '\n')
		textFragment = textFragment:sub(n + 1)
		n = textFragment:find('\n', 1, true)
	end
	insert(fragments, textFragment)
end

---------------------------------------------------------------------------------------------------
-- Lines
---------------------------------------------------------------------------------------------------

-- Creates line list. Each line contains a list of fragments, 
--  a height and a width.
-- @ret(table) the array of lines
function TextParser.createLines(fragments, initialFont, maxWidth)
  local currentLine = { width = 0, height = 0 }
  local lines = {currentLine}
  local currentFont = initialFont
	for i = 1, #fragments do
    local fragment = fragments[i]
    local t = type(fragment)
		if t == 'string' then -- Piece of text
      currentLine = TextParser.addTextFragment(lines, currentLine, fragment, 
        currentFont, maxWidth)
		elseif t == 'Image' then -- Image inside text
			currentLine = TextParser.addImageFragment(lines, currentLine, fragment)
		elseif t == 'userdata' then -- Font change
			currentFont = fragment
      insert(currentLine, { content = fragment })
		else -- Color change
      insert(currentLine, { content = fragment })
    end
	end
	return lines
end

---------------------------------------------------------------------------------------------------
-- Text Fragments
---------------------------------------------------------------------------------------------------

-- Inserts new text fragment to the given line (may have to add new lines).
-- @param(lines : table) the array of lines
-- @param(currentLine : table) the line of the fragment
-- @param(fragment : string) the text fragment
-- @ret(table) the new current line
function TextParser.addTextFragment(lines, currentLine, fragment, font, width)
  if fragment == '\n' then
    -- New line
    currentLine = { width = 0, height = 0 }
    insert(lines, currentLine)
    return currentLine
  end
  if width then
    return TextParser.wrapText(lines, currentLine, fragment, font, width)
  else
    local fw = font:getWidth(fragment)
    local fh = font:getHeight(fragment) * font:getLineHeight()
    insert(currentLine, { content = fragment, width = fw, height = fh })
    currentLine.width = currentLine.width + fw
    currentLine.height = max(currentLine.height, fh)
    return currentLine
  end
end
-- Wraps text fragment (may have to add new lines).
-- @param(lines : table) the array of lines
-- @param(currentLine : table) the line of the fragment
-- @param(fragment : string) the text fragment
-- @ret(table) the new current line
function TextParser.wrapText(lines, currentLine, fragment, font, width)
  local x = currentLine.width
  local breakPoint = nil
  local nextBreakPoint = fragment:find(' ', 1, true)
  while nextBreakPoint do
    breakPoint = nextBreakPoint
    nextBreakPoint = fragment:find(' ', nextBreakPoint + 1, true)
    local nextx = x + font:getWidth(fragment:sub(1, breakPoint - 1))
    if nextx > width then
      break
    end
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
    return TextParser.wrapText(lines, currentLine, 
      fragment:sub(breakPoint + 1), font, width)
  else
    local fw = font:getWidth(fragment)
    local fh = font:getHeight(fragment) * font:getLineHeight()
    currentLine.width = currentLine.width + fw
    currentLine.height = max(currentLine.height, fh)
    insert(currentLine, { content = fragment, width = fw, height = fh })
    return currentLine
  end
end

---------------------------------------------------------------------------------------------------
-- Image Fragments
---------------------------------------------------------------------------------------------------

-- Wraps image fragment (may have to add a new line).
-- @param(lines : table) the array of lines
-- @param(currentLine : table) the line of the fragment
-- @param(fragment : Image) the image fragment
-- @ret(table) the new current line
function TextParser.addImageFragment(lines, currentLine, fragment, width)
	if width and currentLine.width > 0 then 
    local newx = currentLine.width + fragment:getWidth()
    if newx > width  then
      currentLine = { width = fragment:getWidth(), 
        height = fragment:getHeight() }
      insert(lines, currentLine)
    end
  end
  insert(currentLine, { content = fragment, width = fragment:getWidth(),
      height = fragment:getHeight() })
  return currentLine
end

return TextParser
