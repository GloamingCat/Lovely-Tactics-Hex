--[[===============================================================================================

@script Wanderer
---------------------------------------------------------------------------------------------------
NPC that walks around while it is not blocking the player.

-- Parameters:
<pause> Pause in frames between each step.
<pauseVar> Variation of the pause in frames.

=================================================================================================]]

-- Alias
local rand = love.math.random

return function(script)
  script.char.approachToInteract = false
  local pause = tonumber(script.args.pause) or 60
  local pauseVar = tonumber(script.args.pauseVar) or 0
  while true do
    Fiber:wait()
    if not (FieldManager.player:isBusy() or script.char.interacting) then
      local shift = math.field.neighborShift[rand(#math.field.neighborShift)]
      local angle = script.char:shiftToRow(shift.x, shift.y) * 45
      if script.char:tryAngleMovement(angle) then
        script.char:playIdleAnimation()
        script:wait(pause + rand(-pauseVar, pauseVar))
      end
    end
  end
end