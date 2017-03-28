
--[[===========================================================================

ParallelCallback
-------------------------------------------------------------------------------
A base callback that always execute in parallel with its caller.

=============================================================================]]

-- Imports
local Callback = require('core/callback/Callback')

local ParallelCallback = Callback:inherit()

-- Override Callback:initializeCoroutine.
function ParallelCallback:initializeCoroutine(arg)
  local player = FieldManager.player
  local event = arg[1]
  local cofunc = function()
      self:fork(self.exec, unpack(arg))
  end
  self.coroutine = coroutine.create(cofunc)
end

return ParallelCallback
