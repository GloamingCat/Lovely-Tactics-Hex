
local Window = require('core/gui/Window')

--[[===========================================================================

An example of usage of an eventsheet for a Field.

=============================================================================]]

local Callback = require('core/callback/Callback'):inherit()

function Callback:exec(event, ...)
 --[[ local transition = FieldManager:getPlayerTransition()
  transition.fieldID = 1
  self:wait(90)
  transition.tileX = transition.tileX + 10
  --FieldManager:loadBattle(1)
  FieldManager:loadTransition(transition)
  self:wait(90)
  transition.tileY = transition.tileY + 10
  FieldManager:loadTransition(transition)
  self:wait(90)]]
  FieldManager:loadBattle(1)
end

return Callback
