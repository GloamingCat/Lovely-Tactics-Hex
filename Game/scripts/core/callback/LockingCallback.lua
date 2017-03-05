

local Callback = require('core/callback/Callback')

--[[
@module 

A base callback that blocks player's input during its execution.

]]

local LockingCallback = Callback:inherit()

-- Override Callback:initializeCoroutine.
function LockingCallback:initializeCoroutine(arg)
  local player = FieldManager.player
  local cofunc = function()
      player.blocks = player.blocks + 1
      self:exec(unpack(arg))
      player.blocks = player.blocks - 1
  end
  self.coroutine = coroutine.create(cofunc)
end

return LockingCallback
