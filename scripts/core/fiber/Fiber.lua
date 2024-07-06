
-- ================================================================================================

--- A piece of code that may be executed in coroutines.
-- It must be updated by its root every frame, unless it's paused.
---------------------------------------------------------------------------------------------------
-- @basemod Fiber

-- ================================================================================================

-- Class table.
local Fiber = class()

-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam FiberList root The list of fibers this Fiber belongs to.
-- @tparam function func This fiber's function (substitutes "execute" method).
function Fiber:init(root, func, ...)
  if root then
    root:add(self)
    self.root = root
  end
  self.interruptable = true
  local n = select("#", ...)
  local arg
  if not func then
    arg = { self, ... }
    n = n + 1
    func = self.execute
  else
    arg = {...}
  end
  self.execute = function()
    func(unpack(arg, 1, n))
  end
  self.origin = debug.getinfo(3, "n")
  self.traceback = debug.traceback() 
  self.coroutine = coroutine.create(self.execute)
  self.name = self.origin.name
end
--- Creates new Fiber from a script table.
-- @tparam FiberList root The list this Fiber belongs to.
-- @tparam string path Path to script from "custom" folder.
-- @param ... Any other arguments to the Fiber.
-- @treturn Fiber The newly created Fiber (nil if path is empty).
function Fiber:fromScript(root, path, ...)
  local func = require('custom/' .. path)
  return self(root, func, ...)
end
--- Functions that this fiber executes.
function Fiber:execute()
  -- Abstract.
end
--- Resumes the coroutine with this fiber as the global Fiber.
function Fiber:update()
  if not self.coroutine then
    return
  end
  local previous = _G.Fiber
  _G.Fiber = self
  local state, msg = coroutine.resume(self.coroutine)
  if not state then
    -- Output error message
    self:printStackTrace(msg)
    if GameManager:isMobile() and not GameManager:isWeb() then
      love.window.showMessageBox("Error", tostring(msg))
    end
    error("Error updating coroutine " .. tostring(self))
  end
  if self.coroutine and coroutine.status(self.coroutine) == 'dead' then
    self:finish()
  end
  _G.Fiber = previous
end
--- Prints the stacktrace for a given error message.
-- @tparam string msg Error message.
function Fiber:printStackTrace(msg)
  msg = tostring(msg):gsub("%.%.%./?%w*ore%/", "scripts/core/"):gsub("%.%.%.%w*s%/", "scripts/")
  print(msg)
  local traceback = debug.traceback(self.coroutine)
  traceback = traceback:gsub("%.%.%./?%w*ore%/", "scripts/core/"):gsub("%.%.%.%w*s%/", "scripts/")
  print('Coroutine ' .. tostring(traceback))
  local origintraceback = self.traceback
  origintraceback = origintraceback:gsub("%.%.%./?%w*ore%/", "scripts/core/"):gsub("%.%.%.%w*s%/", "scripts/")
  print('Origin ' .. tostring(origintraceback))
end
--- Checks if this fiber is still running.
-- @treturn boolean False if already ended, true otherwise.
function Fiber:isRunning()
  return self.coroutine ~= nil
end
--- Forcefully ends this Fiber, if possible.
function Fiber:interrupt()
  if self.interruptable then
    self:finish()
  end
end
--- Called when the coroutine finished executing.
function Fiber:finish()
  self.coroutine = nil
end

-- ------------------------------------------------------------------------------------------------
-- Fork
-- ------------------------------------------------------------------------------------------------

--- Delegates to `FiberList:fork`.
function Fiber:fork(...)
  return self.root:fork(...)
end
--- Delegates to `FiberList:forkMethod`.
function Fiber:forkMethod(...)
  return self.root:forkMethod(...)
end
--- Delegates to `FiberList:fork`.
function Fiber:forkFromScript(...)
  return self.root:forkFromScript(...)
end

-- ------------------------------------------------------------------------------------------------
-- Auxiliary functions
-- ------------------------------------------------------------------------------------------------

--- Wait until this fiber's function finishes.
-- Specially useful when other fiber must wait until this one finishes.
-- @coroutine
function Fiber:waitForEnd()
  assert(coroutine.running(), 'Called by main thread.')
  while self.coroutine do
    coroutine.yield()
  end
end
--- Wait for frames.
-- @coroutine
-- @tparam number t The number of frames to wait.
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
--- Waits until a given condition returns true.
-- @coroutine
-- @tparam function func A function that returns a boolean.
-- @param ... Function's parameters.
function Fiber:waitUntil(func, ...)
  assert(coroutine.running(), 'Called by main thread.')
  local args = {...}
  while not func(unpack(args)) do
    coroutine.yield()
  end
end
--- Calls a given function after a certain time.
-- @tparam number time Time in frames.
-- @tparam function func Function to be called.
-- @param ... Function's parameters.
function Fiber:invoke(time, func, ...)
  local args = {...}
  self:fork(function()
    self:wait(time)
    func(unpack(args))
  end)
end
-- For debugging.
function Fiber:__tostring()
  return 'Fiber: ' .. tostring(self.name)
end

return Fiber
