--[[===============================================================================================

Stalker
---------------------------------------------------------------------------------------------------
NPC that walks towards the player.

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
    script.char:playIdleAnimation()
    if script.player:isBusy() or script.player.blocks > 1 then
      coroutine.yield()
    else
      script:wait(pause + rand(-pauseVar, pauseVar))
      script.char:turnToPoint(script.player.position.x, script.player.position.z)
      script.char:tryAngleMovement(script.char:getRoundedDirection())
    end
  end
  
end