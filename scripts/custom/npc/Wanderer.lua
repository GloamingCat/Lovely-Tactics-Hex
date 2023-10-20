-- ================================================================================================

--- NPC that walks around while it is not blocking the player.
---------------------------------------------------------------------------------------------------
-- @event Wanderer

-- ================================================================================================

-- Alias
local rand = love.math.random

return function(script)

  --- Contains the tags from the Script's data.
  -- @table param
  -- @tfield number Pause time in frames between each step.
  -- @tfield number Variation of the pause in frames (optional, 0 by default).
  local param = script.args

  script.char.approachToInteract = false
  local pause = tonumber(param.pause) or 60
  local pauseVar = tonumber(param.pauseVar) or 0
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