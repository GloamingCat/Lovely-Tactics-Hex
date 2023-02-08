
--[[===============================================================================================

TextParser
---------------------------------------------------------------------------------------------------
Module to parse a rich text string to generate table of fragments.

Rich text codes:
{i} = set italic;
{b} = set bold;
{u} = set underlined;
{+x} = increases font size by x points;
{-x} = decreases font size by x points;
{fx} = set font (x must be a key in the global Fonts table);
{cx} = sets the color (x must be a key in the global Color table);
{sx} = shows an icon image (x must be a key in the Config.icons table).

=================================================================================================]]

-- Alias
local insert = table.insert
local max = math.max

local TextParser = {}

---------------------------------------------------------------------------------------------------
-- Fragments
---------------------------------------------------------------------------------------------------

-- Split raw text into an array of fragments.
-- @param(text : string) Raw text.
-- @param(plainText : boolean) When true, will not parse commands (optional, false by default).
-- @ret(table) Array of fragments.
function TextParser.parse(text, plainText, fragments)
  local vars = Config.variables
  fragments = fragments or {}
	if text ~= '' then 
    if plainText then
      TextParser.parseFragment(fragments, text)
      return fragments
    end
		for textFragment, resourceKey in text:gmatch('([^{]*){(.-)}') do
      TextParser.parseFragment(fragments, textFragment)
      local t = resourceKey:sub(1, 1)
      if t == 'i' then
        insert(fragments, { type = 'italic' })
      elseif t == 'b' then
        insert(fragments, { type = 'bold' })
      elseif t == 'r' then
        insert(fragments, { type = 'reset' })
      elseif t == 'u' then
        insert(fragments, { type = 'underline' })
      elseif t == 'f' then
        insert(fragments, { type = 'font', value = Fonts[resourceKey:sub(2)] })
      elseif t == '+' then
        insert(fragments, { type = 'size', value = tonumber(resourceKey:sub(2)) })
      elseif t == '-' then
        insert(fragments, { type = 'size', value = -tonumber(resourceKey:sub(2)) })
      elseif t == 'c' then
        insert(fragments, { type = 'color', value = Color[resourceKey:sub(2)] })
      elseif t == 's' then
        insert(fragments, { type = 'sprite', value = Config.icons[resourceKey:sub(2)] })
      elseif t == 'a' then
        insert(fragments, { event = true, type = 'audio', value = Config.sounds[resourceKey:sub(2)] })
      elseif t == 't' then
        insert(fragments, { event = true, type = 'time', value = tonumber(resourceKey:sub(2)) })
      elseif t == 'p' then
        insert(fragments, { event = true, type = 'input' })
      elseif t == '%' then
        local key = resourceKey:sub(2)
        local f
        if vars[key] then
          f = tostring(vars[key].value)
        else
          local value = util.table.access(Vocab, key)
          assert(value, 'Text variable or term ' .. tostring(key) .. ' not found.')
          f = tostring(value)
        end
        if plainText then
          TextParser.parseFragment(fragments, f)
        else
          TextParser.parse(f, false, fragments)
        end
      else
        TextParser.parseFragment(fragments, textFragment .. '{' .. resourceKey .. '}')
        --error('Text command not identified: ' .. (t or 'nil'))
      end
		end
    text = text:match('[^}]+$')
    if text then
      TextParser.parseFragment(fragments, text)
    end
	end
  return fragments
end
-- Parse and insert new fragment(s).
-- @param(fragments : table) Array of parsed fragments.
-- @param(textFragment : string) Unparsed (and unwrapped) text fragment. 
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

-- Creates line list. Each line is a table containing an array of fragments, a height and a width.
-- It also contains its length for character counting.
-- @param(fragments : table) Array of fragments.
-- @ret(table) Array of lines.
-- @ret(table) Array of text events.
function TextParser.createLines(fragments, initialFont, maxWidth, scale)
  local currentFont = ResourceManager:loadFont(initialFont, scale)
  local currentFontInfo = { unpack(initialFont) }
  local currentLine = { width = 0, height = 0, length = 0, { content = currentFont, info = currentFontInfo } }
  local lines = { currentLine, length = 0, scale = scale }
  local events = {}
  local point = 0
	for i = 1, #fragments do
    local fragment = fragments[i]
		if type(fragment) == 'string' then -- Piece of text
      local line, length = TextParser.addTextFragment(lines, currentLine, fragment, 
        currentFont, maxWidth, scale)
      currentLine = line
      point = point + length
    elseif fragment.type == 'sprite' then
      local quad, texture = ResourceManager:loadIconQuad(fragment.value)
      local x, y, w, h = quad:getViewport()
      w = w * scale
      h = h * scale
      if currentLine.width + w > maxWidth * scale then
        currentLine = TextParser.addTextFragment(lines, currentLine, '\n')
      end
      TextParser.insertFragment(lines, currentLine, { content = texture, quad = quad, 
          length = 1, width = w, height = h})
      point = point + 1
    elseif fragment.type == 'color' then
      insert(currentLine, { content = fragment.value })
    elseif fragment.type == 'underline' then
      insert(currentLine, { content = 'underline' })
    elseif fragment.event then
      insert(events, { type = fragment.type, content = fragment.value, point = point })
    else
      if fragment.type == 'italic' then
        currentFontInfo[4] = not currentFontInfo[4]
      elseif fragment.type == 'bold' then
        currentFontInfo[5] = not currentFontInfo[5]
      elseif fragment.type == 'reset' then
        currentFontInfo[4] = false
        currentFontInfo[5] = false
      elseif fragment.type == 'font' then
        currentFontInfo = fragment.value
      elseif fragment.type == 'size' then
        currentFontInfo[3] = fragment.size + currentFontInfo[3]
      end
      currentFont = ResourceManager:loadFont(currentFontInfo, scale)
      insert(currentLine, { content = currentFont, info = util.table.shallowCopy(currentFontInfo) })
    end
	end
	return lines, events
