
-- ================================================================================================

--- Used to create a thread. Needs two arguments when started: the channel object (where the result 
-- of the function will be stored) and a function to be executed.
---------------------------------------------------------------------------------------------------
-- @script Thread

-- ================================================================================================

--- Runs a new thread with given channel.
-- @tparam Channel channel The channel the result will be put in.
-- @tparam function func The function to be executed.
-- @param ... Any other arguments to func.
local function run(channel, func, ...)
  local r = {func(...)}
  for i = 1, #r do
    channel:push(r[i])
  end
end

run(...)