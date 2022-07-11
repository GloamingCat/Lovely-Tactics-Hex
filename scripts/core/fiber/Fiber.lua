
--[[===============================================================================================

Fiber
---------------------------------------------------------------------------------------------------
A piece of code that may be executed in coroutines, as a separate "process" or "thread". 
It must be updated by its root every frame, unless it's paused.

=================================================================================================]]

-- Alias
local insert = table.insert
local create = coroutine.create
local status = coroutine.status
local resume = coroutine.resume
local yield = coroutine.yield

local Fiber = class()

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(root : FiberList) The list of fibers this Fiber belongs to.
-- @param(func : function) This fiber's function (substitutes "execute" method).
function Fiber:init(root, func, ...)
  if root then
    root:add(self)
    self.root = root
  end
  self.interruptable = true
  local arg = {...}
  if not func then
    insert(arg, 1, self)
    func = self.execute
  end
  self.execute = func
  self.origin = debug.getinfo(3, "n")
  self.coroutine = create(function()
    func(unpack(arg))
  end)
end
-- Creates new Fiber from a script table.
-- @param(root : FiberList) The list this Fiber belongs to.
-- @param(path : string) Path to script from "custom" folder.
-- @param(...) Any other arguments to the Fiber.
-- @ret(Fiber) The newly created Fiber (nil if path is empty).
function Fiber:fromScript(root, path, ...)
  local func = require('custom/' .. path)
  return self(root, func, ...)
end
-- Functions that this fiber executes.
function Fiber:execute()
  -- Abstract.
end
-- Resumes the coroutine and sets this fiber as the global Fiber.
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
      -- Output error message
      error( tostring(result), 2 )
      self.coroutine = nil
    end
    _G.Fiber = previous
  end
end
-- Checks if this fiber is still running.
-- @ret(boolean) False if already ended, true otherwise.
function Fiber:running()
  return self.coroutine ~= nil
end
-- Creates a new fiber in from the same root that executes given function.
-- @param(func : function) The function of the new Fiber.
-- @ret(Fiber) Newly created Fiber.
function Fiber:fork(func, ...)
  return Fiber(self.root, func, ...)
end
-- Forcefully ends this Fiber, if possible.
function Fiber:interrupt()
  if self.interruptable then
    self.coroutine = nil
  end
end
-- @ret(string) String identification.
function Fiber:__tostring()
  return 'Fiber: ' .. tostring(self.origin.name)
end

---------------------------------------------------------------------------------------------------
-- Auxiliary functions
---------------------------------------------------------------------------------------------------

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
-- @param(t : number) The number of frames to wait.
--  Consider a rate of 60 frames per second.
function Fiber:wait(t)
  if not t then
    yield()
  else
    while t > 0 do
      t = t - GameManager:frameTime() * 60
      yield()
    end
  end
end
-- Waits until a given condition returns true.
-- @param(func : function) A function that returns a boolean.
-- @param(...) Function's parameters.
function Fiber:waitUntil(func, ...)
  local args = {...}
  while not func(unpack(args)) do
    yield()
  end
end
-- Calls a given function after a certain time.
-- @param(time : number) Time in frames.
-- @param(func : function) Function to be called.
-- @param(...) Function's parameters.
function Fiber:invoke(time, func, ...)
  local args = {...}
  self:fork(function()
    self:wait(time)
    func(unpack(args))
  end)
end

return Fiber
