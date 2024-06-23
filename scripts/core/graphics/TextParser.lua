
-- ================================================================================================

--- Module to parse a rich text string to generate table of fragments.
-- Rich text commands appear in the text in the form of `{C}`, where `C` is the rich text code.
-- When a command requires a parameters, just write it right after the command code, e.g. `{+10}`
-- or `{slove}`.
-- See `TextParser.Code` for the list of codes.
---------------------------------------------------------------------------------------------------
-- @module TextParser

-- ================================================================================================

-- Alias
local insert = table.insert
local max = math.max

local TextParser = {}

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Rich text codes.
-- @enum Code
-- @field i Toggles between italic and non-italic.
-- @field b Toggles between bold and non-bold.
-- @field u Toggles between underlined and not underlined.
-- @field plusx Increases font text by `x` points (type it as `+x`).
-- @field minusx Decreases font text by `x` points (type it as `-x`).
-- @field fx Changes font to `x` (x must be a key in the global `Fonts` table).
-- @field cx Changes text color to `x` (x must be a key in the global `Color` table).
-- @field sx Shows sprite (dialogue-only). `x` must be a key in the `Config.icons` data table).
-- @field ax Player an audio (dialogue-only). `x` must be a key in the `Config.sounds` data table).
-- @field tx Waits for `x` frames before showing the rest of the text (dialogue-only).
-- @field p Waits until the player presses a key (dialogue-only).
TextParser.Code = {
  i = "italic",
  b = "bold",
  u = "underline",
  r = "reset",
  ["+"] = "size",
  ["-"] = "size",
  f = "font",
  c = "color",
  s = "sprite",
  a = "audio",
  t = "time",
  p = "input",
  ["%"] = "var"
}

-- ------------------------------------------------------------------------------------------------
-- Fragments
-- ------------------------------------------------------------------------------------------------

--- Replaces all in-text variables by their values.
-- The variables are evaluated recursively.
-- @tparam string text Raw text.
-- @treturn string Modified text.
function TextParser.evaluate(text)
  local str = ""
  for textFragment, code in text:gmatch('([^{%%]*){(.-)}') do
    local key = code:sub(2)
    local value = GameManager:getVariable(key, _G.Fiber, FieldManager.currentField)
    if value == nil then
      print('Text variable or term not found: ' .. tostring(key))
    end
    local f = tostring(value)
    str = str .. textFragment .. TextParser.evaluate(f)
  end
  local lastText = text:match('[^}]+$')
  if lastText then
    str = str .. lastText
  end
  return str
end
--- Split raw text into an array of fragments.
-- @tparam string text Raw text.
-- @tparam[opt] boolean plainText Flag to not parse commands.
-- @tparam[opt={}] table fragments Array of raw fragments.
-- @treturn table Array of fragments.
function TextParser.parse(text, plainText, fragments)
  fragments = fragments or {}
	if text ~= '' then 
    if plainText then
      TextParser.parseFragment(fragments, text)
      return fragments
    end
		for textFragment, code in text:gmatch('([^{]*){(.-)}') do
      TextParser.parseFragment(fragments, textFragment)
      TextParser.parseCode(fragments, code)
		end
    local lastText = text:match('[^}]+$')
    if lastText then
      TextParser.parseFragment(fragments, lastText)
    end
	end
  return fragments
end
--- Parse and insert new fragment(s).
-- @tparam table fragments Array of parsed fragments.
-- @tparam string textFragment Unparsed (and unwrapped) text fragment.
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
--- Parse and insert new fragment(s) according to code.
-- @tparam table fragments Array of parsed fragments.
-- @tparam string code The next code inside braces.
function TextParser.parseCode(fragments, code)
  local t = code:sub(1, 1)
  if not TextParser.Code[t] then
    TextParser.parseFragment(fragments, '{' .. code .. '}')
    --error('Text command not identified: ' .. (t or 'nil'))
    return
  end
  if t == '%' then
    local key = code:sub(2)
    local value = GameManager:getVariable(key, _G.Fiber, FieldManager.currentField)
    assert(value ~= nil, 'Text variable or term not found: ' .. tostring(key))
    local f = tostring(value)
    if plainText then
      TextParser.parseFragment(fragments, f)
    else
      TextParser.parse(f, false, fragments)
    end
    return
  end
  local fragment = { type = TextParser.Code[t] }
  if t == 'f' then
    fragment.value = Fonts[code:sub(2)]
  elseif t == '+' then
    fragment.value = tonumber(code:sub(2))
  elseif t == '-' then
    fragment.value = -tonumber(code:sub(2))
  elseif t == 'c' then
    fragment.value = Color[code:sub(2)]
  elseif t == 's' then
    fragment.value = Config.icons[code:sub(2)]
  elseif t == 'a' then
    fragment.value = Config.sounds[code:sub(2)]
    fragment.event = true
  elseif t == 't' then
    fragment.value = tonumber(code:sub(2))
    fragment.event = true
  elseif t == 'p' then
    fragment.event = true
  end
  insert(fragments, fragment)
end

-- ------------------------------------------------------------------------------------------------
-- Lines
-- ------------------------------------------------------------------------------------------------

--- Creates line list. Each line is a table containing an array of fragments, a height and a width.
-- It also contains its length for character counting.
-- @tparam table fragments Array of fragments.
-- @tparam Fonts.Info initialFont The default font.
-- @tparam[opt] number maxWidth The width limit for wrapped text.
-- @tparam[opt=1] number scale Text's size multiplier.
-- @treturn table Array of lines.
-- @treturn table Array of text events.
function TextParser.createLines(fragments, initialFont, maxWidth, scale)
  local currentFont = ResourceManager:loadFont(initialFont, scale)
  local currentFontInfo = { unpack(initialFont) }
  local currentLine = { width = 0, height = 0, length = 0, { content = currentFont, info = currentFontInfo } }
  local lines = { currentLine, length = 0, scale = scale }
  local events = {}
  local point = 0
  scale = scale or 1
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
--- Cuts the text in the given character index.
-- @tparam table lines Array of parsed lines.
-- @tparam number point The index of the last text character.
-- @treturn table New array of parsed lines.
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

-- ------------------------------------------------------------------------------------------------
-- Text Fragments
-- ------------------------------------------------------------------------------------------------

--- Inserts new text fragment to the given line (may have to add new lines).
-- @tparam table lines The array of lines.
-- @tparam table currentLine The line of the fragment.
-- @tparam string fragment The text fragment.
-- @tparam Font font Font of the text in this fragment.
-- @tparam[opt] number maxWidth The width limit for wrapped text.
-- @tparam[opt=1] number scale Text's size multiplier.
-- @treturn table The new current line.
-- @treturn number Total length of the fragment inserted.
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
--- Wraps text fragment (may have to add new lines).
-- @tparam table lines The array of lines.
-- @tparam table currentLine The line of the fragment.
-- @tparam string fragment The text fragment.
-- @tparam Font font Font of the text in this fragment.
-- @tparam number width Max width for wrapping.
-- @treturn table The new current line.
-- @treturn number Total length of the fragment inserted.
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
--- Inserts a new fragment into the line.
-- @tparam table lines Array of all lines.
-- @tparam table currentLine The line that the fragment will be inserted.
-- @tparam table|string fragment The fragment to insert.
-- @tparam Font font The font of the fragment's text (in case the fragment is a string).
-- @treturn number The length of the inserted fragment.
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
