
--[[===========================================================================

Stores loadstring cache.

=============================================================================]]

local FunctionCache = {}

-- Overrides Lua's native function to store string in cache if already compiled.
-- @param(str : string) the string chunk
-- @param(... : unknown) any other parameters to the original loadstring function
-- @ret(function) the function that executes the chunk in the string
local old_loadstring = loadstring
function loadstring(str, ...)
  local func = FunctionCache[str]
  if func then
    return func
  else
    func = old_loadstring(str, ...)
    FunctionCache[str] = func
    return func
  end
end
