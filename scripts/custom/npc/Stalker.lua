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
    if not FieldManager.player:isBusy() then
      if script.char.cooldown and script.char.cooldown > 0 then
        script.char.cooldown = script.char.cooldown - GameManager:frameTime() * 60
      else
        script.char:turnToPoint(FieldManager.player.position.x, FieldManager.player.position.z)
        if script.char:tryAngleMovement(script.char:getRoundedDirection()) then
          script.char:playIdleAnimation()
          script:wait(pause + rand(-pauseVar, pauseVar))
        end
      end
    end
    coroutine.yield()
  end
end
