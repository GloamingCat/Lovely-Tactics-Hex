
---------------------------------------------------------------------------------------------------
-- String
---------------------------------------------------------------------------------------------------

-- Formats a string to time.
-- @param(time : number) Time in seconds.
function string.time(time)
  local sec = time % 60
  local min = (time - sec) / 60
  local hour = (time - 60 * min - sec) / 60 
  return string.format("%02d:%02d:%02d", hour, min, sec)
end
-- Splits a string in substring by the given separator.
-- @param(inputstr : string) String to be splitted.
-- @param(sep : string) Separator (optional, black spaces by default).
-- @ret(table) Array of substrings.
function string.split(inputstr, sep)
  sep = sep or "\\s+"
  local t, i = {}, 1
  for str in inputstr:gmatch('([^' .. sep .. ']+)') do
    t[i] = str
    i = i + 1
  end
  return t
end
-- Removes spaces in the start and end of the string.
-- @param(inputstr : string) String to be trimmed.
-- @ret(string) New trimmed string.
function string.trim(inputstr)
  return inputstr:gsub("^%s+", ""):gsub("%s+$", "")
end
-- Checks if first string contains the second.
-- @param(inputstr : string) Longer string.
-- @param(substr : string) Substring.
-- @ret(boolean)
function string.contains(inputstr, substr)
  return inputstr:gmatch(substr) ~= nil
end
-- Checks if first string ends with the second.
-- @param(inputstr : string)
-- @param(suffix : string)
-- @ret(boolean)
function string.endswith(inputstr, suffix)
  return inputstr:sub(-string.len(suffix)) == suffix
end

---------------------------------------------------------------------------------------------------
-- Require
---------------------------------------------------------------------------------------------------

-- Overrides Lua's default require function to ignore ".lua" extension.
local old_require = require
require = function(path)
  return old_require(string.gsub(path, '.lua', ''))
end

---------------------------------------------------------------------------------------------------
-- Coroutine Error
---------------------------------------------------------------------------------------------------

-- Prints coroutine error.
-- @param(msg : string) error message
local function err(msg) 
  print(debug.traceback(msg, 2))  
end
-- Overrides Lua's native coroutine.create function to show errors inside the coroutine.
-- @param(func : function) the coroutine's function
-- @ret(coroutine) the newly created coroutine
local old_coroutine_create = coroutine.create
function coroutine.create(func)
  local pfunc = function() 
    xpcall(func, err)
  end
  return old_coroutine_create(pfunc)
end

---------------------------------------------------------------------------------------------------
-- Function Cache
---------------------------------------------------------------------------------------------------

local FunctionCache = {}

-- Overrides Lua's native function to store string in cache if already compiled.
-- @param(str : string) the string chunk
-- @param(...) any other parameters to the original loadstring function
-- @ret(function) the function that executes the chunk in the string
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
-- Creates a function with the given body and the given parameters.
-- @param(body : string) the code of the body
-- @param(param : string) the list of parameters separated by comma (without parens)
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
-- Generates a function from a formula in string.
-- @param(formula : string) the formula expression
-- @param(param : string) the param needed for the function (optional)
-- @ret(function) the function that evaluates the formulae
function loadformula(formula, param)
  if formula == '' or not formula then
    formula = 'nil'
  end
  return loadfunction('return ' .. formula, param)
end
