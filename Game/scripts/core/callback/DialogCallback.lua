
--[[===========================================================================

DialogCallback
-------------------------------------------------------------------------------
A base class  to callback that starts a dialog with player.

=============================================================================]]

-- Imports
local Callback = require('core/callback/Callback')

local DialogCallback = Callback:inherit()

-- Override Callback:initializeCoroutine.
function DialogCallback:initializeCoroutine(arg)
  local player = FieldManager.player
  local event = arg[1]
  local cofunc = function()
      local dir = event.dest.direction
      event.dest:turnToPoint(player.position.x, player.position.z)
      player.blocks = player.blocks + 1
      self:exec(unpack(arg))
      player.blocks = player.blocks - 1
      event.dest:setDirection(dir)
  end
  self.coroutine = coroutine.create(cofunc)
end

return DialogCallback
