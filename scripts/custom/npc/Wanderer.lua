--[[===============================================================================================

Wanderer
---------------------------------------------------------------------------------------------------
NPC that walks around while it is not blocking the player.

-- Arguments:
<pause> Pause in frames between each step.
<pauseVar> Variation of the pause in frames.

=================================================================================================]]

-- Alias
local rand = love.math.random

return function(script)
  local pause = tonumber(script.args.pause) or 60
  local pauseVar = tonumber(script.args.pauseVar) or 0
  while true do
    Fiber:wait()
    if not (FieldManager.player:isBusy() or script.char.interactScriptIndex) then
      local dir = rand(8) * 45
      if script.char:tryAngleMovement(dir) then
        script.char:playIdleAnimation()
        script:wait(pause + rand(-pauseVar, pauseVar))
      end
    end
  end
end