
-- ================================================================================================

--- Overrides a few functions from standard libraries.
---------------------------------------------------------------------------------------------------
-- @script Override

-- ================================================================================================

-- Rewrites
local old_require = require
local old_loadstring = loadstring

-- ------------------------------------------------------------------------------------------------
-- String
-- ------------------------------------------------------------------------------------------------

--- Formats a string to time.
-- @tparam number time Time in seconds.
function string.time(time)
  local sec = time % 60
  local min = ((time - sec) / 60) % 60
  local hour = (time - 60 * min - sec) / 3600
  return string.format("%02d:%02d:%02d", hour, min, sec)
end
--- Splits a string in substring by the given separator.
-- @tparam string inputstr String to be splitted.
-- @tparam[opt="%s+"] string sep Separator.
-- @treturn table Array of substrings.
function string:split(sep)
  sep = sep or "%s+"
  local t, i = {}, 1
  for str in self:gmatch('([^' .. sep .. ']+)') do
    t[i] = str
    i = i + 1
  end
  return t
end
--- Removes spaces in the start and end of the string.
-- @treturn string New trimmed string.
function string.trim(self)
  return self:gsub("^%s+", ""):gsub("%s+$", "")
end
--- Checks if the first string ends with the second.
-- @tparam string suffix Suffix to be looked for.
-- @treturn boolean True if `suffix` is found at the end of `inputstr`. 
function string.endswith(self, suffix)
  return self:sub(-string.len(suffix)) == suffix
end
--- Interpolates the raw string.
-- @tparam function varAccessor Function that receives a key and returns the value.
-- @param ... Any additional params passed to `varAccessor`. 
-- @treturn string The interpolated string.
function string.interpolate(self, varAccessor, ...)
  local str = ""
  local i = 0
  for textFragment, key in self:gmatch('([^{]*){%%([^}]-)}') do
    local value = varAccessor(key, ...)
    if value == nil then
      print('Text variable or term not found: ' .. tostring(key), ...)
    end
    local f = tostring(value)
    i = i + #textFragment + #key + 3
    str = str .. textFragment .. f:interpolate(varAccessor, ...)
  end
  local lastText = self:sub(i + 1)
  if lastText then
    str = str .. lastText
  end
  return str
end

-- ------------------------------------------------------------------------------------------------
-- Require
-- ------------------------------------------------------------------------------------------------

--- Rewrites `require`. Changes Lua's default require function to ignore ".lua" extension.
-- @rewrite
require = function(path)
  return old_require(string.gsub(path, '%.lua', ''))
end

-- ------------------------------------------------------------------------------------------------
-- Function Cache
-- ------------------------------------------------------------------------------------------------

local FunctionCache = {}

--- Rewrites `loadstring`. Changes Lua's native function to store string in cache if already compiled.
-- @rewrite
function loadstring(str, ...)
  local func = FunctionCache[str]
  if func then
    return func
  else
    local err
    func, err = old_loadstring(str, ...)
    FunctionCache[str] = func
    return func, err
  end
end
--- Creates a function with the given body and the given parameters.
-- @tparam string body The code of the body.
-- @tparam string param The list of parameters separated by comma (without parens).
-- @tparam[opt] boolean unsafe Flag to indice that the text is not always a Lua expression,
--  and in case it isn't, return nil.
function loadfunction(body, param, unsafe)
  local func, err
  if param and param ~= '' then
    local funcString = 
      'function(' .. param .. ') ' ..
        body ..
      ' end'
    func, err = loadstring('return ' .. funcString)
    if func then
      func = func()
    end
  else
    func, err = loadstring(body)
  end
  assert(func or unsafe, err)
  return func
end
--- Generates a function from a formula in string.
-- @tparam string formula The formula expression.
-- @tparam[opt] string param The param needed for the function.
-- @tparam[opt] boolean unsafe Flag to indice that the text is not always a Lua expression,
--  and in case it isn't, return nil.
-- @treturn function The function that evaluates the formula.
function loadformula(formula, param, unsafe)
  if formula == '' or not formula then
    formula = 'nil'
  end
  return loadfunction('return ' .. formula, param, unsafe)
end
