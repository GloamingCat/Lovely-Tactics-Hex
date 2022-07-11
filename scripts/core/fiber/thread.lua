
--[[===============================================================================================

Thread
---------------------------------------------------------------------------------------------------
Used to create a thread. Needs two arguments when started: the channel object (where the result 
of the function will be stored) and a function to be executed.

=================================================================================================]]

-- @param(channel : Channel) the channel the result will be put in
-- @param(func : function) the function to be executed
-- @param(...) any other arguments to func
local function run(channel, func, ...)
  local r = {func(...)}
  for i = 1, #r do
    channel:push(r[i])
  end
end

run(...)