
--[[===============================================================================================

Fiber
---------------------------------------------------------------------------------------------------
A piece of code that may be executed in coroutines, as a separate "process"
or "thread". It must be updated by its root every frame.

=================================================================================================]]

-- Alias
local status = coroutine.status
local resume = coroutine.resume
local yield = coroutine.yield
local time = love.timer.getDelta

local Fiber = class()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(root : FiberList) the list of fibers this Fiber belongs to
-- @param(func : function) this fiber's function
function Fiber:init(root, func, ...)
  if root then
    root:add(self)
    self.root = root
  end
  self.interruptable = true
  local arg = {...}
  self.coroutine = coroutine.create(function()
    func(unpack(arg))
  end)
end

-- Creates new Fiber from a script table.
-- @param(root : FiberList) the list this Fiber belongs to
-- @param(script : table) script table with "path" and "param" fields
-- @param(...) any other arguments to the Fiber
-- @ret(Fiber) the newly created Fiber (nil if path is empty)
function Fiber.fromScript(root, script, ...)
  if script.path ~= '' then
    local func = require('custom/' .. script.path)
    return Fiber(root, func, script.param, ...)
  end
end

-- Resumes the coroutine and sets this fiber as "current".
function Fiber:update()
  if not self.coroutine then
    return
  end
  if status(self.coroutine) == 'dead' then
    self.coroutine = nil
  else
    local previous = _G.Fiber
    _G.Fiber = self
    local state, result = resume(self.coroutine)
    if not state then
      error( tostring(result), 2 )	-- Output error message
      self.coroutine = nil
    end
    _G.Fiber = previous
  end
end

-- Checks if this fiber is still running.
-- @ret(boolean) false if already ended, true otherwise
function Fiber:running()
  return self.coroutine ~= nil
end

-- Creates a new fiber in from the same root.
-- @param(func : function) the function of the new Fiber
-- @ret(Fiber) newly created Fiber
function Fiber:fork(func, ...)
  return Fiber(self.root, func, ...)
end

-- Forcefully end this Fiber, if possible.
function Fiber:interrupt()
  if self.interruptable then
    self.coroutine = nil
  end
end

-------------------------------------------------------------------------------
-- Auxiliary functions
-------------------------------------------------------------------------------

-- Wait until this fiber's function finishes.
-- Specially useful when other fiber must wait until this one finishes.
function Fiber:waitForEnd()
  while self.coroutine do
    yield()
  end
end

-- Executes this fiber until it finishes.
-- Used specially when this fiber does not have a root, 
--  so it's not updated every frame.
function Fiber:execAll()
  while self:update() do
  end
end

-- Wait for frames.
-- @param(t : number) the number of frames to wait.
--  Consider a rate of 60 frames per second.
function Fiber:wait(t)
  while t > 0 do
    t = t - time() * 60
    yield()
  end
end

-- Waits until a given condition returns true.
-- @param(func : function) a function that returns a boolean
function Fiber:waitUntil(func)
  while not func() do
    yield()
  end
end

function Fiber:__tostring()
  return 'Fiber: ' .. tostring(self.coroutine)
end

return Fiber
