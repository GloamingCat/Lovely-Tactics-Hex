
--[[
@module 

Overrides to print full stack trace in coroutine calls.

]]

local function err(msg) 
  print(debug.traceback(msg, 2))  
end
local old_coroutine_create = coroutine.create
function coroutine.create(func)
  local pfunc = function() 
    xpcall(func, err)
  end
  return old_coroutine_create(pfunc)
end