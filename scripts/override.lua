
--[[===============================================================================================

@script Overrides
---------------------------------------------------------------------------------------------------
Overrides a few functions from standard libraries.

=================================================================================================]]

-- ------------------------------------------------------------------------------------------------
-- String
-- ------------------------------------------------------------------------------------------------

--- Formats a string to time.
-- @tparam number time Time in seconds.
function string.time(time)
  local sec = time % 60
  local min = (time - sec) / 60
  local hour = (time - 60 * min - sec) / 60 
  return string.format("%02d:%02d:%02d", hour, min, sec)
end
--- Splits a string in substring by the given separator.
-- @tparam string inputstr String to be splitted.
-- @tparam string sep Separator (optional, black spaces by default).
-- @treturn table Array of substrings.
function string.split(inputstr, sep)
  sep = sep or "%s+"
  local t, i = {}, 1
  for str in inputstr:gmatch('([^' .. sep .. ']+)') do
    t[i] = str
    i = i + 1
  end
  return t
end
--- Removes spaces in the start and end of the string.
-- @tparam string inputstr String to be trimmed.
-- @treturn string New trimmed string.
function string.trim(inputstr)
  return inputstr:gsub("^%s+", ""):gsub("%s+$", "")
end
--- Checks if first string ends with the second.
-- @tparam string inputstr String to be verified.
-- @tparam string suffix Suffix to be looked for.
-- @treturn boolean
function string.endswith(inputstr, suffix)
  return inputstr:sub(-string.len(suffix)) == suffix
end

-- ------------------------------------------------------------------------------------------------
-- Require
-- ------------------------------------------------------------------------------------------------

--- Overrides Lua's default require function to ignore ".lua" extension.
local old_require = require
require = function(path)
  return old_require(string.gsub(path, '.lua', ''))
end

-- ------------------------------------------------------------------------------------------------
-- Function Cache
-- ------------------------------------------------------------------------------------------------

local FunctionCache = {}

--- Overrides Lua's native function to store string in cache if already compiled.
-- @tparam string str The string chunk.
-- @tparam(...) Any other parameters to the original loadstring function.
-- @treturn function The function that executes the chunk in the string.
local old_loadstring = loadstring
function loadstring(str, ...)
  local func = FunctionCache[str]
  if func then
    return func
  else
    local err
    func, err = old_loadstring(str, ...)
    assert(func, err)
    FunctionCache[str] = func
    return func
  end
end
--- Creates a function with the given body and the given parameters.
-- @tparam string body The code of the body.
-- @tparam string param The list of parameters separated by comma (without parens).
function loadfunction(body, param)
  if param and param ~= '' then
    local funcString = 
      'function(' .. param .. ') ' ..
        body ..
      ' end'
    return loadstring('return ' .. funcString)()
  else
    return loadstring(body)
  end
end
--- Generates a function from a formula in string.
-- @tparam string formula The formula expression.
-- @tparam string param The param needed for the function (optional).
-- @treturn function The function that evaluates the formula.
function loadformula(formula, param)
  if formula == '' or not formula then
    formula = 'nil'
  end
  return loadfunction('return ' .. formula, param)
end
