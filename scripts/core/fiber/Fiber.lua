
--[[===============================================================================================

Fiber
---------------------------------------------------------------------------------------------------
A piece of code that may be executed in coroutines, as a separate "process" or "thread". 
It must be updated by its root every frame, unless it's paused.

=================================================================================================]]

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
    table.insert(arg, 1, self)
    func = self.execute
  end
  self.execute = function()
    func(unpack(arg))
  end
  self.origin = debug.getinfo(3, "n")
  self.traceback = debug.traceback() 
  self.coroutine = coroutine.create(self.execute)
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
  if coroutine.status(self.coroutine) == 'dead' then
    self:finish()
  else
    local previous = _G.Fiber
    _G.Fiber = self
    local state, result = coroutine.resume(self.coroutine)
    if not state then
      -- Output error message
      print(result:gsub(".*ore%/", "scripts/core/"))
      print('Coroutine ' .. tostring(debug.traceback(self.coroutine)):gsub(".*ore%/", "scripts/core/"))
      print('Origin ' .. tostring(self.traceback))
      error("Error updating coroutine.")
      if GameManager:isMobile() and not GameManager:isWeb() then
        love.window.showMessageBox("Error", tostring(result))
      end
      self:finish()
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
    self:finish()
  end
end
-- @ret(string) String identification.
function Fiber:__tostring()
  return 'Fiber: ' .. tostring(self.origin.name)
end
-- Called when the coroutine finished executing.
function Fiber:finish()
  self.coroutine = nil
end

---------------------------------------------------------------------------------------------------
-- Auxiliary functions
---------------------------------------------------------------------------------------------------

-- Executes this fiber until it finishes.
-- Used specially when this fiber does not have a root, 
--  so it's not updated every frame.
function Fiber:execAll()
  while self:update() do
  end
end
-- [COROUTINE] Wait until this fiber's function finishes.
-- Specially useful when other fiber must wait until this one finishes.
function Fiber:waitForEnd()
  assert(coroutine.running(), 'Called by main thread.')
  while self.coroutine do
    coroutine.yield()
  end
end
-- [COROUTINE] Wait for frames.
-- @param(t : number) The number of frames to wait.
--  Consider a rate of 60 frames per second.
function Fiber:wait(t)
  assert(coroutine.running(), 'Called by main thread.')
  if not t then
    coroutine.yield()
  else
    while t > 0 do
      t = t - GameManager:frameTime() * 60
      coroutine.yield()
    end
  end
end
-- [COROUTINE] Waits until a given condition returns true.
-- @param(func : function) A function that returns a boolean.
-- @param(...) Function's parameters.
function Fiber:waitUntil(func, ...)
  assert(coroutine.running(), 'Called by main thread.')
  local args = {...}
  while not func(unpack(args)) do
    coroutine.yield()
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