end
-- Cuts the text in the given character index.
-- @param(lines : table) Array of parsed lines.
-- @param(point : number) The index of the last text character.
-- @ret(table) New array of parsed lines.
function TextParser.cutText(lines, point)
  local newLines = { length = 0 }
  for l = 1, #lines do
    if point < lines[l].length then
      -- Found line to be cut.
      local newLine = { width = 0, height = 0, length = 0 }
      for i = 1, #lines[l] do
        local fragment = lines[l][i]
        if fragment.length and point < fragment.length then
          -- Found fragment to be cut.
          local content = fragment.content:sub(1, point)
          TextParser.insertFragment(newLines, newLine, content, fragment.font)
          break
        else
          point = point - (fragment.length or 0)
          TextParser.insertFragment(newLines, newLine, fragment)
        end
      end
      insert(newLines, newLine)
      break
    else
      insert(newLines, lines[l])
      point = point - lines[l].length
    end
  end
  return newLines
end

---------------------------------------------------------------------------------------------------
-- Text Fragments
---------------------------------------------------------------------------------------------------

-- Inserts new text fragment to the given line (may have to add new lines).
-- @param(lines : table) The array of lines.
-- @param(currentLine : table) The line of the fragment.
-- @param(fragment : string) The text fragment.
-- @param(maxWidth : number) Max width for wrapping.
-- @param(scale : number) Font scale.
-- @ret(table) The new current line.
-- @ret(number) Total length of the fragment inserted.
function TextParser.addTextFragment(lines, currentLine, fragment, font, maxWidth, scale)
  if fragment == '\n' then
    -- New line
    currentLine = { width = 0, height = 0, length = 0 }
    insert(lines, currentLine)
    return currentLine, 0
  end
  if maxWidth then
    return TextParser.wrapText(lines, currentLine, fragment, font, maxWidth * scale)
  else
    return currentLine, TextParser.insertFragment(lines, currentLine, fragment, font)
  end
end
-- Wraps text fragment (may have to add new lines).
-- @param(lines : table) The array of lines.
-- @param(currentLine : table) The line of the fragment.
-- @param(fragment : string) The text fragment.
-- @param(width : number) Max width for wrapping.
-- @ret(table) The new current line.
-- @ret(number) Total length of the fragment inserted.
function TextParser.wrapText(lines, currentLine, fragment, font, width)
  local x = currentLine.width
  local breakPoint = nil
  local nextBreakPoint = fragment:find(' ', 1, true) or #fragment + 1
  while nextBreakPoint ~= breakPoint do
    local nextx = x + font:getWidth(fragment:sub(1, nextBreakPoint - 1))
    if nextx > width then
      break
    end
    breakPoint = nextBreakPoint
    nextBreakPoint = fragment:find(' ', nextBreakPoint + 1, true) or #fragment + 1
  end
  if breakPoint ~= nextBreakPoint then
    if breakPoint then
      -- Insert first part.
      local part1 = fragment:sub(1, breakPoint - 1)
      local length1 = TextParser.insertFragment(lines, currentLine, part1, font)
      -- Create new line.
      currentLine = { width = 0, height = 0, length = 0 }
      insert(lines, currentLine)
      -- Insert second part.
      local part2 = fragment:sub(breakPoint + 1)
      local line, length2 = TextParser.wrapText(lines, currentLine, part2, font, width)
      return line, length1 + length2
    elseif nextBreakPoint < #fragment + 1 then
      currentLine = { width = 0, height = 0, length = 0 }
      insert(lines, currentLine)
      return TextParser.wrapText(lines, currentLine, fragment, font, width)
    end
  end
  return currentLine, TextParser.insertFragment(lines, currentLine, fragment, font)
end
-- Inserts a new fragment into the line.
-- @param(lines : table) Array of all lines.
-- @param(currentLine : table) The line that the fragment will be inserted.
-- @param(fragment : table | string) The fragment to insert.
-- @param(font : Font) The font of the fragment's text (in case the fragment is a string).
-- @ret(number) The length of the inserted fragment.
function TextParser.insertFragment(lines, currentLine, fragment, font)
  if type(fragment) == 'string' then
    local fw = font:getWidth(fragment)
    local fh = font:getHeight(fragment) * font:getLineHeight()
    fragment = { content = fragment, width = fw, height = fh, length = #fragment, font = font }
  end
  local length = fragment.length or 0
  currentLine.width = currentLine.width + (fragment.width or 0)
  currentLine.height = max(currentLine.height, (fragment.height or 0))
  currentLine.length = currentLine.length + length
  insert(currentLine, fragment)
  lines.length = lines.length + length
  return length
end

return TextParser
