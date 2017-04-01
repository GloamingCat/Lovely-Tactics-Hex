
--[[===========================================================================

Callback
-------------------------------------------------------------------------------
A piece of code that may be executed in coroutines, as a separate "process"
or "thread". It must be updated by its tree every frame.

=============================================================================]]

-- Imports
local CallbackTree = require('core/callback/CallbackTree')

-- Alias
local time = love.timer.getDelta

local Callback = CallbackTree:inherit()

-- @param(exec : Function) the callback's function
-- @param(... : unknown) the function's parameters
local old_init = Callback.init
function Callback:init(exec, ...)
  local arg = {...}
  old_init(self)
	self.parent = nil
	self.exec = self.exec or exec 
  self:initializeCoroutine(arg)
end

-- Creates coroutine function.
-- @param(arg : table) the array of the arguments to pass to the function
function Callback:initializeCoroutine(arg)
  local cofunc = function()
      self:exec(unpack(arg))
  end
  self.coroutine = coroutine.create(cofunc)
end

-- Resumes the coroutine and sets this callback as "current".
-- @param(co : coroutine) this callback's coroutine
function Callback:resume(co)
  if coroutine.status(co) == 'dead' then
    return false
  else
    local previous = _G.Callback
    _G.Callback = self
    local state, result = coroutine.resume(co)
    if not state then
      error( tostring(result), 2 )	-- Output error message
      return false
    end
    _G.Callback = previous
    return true
  end
end

-- Updates all children if the coroutine is still active.
local old_update = Callback.update
function Callback:update()
  if self:resume(self.coroutine) then
    old_update(self)
    return true
  else
    return false
  end
end

-------------------------------------------------------------------------------
-- Auxiliary functions
-------------------------------------------------------------------------------

-- Executes this callback until it finishes.
-- Specially useful when the parent callback must wait until this one finishes.
function Callback:execAll()
  while self:update() do
  end
end

-- Wait for frames.
-- @param(t : number) the number of frames to wait.
--  Consider a rate of 60 frames per second.
function Callback:wait(t)
  while t > 0 do
    t = t - time() * 60
    coroutine.yield()
  end
end

-- Waits until a given condition returns true.
-- @param(func : function) a function that returns a boolean
function Callback:waitUntil(func)
  while not func() do
    coroutine.yield()
  end
end

-- Moves this callback to another parent callback or tree.
-- Be aware that this callback may be updated two times in the same 
-- frame (if the new parent is updated after the old one).
-- @param(parent : CallbackTree) the new parent
function Callback:moveTo(parent)
  if self.parent then
    self.parent.children:removeElement(self)
  end
  parent:addChild(self)
end

return Callback
